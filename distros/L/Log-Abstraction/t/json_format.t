#!/usr/bin/env perl
# t/json_format.t -- Tests for format => 'json' in Log::Abstraction

use strict;
use warnings;

use Test::Most;
use JSON::PP;
use File::Temp qw(tempfile);

use Log::Abstraction;

# ---------------------------------------------------------------------------
# Helper: parse the first line written to a temp file, return decoded hashref
# ---------------------------------------------------------------------------
sub _first_json_line {
	my ($fh, $fname) = @_;
	seek $fh, 0, 0;
	my $line = <$fh> // '';
	chomp($line);
	return eval { JSON::PP::decode_json($line) };
}

# ---------------------------------------------------------------------------
# 1. Array backend with format=>'json': fd writes, not array (arrays get raw
#    message text regardless of format).  Use a scalar-path logger instead.
# ---------------------------------------------------------------------------

subtest 'file backend emits valid JSON per line' => sub {
	plan tests => 7;

	my ($fh, $fname) = tempfile(UNLINK => 1);

	my $logger = Log::Abstraction->new(
		logger => $fname,
		level  => 'debug',
		format => 'json',
	);

	$logger->info('hello json');

	my $obj = _first_json_line($fh, $fname);
	ok(defined($obj), 'line decodes as valid JSON');
	is($obj->{level},   'info',       'level field correct');
	is($obj->{message}, 'hello json', 'message field correct');
	ok(defined($obj->{timestamp}), 'timestamp present');
	like($obj->{timestamp}, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
		'timestamp in YYYY-MM-DD HH:MM:SS format');
	ok(defined($obj->{file}), 'file field present');
	ok(defined($obj->{line}), 'line field present');
};

subtest 'json line number is an integer' => sub {
	plan tests => 1;

	my ($fh, $fname) = tempfile(UNLINK => 1);
	my $logger = Log::Abstraction->new(
		logger => $fname,
		level  => 'debug',
		format => 'json',
	);
	$logger->debug('linenum test');

	my $obj = _first_json_line($fh, $fname);
	ok(($obj->{line} =~ /^\d+$/) && ($obj->{line} + 0 == $obj->{line}),
		'line is a numeric integer');
};

subtest 'class field absent for base Log::Abstraction instance' => sub {
	plan tests => 1;

	my ($fh, $fname) = tempfile(UNLINK => 1);
	my $logger = Log::Abstraction->new(
		logger => $fname,
		level  => 'debug',
		format => 'json',
	);
	$logger->info('no class');

	my $obj = _first_json_line($fh, $fname);
	ok(!exists($obj->{class}),
		'class key absent for base-class instance');
};

subtest 'class field present for subclass instance' => sub {
	plan tests => 2;

	{
		package My::SubLogger;
		use parent -norequire, 'Log::Abstraction';
	}

	my ($fh, $fname) = tempfile(UNLINK => 1);
	my $logger = My::SubLogger->new(
		logger => $fname,
		level  => 'debug',
		format => 'json',
	);
	$logger->info('subclass log');

	my $obj = _first_json_line($fh, $fname);
	ok(exists($obj->{class}),        'class key present for subclass');
	is($obj->{class}, 'My::SubLogger', 'class value matches subclass name');
};

subtest 'warn level produces json with level=warn' => sub {
	plan tests => 2;

	my ($fh, $fname) = tempfile(UNLINK => 1);
	my $logger = Log::Abstraction->new(
		logger => $fname,
		level  => 'warn',
		format => 'json',
	);
	$logger->warn('a warning');

	my $obj = _first_json_line($fh, $fname);
	ok(defined($obj), 'JSON line present');
	is($obj->{level}, 'warn', 'level is warn');
};

subtest 'multiple messages produce one JSON line each' => sub {
	plan tests => 3;

	my ($fh, $fname) = tempfile(UNLINK => 1);
	my $logger = Log::Abstraction->new(
		logger => $fname,
		level  => 'debug',
		format => 'json',
	);
	$logger->info('first');
	$logger->debug('second');
	$logger->warn('third');

	seek $fh, 0, 0;
	my @lines = <$fh>;
	chomp @lines;
	is(scalar(@lines), 3, 'three lines written');
	for my $line (@lines) {
		my $obj = eval { JSON::PP::decode_json($line) };
		ok(defined($obj), 'each line is valid JSON') if $line eq $lines[0];
	}
	my $objs = [ map { JSON::PP::decode_json($_) } @lines ];
	is($objs->[0]{message}, 'first',  'first message correct');
};

subtest 'fd backend with json format' => sub {
	plan tests => 3;

	my ($fh, $fname) = tempfile(UNLINK => 1);
	my $logger = Log::Abstraction->new(
		fd     => $fh,
		level  => 'debug',
		format => 'json',
	);
	$logger->info('fd json test');

	my $obj = _first_json_line($fh, $fname);
	ok(defined($obj),            'fd JSON line valid');
	is($obj->{level},   'info',          'level correct');
	is($obj->{message}, 'fd json test',  'message correct');
};

subtest 'hash logger with file sub-key and json format' => sub {
	plan tests => 3;

	my ($fh, $fname) = tempfile(UNLINK => 1);
	close $fh;    # _validate_file_path writes its own handle
	my $logger = Log::Abstraction->new(
		level  => 'debug',
		format => 'json',
		logger => { file => $fname },
	);
	$logger->info('hash file json');

	open(my $rfh, '<', $fname) or die "Cannot open $fname: $!";
	my $line = <$rfh> // '';
	close $rfh;
	chomp($line);
	my $obj = eval { JSON::PP::decode_json($line) };
	ok(defined($obj),              'hash-file JSON line valid');
	is($obj->{level},   'info',            'level correct');
	is($obj->{message}, 'hash file json',  'message correct');
};

done_testing();
