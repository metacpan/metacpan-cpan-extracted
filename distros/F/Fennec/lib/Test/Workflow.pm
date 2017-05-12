package Test::Workflow;
use strict;
use warnings;

use Exporter::Declare;
use Test::Workflow::Meta;
use Test::Workflow::Test;
use Test::Workflow::Layer;
use List::Util qw/shuffle/;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

our @CARP_NOT = qw/ Test::Workflow Test::Workflow::Test /;

default_exports qw/
    tests       run_tests
    describe    it
    cases       case
    before_case after_case
    before_each after_each around_each
    before_all  after_all  around_all
    with_tests
    test_sort
    /;

gen_default_export TEST_WORKFLOW => sub {
    my ( $class, $importer ) = @_;
    my $meta = Test::Workflow::Meta->new($importer);
    return sub { $meta };
};

{ no warnings 'once'; @DB::CARP_NOT = qw/ DB Test::Workflow / }

sub _get_layer {
    my ( $offset, $sub, $caller ) = @_;

    my $meta = $caller->[0]->TEST_WORKFLOW;
    croak "$sub() can only be used within a describe or case block, or at the package level."
        if $meta->build_complete;

    my $layer = $meta->peek_layer;

    if ( blessed($layer) && blessed($layer)->isa('Test::Workflow::Layer') ) {
        croak "Layer has already been finalized!"
            if $layer->finalized;
        return $layer;
    }

    return $meta->root_layer;
}

sub with_tests {
    my @caller = caller;
    my $layer = _get_layer( 0, 'with_tests', \@caller );
    $layer->merge_in( \@caller, @_ );
}

{
    no warnings 'once';
    *it = \&tests;
}

sub tests {
    my $name   = shift;
    my @caller = caller;
    my $layer  = _get_layer( 0, 'tests', \@caller );
    $layer->add_test(
        \@caller,
        $name,
        verbose => 1,
        @_
    );
}

sub describe { _add_child( 'describe', @_ ) }
sub cases    { _add_child( 'case',     @_ ) }

sub _add_child {
    my $type   = shift;
    my @caller = caller(1);
    my $layer  = _get_layer( 1, $type, \@caller );
    $layer->add_child( \@caller, @_ );
}

sub case        { _add_type( 'case',        @_ ) }
sub before_case { _add_type( 'before_case', @_ ) }
sub before_each { _add_type( 'before_each', @_ ) }
sub before_all  { _add_type( 'before_all',  @_ ) }
sub after_each  { _add_type( 'after_each',  @_ ) }
sub after_all   { _add_type( 'after_all',   @_ ) }
sub after_case  { _add_type( 'before_each', @_ ) }
sub around_each { _add_type( 'around_each', @_ ) }
sub around_all  { _add_type( 'around_all',  @_ ) }

sub _add_type {
    my $type = shift;
    my $meth = "add_$type";

    my @caller = caller(1);
    my $layer = _get_layer( 1, $type, \@caller );
    $layer->$meth( \@caller, @_ );
}

sub test_sort { caller->TEST_WORKFLOW->test_sort(@_) }

sub run_tests {
    my ($instance) = @_;
    unless ($instance) {
        my $caller = caller;
        $instance = $caller->new() if $caller->can('new');
        $instance ||= bless( {}, $caller );
    }
    my $layer = $instance->TEST_WORKFLOW->root_layer;
    my @tests = get_tests( $instance, $layer, 'PACKAGE LEVEL', [], [], [], [], [] );
    $instance->TEST_WORKFLOW->build_complete(1);
    my $sort = $instance->TEST_WORKFLOW->test_sort || 'rand';
    @tests = order_tests( $sort, @tests );
    $_->run($instance) for @tests;
}

sub order_tests {
    my ( $sort, @tests ) = @_;

    if ( "$sort" =~ /^sort/ ) {
        @tests = sort { $a->name cmp $b->name } @tests;
    }
    elsif ( "$sort" =~ /^rand/ ) {
        @tests = shuffle @tests;
    }
    elsif ( ref $sort eq 'CODE' ) {
        @tests = $sort->(@tests);
    }
    elsif ( $sort !~ /^ord/ ) {
        croak "'$sort' is not a recognized option to test_sort";
    }

    return sort {
        return 0 if $a->is_wrap == $b->is_wrap;
        return 1 if $a->is_wrap;
        return 0;
    } @tests;
}

