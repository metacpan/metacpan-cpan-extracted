package Import::Base;
# ABSTRACT: Import a set of modules into the calling module
our $VERSION = '1.004';

use strict;
use warnings;
use mro ();
use Import::Into;
use Module::Runtime qw( use_module );

require Exporter;

our @ISA = qw(Exporter);

sub modules {
    my ( $class, $bundles, $args ) = @_;
    my @modules = ();

    # Find all the modules from the static API
    # Reverse the array to allow more-specific classes to override
    # less-specific ones
    for my $pkg ( reverse @{ mro::get_linear_isa( $class ) } ) {
        no strict 'refs';
        no warnings 'once';

        if ( !$args->{bundles_only} ) {
            push @modules, @{ $pkg . "::IMPORT_MODULES" };
        }

        my %bundles = %{ $pkg . "::IMPORT_BUNDLES" };
        push @modules, map { @{ $bundles{ $_ } } }
            grep { exists $bundles{ $_ } }
            @$bundles;
    }

    return @modules;
}

sub _parse_args {
    my ( $class, @args ) = @_;
    my @bundles;
    while ( @args ) {
        last if $args[0] =~ /^-/;
        push @bundles, shift @args;
    }
    my %args = @args;
    return ( \@bundles, \%args );
}

sub import_bundle {
    my ( $class, @args ) = @_;
    my ( $bundles, $args ) = $class->_parse_args( @args );

    # Add internal Import::Base args
    $args->{package} = scalar caller(0);
    $args->{bundles_only} = 1;

    my @modules = $class->modules( $bundles, $args );
    $class->_import_modules( \@modules, $bundles, $args );
}

sub import {
    my ( $class, @args ) = @_;
    my ( $bundles, $args ) = $class->_parse_args( @args );

    # Add internal Import::Base args
    $args->{package} = scalar caller(0);

    my @modules = $class->modules( $bundles, $args );
    $class->_import_modules( \@modules, $bundles, $args );
}

sub _import_modules {
    my ( $class, $modules, $bundles, $args ) = @_;

    die "Argument to -exclude must be arrayref"
        if $args->{-exclude} && ref $args->{-exclude} ne 'ARRAY';
    my $exclude = {};
    if ( $args->{-exclude} ) {
        while ( @{ $args->{-exclude} } ) {
            my $module = shift @{ $args->{-exclude} };
            my $subs = ref $args->{-exclude}[0] eq 'ARRAY' ? shift @{ $args->{-exclude} } : undef;
            $exclude->{ $module } = $subs;
        }
    }

    # Add internal Import::Base args
    $args->{package} ||= scalar caller(0);

    my @modules = @$modules;
    my @cb_args = ( $bundles, $args );

    # Prepare the modules to load
    # First pass determines the order to load
    my ( @first_load, @last_load );
    while ( @modules ) {
        if ( ref $modules[0] eq 'CODE' ) {
            push @first_load, shift @modules;
            next;
        }

        my $thing = shift @modules;
        my $module;
        my $version;
        if ( ref $thing eq 'HASH' ) {
            ( $module, $version ) = %$thing;
        }
        else {
            $module = $thing;
        }
        my $imports = ref $modules[0] eq 'ARRAY' ? shift @modules : [];

        # Determine the module order
        if ( $module =~ /^</ ) {
            $module =~ s/^<//;
            if ( defined $version ) {
                unshift @first_load, { $module => $version } => $imports;
            }
            else {
                unshift @first_load, $module => $imports;
            }
        }
        elsif ( $module =~ /^>/ ) {
            $module =~ s/^>//;
            if ( defined $version ) {
                push @last_load, { $module => $version } => $imports;
            }
            else {
                push @last_load, $module => $imports;
            }
        }
        else {
            push @first_load, $thing => $imports;
        }
    }

    # Second pass loads the modules
    my @loads = ( @first_load, @last_load );
    while ( my $load = shift @loads ) {
        my $module;
        my $version;
        if ( ref $load eq 'CODE' ) {
            unshift @loads, $load->( @cb_args );
            next;
        }
        elsif ( ref $load eq 'HASH' ) {
            ( $module, $version ) = %$load;
        }
        else {
            $module = $load;
        }

        my $imports = ref $loads[0] eq 'ARRAY' ? shift @loads : [];

        if ( exists $exclude->{ $module } ) {
            if ( defined $exclude->{ $module } ) {
                my @left;
                for my $import ( @$imports ) {
                    push @left, $import
                        unless grep { $_ eq $import } @{ $exclude->{ $module } };
                }
                $imports = \@left;
            }
            else {
                next;
            }
        }

        my $method = 'import::into';
        if ( $module =~ /^-/ ) {
            $method = 'unimport::out_of';
            $module =~ s/^-//;
        }

        if ($module->isa("Import::Base")) {
            $module->export_to_level( 2, $module, @{ $imports } );

            next;
        }

        use_module( $module );
        if ( defined $version ) {
            $module->$method( { level => 2, version => $version }, @{ $imports } );
        }
        else {
            $module->$method( 2, @{ $imports } );
        }
    }
}

