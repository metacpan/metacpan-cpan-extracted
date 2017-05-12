use Test::More tests => 15;
use Test::Exception;

use File::Temp 'tempfile';

BEGIN {
	use_ok('File::VirusScan');
	use_ok('File::VirusScan::Engine');
	use_ok('File::VirusScan::Result');
}

dies_ok { File::VirusScan->new() } 'Constructor dies with no arguments';
like( $@, qr/Must supply an 'engines' value to constructor/, '... error as expected');

dies_ok { File::VirusScan->new({ engines => { wookie => {} }}) } 'Constructor dies with nonexistent engine';
like( $@, qr/Unable to find class wookie for backend 'wookie'/, '... error as expected');

{
	package File::VirusScan::Engine::Bogus;
	use base qw( File::VirusScan::Engine );
	sub new  { bless {}, $_[0]; }
	sub scan { return File::VirusScan::Result->error( "bogus scanner looking at $_[1]" ); };
	$INC{'File/VirusScan/Engine/Bogus.pm'} = 1;
}

my $s;
lives_ok { $s = File::VirusScan->new({ engines => { -Bogus => {} } }); } 'Constructor lives with trivial non-working engine';
my $result = $s->scan('/');
isa_ok( $result, 'File::VirusScan::ResultSet');
ok( $result->has_error(), 'Result is an error' );
my ($err) = $result->get_error();
isa_ok( $err, 'File::VirusScan::Result');
is( $err->get_data(), 'bogus scanner looking at /', 'Error string is what we expected');

my($fh, $filename) = tempfile();
my $test_msg = <<'EOM';
To: postmaster
From: root
Subject: Testing

EOM

$fh->print($test_msg) or die "Couldn't write to $filename: $!";
$fh->close;

$result = $s->scan( $filename );
isa_ok( $result, 'File::VirusScan::ResultSet');
ok( $result->has_error(), 'Result is an error' );
like( ($result->get_error)[0]->get_data, qr{^bogus scanner looking at /tmp/(?:[A-Za-z0-9]+)$}, 'Error string is what we expected');
1;
