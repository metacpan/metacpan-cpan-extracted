package File::Rules;

use warnings;
use strict;
use Carp;
use File::Spec;
use Data::Dump qw( dump );
use Path::Class;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $rules = ref( $_[0] ) ? shift : [@_];
    my $self  = bless { _rules => [] }, $class;
    $self->add($_) for @$rules;
    return $self;
}

my $debug = $ENV{PERL_DEBUG} || 0;

my $FileRuleRegEx
    = qr/^(filename|pathname|dirname|directory)\ +(contains|is|regex)\ +(.+)/io;

sub add {
    my $self = shift;
    my $str = shift or croak "rule string required";

    # parse
    my ( $type, $action, $re ) = ( $str =~ m/$FileRuleRegEx/ );
    if ( !$type or !$action or !$re ) {
        croak "Bad syntax in FileRule: $str";
    }
    if ( $action eq 'regex' or $type eq 'directory' ) {
        eval "\$re = qr$re";    # TODO dangerous?
    }

    # unclear from swish-e docs whether this is true or not,
    # but we are conservative.
    if ( $type eq 'directory' and $action ne 'contains' ) {
        croak "Rule for 'directory' may only have 'contains' action.";
    }

    my $rule = {
        type   => $type,
        action => $action,
        re     => $re,
    };

    push @{ $self->{_rules} }, $rule;

    return $rule;
}

sub rules {
    my $self = shift;
    if (@_) {
        $self->{_rules} = ref( $_[0] ) ? shift : [@_];
    }
    return $self->{_rules};
}

sub match {
    my $self = shift;
    my $file = shift or croak "file required";
    if ( -d $file ) {
        return $self->match_dir( $file, { strict => 1 } );
    }
    else {
        return $self->match_file( $file, { strict => 1 } );
    }
}

sub match_dir {
    my $self = shift;
    my $dir  = shift or croak "dir required";
    my $opts = shift || {};

    if ( $opts->{strict} and !-d $dir ) {
        return 0;
    }

    my $rules = $self->{_rules};

    $debug and warn "match_dir $dir: " . dump($rules) . "\n";

    for my $rule (@$rules) {
        next if $rule->{type} eq 'filename';
        my $method = '_apply_' . $rule->{type} . '_rule';
        return 1 if $self->$method( $dir, $rule, 1 );
    }

    return 0;
}

sub match_file {
    my $self = shift;
    my $file = shift or croak "file required";
    my $opts = shift || {};

    if ( $opts->{strict} and -d $file ) {
        return 0;
    }

    my $rules = $self->{_rules};

    $debug and warn "match_file $file: " . dump($rules) . "\n";

    for my $rule (@$rules) {
        my $method = '_apply_' . $rule->{type} . '_rule';
        return 1 if $self->$method( $file, $rule );
    }

    return 0;
}

sub _apply_filename_rule {
    my ( $self, $file, $rule ) = @_;
    my $match = 0;
    my ( $volume, $dirname, $filename ) = File::Spec->splitpath($file);

    $debug and warn dump($rule) . "\n";
    $debug and warn "dirname=$dirname   filename=$filename\n";

    if ( $rule->{action} eq 'is' ) {
        $match = $rule->{re} eq $filename ? 1 : 0;
    }
    elsif ( $rule->{action} eq 'contains' ) {
        if ( $filename =~ m{$rule->{re}} ) {
            $match = 1;
        }
    }
    elsif ( $rule->{action} eq 'regex' ) {
        my $regex = $rule->{re};
        if ( $filename =~ m{$regex} ) {
            $match = 1;
        }
    }

    $debug
        and warn "_apply_filename_rule for $file returns $match : "
        . dump($rule) . "\n";

    return $match;
}

sub _apply_dirname_rule {
    my ( $self, $file, $rule, $is_dir ) = @_;
    my $match = 0;
    my ( $volume, $dirname, $filename ) = File::Spec->splitpath($file);

    $debug and warn dump($rule) . "\n";
    $debug and warn "dirname=$dirname   filename=$filename\n";

    if ( $rule->{action} eq 'is' ) {
        $match = grep { $rule->{re} eq $_ }
            File::Spec->splitdir( $is_dir ? $file : $dirname );
    }
    elsif ( $rule->{action} eq 'contains' ) {
        if ( $dirname =~ m{$rule->{re}} ) {
            $match = 1;
        }
    }
    elsif ( $rule->{action} eq 'regex' ) {
        my $regex = $rule->{re};
        if ( $dirname =~ m{$regex} ) {
            $match = 1;
        }
    }

    $debug
        and warn "_apply_dirname_rule for $file returns $match : "
        . dump($rule) . "\n";

    return $match;
}