1;

__END__

=pod

=head1 NAME

Import::Base - Import a set of modules into the calling module

=head1 VERSION

version 1.004

=head1 SYNOPSIS

    ### Static API
    package My::Base;
    use parent 'Import::Base';

    # Modules that are always imported
    our @IMPORT_MODULES = (
        'strict',
        'warnings',
        # Import only these subs
        'My::Exporter' => [ 'foo', 'bar', 'baz' ],
        # Disable uninitialized warnings
        '-warnings' => [qw( uninitialized )],
        # Test for minimum version
        { 'Getopt::Long' => 2.31 },
        # Callback to generate modules to import
        sub {
            my ( $bundles, $args ) = @_;
            return "My::MoreModule" => [qw( fuzz )];
        },
    );

    # Optional bundles
    our %IMPORT_BUNDLES = (
        with_signatures => [
            'feature' => [qw( signatures )],
            # Put this last to make sure nobody else can re-enable this warning
            '>-warnings' => [qw( experimental::signatures )]
        ],
        Test => [qw( Test::More Test::Deep )],
        Class => [
            # Put this first so we can override what it enables later
            '<Moo',
        ],
    );

    ### Consumer classes
    # Use only the default set of modules
    use My::Base;

    # Use one of the optional packages
    use My::Base 'with_signatures';
    use My::Base 'Test';
    use My::Base 'Class';

    # Exclude some modules and symbols we don't want
    use My::Base -exclude => [ 'warnings', 'My::Exporter' => [ 'bar' ] ];

=head1 DESCRIPTION

This module makes it easier to build and manage a base set of imports. Rather
than importing a dozen modules in each of your project's modules, you simply
import one module and get all the other modules you want. This reduces your
module boilerplate from 12 lines to 1.

=head1 USAGE

=head2 Base Module

Creating a base module means extending Import::Base and creating an
C<@IMPORT_MODULES> package variable with a list of modules to import,
optionally with a arrayref of arguments to be passed to the module's import()
method.

A common base module should probably include L<strict|strict>,
L<warnings|warnings>, and a L<feature|feature> set.

    package My::Base;
    use parent 'Import::Base';

    our @IMPORT_MODULES = (
        'strict',
        'warnings',
        feature => [qw( :5.14 )],
    );

Now we can consume our base module by doing:

    package My::Module;
    use My::Base;

Which is equivalent to:

    package My::Module;
    use strict;
    use warnings;
    use feature qw( :5.14 );

Now when we want to change our feature set, we only need to edit one file!

=head2 Import Bundles

In addition to a set of modules, we can also create optional bundles with the
C<%IMPORT_BUNDLES> package variable.

    package My::Bundles;
    use parent 'My::Base';

    # Modules that will always be included
    our @IMPORT_MODULES
        experimental => [qw( signatures )],
    );

    # Named bundles to include
    our %IMPORT_BUNDLES = (
        Class => [qw( Moose MooseX::Types )],
        Role => [qw( Moose::Role MooseX::Types )],
        Test => [qw( Test::More Test::Deep )],
    );

Now we can choose one or more bundles to include:

    # lib/MyClass.pm
    use My::Base 'Class';

    # t/mytest.t
    use My::Base 'Test';

    # t/lib/MyTest.pm
    use My::Base 'Test', 'Class';

