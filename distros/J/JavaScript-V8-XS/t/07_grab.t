use strict;
use warnings;

use Data::Dumper;
use Text::Trim qw(trim);
use Test::More;
use Test::Output qw/ output_from /;

my $CLASS = 'JavaScript::V8::XS';

sub test_capture {
    my %opts = (
        cap => 1,
        prt => 0,
    );
    foreach my $opt (sort keys %opts) {
        my $save = $opts{$opt};
        my $vm = $CLASS->new({ save_messages => $save });
        ok($vm, "created $CLASS object with save_messages => $save");

        my $times = 3;
        my @got_out;
        my @got_err;
        my @expected;
        foreach my $try (1..$times) {
            my $msg = sprintf("Hi Gonzo #%d", rand(1000*$try));
            push @expected, $msg;
            my $js = "console.log('$msg'); gonzo.length";
            if ($save) {
                $vm->eval($js);
            }
            else {
                my ($out, $err) = output_from(sub { $vm->eval($js); });
                # printf STDERR ("OUTPUT: [%s] [%s]\n", trim($out), trim($err));
                push @got_out, trim($out);
                push @got_err, trim($err);
            }
        }
        if ($save) {
            my $msgs = $vm->get_msgs();
            # print Dumper($msgs);
            @got_out = map +( trim $_ ), @{ $msgs->{stdout} } if exists $msgs->{stdout};
            @got_err = @{ $msgs->{stderr} } if exists $msgs->{stderr};
        }
        # printf STDERR ("MESSAGES [%s] [%s]\n", join(',', @got_out), join(',', @got_err));
        # printf STDERR ("EXPECTED [%s]\n", join(',', @expected));

        my $label = $save ? "captured" : "found";
        is_deeply(\@got_out, \@expected, "$label $times messages sent to stdout from JS");

        my $got_err = join("\n", map +( trim $_ ), @got_err);
        like($got_err, qr/(not |un)defined/, "$label messages sent to stderr from JS");
    }
}

sub main {
    use_ok($CLASS);

    test_capture();
    done_testing;
    return 0;
}

exit main();
