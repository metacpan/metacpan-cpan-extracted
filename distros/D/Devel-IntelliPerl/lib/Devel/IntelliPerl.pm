package Devel::IntelliPerl;
our $VERSION = '0.04';

use Moose;
use Moose::Util::TypeConstraints;
use PPI;
use Class::MOP;
use Path::Class;
use List::Util qw(first);

my $KEYWORD = '[a-zA-Z_][_a-zA-Z0-9]*';
my $CLASS   = '(' . $KEYWORD . ')(::' . $KEYWORD . ')*';
my $VAR     = '\$' . $CLASS;


has line_number => ( isa => 'Int', is => 'rw', required => 1 );
has column      => ( isa => 'Int', is => 'rw', required => 1 );
has filename    => ( isa => 'Str', is => 'rw', trigger  => \&update_inc );
has source      => ( isa => 'Str', is => 'rw', required => 1 );
has inc => ( isa => 'ArrayRef[Str]', is => 'rw' );
has ppi => (
    isa     => 'PPI::Document',
    is      => 'rw',
    lazy    => 1,
    builder => '_build_ppi',
    clearer => 'clear_ppi'
);
has error => ( isa => 'Str', is => 'rw' );

after source => sub {
    my $self = shift;
    $self->clear_ppi if (@_);
};

after inc => sub {
    my $self = shift;
    unshift( @INC, @{ $_[0] } ) if ( $_[0] );
};

sub update_inc {
    my $self = shift;
    return unless ( $self->filename );
    my $parent = Path::Class::File->new( $self->filename );
    my @libs;
    while ( $parent = $parent->parent ) {
        last if ( $parent eq $parent->parent );
        last unless -d $parent;
        push( @libs, $parent->subdir('lib')->stringify )
          if ( -e $parent->subdir('lib') );
    }
    return $self->inc( \@libs );
}

sub line {
    my ( $self, $line ) = @_;
    my @source = split( "\n", $self->source );
    if ( defined $line ) {
        $source[ $self->line_number - 1 ] = $line;
        $self->source( join( "\n", @source ) );
    }
    return $source[ $self->line_number - 1 ];
}

sub inject_statement {
    my ( $self, $statement ) = @_;
    my $line = $self->line;
    my $prefix = substr( $line, 0, $self->column - 1 );
    my $postfix;
    $postfix = substr( $self->line, $self->column - 1 )
      if ( length $self->line >= $self->column );
    $self->line( $prefix . $statement . ( $postfix || '' ) );
    return $self->line;
}

sub _build_ppi {
    return PPI::Document->new( \( shift->source ) );
}

sub keyword {
    my ($self) = @_;
    my $line = substr( $self->line, 0, $self->column - 1 );
    if ( $line =~ /.*?(\$?$CLASS(->($KEYWORD))*)->($KEYWORD)?$/ ) {
        return $1 || '';
    }
}

sub prefix {
    my ($self) = @_;
    my $line = substr( $self->line, 0, $self->column - 1 );
    if ( $line =~ /.*?(\$?$CLASS)->($KEYWORD)?$/ ) {
        return $4 || '';
    }
}

sub handle_self {
    my ( $self, $keyword ) = @_;
    $self->inject_statement('; my $FINDME;');
    my $doc     = $self->ppi;
    my $package = $doc->find_first('Statement::Package');

    return unless ($package);

    my $class = $package->namespace;

    my $var       = $doc->find('Statement::Variable');
    my $statement = first {
        first { $_ eq '$FINDME' } $_->variables;
    }
    @{$var};

    $statement->sprevious_sibling->remove;
    $statement->remove;
    eval "$doc";
    if ($@) {
        $self->error($@);
        return;
    }
    return $class;
}

sub handle_variable {
    my ( $self, $keyword ) = @_;
    my @source = split( "\n", $self->source );
    my @previous = reverse splice( @source, 0, $self->line_number - 1 );
    my $class = undef;
    foreach my $line (@previous) {
        if ( $line =~ /\Q$keyword\E.*?($CLASS)->new/ ) {
            $class = $1;
            last;
        }
        elsif ( $line =~ /\Q$keyword\E.*?new ($CLASS)/ ) {
            $class = $1;
            last;
        }
        elsif ( $line =~ /#.*\Q$keyword\E isa ($CLASS)/ ) {
            $class = $1;
            last;
        }
    }
    return $class;
}

