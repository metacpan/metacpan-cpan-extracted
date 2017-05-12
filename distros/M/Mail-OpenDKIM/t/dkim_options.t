#!/usr/bin/perl -wT

use Test::More tests => 11;
BEGIN { use_ok('Mail::OpenDKIM') };

#########################

LIBFEATURE: {

	my $o = new_ok('Mail::OpenDKIM');
	ok($o->dkim_init());

	my $args = {
		op => DKIM_OP_GETOPT,
		opt => DKIM_OPTS_TMPDIR,
		data => pack('B' x 80, 0 x 80),
		len => 80
	};

	ok($o->dkim_options($args) == DKIM_STAT_OK);

	ok(defined($$args{data}));
	like($$args{data}, qr/^\//);

	$$args{opt} = DKIM_OPTS_FLAGS;
	$$args{len} = 4;
	ok($o->dkim_options($args) == DKIM_STAT_OK);

	my $flags = unpack('L', $$args{data});
	ok(unpack('L', $$args{data}) != DKIM_LIBFLAGS_FIXCRLF);

	$$args{op} = DKIM_OP_SETOPT;
	$$args{data} = pack('L', DKIM_LIBFLAGS_FIXCRLF);

	ok($o->dkim_options($args) == DKIM_STAT_OK);

	$$args{data} = pack('L', -1);

	$$args{op} = DKIM_OP_GETOPT;
	ok($o->dkim_options($args) == DKIM_STAT_OK);

	$flags = unpack('L', $$args{data});
	ok(unpack('L', $$args{data}) == DKIM_LIBFLAGS_FIXCRLF);

	$o->dkim_close();
}

