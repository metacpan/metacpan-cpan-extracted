use strict;
use warnings;

use Data::Dumper;
use Text::Trim qw(trim);
use Test::More;
use Test::Output qw/ stderr_from /;
use JavaScript::Duktape::XS;

sub test_grab {
    my $duk = JavaScript::Duktape::XS->new({ save_messages => 1 });
    ok($duk, "created JavaScript::Duktape::XS object");

    my $times = 3;
    my @expected;
    foreach my $try (1..$times) {
        my $msg = sprintf("Hi Gonzo #%d", rand(1000*$try));
        my $js = "console.log('$msg')";
        $duk->eval($js);
        push @expected, $msg;
    }
    my $msgs = $duk->get_msgs();
    my @got = map +( trim $_ ), @{ $msgs->{stderr} };
    is_deeply(\@got, \@expected, "grabbed $times messages back from JS");
}

sub test_no_grab {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $times = 3;
    my @got;
    my @expected;
    foreach my $try (1..$times) {
        my $msg = sprintf("Hi Gonzo #%d", rand(1000*$try));
        my $js = "console.log('$msg')";
        my $err = stderr_from(sub { $duk->eval($js); });
        push @expected, $msg;
        push @got, trim($err);
    }
    is_deeply(\@got, \@expected, "found $times messages in stderr from JS");
}

sub main {
    test_grab();
    test_no_grab();
    done_testing;
    return 0;
}

exit main();