sub _apply_pathname_rule {
    my ( $self, $file, $rule ) = @_;
    my $match = 0;

    my ( $volume, $dirname, $filename ) = File::Spec->splitpath($file);

    $debug and warn dump($rule) . "\n";
    $debug and warn "dirname=$dirname   filename=$filename\n";

    if ( $rule->{action} eq 'is' ) {
        $match = $rule->{re} eq $file;
    }
    elsif ( $rule->{action} eq 'contains' ) {
        if ( $file =~ m{$rule->{re}} ) {
            $match = 1;
        }
    }
    elsif ( $rule->{action} eq 'regex' ) {
        my $regex = $rule->{re};
        if ( $file =~ m{$regex} ) {
            $match = 1;
        }
    }

    $debug
        and warn "_apply_pathname_rule for $file returns $match : "
        . dump($rule) . "\n";

    return $match;
}

sub _apply_directory_rule {
    my ( $self, $dir, $rule ) = @_;
    my $match = 0;
    my $re    = $rule->{re};
    $dir = Path::Class::Dir->new($dir);
    while ( my $file = $dir->next ) {
        if ( $file =~ m/$re/ ) {
            $match = $file;
            last;
        }
    }

    $debug
        and warn "_apply_directory_rule for $dir returns $match : "
        . dump($rule) . "\n";

    return $match;
}

1;

__END__

=head1 NAME

File::Rules - humane syntax for matching files and directories

=head1 SYNOPSIS

 use File::Rules;
 my $rules = File::Rules->new([
    'directory is foo',
    'filename contains bar'
 ]);
 
 $rules->add('dirname regex white'); 
 
 for my $path (('foo/123','abc/bar')) {
    if ($rules->match($path)) {
        print "rules match $path\n";
    }
    else {
        print "rules do not match $path\n";
    }
 }

=head1 DESCRIPTION

File::Rules is based on the Swish-e search configuration option
FileRules. See the ACKNOWLEDGEMENTS section.

In the course of refactoring SWISH::Prog to expand the support
for the FileRules config feature, it seemed obvious to me (so many things
become obvious after staring at them for years) to extract
the FileRules logic into its own module.

=head1 METHODS

=head2 new

Constructor. Takes array or arrayref of FileRule-type strings, and returns
a File::Rules object.

=head2 add( I<str> )

Add a FileRule to the object.

=head2 rules([ I<rules> ])

Get/set the rule structures. I<rules> should be an array or arrayref
of hashrefs conforming to the internal structure.

=head2 match_dir( I<str> [, I<opts>] )

Compares I<str> to the rules as if it were a directory path.
I<opts> can be a hashref of options. The only supported option
currently is C<strict> which will test I<str> with the -d operator.
Example:

 $dir = '/foo/bar';  # -d $dir would return false
 $rules->match_dir($dir, { strict => 1 });  # returns false regardless of rules

=head2 match_file( I<str> [, I<opts>] )

Compares I<str> to the rules as if it were a file path.
I<opts> can be a hashref of options. The only supported option
currently is C<strict> which will test I<str> with the -d operator.
Example:

 $file = '/path/to/some/dir';  # -d $dir would return true
 $rules->match_dir($file, { strict => 1 });  # returns false regardless of rules


=head2 match( I<str> )

Returns true if I<str> matches any of the rules. Calling match() will test
I<str> with the -d operator, similar to calling match_dir() or match_file()
with the C<strict> option.


=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-rules at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Rules>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Rules


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Rules>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Rules>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Rules>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Rules/>

=back


=head1 ACKNOWLEDGEMENTS

Syntax based on the Swish-e configuration feature FileRules and FileMatch:
http://swish-e.org/docs/swish-config.html#item_filerules

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