Bundles must always come before options. Bundle names cannot start with "-".

=head2 Extended Base Module

We can further extend our base module to create more specialized modules for
classes and testing.

    package My::Class;
    use parent 'My::Base';
    our @IMPORT_MODULES = (
        'Moo::Lax',
        'Types::Standard' => [qw( :all )],
    );

    package My::Test;
    use parent 'My::Base';
    our @IMPORT_MODULES = (
        'Test::More',
        'Test::Deep',
        'Test::Exception',
        'Test::Differences',
    );

Now all our classes just need to C<use My::Class> and all our test scripts just
need to C<use My::Test>.

B<NOTE:> Be careful when extending base modules from other projects! If the
module you are extending changes, your modules may unexpectedly break. It is
best to keep your base modules on a per-project scale.

=head2 Unimporting

Sometimes instead of C<use Module> we need to do C<no Module>, to turn off
C<strict> or C<warnings> categories for example.

By prefixing the module name with a C<->, Import::Base will act like C<no>
instead of C<use>.

    package My::Base;
    use parent 'Import::Base';
    our @IMPORT_MODULES = (
        'strict',
        'warnings',
        feature => [qw( :5.20 signatures )],
        '-warnings' => [qw( experimental::signatures )],
    );

Now the warnings for using the 5.20 subroutine signatures feature will be
disabled.

=head2 Version Check

The standard Perl C<use> function allows for a version check at compile
time to ensure that a module is at least a minimum version.

    # Require Getopt::Long version 2.31 or higher
    use Getopt::Long 2.31;

Generally, you should be declaring your dependency with the correct version,
but some modules (like Getopt::Long) change their behavior based on what
version you ask for.

To ask for a specific version, use a hashref with the key is the module and
the value as the required version.

    our @IMPORT_MODULES = (
        # Require a minimum version
        { 'Getopt::Long' => 2.31 },
        # Version and imports
        { 'File::Spec::Functions' => 3.47 } => [qw( catfile )],
    );

=head2 -exclude

When importing a base module, you can use C<-exclude> to prevent certain
modules or symbols from being imported (if, for example, they would
conflict with existing symbols).

    # Prevent the "warnings" module from being imported
    use My::Base -exclude => [ 'warnings' ];

    # Prevent the "bar" sub from My::Exporter from being imported
    use My::Base -exclude => [ 'My::Exporter' => [ 'bar' ] ];

NOTE: If you find yourself using C<-exclude> often, you would be better off
removing the module or sub and creating a bundle, or only including it in those
modules that need it.

=head2 Control Ordering

The order you import modules can be important!

    use warnings;
    no warnings 'uninitialized';
    # Uninitialized warnings are disabled

    no warnings 'uninitialized';
    use warnings;
    # Uninitialized warnings are enabled!

Due to modules enforcing their own strict and warnings, like L<Moose> and
L<Moo>, you may not even know it's happening. This can make it hard to disable the
experimental warnings:

    use feature qw( postderef );
    no warnings 'experimental::postderef';
    use Moo;
    # The postderef warnings are back on!

To force a module to the front or the back of the list of imports, you can prefix
the module name with C<E<lt>> or C<E<gt>>.

    package My::Base;
    use parent 'Import::Base';
    our @IMPORT_MODULES = (
        feature => [qw( postderef )],
        # Disable this warning last!
        '>-warnings' => [qw( experimental::postderef )],
    );

    our %IMPORT_BUNDLES = (
        Class => [
            # Import this module first!
            '<Moo',
        ],
    );

    package main;
    use My::Base 'Class';
    my @foo = [ 1, 2, 3 ]->@*; # postderef!

In this case, either putting Moo first or putting C<no warnings
'experimental::postderef'> last would solve the problem.

B<NOTE:> C<E<lt>> and C<E<gt>> come before C<->.

If you need even more control over the order, consider the L</"Dynamic API">.

=head2 Subref Callbacks

To get a little bit of dynamic support in the otherwise static module lists, you may
add sub references to generate module imports.

    package My::Base;
    use parent 'Import::Base';
    our @IMPORT_MODULES = (
        sub {
            my ( $bundles, $args ) = @_;
            return (
                qw( strict warnings ),
                feature => [qw( :5.20 )],
            );
        },
    );

    # strict, warnings, and 5.20 features will be imported

Plain strings are module names. Array references are arguments to import.

B<NOTE:> Subrefs cannot return modules with C<E<lt>> or C<E<gt>> to control
ordering. Subrefs are run after the order has already been determined, while
the imports are being executed. Subrefs can assume that imports before them
have already been completed.

=head2 Subref Arguments

Sub references get an arrayref of bundles being requested, and a hashref of
extra arguments. Arguments from the calling side start with a '-'. Arguments
from Import::Base do not. Possible arguments are:

    package         - The package we are exporting to
    -exclude        - The exclusions, see L</"-exclude">.

Using C<package>, a subref could check or alter C<@ISA>, work with the object's
metaclass (if you're using one), or export additional symbols not set up for
export.

Here's an example for applying a role (L<Moo::Role>, L<Role::Tiny>,
L<Moose::Role>, and anything that uses C<with>) when importing a bundle:

    package My::Base;
    use parent 'Import::Base';
    our %IMPORT_BUNDLES = (
        'Plugin' => [
            'Moo',
            # Plugins require the "My::Plugin" role
            sub {
                my ( $bundles, $args ) = @_;
                $args->{package}->can( 'with' )->( 'My::Plugin' );
                return;
            },
        ],
    );

    package My::Custom::Plugin;
    use My::Base 'Plugin';

B<NOTE:> This sub is still being called during the compile phase. If you need your
role to be applied later, if you get errors when trying to apply it at compile time,
use L<the import_bundle method|/import_bundle>, below.

=head2 Custom Arguments

When using L</"Subref Callbacks">, you can add additional arguments to the
C<use> line. The arguments list starts after the first key that starts with a
'-'. To avoid conflicting with any future Import::Base feature, prefix all your
custom arguments with '--'.

    use My::Base -exclude => [qw( strict )], --custom => "arguments";
    # Subrefs will get $args{--custom} set to "arguments"

=head2 Dynamic API

Instead of providing C<@IMPORT_MODULES> and C<%IMPORT_BUNDLES>, you can override the
C<modules()> method to do anything you want.

    package My::Bundles;
    use parent 'My::Base';

    sub modules {
        my ( $class, $bundles, $args ) = @_;

        # Modules that will always be included
        my @modules = (
            experimental => [qw( signatures )],
        );

        # Named bundles to include
        my %bundles = (
            Class => [qw( Moose MooseX::Types )],
            Role => [qw( Moose::Role MooseX::Types )],
            Test => [qw( Test::More Test::Deep )],
        );

        # Go to our parent class first
        return $class->SUPER::modules( $bundles, $args ),
            # Then the always included modules
            @modules,
            # Then the bundles we asked for
            map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
    }

Using the above boilerplate will ensure that you start with all the basic functionality.

One advantage the dynamic API has is the ability to remove modules from superclasses, or
completely control the order that modules are imported, even from superclasses.

=head2 Exporting symbols from the base class

Import::Base inherits from Exporter and allows for EXPORT_OK usage.

    package My::Base;
    use parent 'Import::Base';

    our @EXPORT_OK = qw($joy);

    our @IMPORT_MODULES = (
        'strict',
        'warnings',
        feature => [qw( :5.10 )],
        'My::Base' => [qw( $joy )],
    );

    our $joy = "Is everywhere";

    package main;

    use My::Base;

    say $joy;

Notice how the base class 'My::Base' is in it's own IMPORT_MODULES definition.

=head1 METHODS

=head2 modules( $bundles, $args )

Prepare the list of modules to import. $bundles is an array ref of bundles, if any.
$args is a hash ref of generic arguments, if any.

Returns a list of MODULE => [ import() args ]. MODULE may appear multiple times.

=head2 import_bundle( @bundles, @args )

Import a bundle at runtime. This method takes the exact same arguments as in
the C<use My::Base ...> compile-time API, but allows it to happen at runtime,
so that all of the current package's subs have been made available, and all
C<BEGIN> blocks have been executed.

This is useful when using bundles to apply roles that have dependencies or
other esoteric use-cases. It is not necessary for most things.