sub handle_class {
    my ( $self, $keyword ) = @_;
    eval { Class::MOP::load_class($keyword); };
    if ($@) {
        $self->handle_self;
    }
    return $keyword;
}

sub handle_method {
    my ( $self, $keyword ) = @_;
    $keyword =~ /^(\$?$CLASS)((->($KEYWORD))+)$/;
    my ( undef, $method, @rest ) = split( /->/, $4 );
    my $class;
    my $pclass = $self->guess_class($1);
    $self->handle_class($pclass);
    my $meta = Class::MOP::Class->initialize($pclass);
    if ( $meta->has_attribute($method) ) {
        my $type_constraint = $meta->get_attribute($method)->type_constraint;
        my $class_tc;
        do {
            $class_tc = $type_constraint
              if ( $type_constraint->isa('Moose::Meta::TypeConstraint::Class') );
          } while ( !$class_tc
            && ( $type_constraint = $type_constraint->parent ) );

        $class = $class_tc->class if ($class_tc);
    }
    elsif ($meta->has_method($method)
        && ( my $method_meta = $meta->get_method($method) )
        && $meta->get_method($method)
        ->isa('MooseX::Method::Signatures::Meta::Method') )
    {

        my $constraints =
          $method_meta->_return_type_constraint->type_constraints;
        my $class_tc;
        foreach my $type_constraint (@$constraints) {
            do {
                $class_tc = $type_constraint
                  if (
                    $type_constraint->isa('Moose::Meta::TypeConstraint::Class')
                  );
                push( @$constraints, @{ $type_constraint->type_constraints } )
                  if ( $type_constraint->can('type_constraints') );
              } while ( !$class_tc
                && ( $type_constraint = $type_constraint->parent ) );
            last if $class_tc;
        }
        $class = $class_tc->class if ($class_tc);

    }
    return @rest
      ? $self->guess_class( $class . '->' . join( '->', @rest ) )
      : $class;
}

sub trimmed_methods {
    my ($self) = @_;
    my $prefix = $self->prefix;
    return map { substr( $_, length $prefix ) } $self->methods;
}

sub guess_class {
    my ( $self, $keyword ) = @_;
    if ( $keyword =~ /^\$self$/ ) {
        return $self->handle_self($keyword);
    }
    elsif ( $keyword =~ /^$VAR$/ ) {
        return $self->handle_variable($keyword);
    }
    elsif ( $keyword =~ /^(\$?$CLASS)(->($KEYWORD))+$/ ) {
        return $self->handle_method($keyword);
    }
    else {
        return $self->handle_class($keyword);
    }
    return;
}

