package Import::Box;
use strict;
use warnings;

our $VERSION = '0.001';

use Scalar::Util();
use Carp();
use vars qw/$AUTOLOAD/;

my %STASHES;

sub __DEFAULT_AS { }
sub __DEFAULT_NS { }

# We do not want this methods to be accessible, so we are putting it in a
# lexical variable to use internally.
my $GEN_STASH = do {
    my $GEN = 'A';
    sub { __PACKAGE__ . '::__GEN_STASH__::' . shift(@_) . '::__' . ($GEN++) . '__' };
};

# We do not want this methods to be accessible, so we are putting it in a
# lexical variable to use internally.
my $IMPORT = sub {
    my $proto  = shift;
    my $caller = shift;

    return unless @_;

    my (%params, @loads);
    while (my $arg = shift) {
        if (substr($arg, 0, 1) eq '-') {
            $params{$arg} = shift;
        }
        else {
            my $args = ref($_[0]) ? shift : [];
            push @loads => [$arg, @$args];
        }
    }

    my ($stash, $class, $no_scope);
    if ($class = Scalar::Util::blessed($proto)) {
        Carp::croak("Params are not allowed when using import() as an object method: " . join(', ', keys %params))
            if keys %params;

        $stash = $$proto;
        $no_scope = 1;
    }
    else {
        $class = $proto;

        my $as = delete $params{'-as'} || $class->__DEFAULT_AS;
        Carp::croak(qq{No box name specified, and no default available, please specify with '-as => "BOXNAME"'})
            unless defined $as;

        my $from = delete $params{'-from'} || $caller->[0];
        $no_scope = delete $params{'-no_scope'};

        Carp::croak("Invalid params: " . join(', ', keys %params))
            if keys %params;

        $stash = $STASHES{$from}->{$as} ||= $GEN_STASH->($caller->[0]);
        bless(\$stash, $class) unless Scalar::Util::blessed(\$stash);

        unless ($caller->[0]->can($as)) {
            my $t = sub {
                return \$stash unless @_;

                my $meth = shift;

                my $sub = $stash->can($meth)
                    or Carp::croak("No such function: '$meth'");

                goto &$sub;
            };

            no strict 'refs';
            *{"$caller->[0]\::$as"} = $t;
        }
    }

    return unless @loads;

    my $header = qq{package $stash;\n#line $caller->[2] "$caller->[1]"};
    my $sub = $no_scope ? undef : eval qq{$header\nsub { shift\->import(\@_) };} || die $@;
    my $prefix = $class->__DEFAULT_NS;

    for my $set (@loads) {
        my ($mod, @args) = @$set;

        # Strip '+' prefix OR append module prefix
        unless ($mod =~ s/^\+//) {
            $mod = "$prefix\::$mod" if $prefix;
        }

        my $file = $mod;
        $file =~ s{::|'}{/}g;
        $file .= '.pm';
        require $file;

        if ($no_scope) {
            eval qq{$header\nBEGIN { \$mod\->import(\@args) }; 1} or die $@;
        }
        else {
            $sub->($mod, @args);
        }
    }
};

sub import {
    my $proto = shift;
    my @caller = caller(0);

    $proto->$IMPORT(\@caller, @_);
}

sub new {
    my $class = shift;
    my @caller = caller(0);

    my $stash = $GEN_STASH->($caller[0]);
    my $self = bless(\$stash, $class);

    $self->$IMPORT(\@caller, @_) if @_;

    return $self;
}

sub box {
    my $class = shift;
    my $stash = shift;
    my $self = bless(\$stash, $class);
    return $self;
}

# These methods need to instead call the stash version when called on an
# instance.
for my $meth (qw/new box/) {
    my $orig = __PACKAGE__->can($meth);

    my $new = sub {
        my ($proto) = @_;
        goto &$orig unless Scalar::Util::blessed($proto);

        my $sub = $proto->can($meth) or Carp::croak("No such function: '$meth'");
        goto &$sub;
    };

    no strict 'refs';
    no warnings 'redefine';
    *$meth = $new;
}

sub can {
    my $proto = shift;
    my $class = Scalar::Util::blessed($proto)
        or return $proto->SUPER::can(@_);

    my $stash = $$proto;
    return $stash->can(@_);
}

sub isa {
    my $proto = shift;
    return $proto->SUPER::isa(@_);
}

sub AUTOLOAD {
    my $meth = $AUTOLOAD;
    $meth =~ s/^.*:://g;

    return if $meth eq 'DESTROY';

    my $class = Scalar::Util::blessed($_[0])
        or Carp::croak(qq{Can't locate object method "$meth" via package "$_[0]"});

    # Need to shift self as the "methods" are actually functions imported into
    # the stash.
    my $self = shift @_;

    my $sub = $self->can($meth)
        or Carp::croak("No such function '$meth'");

    goto &$sub;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Import::Box - Box up imports into an object or unified function.

=head1 DESCRIPTION

This package lets you box up imported functions in either a unified function,
or an object. This allows you access to functions you would normally import,
but now you can do so without cluttering your namespace.

This module can be helpful in situations where you need to use exported
functions from different modules where the functions have identical names. For
instance L<Moose> exports C<meta()>, L<Test2::Tools::Compare> also exports
C<meta()>, in such a simple case you can just rename the import, but in cases
where there are many conflicts this can get tedious.

=head1 SYNOPSIS

=head2 BOX FUNCTION

You can process imports when you use L<Import::Box>, this will give you a
function that gives you access to the functions.

    use Import::Box -as => 'dd', 'Data::Dumper' => ['Dumper'];

    # Dumper $thing1 and $thing2, dd() itself is not dumped
    print dd->Dumper($thing1, $thing2);

    # Tell dd to call Dumper() on $thing1 and $thing2, dd() itself is not dumped
    dd Dumper => ($thing, $thing2);

=head2 BOX INSTANCE

You can completely avoid any subs being imported into your namespace and go the
completely OO route:

    use Import::Box;

    my $dd = Import::Box->new('Data::Dumper' => ['Dumper']);

    # Dump $thing1 and $thing2. $dd is not dumped
    print $dd->Dumper($thing1, $thing2);

    # Indirect object notation also works (but please do not do this)
    Dumper $dd($thing1, $thing2)

=head1 SUBCLASSING

Subclassing is a way to create shortcuts for common boxing patterns.

    package T2;
    use parent 'Import::Box';

    sub __DEFAULT_AS { 't2' }
    sub __DEFAULT_NS { 'Test2::Tools' }

The subclass above creates a shortcut for importing Test2::Tools::* packages:

    use T2 'Basic', 'Compare' => [qw/is/];

    # The 't2' function was specified for us, no need for '-as' in the
    # arguments above.

    t2 ok => (1, "everything is ok");

    t2->is('a', 'a', "these letters are both identical");

    t2->done_testing;

=head2 SUBCLASS METHODS

=over 4

=item $name = $class->__DEFAULT_AS()

This lets you specify a default argument for C<-as>, that is the name of the
sub that gives you access to your imports.

=item $prefix = $class->__DEFAULT_NS()

This lets you specify a prefix to add to any module argument. The default can
be bypassed using the '+' prefix in your import:

    use T2 '+Not::In::Test2::Tools::Tool';

=back

=head1 IMPORT ARGUMENTS

These are all valid when importing L<Import::Box>. Arguments prefixed with a
dash (C<->) are not allowed when calling import() as an instance method.

=over 4

=item -as => $NAME

Specify a function name that will be added to your namespace. You may import
multiple times with the same '-as' value to append new imports to an existing
box.

    use Import::Box -as => 'foo', 'Data::Dumper';
    use Import::Box -as => 'foo', 'Scalar::Util';

    foo()->Dumper(...);
    foo()->blessed(...);

=item -from => $PACKAGE

This lets you import a box function from another package:

    package Other::Package;
    use Import::Box -as => 'foo', 'Data::Dumper';

    package main;

    # This will bring in 'foo' from Other::Package.
    use Import::Box -as => 'foo', -from => 'Other::Package';

In this case '-as' specifies BOTH what the sub will be called, and which sub to
get from Other::Package.

=item -no_scope => $BOOL

This can be used to prevent compile-time effects from your imports, for instance:

    use Import::Box 'strict';
    # Strict is turned on

With the arg:

    use Import::Box -no_scope => 1, 'strict';
    # strict settings are not changed

It is worth noting that the same thing can be achieved this way:

    { use Import::Box 'strict'; }
    # strict settings not changed

=item MODULE_NAME

=item MODULE_NAME => \@IMPORT_LIST

Any argument not prefixed with a dash will be considered a module name. A
module name can optionally be followed by an arrayref of import arguments. If
no arrayref is specified then the default import will happen.

You may specify any number of modules for import:

    use Import::Box(
        'Data::Dumper',
        'Carp' => [ qw/croak confess/ ],
        ...
    );

or OO via C<new()>

    my $foo = Import::Box->new(
        'Data::Dumper',
        'Carp' => [ qw/croak confess/ ],
        ...
    );

or via C<< ->import >> on an instance or box function:

    $foo->import(...);
    foo()->import(...);

=back

=head1 CONSTRUCTORS

=over 4

=item $box = Import::Box->new($MODULE1, $MODULE2 => \@import_args)

This will create a completely new box with the specified imports.

=item $box = Import::Box->box($MODULE)

This will box up an existing namespace. This will not load the specified
module, you must load it yourself with C<require> if necessary.

    require Data::Dumper;
    my $box = Import::Box->box('Data::Dumper);

B<Note:> Normally a box is made by importing the modules into a generated
package name, when you use this constructor you do not create a new package,
instead the box directly touches the symbol table for the specified package.

The following would import all the subs from C<Carp> into the C<Data::Dumper>
namespace, you probably do not want this!

    $box->import('Carp');

=back

=head1 PREDEFINED METHODS (you cannot access imports under these names)

=over 4

=item import($MODULE1, $MODULE2 => \@import_args)

C<import()> is always going to be the L<Import::Box> import method, it will
never delegate to the imported packages.

=item isa($class)

C<isa()> will never be delegated.

=item can($name)

C<can()> will never be delegated. When called on a class this will return
methods that exist on L<Import::Box> or your subclass. When called on an
instance this will only return subs that have been imported.

=item DESTROY()

C<DESTROY()> is a magic special case, never delegated.

=item AUTOLOAD(...)

C<AUTOLOAD()> is used internally as an implementation detail, never delegated.

=back

=head1 SOURCE

The source code repository for Import::Box can be found at
L<http://github.com/exodist/Import-Box>.

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
