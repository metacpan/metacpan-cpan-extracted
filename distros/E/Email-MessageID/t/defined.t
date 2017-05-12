use strict;
use warnings;
use Test::More tests => 7;
use Email::MessageID;

my ($user, $host) = ('fred', 'barney');

my $mid_user = Email::MessageID->new(user => $user);
isa_ok $mid_user, 'Email::MessageID';
is $mid_user->user, $user, "$user set";

my $mid_host = Email::MessageID->new(host => $host);
isa_ok $mid_host, 'Email::MessageID';
is $mid_host->host, $host, "$host set";

my $mid_both = Email::MessageID->new(user => $user, host => $host);
isa_ok $mid_both, 'Email::MessageID';
is $mid_both->user, $user, "$user set";
is $mid_both->host, $host, "$host set";
