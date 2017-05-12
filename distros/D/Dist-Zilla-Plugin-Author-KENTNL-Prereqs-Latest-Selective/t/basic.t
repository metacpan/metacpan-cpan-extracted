use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini Builder );

# FILENAME: basic.t
# CREATED: 08/31/14 00:29:32 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: basic

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/dist.ini' => simple_ini( [ 'Prereqs', { 'Test::More' => 0 } ], ['Author::KENTNL::Prereqs::Latest::Selective'], ),
    },
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

my $dm = $zilla->distmeta->{prereqs}->{runtime};
ok( exists $dm->{requires}->{'Test::More'}, "Test::More is required" ) or diag explain $dm;
if ( eval { Test::More->VERSION('0.90'); 1; } ) {
  isnt( $dm->{requires}->{'Test::More'}, '0.89', "Test::More is better than 0.89" );
}
isnt( $dm->{requires}->{'Test::More'}, '0', "Test::More is better than 0" );

done_testing;
