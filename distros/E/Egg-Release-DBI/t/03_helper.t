use Test::More tests => 9;
use lib qw( ./lib ../lib );
use Egg::Helper;

my $pkg= 'Egg::Helper::Model::DBI';

require_ok($pkg);

my $name = 'Test';
my $e    = Egg::Helper->run( Vtest => { helper_test=> $pkg });
my $c    = $e->config;
my $p    = $e->project_name;
my $path = "$c->{root}/lib/$p/Model/DBI/$name.pm";

@ARGV= ($name, '-ddbi:test', '-utester', '-ptester', '-slocal', '-i1111');
$c->{helper_option}{project_root}= $c->{root};

ok $e->_start_helper, q{$e->_start_helper};
ok -e $path, qq{-e $path};
ok my $body= $e->helper_fread($path),
      q{my $body= $e->helper_fread( ..... );};
like $body, qr{^package\s+$p\:+Model\:+DBI\:+$name\;}s,
      q{$body, qr{^package\s+$p\:+Model\:+DBI\:+$name\;}s};
like $body, qr{\nuse\s+base\s+qw\/\s*Egg\:+Model\:+DBI\:+Base\s*\/\;\n}s,
      q{$body, qr{\nuse\s+base\s+qw\/\s*Egg\:+Model\:+DBI\:+Base\s*\/\;\n}s};
like $body, qr{\n\s+dsn\s+\=>\s*\'dbi\:test\;host\=local\;port\=1111\'\,\s*\n}s,
      q{$body, qr{\n\s+dsn\s+\=>\s*\'dbi\:test\;host\=local\;port\=1111\'\,\s*\n}s};
like $body, qr{\n\s+user\s+\=\>\s+\'tester\'\,\s*\n}s,
      q{$body, qr{\n\s+user\s+\=\>\s+\'tester\'\,\s*\n}s};
like $body, qr{\n\s+password\s+\=\>\s+\'tester\'\,\s*\n}s,
      q{$body, qr{\n\s+password\s+\=\>\s+\'tester\'\,\s*\n}s};

