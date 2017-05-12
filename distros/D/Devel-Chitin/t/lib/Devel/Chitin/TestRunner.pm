use strict;
use warnings;

package Devel::Chitin::TestRunner;

use Devel::Chitin;
use Devel::Chitin::Location;
use base 'Devel::Chitin';
use Carp;

use Exporter qw(import);
our @EXPORT = qw(run_test loc run_in_debugger is_in_test_program has_callsite);

sub is_in_test_program {
    no warnings 'uninitialized';
    return $ARGV[0] eq '--test';
}

my $PKG = __PACKAGE__;
our $at_end = 1;
sub run_test {
    _start_test_in_debugger() unless is_in_test_program();

    my $plan = shift;
    my $program = shift;
    my @tests = @_;

    unless (exists $INC{'Test/More.pm'}) {
        local $@;
        eval "use Test::More";
        Carp::croak("Can't use Test::More: $@") if $@;
    }
    if (defined $plan) {
        Test::More::plan(tests => $plan);
    } else {
        Test::More::plan(skip_all => '');
    }

    my $db = bless \@tests, $PKG;
    $db->attach();
    {
        local($at_end) = 0;
        $program->();
    }
    $DB::single=1;

}

my $has_callsite;
sub has_callsite {
    unless (defined $has_callsite) {
        my $test_callsite = ( sub { Devel::Chitin::Location::get_callsite(0) })->();
        $has_callsite = ! ! $test_callsite;
    }
    return $has_callsite;
}

sub loc {
    my %params = @_;

    defined($params{subroutine}) || do { $params{subroutine} = 'ANON' };
    defined($params{filename}) || do { $params{filename} = (caller)[1] };
    defined($params{package}) || do { $params{package} = 'main' };
    defined($params{callsite}) || do { $params{callsite} = has_callsite() ? Devel::Callsite::callsite(0) : undef };
    return Devel::Chitin::Location->new(%params);
}

sub notify_stopped {
    my($db, $loc) = @_;
    #printf("stopped at %s:%d\n", $loc->filename, $loc->line);

    COMMAND_LOOP:
    while( my $next_test = shift @$db ) {

        if (ref($next_test) eq 'CODE') {
            local $@;
            eval { $next_test->($db, $loc) };
            if ($@) {
                print STDERR $@;
                die $@;
            }

        } elsif ($next_test->isa('Devel::Chitin::Location')) {
            _compare_locations($db, $loc, $next_test);

        } elsif (! ref($next_test)) {
            $db->$next_test();

        } else {
            Carp::croak('Unknown test type '.ref($next_test));
        }
    }

    if (! @$db and ! $at_end) {
        ok(0, sprintf('Ran out of tests before reaching done, at %s:%d',
                        $loc->filename, $loc->line));
        exit;
    } elsif (@$db and $at_end) {
        ok(0, 'Test code ended with '.scalar(@$db).' tests remaining');
    }
}

sub notify_program_exit {
    my $db = shift;
    if (@$db) {
        ok(0, "program exit before ",scalar(@$db)," commands consumed");
    }
}

sub _compare_locations {
    my($db, $got_loc, $expected_loc) = @_;

    my @compare = (
        sub {
                my $expected_sub = $expected_loc->subroutine;
                return ($expected_sub eq 'ANON')
                        ? $got_loc->subroutine =~ m/__ANON__/
                        : $got_loc->subroutine eq $expected_sub;
            },
        sub { return $expected_loc->package eq $got_loc->package },
        sub { return $expected_loc->line == $got_loc->line },
        sub { return $expected_loc->filename eq $got_loc->filename },
    );

    my $report_test; $report_test = sub {
        Test::More::ok(shift, sprintf('Expected location %s:%d got %s:%d',
                                    $expected_loc->filename, $expected_loc->line,
                                    $got_loc->filename, $got_loc->line));
        $report_test = sub {}; # only report the error once
    };

    foreach my $compare ( @compare ) {
        unless ( $compare->() ) {
            $report_test->(0);
        }
    }
    $report_test->(1);
}
            

sub step {
    my $db = shift;
    $db->SUPER::step();
    no warnings 'exiting';
    last COMMAND_LOOP;
}

sub continue {
     my $db = shift;
    $db->SUPER::continue();
    no warnings 'exiting';
    last COMMAND_LOOP;
}

sub stepout {
    my $db = shift;
    $db->SUPER::stepout();
    no warnings 'exiting';
    last COMMAND_LOOP;
}

sub stepover {
    my $db = shift;
    $db->SUPER::stepover();
    no warnings 'exiting';
    last COMMAND_LOOP;
}

sub done {
    my $db = shift;
    $at_end = 1;
    $db->user_requested_exit();
    $db->continue;
    no warnings 'exiting';
    last COMMAND_LOOP;
}

sub at_end {
    my $db = shift;
    Test::More::ok($at_end, 'finished');
}

{
    my $should_poll = 0;
    sub poll {
        return $should_poll;
    }

    sub test_eval {
        my($db, $code_string, $wantarray, $cb) = @_;

        ++$should_poll;
        my $wrapped = sub {
            &$cb;
            $should_poll--;
        };

        $db->eval($code_string, $wantarray, $wrapped);
    }
}
    


sub run_in_debugger {
    _start_test_in_debugger() unless is_in_test_program();
}

sub _start_test_in_debugger {
    my $pid = fork();
    if ($pid) {
        waitpid($pid, 0);
        Carp::croak("Child test program exited with status $?") if $?;
        exit;

    } elsif (defined $pid) {
        exec($^X, '-Ilib', '-It/lib', '-d:Chitin::TestRunner', $0, '--test')
            or Carp::croak("Exec test program failed: $!");

    } else {
        Carp::croak("Fork test program failed: $!");
    }
}

1;