sub methods {
    my ($self) = @_;
    my $keyword = $self->keyword;

    my $class = $self->guess_class($keyword);

    return unless ( $class && $class =~ /^$CLASS$/ );

    eval { Class::MOP::load_class($class); };
    if ($@) {
        $self->error($@);
        return;
    }

    my $prefix = $self->prefix;

    my $meta = Class::MOP::Class->initialize($class);

    my @methods =
      sort { $a =~ /^_/ cmp $b =~ /^_/ }
      sort { $a =~ /^[A-Z][A-Z]$KEYWORD/ cmp $b =~ /^[A-Z][A-Z]$KEYWORD/ }
      sort { lc($a) cmp lc($b) } $meta->get_all_method_names;

    return grep { $_ =~ /^$prefix/ } @methods;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Devel::IntelliPerl - Auto-completion for Perl


=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Devel::IntelliPerl;

    my $source = <<'SOURCE';
    package Foo;

    use Moose;

    has foobar => ( isa => 'Str', is => 'rw' );
    has foo => ( isa => 'Foo', is => 'rw' );

    sub bar {
        my ($self, $c) = @_;
        # $c isa Catalyst
        $self->
    }

    1;
    SOURCE


    my $ip = Devel::IntelliPerl->new(source => $source, line_number => 10, column => 12);
    
    my @methods = $ip->methods;
    
C<@methods> contains C<bar>, C<foo>, and C<foobar> amongst others.
Method completion for C<$c> works as well. Using the comment C<# $c isa Catalyst> you can specify
the variable C<$c> as an object of the C<Catalyst> class. This comment can be located anywhere in
the current file.

Even though the example uses Moose, this module works also with non Moose classes.

See L</SCREENCASTS> for usage examples.
    
=head1 ATTRIBUTES

=head2 line_number (Int $line_number)

B<Required>

Line number of the cursor. Starts at C<1>.

=head2 column (Int $column)

B<Required>

Position of the cursor. Starts at C<1>.

=head2 source (Str $source)

B<Required>

Source code.

=head2 filename

B<Optional>

Store the filename of the current file. If this value is set C<@INC> is extended by all C<lib> directories
found in any parent directory. This is useful if you want to have access to modules which are not in C<@INC> but in
your local C<lib> folder. This method sets L</inc>.

B<This value is NOT used to retrive the source code!> Use L<source|/source (Str $source)> instead.

=head2 inc (ArrayRef[Str] $inc)

B<Optional>

All directories specified will be prepended to C<@INC>.

=head1 METHODS

=head2 error (Str $error)

If an error occurs it is accessible via this method.

=head2 line (Str $line)

Sets or gets the current line.

=head2 keyword

This represents the current keyword.

Examples (C<_> stands for the cursor position):

  my $foo = MyClass->_ # keyword is MyClass
  my $foo->_           # keyword is $foo
  my $foo->bar->_      # keyword is $foo->bar
  
=head2 prefix

Part of a method which has been typed already.

Examples (C<_> stands for the cursor position):

  my $foo = MyClass->foo_ # keyword is MyClass, prefix is foo
  my $foo->bar_           # keyword is $foo,    prefix is bar

=head2 methods

Returns all methods which were found for L</keyword> and L</prefix>.

=head2 trimmed_methods

Returns L</methods> truncated from the beginning by the length of L</prefix>.

=head1 INTERNAL METHODS

=head2 guess_class (Str $keyword)

Given a keyword (e.g. C<< $foo->bar->file >>) this method tries to find the class
from which to load the methods.

=head2 handle_class

Loads the selected class.

=head2 handle_self

Loads the current class.

=head2 handle_method

This method tries to resove the class of the returned value of a given method.
It supports Moose attributes as well as L<MooseX::Method::Signatures>.

Example for an instrospectable class:

    package Signatures;

    use Moose;
    use Path::Class::File;
    use MooseX::Method::Signatures;
    use Moose::Util::TypeConstraints;
    
    has dir => ( isa => 'Path::Class::Dir', is => 'rw' );

    BEGIN { class_type 'PathClassFile', { class => 'Path::Class::File' }; }

    method file returns (PathClassFile) {
        return new Path::Class::File;
    }

    1;

Given this class, Devel::IntelliPerl provides the following features:

  my $sig = new Signatures;
  $sig->_        # will suggest "dir" and "file" amongst others
  $sig->file->_  # will suggest all methods from Path::Class::File

=head2 handle_variable

Tries to find the variable's class using regexes. Supported syntaxes:

  $variable = MyClass->new
  $variable = MyClass->new(...)
  $variable = new MyClass
  # $variable isa MyClass

=head2 inject_statement (Str $statement)

Injects C<$statement> at the current position.

=head2 update_inc

Trigger called by L</filename>.

=head1 SCREENCASTS

L<http://www.screencast.com/t/H5DdRNbQVt>

L<http://www.screencast.com/t/djkraaYgpx>

=head1 TODO

=over

=item Support for auto completion in the POD (e.g. C<< L <Devel::IntelliPerl/[auto complete]> >>)

=back

=head1 AUTHOR

Moritz Onken, C<< <onken at netcubed.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-intelliperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-IntelliPerl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::IntelliPerl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-IntelliPerl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-IntelliPerl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-IntelliPerl>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-IntelliPerl/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut