package Fennec::Lite;
use strict;
use warnings;

use Carp qw/ croak /;
use List::Util qw/ shuffle /;
use B;

our $VERSION = '0.004';

our %MODULE_LOADERS = (
    'Test::More' => sub {
        my ( $self ) = @_;
        my $into = $self->test_class;
        require Test::More;

        my $plan = $self->plan || (Test::More->can('done_testing') ? '' : 'no_plan');
        eval "package $into; Test::More->import(" . ($plan ? 'tests => $plan' : '') . "); 1"
            || die $@;
    },
);

sub import_hook {}
sub module_loaders { \%MODULE_LOADERS }
sub must_load {qw/ Test::More /}
sub may_load {qw/
    Test::Warn
    Test::Exception
/};

fennec_accessors(qw/
    tests
    test_class
    seed
    random
    testing
    alias
    alias_to
    plan
    TB
/);

sub import {
    my $class = shift;
    my %specs = @_;
    my $caller = caller;

    $specs{random} = 1 unless defined $specs{random};

    my $instance = $class->new( %specs, test_class => $caller );

    $instance->_import_must_loads();
    $instance->_import_way_loads();
    $instance->_export_shortcuts();
    $instance->_export_aliases();
    $instance->_export_functions();
    $instance->import_hook();

    1;
}

sub new {
    my $class = shift;
    my @ltime = localtime(time);
    my $self = bless ({
        tests => [],
        seed => $ENV{FENNEC_SEED} || join( '', @ltime[5,4,3] ),
        @_,
    }, $class );
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    require Test::Builder;
    $self->TB( Test::Builder->new());
}

sub _import_loads {
    my $self = shift;
    my ( $no_die_on_fail, @load ) = @_;
    my $handlers = $self->module_loaders;

    for my $package ( @load ) {
        if ($handlers->{$package}) {
            $handlers->{$package}->( $self );
            next;
        }
        my ($ret, $error) = load_package_into( $package, $self->test_class );
        next if $ret;
        die $error unless $no_die_on_fail && $error =~ m/Can't locate [\w\d_\/\.]+\.pm in \@INC/;
    }
}

sub load_package_into {
    my ( $load, $into ) = @_;
    local $@;
    my $ret = eval "package $into; use $load; 1;";
    return $ret ? ( $ret ) : ( $ret, $@ );
}

sub _import_must_loads {
    my $self = shift;
    $self->_import_loads( 0, $self->must_load );
}

sub _import_way_loads {
    my $self = shift;
    $self->_import_loads( 1, $self->may_load );
}

sub _export_shortcuts {
    my $self = shift;
    my $package = $self->testing || return;
    my $into = $self->test_class;

    no strict 'refs';
    *{"$into\::CLASS"} = sub { $package };
    *{"$into\::CLASS"} = \$package;
}

sub _export_aliases {
    my $self = shift;
    my $caller = $self->test_class;

    if ( my $aliases = $self->alias ) {
        $aliases = [ $aliases ] unless ref $aliases;
        for my $class ( @$aliases ) {
            eval "require $class; 1" || die $@;
            no strict 'refs';
            my $name = $class;
            $name =~ s/^.*:([^:]+)$/$1/;
            *{"$caller\::$name"} = sub { $class };
        }
    }

    if ( my $alias_map = $self->alias_to ) {
        for my $name ( keys %$alias_map ) {
            my $class = $alias_map->{ $name };
            no strict 'refs';
            *{"$caller\::$name"} = sub { $class };
        }
    }
}

sub _export_functions {
    my $self = shift;
    my $into = $self->test_class;

    no strict 'refs';
    *{"$into\::tests"}     = sub { $self->_add_tests( @_ ) };
    *{"$into\::run_tests"} = sub { $self->run_tests( @_ )  };
    *{"$into\::fennec"}    = sub { return $self            };

    *{"$into\::fennec_accessors"} = \&fennec_accessors;
}

sub add_tests {
    my $self = shift;
    $self->_add_tests( @_ );
}

sub _add_tests {
    my $self = shift;
    ( undef, undef, my $end_line ) = caller(1);
    my $name = shift;
    my %proto = ( @_ == 1 )
        ? ( method => $_[0] )
        : @_;

    $proto{ name } = $name if $name;
    $proto{ method } ||= $proto{ code } || $proto{ sub };
    $proto{ end_line } = $end_line;
    $proto{ start_line } = B::svref_2object( $proto{ method })->START->line;

    croak "You must name your test group"
        unless $proto{name};

    croak "You must provide a coderef as one of the following params 'method', 'code', or 'sub'."
        unless $proto{method};

    push @{$self->tests} => \%proto;
}

sub run_tests {
    my $self = shift;
    my %params = @_;
    my $tests = $self->tests;
    my $pass = 1;
    my $item = $ENV{FENNEC_ITEM};

    my $invocant_class = $self->test_class;
    my $invocant = $invocant_class->can( 'new' )
        ? $invocant_class->new( %params )
        : bless( \%params, $invocant_class );

    # Seed before randomizing tests, for reproducibility
    srand( $self->seed );
    $tests = [ shuffle @$tests ]
        if $self->random;

    for my $test ( @$tests ) {
        my $method = $test->{method};
        my $name = $test->{name};

        if ( $item ) {
            if ( $item =~ m/^\d+$/ ) {
                next unless $test->{start_line} <= ($item + 1);
                next unless $test->{end_line} >= $item;
            }
            else {
                next unless $name eq $item;
            }
        }

        if ( $test->{ skip }) {
            $pass &&= $self->run_skip_group( $invocant, $test );
        }
        elsif( $test->{ todo }) {
            $pass &&= $self->run_todo_group( $invocant, $test );
        }
        else {
            $pass &&= $self->run_test_group( $invocant, $test );
        }
    }

    $self->tests([]);
    return $pass;
}

sub run_skip_group {
    my $self = shift;
    my ( $invocant, $test ) = @_;
    my $name = $test->{ name };
    $self->TB->note( "Skipping: $name" );
    $self->TB->skip( $test->{skip} );
    1;
}

sub run_todo_group {
    my $self = shift;
    my ( $invocant, $test ) = @_;
    $self->TB->todo_start( $test->{todo} );
    my $out = $self->run_test_eval( $invocant, $test );
    $self->TB->todo_end();
    return $out;
}

sub run_test_group {
    my $self = shift;
    my ( $invocant, $test ) = @_;
    $self->run_test_eval( $invocant, $test );
}

sub run_test_eval {
    my $self = shift;
    my ( $invocant, $test ) = @_;

    # Seed again before running test, for reproducibility
    srand( $self->seed );
    my $ret = eval { $test->{method}->( $invocant ); 1 };
    return $ret ? $ret : $self->test_eval_error( $ret, $@, $test );
}

sub test_eval_error {
    my $self = shift;
    my ( $ret, $error, $test ) = @_;

    return !$ret if $test->{ should_fail };

    my $name = $test->{name};
    $self->TB->ok( $ret, "Test Group '$name' died (it should not)" );
    $self->TB->diag( $error );

    return $ret;
}

sub fennec_accessors {
    my $caller = caller;
    for my $name ( @_ ) {
        my $sub = sub {
            my $self = shift;
            ( $self->{ $name }) = @_ if @_;
            return $self->{ $name };
        };
        no strict 'refs';
        *{"$caller\::$name"} = $sub;
    }
}

1;

=head1 NAME

Fennec::Lite - Minimalist Fennec, the commonly used bits.

=head1 DESCRIPTION

L<Fennec> does a ton, but it may be hard to adopt it all at once. It also is a
large project, and has not yet been fully split into component projects.
Fennec::Lite takes a minimalist approach to do for Fennec what Mouse does for
Moose.

Fennec::Lite is a single module file with no non-core dependencies. It can
easily be used by any project, either directly, or by copying it into your
project. The file itself is less than 300 lines of code at the time of this
writing, that includes whitespace.

This module does not cover any of the more advanced features such as result
capturing or SPEC workflows. This module only covers test grouping and group
randomization. You can also use the FENNEC_ITEM variable with a group name or
line number to run a specific test group only. Test::Builder is used under the
hood for TAP output.

=head1 SYNOPSIS

=head2 SIMPLE

    #!/usr/bin/perl
    use strict;
    use warnings;

    # Brings in Test::More for us.
    use Fennec::Lite;

    tests good => sub {
        ok( 1, "A good test" );
    };

    # You most call run_tests() after declaring your tests.
    run_tests();
    done_testing();

=head2 ADVANCED

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Fennec::Lite
        plan => 8,
        random => 1,
        testing => 'My::Class',
        alias => [
            'My::Class::ThingA'
        ],
        alias_to => {
            TB => 'My::Class::ThingB',
        };

    # Quickly create get/set accessors
    fennec_accessors qw/ construction_string /;

    # Create a constructor for our test class.
    sub new {
        my $class = shift;
        my $string = @_;
        return bless({ construction_string => $string }, $class );
    }

    tests good => sub {
        # Get $self. Created with new()
        my $self = shift;
        $self->isa_ok( __PACKAGE__ );
        is(
            $self->construction_string,
            "This is the construction string",
            "Constructed properly"
        );
        ok( 1, "A good test" );
    };

    tests "todo group" => (
        todo => "This will fail",
        code => sub { ok( 0, "false value" )},
    );

    tests "skip group" => (
        skip => "This will fail badly",
        sub => sub { die "oops" },
    );

    run_tests( "This is the construction string" );

=head2 Pure OO Interface

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Fennec::Lite ();
    use Test::More;

    my $fennec = Fennec::Lite->new( test_class => __PACKAGE__ );

    $fennec->add_tests( "test name" => sub {
        ok( ... );
    });

    $fennec->run_tests;

    done_testing();

=head1 IMPORTED FOR YOU

When you use Fennec::Lite, L<Test::More> is automatically imported for you. In
addition L<Test::Warn> and L<Test::Exception> will also be loaded, but only if
they are installed.

=head1 IMPORT ARGUMENTS

    use Fennec::Lite %ARGS

=over 4

=item plan => 'no_plan' || $count

Plan to pass into Test::More.

=item random => $bool

True by default. When true test groups will be run in random order.

=item testing => $CLASS_NAME

Declare what class you ore testing. Provides $CLASS and CLASS(), both of which
are simply the name of the class being tested.

=item alias => @PACKAGES

Create alias functions your the given package. An alias is a function that
returns the package name. The aliases will be named after the last part of the
package name.

=item alias_to => { $ALIAS => $PACKAGE, ... }

Define aliases, keys are alias names, values are tho package names they should
return.

=back

=head1 RUNNING IN RANDOM ORDER

By default test groups will be run in a random order. The random seed is the
current date (YYYYMMDD). This is used so that the order does not change on the
day you are editing your code. However the ardor will change daily allowing for
automated testing to find order dependent failures.

You can manually set the random seed to reproduce a failure. The FENNEC_SEED
environment variable will be used as the seed when it is present.

    $ FENNEC_SEED="20100915" prove -I lib -v t/*.t

=head1 RUNNING SPECIFIC GROUPS

You can use the FENNEC_ITEM variable with a group name or line number to run a
specific test group only.

    $ FENNEC_ITEM="22" prove -I lib -v t/MyTest.t
    $ FENNEC_ITEM="Test Group A" prove -I lib -v t/MyTest.t

This can easily be integrated into an editor such as vim or emacs.

=head1 EXPORTED FUNCTIONS

=over 4

=item tests $name => $coderef,

=item tests $name => ( code => $coderef, todo => $reason )

=item tests $name => ( code => $coderef, skip => $reason )

=item tests $name => ( sub => $coderef )

=item tests $name => ( method => $coderef )

Declare a test group. The first argument must always be the test group name. In
the 2 part form the second argument must be a coderef. In the multi-part form
you may optionally declare the group as todo, or as a skip. A coderef must
always be provided, in multi-part form you may use the code, method, or sub
params for this purpose, they are all the same.

=item run_tests( %params )

Instantiate an instance of the test class, passing %params to the constructor.
If no constructor is present a default is used. All tests that have been added
will be run. All tests will be cleared, you may continue to declare tests and
call run_tests again to run the new tests.

=item fennec()

Returns the instance of Fennec::Lite created when you imported it. This is the
instance that tests() and run_tests() act upon.

=item fennec_accessors( @NAMES )

Quickly generate get/set accessors for your test class. You could alternatively
do it manually or use L<Moose>.

=back

=head1 PURE OO INTERFACE METHODS

=over 4

=item $tests_ref = $fennec->tests()

Get a reference to the array of tests that have been added since the last run.

=item $classname = $fennec->test_class( $classname )

Get/Set the class name that will be used to create test objects that will act
as the invocant on all test methods.

=item $seed = $fennec->seed( $newseed )

Get/Set the random seed that will be used to re-seed srand() before randomizing
tests, as well as before each test.

=item $bool = $fennec->random( $bool )

Turn random on/off.

=item $fennec->add_tests( $name => sub { ... })

=item $fennec->add_tests( $name, %args, method => sub { ... })

Add a test group.

=item $fennec->run_tests( %test_class_construction_args )

Run the test groups

=item $bool = $fennec->run_skip_test( \%test )

Run a skip test (really just returns true)

=item $bool = $fennec->run_todo_group( \%test )

Run a group as TODO

=item $bool = $fennec->run_test_group( \%test )

Run a test group.

=item ( $bool, $error ) = $fennec->run_test_eval( \%test )

Does the actual test running in an eval to capture errors.

=item $fennec->test_eval_error( $bool, $error, \%test )

Handle a test eval error.

=back

=head1 Extending Fennec::Lite

In the tradition of the Fennec project, Fennec::Lite is designed to be
extensible. You can even easily subclass/edit Fennec::Lite to work with
alternatives to Test::Builder.

=head2 METHODS TO OVERRIDE

=over 4

=item $fennec->init()

Called by new prior to returning the newly constructed object. In Fennec::Lite
this loads L<Test::Builder> and puts a reference to it in the TB() accessor. If
you do want to replace L<Test::Builder> in your subclass you may do so by
overriding init().

=item $fennec->run_skip_test( \%test )

Calls Test::Builder->skip( $reason ), then returns true. Override this if you
replace Test::Builder in your subclass.

=item $fennec->run_todo_group( \%test )

Calls run_test_eval() in a TODO environment. Currently uses L<Test::Builder> to
start/stop TODO mode around the test. Override this if you wish to replace
Test::Builder.

=item $fennec->test_eval_error( $bool, $error, \%test )

Handle an exception thrown in a test group method. Currently calls
Test::Bulder->ok( 0, GROUP_NAME ).

=item @list = must_load()

Returns a list of modules that MUST be loaded into tho calling class (unless
used in OO form). This is currently only L<Test::More>.

=item @list = may_load()

Returns a list of modules that should be loaded only if they are installed.

=item $name_to_code_ref = module_loaders()

Returns a hashref containing package => sub { ... }. Use this if you need to
load modules in a custom way, currently Test::More has a special loader in here
to account for plans.

=item $fennec->import_hook()

Called on the instance that was created by import(), runs at the very end of
the import process. Currently does nothing.

=back

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extensible and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greater framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec-Lite is free software; Standard perl license.

Fennec-Lite is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
