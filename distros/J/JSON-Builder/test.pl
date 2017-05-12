$| = 1;
use v5.10;
use strict;
use warnings;


use JSON::XS;
use File::Temp qw(tempfile);

use Compress::Zlib;
use MIME::Base64;
use URI::Escape;


use Test::More tests => 5;

BEGIN { use_ok( 'JSON::Builder' ) }

my $json = JSON::XS->new()->utf8(1)->ascii(1);


sub read_fh {
	my ($fh) = @_;
	$fh->flush();
	$fh->seek(0,0);
	join "", <$fh>;
}


sub build {
	my ($fh, $builder) = @_;

	my $fv = $builder->val( { a => 'b', c => 'd' } );

	my $l = $builder->list();
	$l->add( { 1 => 'a', 2 => 'b' } );
	$l->add( { 1 => 'c', 2 => 'd' } );
	my $fl = $l->end();

	my $o = $builder->obj();
	$o->add( o1 => ['a', 'b'] );
	$o->add( o2 => ['c', 'd'] );
	my $fo = $o->end();

	my %d = (
		one => 1,
		v   => $fv,
		l   => $fl,
		o   => $fo,
		zl  => $builder->list()->end(),
		zo  => $builder->obj()->end(),
	);

	$builder->encode(\%d);

}


my $j = {
	one => 1,
	v => { a => 'b', c => 'd' },
	l => [
		{ 1 => 'a', 2 => 'b' },
		{ 1 => 'c', 2 => 'd' },
	],
	o => {
		o1 => ['a', 'b'],
		o2 => ['c', 'd'],
	},
	zl => [],
	zo => {},
};


# Simple
{
	my ($fh) = tempfile(UNLINK => 1);

	my $builder = JSON::Builder->new(
		json    => $json,
		fh      => $fh,
		read_in => 1000*57
	);

	build($fh, $builder);

	my $r = read_fh($fh);
	is_deeply($json->decode($r), $j, "Simple");
}


# Plain
{
	my ($fh)       = tempfile(UNLINK => 1);
	my ($fh_plain) = tempfile(UNLINK => 1);

	my $builder = JSON::Builder::Compress->new(
		json     => $json,
		fh       => $fh,
		read_in  => 1000*57,
		fh_plain => $fh_plain, 
	);

	build($fh, $builder);

	my $r = read_fh($fh);
	my $rj = uncompress(MIME::Base64::decode_base64url($r));
	is_deeply($json->decode($rj), $j, "Compress and Base64");

	my $r_plain = read_fh($fh_plain);
	is_deeply($json->decode($rj), $json->decode($r_plain), "Plain");
}


# encode_sub
{

	my ($fh) = tempfile(UNLINK => 1);

	my $builder = JSON::Builder::Compress->new(
		json     => $json,
		fh       => $fh,
		read_in  => 1000*57,
		encode_sub        => sub { uri_escape(encode_base64($_[0], "")) },
		encode_chunk_size => 57,
	);

	build($fh, $builder);

	my $r = read_fh($fh);
	my $rj = uncompress(decode_base64(uri_unescape($r)));
	is_deeply($json->decode($rj), $j, "Compress and encode_sub");
}