=head1 DOCUMENTATION BOILERPLATE

Here is an example for documenting your own base modules

    =head1 SYNOPSIS

        package MyModule;
        use My::Base;

        use My::Base 'Class';
        use My::Base 'Role';
        use My::Base 'Test';

    =head1 DESCRIPTION

    This is the base module that all {{PROJECT}} files should use.

    This module always imports the following into your namespace:

    =over

    =item L<strict>

    =item L<warnings>

    =item L<feature>

    Currently the 5.20 feature bundle

    =item L<experimental> 'signatures' 'postderef'

    We are using the 5.20 experimental signatures and postfix deref syntax.

    =back

    =head1 BUNDLES

    The following bundles are available. You may import one or more of these by name.

    =head2 Class

    The class bundle makes your package into a class and includes:

    =over 4

    =item L<Moo::Lax>

    =item L<Types::Standard> ':all'

    =back

    =head2 Role

    The role bundle makes your package into a role and includes:

    =over 4

    =item L<Moo::Role::Lax>

    =item L<Types::Standard> ':all'

    =back

    =head2 Test

    The test bundle includes:

    =over 4

    =item L<Test::More>

    =item L<Test::Deep>

    =item L<Test::Differences>

    =item L<Test::Exception>

    =back

    =head1 SEE ALSO

    =over

    =item L<Import::Base>

    =back

=head1 BEST PRACTICES

=head2 One Per Project

Every project of at least medium size should have its own base module.
Consolidating a bunch of common base modules into a single distribution and
releasing to CPAN may sound like a good idea, but it opens you up to
difficult-to-diagnose problems.

If many projects all depend on the same base, any change to the central base
module could potentially break one of the consuming modules. In a single,
well-tested project, it is easy to track down and address issues due to changes
in the base module. If the base module is released to CPAN, breakage may not
appear until someone tries to install a module that depends on your base.

Version incompatibility, where project Foo depends on version 1 of the base,
while project Bar depends on version 2, will create very frustrating situations
for your users.

Having to track down another project to figure out what modules are active in
the current package is a lot of work, creating frustration for contributing
authors.

=head1 KNOWN ISSUES

=over 4

=item Moo::Role does not work if base module shares the same file as role package

When trying to import L<Moo::Role> using Import::Base, the role will not
be applied if it shares the same file as the Import::Base module. For
safety and sanity, you should keep your Import::Base module separate
from classes and roles.

=item Dancer plugins do not work when applied with Import::Base

Dancer plugins check, at compile time, to see if they can be imported into
the consuming class by looking for the Dancer DSL. Because Import::Base uses
Module::Runtime to load the class, Dancer::Plugin thinks Module::Runtime is
the calling class, sees there is no DSL to register itself with, and bails.

This issue was fixed in Dancer2 v0.200000 (released 2016-05-31). See
L<https://github.com/PerlDancer/Dancer2/pull/1136> for more information.

=back

=head1 SEE ALSO

=over

=item L<Import::Into|Import::Into>

The module that provides the functionality to create this module. If Import::Base
doesn't do what you want, look at Import::Into to build your own.

=item L<Importer|Importer>

This module wraps the C<import> method of other modules, allowing you to rename
the symbols you import. If you need to change a name, use this module together
with Import::Base.

=item L<perl5|perl5>

This module is very similar, and has a bunch of built-in bundles and features for
quickly importing Perl feature sets. It is also flexible, allowing you to specify
your own module bundles.

=item L<ToolSet|ToolSet>

ToolSet is very similar. Its API just uses package methods instead of package
variables. It also allows for exporting symbols directly from the bundle.

=item L<sanity|sanity>

Sanity is more consise, but not as flexible. If you don't need the wild
flexibility of Import::Base or the above solutions, take a look.

=item L<Toolkit|Toolkit>

This one requires configuration files in a home directory, so is not shippable.

=item L<rig|rig>

This one also requires configuration files in a home directory, so is not shippable.

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Brian Medley Dan Book Doug Bell

=over 4

=item *

Brian Medley <pub-github@bmedley.org>

=item *

Dan Book <grinnz@gmail.com>

=item *

Doug Bell <doug@preaction.me>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
