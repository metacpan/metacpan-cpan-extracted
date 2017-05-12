package Fennec::Runner;
use strict;
use warnings;

use Fennec::Util qw/verbose_message/;

BEGIN {
    my @ltime = localtime;
    $ltime[5] += 1900;
    $ltime[4] += 1;      # months start at 0?
    for ( 3, 4 ) {
        $ltime[4] = "0$ltime[$_]" unless $ltime[$_] > 9;
    }
    my $seed = $ENV{FENNEC_SEED} || join( '', @ltime[5, 4, 3] );
    verbose_message("\n*** Seeding random with date ($seed) ***\n");
    srand($seed);
}

use Cwd qw/abs_path/;
use Carp qw/carp croak confess/;
use List::Util qw/shuffle/;
use Scalar::Util qw/blessed/;
use Fennec::Util qw/accessors require_module/;
use Fennec::Collector::TB::TempFiles;
use Parallel::Runner;

accessors qw/pid test_classes collector _ran _skip_all/;

my $SINGLETON;
sub is_initialized { $SINGLETON ? 1 : 0 }

sub init { }

sub import {
    my $self = shift->new();
    return unless @_;
    $self->_load_guess($_) for @_;
    $self->inject_run( scalar caller );
}

sub inject_run {
    my $self = shift;
    my ( $caller, $sub ) = @_;

    $sub ||= sub { $self->run(@_) };

    require Fennec::Util;
    Fennec::Util::inject_sub( $caller, 'run', $sub );
}

sub new {
    my $class  = shift;
    my @caller = caller;

    croak "listener_class is deprecated, it was thought nobody used it... sorry. See Fennec::Collector now"
        if $class->can('listener_class');

    croak "Runner was already initialized!"
        if $SINGLETON && @_;

    return $SINGLETON if $SINGLETON;

    my %params = @_;

    my $collector_class = $params{collector_class} || 'Fennec::Collector::TB::TempFiles';
    my $collector = $collector_class->new();

    $SINGLETON = bless(
        {
            test_classes => [],
            pid          => $$,
            collector    => $collector,
        },
        $class
    );

    $SINGLETON->init(%params);

    return $SINGLETON;
}

sub _load_guess {
    my $self = shift;
    my ($item) = @_;

    if ( ref $item && ref $item eq 'CODE' ) {
        $self->_load_guess($_) for ( $self->$item );
        return;
    }

    return $self->load_file($item)
        if $item =~ m/\.(pm|t|pl|ft)$/i
        || $item =~ m{/};

    return $self->load_module($item)
        if $item =~ m/::/
        || $item =~ m/^\w[\w\d_]+$/;

    die "Not sure how to load '$item'\n";
}

sub load_file {
    my $self = shift;
    my ($file) = @_;
    print "Loading: $file\n";
    eval { require $file; 1 } || $self->exception( $file, $@ );
}

sub load_module {
    my $self   = shift;
    my $module = shift;
    print "Loading: $module\n";
    eval { require_module $module } || $self->exception( $module, $@ );
}

sub check_pid {
    my $self = shift;
    return unless $self->pid != $$;
    die "PID has changed! Did you forget to exit a child process?\n";
}

sub exception {
    my $self = shift;
    my ( $name, $exception ) = @_;

    if ( $exception =~ m/^FENNEC_SKIP: (.*)\n/ ) {
        $self->collector->ok( 1, "SKIPPING $name: $1" );
        $self->_skip_all(1);
    }
    else {
        $self->collector->ok( 0, $name );
        $self->collector->diag($exception);
    }
}

sub prunner {
    my $self = shift;
    my ($max) = @_;

    my $runner = Parallel::Runner->new($max);

    $runner->reap_callback(
        sub {
            my ( $status, $pid, $pid_again, $proc ) = @_;

            # Status as returned from system, so 0 is good, 1+ is bad.
            $self->exception( "Child process did not exit cleanly", "Status: $status" )
                if $status;
        }
    );

    $runner->iteration_callback( sub { $self->collector->collect } );

    return $runner;
}

sub run {
    my $self = shift;
    my ($follow) = @_;

    $self->_ran(1);

    for my $class ( shuffle @{$self->test_classes} ) {
        next unless $class;
        $self->run_test_class($class);
        $self->check_pid;
    }

    if ($follow) {
        $self->collector->collect;
        verbose_message("Entering final follow-up stage\n");
        $follow->();
    }

    $self->collector->collect;
    $self->collector->finish();
}

sub run_test_class {
    my $self = shift;
    my ($class) = @_;

    return unless $class;

    verbose_message("Entering workflow stage: $class\n");
    return unless $class->can('TEST_WORKFLOW');

    my $instance = $class->can('new') ? $class->new : bless( {}, $class );
    my $ptests   = $self->prunner( $class->FENNEC->parallel );
    my $pforce   = $class->FENNEC->parallel ? 1 : 0;
    my $meta     = $instance->TEST_WORKFLOW;
    my $orig_cwd = abs_path;

    $meta->test_wait( sub { $ptests->finish } );
    $meta->test_run(
        sub {
            my ($run) = @_;
            $ptests->run(
                sub {
                    chdir $orig_cwd;
                    local %ENV = %ENV;
                    $run->();
                    $self->collector->end_pid();
                },
                $pforce
            );
        }
    );

    Test::Workflow::run_tests($instance);
    $ptests->finish;

    if ( my $post = $class->FENNEC->post ) {
        $self->collector->collect;
        verbose_message("Entering follow-up stage: $class\n");
        eval { $post->(); 1 } || $self->exception( 'done_testing', $@ );
    }
}

sub DESTROY {
    my $self = shift;
    return unless $self->pid == $$;
    return if $self->_ran;
    return if $self->_skip_all;
    return if $^C; # No warning in syntax check

    my $tests = join "\n" => map { "#   * $_" } @{$self->test_classes};

    print STDERR <<"    EOT";

# *****************************************************************************
# ERROR: done_testing() was never called!
#
# This usually means you ran a Fennec test file directly with prove or perl,
# but the file does not call done_testing at the end.
#
# Fennec Tests loaded, but not run:
$tests
#
# *****************************************************************************

    EOT
    exit(1);
}

# Set exit code to failed tests
my $PID = $$;

END {
    return if $?;
    return unless $SINGLETON;
    return unless $PID == $$;
    my $failed = $SINGLETON->collector->test_failed;
    return unless $failed;
    $? = $failed;
}

1;

__END__

=head1 NAME

Fennec::Runner - Responsible for Test::Workflow interaction

=head1 DESCRIPTION

Handles L<Test::Workflow> processing and concurrency. This class is a singleton
instantiated by import() or new(), whichever comes first.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
