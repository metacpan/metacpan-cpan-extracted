use strict;
use warnings;
use Data::Dumper qw{Dumper};

use Test::More tests => 24;
BEGIN { use_ok('ExtUtils::MakeMaker::META_MERGE::GitHub') };
my $obj=ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>'mrdvt92', repo=>'perl-ExtUtils-MakeMaker-META_MERGE-GitHub');
isa_ok($obj, 'ExtUtils::MakeMaker::META_MERGE::GitHub');
can_ok($obj, 'new');
can_ok($obj, 'META_MERGE');
can_ok($obj, 'owner');
can_ok($obj, 'repo');
can_ok($obj, 'version');
can_ok($obj, 'type');
can_ok($obj, 'base_url');
can_ok($obj, 'base_ssh');

my %mm = $obj->META_MERGE;
diag(Dumper(\%mm));

isa_ok($mm{'META_MERGE'}, 'HASH');
is($obj->owner, 'mrdvt92', 'owner');
is($obj->repo, 'perl-ExtUtils-MakeMaker-META_MERGE-GitHub', 'repo');
is($obj->version, 2, 'version');
is($obj->base_url, 'https://github.com');
is($obj->base_ssh, 'git@github.com');
is($mm{'META_MERGE'}->{'meta-spec'}->{'version'}, 2, 'version');
is($mm{'META_MERGE'}->{'resources'}->{'homepage'}, 'https://github.com/mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub', 'homepage');
is($mm{'META_MERGE'}->{'resources'}->{'bugtracker'}->{'web'}, 'https://github.com/mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub/issues', 'bugtracker');
is($mm{'META_MERGE'}->{'resources'}->{'repository'}->{'type'}, 'git', 'repository type');
is($mm{'META_MERGE'}->{'resources'}->{'repository'}->{'web'}, 'https://github.com/mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub.git', 'repository web');
is($mm{'META_MERGE'}->{'resources'}->{'repository'}->{'url'}, 'git@github.com:mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub.git', 'repository url');

is($obj->owner('X'), 'X', "owner set");
is($obj->repo('X') , 'X', "repo set");