#<<< no-tidy
sub get_tests {
    my ( $instance, $layer, $name, $before_case, $before_each, $after_each, $around_each, $control, $todo ) = @_;

    # get before_each and after_each
    push    @$before_case => @{ $layer->before_case };
    push    @$before_each => @{ $layer->before_each };
    push    @$around_each => @{ $layer->around_each };
    push    @$control     => @{ $layer->control     };
    unshift @$after_each  => @{ $layer->after_each  };

    my @tests = @{ $layer->test };

    if ($todo) {
        $_->todo( $todo ) for @tests
    }

    if ( my $specific = $ENV{FENNEC_TEST}) {
        @tests = grep {
            my $out = 0;
            if ( $specific =~ m/^\d+$/ ) {
                $out = 1 if $_->start_line <= $specific && $_->end_line >= $specific;
            }
            else {
                $out = 1 if $_->name eq $specific;
            }
            $out;
        } @tests;
    }

    my @cases = @{ $layer->case };
    if ( @cases ) {
        my @new_tests;
        for my $test ( @tests ) {
            for my $case ( @cases ) {
                push @new_tests => Test::Workflow::Test->new(
                    setup => [ @$before_case, $case, @$before_each ],
                    tests => [
                        $test->clone_with(
                            name => "'" . $case->name . "' x '" . $test->name . "'"
                        )
                    ],
                    teardown   => [ @$after_each  ],
                    around     => [ @$around_each ],
                    control    => [ @$control     ],
                    block_name => $name,
                );
            }
        }
        @tests = @new_tests;
    }
    else {
        @tests = map { Test::Workflow::Test->new(
            setup      => [ @$before_each ],
            tests      => [ $_            ],
            teardown   => [ @$after_each  ],
            around     => [ @$around_each ],
            control    => [ @$control     ],
            block_name => $name,
        )} @tests;
    }

    push @tests => map {
        my $layer = Test::Workflow::Layer->new;

        $instance->TEST_WORKFLOW->push_layer( $layer );
        $_->todo( $todo ) if $todo;
        $_->run( $instance, $layer );

        my @tests = get_tests(
            $instance,
            $layer,
            $_->name,
            [@$before_case],
            [@$before_each],
            [@$after_each],
            [@$around_each],
            [@$control],
            $_->todo,
        );

        $instance->TEST_WORKFLOW->pop_layer( $layer );

        unless (@tests) {
            my $name  = $_->name;
            my $start = $_->start_line;
            my $end   = $_->end_line;
            warn "No tests in block '$name' approx lines $start -> $end\n"
                unless $ENV{FENNEC_TEST};
        }

        @tests;
    } @{ $layer->child };

    my @before_all = @{ $layer->before_all };
    my @after_all  = @{ $layer->after_all  };
    my @around_all = @{ $layer->around_all };
    my @control    = @{ $layer->control    };
    return Test::Workflow::Test->new(
        setup      => [ @before_all ],
        tests      => [ @tests      ],
        teardown   => [ @after_all  ],
        around     => [ @around_all ],
        control    => [ @control    ],
        block_name => $name,
        is_wrap    => 1,
    ) if @before_all || @after_all || @around_all || @control;

    return @tests;
}
#>>>

1;

__END__

=head1 NAME

Test::Workflow - Provide test grouping, reusability, and structuring such as
RSPEC and cases.

=head1 DESCRIPTION

Test::Workflow provides tools for grouping and structuring tests. There is also
a facility to write re-usable tests. Test::Workflow test files define classes.
Tests within the files are defined as a type of method.

Test::Workflow provides an RSPEC implementation. This implementation includes
C<describe> blocks, C<it> blocks, as well as C<before_each>, C<before_all>,
C<after_each>, C<after_all>. There are even two new types: C<around_each> and
C<around_all>.

Test::Workflow provides a cases workflow. This workflow allows you to create
multiple cases, and multiple tests. Each test will be run under each case. This
allows you to write a test that should pass under multiple conditions, then
write a case that builds that specific condition.

Test::Workflow provides a way to 'inherit' tests. You can write classes that
use Test::Workflow, and define test groups, but not run them. These classes can
then be imported into as many test classes as you want. This is achieved with
the C<with_tests> function.

