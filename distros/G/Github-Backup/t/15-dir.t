use strict;
use warnings;

use File::Path;
use Github::Backup;
use Test::More;

my $mod = 'Github::Backup';

my $o = $mod->new(
    api_user => 'stevieb9',
    token => 'xxx',
    dir => 't/backup',
    _clean => 1
);

is $o->stg, 't/backup.stg', "staging directory housed ok";
#is -d $o->stg . '/berrybrew', 1, "repos exist in the staging dir";

done_testing();
