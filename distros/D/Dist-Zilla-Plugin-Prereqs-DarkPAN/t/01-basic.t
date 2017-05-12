use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );
my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        ['MetaConfig'],
        [
          'Prereqs::DarkPAN' => {
            DDG => 'http://darkpan.duckduckgo.com/',
          }
        ],
      ),
    }
  }
);
$tzil->chrome->logger->set_debug(1);
$tzil->build;
pass("build ok");
note explain $tzil->distmeta;
note explain $tzil->log_messages;
