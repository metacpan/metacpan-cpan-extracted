#!/usr/bin/env perl
package Test::Procs;
use strict;
use warnings;

use Fennec parallel => 1, test_sort => 'ordered';

use File::Temp qw/tempfile/;

my ( $fh, $name ) = tempfile();

describe procs_1 => sub {
    my @pids = ($$);

    before_all setup => sub {
        ok( $pids[-1] == $$, "before_all happens in parent" );
        push @pids => $$;
    };

    tests a => sub {
        ok( $$ != $pids[-1], "New proc, even for just 1 test" );
        push @pids => $$;
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

describe procs_2 => sub {
    my @pids = ($$);
    my $test_pid;

    before_all setup => sub {
        ok( $pids[-1] == $$, "before_all happens in parent" );
        push @pids => $$;
    };

    tests a => sub {
        ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
        ok( !$test_pid,      "Did not see other test" );
        $test_pid = $$;
    };

    tests b => sub {
        ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
        ok( !$test_pid,      "Did not see other test" );
        $test_pid = $$;
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

describe procs_nested => sub {
    my @caller = caller;
    my @pids   = ($$);
    my $test_pid;

    before_all setup => sub {
        print $fh "OUTER SETUP\n";
        ok( $pids[-1] == $$, "before_all happens in parent" );
        push @pids => $$;
    };

    tests outer_a => sub {
        print $fh "OUTER TEST\n";
        ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
        ok( !$test_pid,      "Did not see other test" );
        $test_pid = $$;
    };

    describe inner => sub {
        before_all inner_setup => sub {
            print $fh "INNER SETUP\n";
            ok( $pids[-1] == $$, "before_all happens in parent" );
            push @pids => $$;
        };

        around_each spin_me_right_round => sub {
            my $self = shift;
            my ($run) = @_;
            print $fh "AROUND START\n";
            $run->();
            print $fh "AROUND END\n";
        };

        tests a => sub {
            print $fh "INNER TEST\n";
            ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
            ok( !$test_pid,      "Did not see other test" );
            $test_pid = $$;
        };

        tests b => sub {
            print $fh "INNER TEST\n";
            ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
            ok( !$test_pid,      "Did not see other test" );
            $test_pid = $$;
        };

        after_all inner_teardown => sub {
            ok( $$ == $pids[-1], "Same process as before_all" );
        };
    };

    tests outer_b => sub {
        print $fh "OUTER TEST\n";
        ok( $$ != $pids[-1], "Multiple Tests, each should have a different proc" );
        ok( !$test_pid,      "Did not see other test" );
        $test_pid = $$;
    };

    after_all teardown => sub {
        ok( $$ == $pids[-1], "Same process as before_all" );
    };
};

done_testing( sub {
    close($fh);
    open( $fh, '<', $name ) || die $!;
    is_deeply( join( '' => <$fh> ), <<"    EOT", "Order is correct" );
OUTER SETUP
OUTER TEST
OUTER TEST
INNER SETUP
AROUND START
INNER TEST
AROUND END
AROUND START
INNER TEST
AROUND END
    EOT
});
