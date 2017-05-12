use Test::More tests => 6;
use lib qw( ./lib ../lib );
use Egg::Helper;

my $pkg= 'Egg::Helper::Model::FsaveDate';

require_ok($pkg);

my $e    = Egg::Helper->run( Vtest => { helper_test=> $pkg });
my $c    = $e->config;
my $p    = $e->project_name;
my $path = "$c->{root}/lib/$p/Model/FsaveDate.pm";

@ARGV= ();
$c->{helper_option}{project_root}= $c->{root};

ok $e->_start_helper, q{$e->_start_helper};
ok -e $path, qq{-e $path};

ok my $body= $e->helper_fread($path),
      q{my $body= $e->helper_fread( ..... );};

like $body, qr{package\s+Vtest\:+Model\:+FsaveDate\;\s*\n},
     q{$body,  package Manager.};

like $body, qr{package\s+Vtest\:+Model\:+FsaveDate\:+handler\;\s*\n},
     q{$body,  package handler.};