Test::Workflow gives you control over the order in which test groups will be
run. You can use the predefined 'random', 'ordered', or 'sort' settings. You
may also provide your own ordering function. This is achieved using the
C<test_sort> function.

=head1 SYNOPSIS

    package MyTest;
    use strict;
    use warnings;

    use Test::More;
    use Test::Workflow;

    with_tests qw/ Test::TemplateA Test::TemplateB /;
    test_sort 'rand';

    # Tests can be at the package level
    use_ok( 'MyClass' );

    tests loner => sub {
        my $self = shift;
        ok( 1, "1 is the loneliest number... " );
    };

    tests not_ready => (
        todo => "Feature not implemented",
        code => sub { ... },
    );

    tests very_not_ready => (
        skip => "These tests will die if run"
        code => sub { ... },
    );

    run_tests();
    done_testing();

=head2 RSPEC WORKFLOW

Here setup/teardown methods are declared in the order in which they are run,
but they can really be declared anywhere within the describe block and the
behavior will be identical.

    describe example => sub {
        my $self = shift;
        my $number = 0;
        my $letter = 'A';

        before_all setup => sub { $number = 1 };

        before_each letter_up => sub { $letter++ };

        # it() is an alias for tests()
        it check => sub {
            my $self = shift;
            is( $letter, 'B', "Letter was incremented" );
            is( $number, 2,   "number was incremented" );
        };

        after_each reset => sub { $number = 1 };

        after_all teardown => sub {
            is( $number, 1, "number is back to 1" );
        };

        describe nested => sub {
            # This nested describe block will inherit before_each and
            # after_each from the parent block.
            ...
        };

        describe maybe_later => (
            todo => "We might get to this",
            code => { ... },
        );
    };

    describe addon => sub {
        my $self = shift;

        around_each localize_env => sub {
            my $self = shift;
            my ( $inner ) = @_;

            local %ENV = ( %ENV, foo => 'bar' );

            $inner->();
        };

        tests foo => sub {
            is( $ENV{foo}, 'bar', "in the localized environment" );
        };
    };

=head2 CASE WORKFLOW

Cases are used when you have a test that you wish to run under several tests
conditions. The following is a trivial example. Each test will be run once
under each case. B<Beware!> this will run (cases x tests), with many tests and
cases this can be a huge set of actual tests. In this example 8 in total will
be run.

B<Note:> The 'cases' keyword is an alias to describe. case blocks can go into
any workflow and will work as expected.

    cases check_several_numbers => sub {
        my $number;
        case one => sub { $number = 2 };
        case one => sub { $number = 4 };
        case one => sub { $number = 6 };
        case one => sub { $number = 8 };

        tests is_even => sub {
            ok( !$number % 2, "number is even" );
        };

        tests only_digits => sub {
            like( $number, qr/^\d+$/i, "number is all digits" );
        };
    };

=head1 EXPORTS

=over 4

=item with_tests( @CLASSES )

Use tests defined in the specified classes.

=item test_sort( sub { my @tests = @_; ...; return @tests })

=item test_sort( 'sort' )

=item test_sort( 'random' )

=item test_sort( 'ordered' )

Declare how tests should be sorted.

=item cases( name => sub { ... })

=item cases( 'name', %params, code => sub { ... })

=item describe( name => sub { ... })

=item describe( 'name', %params, code => sub { ... })

Define a block that encapsulates workflow elements.

=item tests( name => sub { ... })

=item tests( 'name', %params, code => sub { ... })

=item it( name => sub { ... })

=item it( 'name', %params, code => sub { ... })

Define a test block.

=item case( name => sub { ... })

=item case( 'name', %params, code => sub { ... })

Define a case, each test will be run once per case that is defined at the same
level (within the same describe or cases block).

=item before_each( name => sub { ... })

=item after_each( name => sub { ... })

=item before_all( name => sub { ... })

=item after_all( name => sub { ... })

These define setup and teardown functions that will be run around tests.

=item around_each( name => sub { ... })

=item around_all( name => sub { ... })

These are special additions to the setup and teardown methods. They are used
like so:

    around_each localize_env => sub {
        my $self = shift;
        my ( $inner ) = @_;

        local %ENV = ( %ENV, foo => 'bar' );

        $inner->();
    };

=item run_tests()

This will finalize the meta-data (forbid addition of new tests) and run the
tests.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Test-Workflow is free software; Standard perl license.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
