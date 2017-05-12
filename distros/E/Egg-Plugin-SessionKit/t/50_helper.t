use Test::More tests => 6;
use lib qw( ./lib ../lib );
use Egg::Helper;

my $pkg= 'Egg::Helper::Model::Session';

require_ok($pkg);

my $name = 'Test';
my $e    = Egg::Helper->run( Vtest => { helper_test=> $pkg });
my $c    = $e->config;
my $p    = $e->project_name;
my $path = "$c->{root}/lib/$p/Model/Session/$name.pm";

@ARGV= ($name);
$c->{helper_option}{project_root}= $c->{root};

ok $e->_start_helper, q{$e->_start_helper};
ok -e $path, qq{-e $path};
ok my $body= $e->helper_fread($path),
      q{my $body= $e->helper_fread( ..... );};
like $body, qr{package\s+Vtest\:+Model\:+Session\:+Test\;\s*\n},
     q{$body,  package Manager.};
like $body, qr{\npackage\s+Vtest\:+Model\:+Session\:+Test\:+TieHash\;\s*\n},
     q{$body,  package TieHash.};
