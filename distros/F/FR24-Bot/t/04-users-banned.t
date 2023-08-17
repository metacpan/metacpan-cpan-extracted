use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Temp qw/ :POSIX /;

use_ok('FR24::Utils');
 
my $conf = FR24::Utils::loadconfig("$RealBin/banned.ini");
ok($conf->{"users"}->{"everyone"}, "Everyone is set");
ok($conf->{"users"}->{"everyone"} eq "1", "Everyone is set to 1");
ok($conf->{"users"}->{666} == 0, "Evil user banned");

my %test_users = (
    666 => 0,
    777 => 1,
    999 => 1,
    000 => 1,
);

for my $user_id (sort keys %test_users) {
    my $is_auth = FR24::Utils::authorized($conf, $user_id);
    #
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
everyone=1
666=0