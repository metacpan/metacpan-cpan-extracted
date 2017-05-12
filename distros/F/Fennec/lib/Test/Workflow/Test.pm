package Test::Workflow::Test;
use strict;
use warnings;

use Fennec::Util qw/accessors/;
use List::Util qw/shuffle/;
use Carp qw/cluck/;
require Time::HiRes;

accessors qw/setup tests teardown around block_name is_wrap control/;

sub new {
    my $class  = shift;
    my %params = @_;
    return bless(
        {
            setup      => $params{setup}      || [],
            tests      => $params{tests}      || [],
            teardown   => $params{teardown}   || [],
            around     => $params{around}     || [],
            control    => $params{control}    || [],
            block_name => $params{block_name} || "",
            is_wrap    => $params{is_wrap}    || 0,
        },
        $class
    );
}

sub name {
    my $self = shift;
    return $self->tests->[0]->name
        if @{$self->tests} == 1;

    return $self->block_name;
}

sub run {
    my $self = shift;

    my ($instance) = @_;

    my $run       = $self->_wrap_tests($instance);
    my $prunner   = $instance->TEST_WORKFLOW->test_run;
    my $testcount = @{$self->tests};

    return $run->() if $self->is_wrap;

    return $prunner->( $run, $self, $instance )
        if $prunner && $testcount == 1;

    $run->();
}

sub _wrap_tests {
    my $self = shift;
    my ($instance) = @_;

    my $ref = ref $self;
    $ref =~ s/^.*:://;

    my $meta = $instance->TEST_WORKFLOW;

    my $sort = $meta->test_sort || 'rand';
    my @tests = Test::Workflow::order_tests( $sort, @{$self->tests} );

    my $wait = $meta->test_wait;
    my $pid  = $$;

    my $debug = $instance->can('FENNEC') && $instance->FENNEC->debug;
    my $collector = $debug ? Fennec::Runner->new->collector : undef;

    return sub {
        my $control_store = [];
        $meta->control_store($control_store);
        for my $sub (@{$self->control}) {
            my $control = $sub->();
            if ($debug) {
                my ($sec, $ms) = Time::HiRes::gettimeofday();
                my $msg = sprintf(
                    "FENNEC_DEBUG_MOCK:PID:%d\0CLASS:%s\0SEC:%d\0MSEC:%d\0OVERRIDES:%s\n",
                    $$,
                    $control->package,
                    $sec,
                    $ms,
                    join ' ' => grep { /^\w/ } keys %$control
                );
                $collector->diag($msg);
            }
            push @$control_store => $control;
        }

        $wait->() if $wait && $self->can('is_wrap') && $self->is_wrap;

        $_->run($instance) for @{$self->setup};

        my $base = sub {
            for my $test (@tests) {
                $test->run($instance);
            }
        };

        my $outer = $base;
        for my $around ( @{$self->around} ) {
            my $inner = $outer;
            $outer = sub { $around->run( $instance, $inner ) };
        }

        $outer->();

        $_->run($instance) for @{$self->teardown};

        $meta->control_store(undef);
        $control_store = undef;

        $wait->() if $wait && $self->can('is_wrap') && $self->is_wrap;
    };
}

1;

__END__

=head1 NAME

Test::Workflow::Test - A test block wrapped with setup/teardown methods, ready
to be run.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Test-Workflow is free software; Standard perl license.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
