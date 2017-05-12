#!/usr/bin/perl

use Class::Easy;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
};

my $path = 'test_file_gtwbwerwerf';

unlink $path;

my $io = IO::Easy->new ($path);

ok (defined $io and ! -e $io);

ok $io->touch;

ok (-e $io, "file name is: '$io'");
ok (-e $io->abs_path, "abs file name is: '".$io->abs_path."'");

$io = $io->as_file;

ok (ref $io eq qw(IO::Easy::File), "package changed: " . ref $io);
ok ($io->layer eq ':raw', "layer is: " . $io->layer);

# string_reader

my $chunk_count = 1 << 10;

$io->store ("123\n456\n789\n" x $chunk_count);

my $counter = 0;

my $string_test = [123, 456, 789];

$io->string_reader (sub {
	my $s = shift;
	
	if ($counter < 3) {
		ok ($s eq $string_test->[$counter], "pattern ok: $s");
	}
	
	$counter ++;
	
	return if $counter > 3 * $chunk_count;
	
	die "$s, $counter" if length $s != 3;
	# diag "string is: '$s'";
});

ok $counter == 3 * $chunk_count + 1, "string count is: $counter, waiting for: " . (3 * $chunk_count + 1);

$counter = 0;
$string_test = [reverse @$string_test];

$io->string_reader (sub {
	
	my $s = shift;
	
	if ($counter > 0 and $counter < 4) {
		ok ($s eq $string_test->[$counter - 1], "pattern ok: $s");
	}
	
	$counter ++;
	
	return if $counter == 1;
	
	die "$s, $counter" if length $s != 3;
	# diag "string is: '$s'";
}, reverse => 1);
#});

ok $counter == 3 * $chunk_count + 1, "string count is: $counter, waiting for: " . (3 * $chunk_count + 1);

sub handler {my $a = shift; return;}

my $timings;

foreach (1 .. 5) {
    my $t = timer ('standard perl');
    open (FH, $io);
    while (my $str = <FH>){chomp $str; &handler ($str)}
    close FH;
    $timings->[0] += $t->lap ('string_reader');
    $io->string_reader (\&handler);
    $timings->[1] += $t->lap ('string_reader reverse');
    $io->string_reader (\&handler, reverse => 1);
    $timings->[2] += $t->end;
}

foreach (0 .. 2) {
    $timings->[$_] /= 5;
}

diag "perl readline        : $timings->[0]";
diag "string_reader        : $timings->[1]";
diag "string_reader reverse: $timings->[2]";

$io->enc ('utf-8');

ok ($io->layer eq ':encoding(utf-8)');

my $string = "\x{263A}\x{263A}\x{263A}";

#my $string = Encode::decode_utf8 ($string_raw);
ok Encode::is_utf8 ($string);

$io->store ($string);

my $string2 = $io->contents;
ok Encode::is_utf8 ($string2);

ok ($string2 eq $string, "string length: " . length ($string2));

# diag $string2;

# $io->store ($string_raw);

# diag $io->enc;
# diag $io->layer;

$string2 = $io->contents;

#TODO: { # 
#	local $TODO = 'FCUK!!!';
	
	ok ($string2 eq $string, "string length: " . length ($string2));
#}

# diag $string2;

ok unlink $path;

__DATA__

############################
# IO::Easy::File aaa.pl
############################

print "Hello world!\n";

############################
# IO::Easy::File bbb.pl
############################

############################
# IO::Easy::File ccc.pl
############################

print "Hello world 2!\n";

############################
# IO::Easy::File ddd.pl
############################