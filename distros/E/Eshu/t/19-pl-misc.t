use strict;
use warnings;
use Test::More tests => 7;
use Eshu;

# unless block
{
	my $input = <<'END';
unless ($debug) {
log_error($msg);
exit 1;
}
END

	my $expected = <<'END';
unless ($debug) {
	log_error($msg);
	exit 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'unless block');
}

# until loop
{
	my $input = <<'END';
until ($done) {
process_next();
$done = is_finished();
}
END

	my $expected = <<'END';
until ($done) {
	process_next();
	$done = is_finished();
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'until loop');
}

# do-while
{
	my $input = <<'END';
do {
$line = <$fh>;
chomp $line;
} while (defined $line && $line ne '');
END

	my $expected = <<'END';
do {
	$line = <$fh>;
	chomp $line;
} while (defined $line && $line ne '');
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'do-while loop');
}

# C-style for loop
{
	my $input = <<'END';
for (my $i = 0; $i < @items; $i++) {
my $item = $items[$i];
process($item, $i);
}
END

	my $expected = <<'END';
for (my $i = 0; $i < @items; $i++) {
	my $item = $items[$i];
	process($item, $i);
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'C-style for loop');
}

# Complex nested data structure
{
	my $input = <<'END';
my %config = (
host => 'localhost',
port => 3306,
options => {
timeout => 30,
retry => 3,
},
tags => [
'production',
'v2',
],
);
END

	my $expected = <<'END';
my %config = (
	host => 'localhost',
	port => 3306,
	options => {
		timeout => 30,
		retry => 3,
	},
	tags => [
		'production',
		'v2',
	],
);
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'nested hash/array data structure');
}

# local variable modification
{
	my $input = <<'END';
sub read_file {
my ($file) = @_;
local $/;
open my $fh, '<', $file or die $!;
return <$fh>;
}
END

	my $expected = <<'END';
sub read_file {
	my ($file) = @_;
	local $/;
	open my $fh, '<', $file or die $!;
	return <$fh>;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'local variable inside sub');
}

# Chained method calls with wrong indentation stripped
{
	my $input = <<'END';
my $result = $dbh
    ->prepare($sql)
    ->execute(@params);
END

	my $expected = <<'END';
my $result = $dbh
->prepare($sql)
->execute(@params);
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'chained method calls re-indented at depth 0');
}
