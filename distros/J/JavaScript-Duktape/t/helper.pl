use Data::Dumper;
use Carp;
use Test::More;

sub SET_PRINT_METHOD {
    my $duk = shift;
    $duk->push_perl(sub {
        my $top = $duk->get_top();
        my @str = ();
        for (my $i = 0; $i < $top; $i++){
            $duk->dup($i);
            push @str, $duk->safe_to_string(-1);
            $duk->pop();
        }
        my $str = join " ", @str;
        print $str;
        print "\n";
    });
    $duk->put_global_string('print');
}

sub TEST_SAFE_CALL {
    my $duk = shift;
    my $sub = shift;
    my $name = shift;
    printf("*** %s (duk_safe_call)\n", $name);
    my $_rc = $duk->safe_call($sub, 0, 1);
    printf("==> rc=%d, result='%s'\n", $_rc, $duk->safe_to_string(-1));
    $duk->pop();
}

open STDOUT, ">duk_test.out" or die "Could not redirect STDOUT! $!";

sub test_stdout {

    my $data = do {
        local $/;
        <DATA>;
    };

    open my $out, "duk_test.out" or die "Could not read from duk_test.out! $!";
    my $outdata = do {
        local $/;
        <$out>;
    };

    my @got = split "\n", $outdata;
    my @expected = split "\n", $data;

    print Dumper \@out;
    print Dumper \@contents;
    my $total_tests = scalar @expected;
    for (my $i = 0; $i < scalar @expected; $i++){
        my $got = $got[$i];
        my $expect = $expected[$i];
        $expect =~ s/\r//g;
        $got =~ s/\r//g;
        if ($expect =~ /^#skip/) {
            diag "skip -- $expect";
            --$total_tests;
        } else {
            is ($got, $expect, $expect);
        }
    }

    done_testing($total_tests);
}

END {
    close STDOUT;
    unlink 'duk_test.out';
}

1;
