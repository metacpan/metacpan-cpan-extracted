use Test::More tests => 11;
use Test::Cmd;
use strict; use warnings;

BEGIN {
  use_ok('YAML::XS');
}

my $cmd = new_ok( 'Test::Cmd' => [
   workdir => '',
   prog    => 'blib/script/ircindexer-examplecf',
 ],
);

is( $cmd->run(args => '-h'), 0, 'ircindexer-examplecf exit 0' );

is( $cmd->run(args => '-s -t httpd'), 0, 'Get httpd cf' );
my $yaml;
ok( $yaml = $cmd->stdout, 'httpd cf exists' );
my $ref;
ok( $ref = YAML::XS::Load($yaml), 'Load httpd cf' );
ok( $ref->{NetworkDir}, 'httpd cf looks OK' );

$yaml = undef; $ref = undef;
is( $cmd->run(args => '-s -t spec'), 0, 'Get specfile cf' );
ok( $yaml = $cmd->stdout, 'specfile exists' );
ok( $ref = YAML::XS::Load($yaml), 'Load specfile cf' );
ok( ($ref->{Network} and $ref->{Server}), 'specfile cf looks OK' )
