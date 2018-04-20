use strict;
use warnings;

use Data::Dumper;
use Text::Trim qw(trim);
use Test::More;
use Test::Output qw/ output_from /;
use JavaScript::Duktape::XS;

sub test_capture {
    my %opts = (
        cap => 1,
        prt => 0,
    );
    foreach my $opt (sort keys %opts) {
        my $save = $opts{$opt};
        my $duk = JavaScript::Duktape::XS->new({ save_messages => $save });
        ok($duk, "created JavaScript::Duktape::XS object with save_messages => $save");

        my $times = 3;
        my @got_out;
        my @got_err;
        my @expected;
        foreach my $try (1..$times) {
            my $msg = sprintf("Hi Gonzo #%d", rand(1000*$try));
            push @expected, $msg;
            my $js = "console.log('$msg'); gonzo.length";
            if ($save) {
                $duk->eval($js);
            }
            else {
                my ($out, $err) = output_from(sub { $duk->eval($js); });
                # printf STDERR ("OUTPUT: [%s] [%s]\n", trim($out), trim($err));
                push @got_out, trim($out);
                push @got_err, trim($err);
            }
        }
        if ($save) {
            my $msgs = $duk->get_msgs();
            @got_out = map +( trim $_ ), @{ $msgs->{stdout} } if exists $msgs->{stdout};
            @got_err = @{ $msgs->{stderr} } if exists $msgs->{stderr};
            # printf STDERR ("MESSAGES [%s] [%s]\n", join(',', @got_out), join(',', @got_err));
        }

        my $label = $save ? "captured" : "found";
        is_deeply(\@got_out, \@expected, "$label $times messages sent to stdout from JS");

        my $got_err = join("\n", map +( trim $_ ), @got_err);
        like($got_err, qr/undefined/, "$label messages sent to stderr from JS");
    }
}

sub main {
    test_capture();
    done_testing;
    return 0;
}

exit main();
