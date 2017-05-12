use strict;
use warnings;
use Test::More tests => 13;

use MIME::Field::ContType;
use MIME::WordDecoder;

use Encode;

# Trivial test
{
	my $field = Mail::Field->new('Content-type');

	isa_ok( $field, 'MIME::Field::ParamVal');
	isa_ok( $field, 'Mail::Field');

	$field->param('_', 'stuff');
	$field->param('answer', 42);

	is( $field->stringify, 'stuff; answer="42"', 'Object stringified to expected value');
}

# Test for CPAN RT #34451
{
	my $header = 'stuff; answer*=utf-8\'\'%c3%be%20%c3%bf';

	my $field = Mail::Field->new('Content-type');
	$field->parse( $header );
	is( $field->param('_'), 'stuff', 'Got body of header');

	# We get it back in UTF-8!
	my $expected = pack('CCCCC', 0xc3, 0xbe, 0x20, 0xc3, 0xbf);
	my $wd = supported MIME::WordDecoder 'UTF-8';

	is( encode('utf8', $wd->decode($field->param('answer'))), $expected, 'answer param was unpacked correctly');
}

# Test for CPAN RT #105455
{
	my $header = 'attachment; filename=wookie.zip size=3; junk=cabbage';

	my $field = Mail::Field->new('Content-type');
	$field->parse( $header );
	is( $field->param('_'), 'attachment', 'Got body of header');
	is ($field->param('filename'), 'wookie.zip', 'Got correct filename');
	is ($field->param('junk'), 'cabbage', 'Got correct final param');

	$header = 'attachment; filename="wookie.zip size=3"';

	$field = Mail::Field->new('Content-type');
	$field->parse( $header );
	is( $field->param('_'), 'attachment', 'Got body of header');
	is ($field->param('filename'), 'wookie.zip size=3', 'Got correct filename');

	$header = 'attachment; filename="wookie.zip;x=1"; (crap); (more_crap) adhesive=glueme';

	$field = Mail::Field->new('Content-type');
	$field->parse( $header );
	is( $field->param('_'), 'attachment', 'Got body of header');
	is ($field->param('filename'), 'wookie.zip;x=1', 'Got correct filename');
	is ($field->param('adhesive'), 'glueme', 'Got correct final parameter');
}
