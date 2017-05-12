use strict;
use warnings;
use blib;
use Carp qw(cluck);

use Test::More tests => 4;

use_ok('Mail::Karmasphere::Client');
use_ok('Mail::Karmasphere::Query');
use_ok('Mail::Karmasphere::Response');

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

my $query = new Mail::Karmasphere::Query();
for (0..5) {
	$query->identity('123.45.6.7', 'ip4', 'tag' . $_);
}
$query->identity('123.45.6.7', 'ip6', 'ip6-tag');
is(2, scalar @{ $query->identities });
