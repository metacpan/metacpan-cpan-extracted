use strict;
use warnings;
use Data::Dumper qw{Dumper};

use Test::More tests => 33;
BEGIN { use_ok('ExtUtils::MakeMaker::META_MERGE::GitHub') };
my $obj = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>'myowner', repo=>'myrepo', protocol=>'myprotocol', host=>'myhost', login=>'mylogin');
isa_ok($obj, 'ExtUtils::MakeMaker::META_MERGE::GitHub');
can_ok($obj, 'new');
can_ok($obj, 'META_MERGE');
can_ok($obj, 'owner');
can_ok($obj, 'repo');
can_ok($obj, 'version');
can_ok($obj, 'type');
can_ok($obj, 'base_url');
can_ok($obj, 'base_ssh');
can_ok($obj, 'login');
can_ok($obj, 'host');
can_ok($obj, 'protocol');

my %mm = $obj->META_MERGE;

isa_ok($mm{'META_MERGE'}, 'HASH');
is($obj->owner, 'myowner', 'owner');
is($obj->repo, 'myrepo', 'repo');
is($obj->host, 'myhost', 'host set');
is($obj->protocol , 'myprotocol', 'protocol set');
is($obj->login , 'mylogin', 'login set');
is($obj->version, 2, 'version');
is($obj->base_url, 'myprotocol://myhost');
is($obj->base_ssh, 'mylogin@myhost');
is($mm{'META_MERGE'}->{'meta-spec'}->{'version'}, 2, 'version');
is($mm{'META_MERGE'}->{'resources'}->{'homepage'}, 'myprotocol://myhost/myowner/myrepo', 'homepage');
is($mm{'META_MERGE'}->{'resources'}->{'bugtracker'}->{'web'}, 'myprotocol://myhost/myowner/myrepo/issues', 'bugtracker');
is($mm{'META_MERGE'}->{'resources'}->{'repository'}->{'type'}, 'git', 'repository type');
is($mm{'META_MERGE'}->{'resources'}->{'repository'}->{'web'}, 'myprotocol://myhost/myowner/myrepo.git', 'repository web');
is($mm{'META_MERGE'}->{'resources'}->{'repository'}->{'url'}, 'mylogin@myhost:myowner/myrepo.git', 'repository url');

is($obj->owner('X'), 'X', 'owner set');
is($obj->repo('X') , 'X', 'repo set');
is($obj->host('X') , 'X', 'host set');
is($obj->protocol('X') , 'X', 'protocol set');
is($obj->login('X') , 'X', 'login set');
