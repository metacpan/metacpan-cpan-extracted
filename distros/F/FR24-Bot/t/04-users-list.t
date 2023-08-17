use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Temp qw/ :POSIX /;

use_ok('FR24::Utils');
 
my $conf = FR24::Utils::loadconfig("$RealBin/users.ini");

ok($conf->{"users"}->{666} == 0, "Evil user banned 666=0: " . $conf->{"users"}->{666});
ok($conf->{"users"}->{777} == 1, "Good user is authorized 777=1: " . $conf->{"users"}->{777});

my %test_users = (
    666 => 0,
    777 => 1,
    999 => 0,
    000 => 0,
    "Invalid" => 0,
);

for my $user_id (sort keys %test_users) {
    my $is_auth = FR24::Utils::authorized($conf, $user_id);
    my $not = $test_users{$user_id} ? "NOT" : "";
    ok($is_auth == $test_users{$user_id}, "User $user_id is $not authorized: $is_auth");
}
done_testing();

__END__
[telegram]
apikey=7908487915:AEEQFftvQtEbavBGcB81iF1cF2koliWFxJE

[server]
ip=localhost

[users]
777=1
666=0