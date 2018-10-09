use strict;
use warnings;

use File::Spec ();
use File::Slurp;
use File::Temp qw(tempfile);
use IO::Handle ();
use POSIX qw( :fcntl_h ) ;
use Test::More;

plan tests => 9;

# get the current position (BYTES)_
my $data_seek = tell(\*DATA);
ok($data_seek, 'tell: find position of __DATA__');

# get the baseline to test against
my @data_lines = <DATA>;
ok(@data_lines, 'readfile<>: list context, joined - grabbed __DATA__');
my $data_text = join '', @data_lines;
ok($data_text, 'Got a good baseline text');

# seek back to that inital BYTES position
my $seek = seek(\*DATA, $data_seek, 0) || die "seek $!" ;
ok($seek, 'seek: Move back to original __DATA__ position');

# first slurp in the text
my $slurp_text = read_file(\*DATA);
ok($slurp_text, 'read_file: scalar context - grabbed __DATA__');
is($slurp_text, $data_text, 'scalar read matches baseline');

# seek back to that inital BYTES position
$seek = seek(\*DATA, $data_seek, 0) || die "seek $!" ;
ok($seek, 'seek: Move back to original __DATA__ position');

# first slurp in the lines
my @slurp_lines = read_file(\*DATA);
ok(@slurp_lines, 'read_file: list context - grabbed __DATA__');
is_deeply(\@slurp_lines, \@data_lines, 'list read matches baseline');

exit();

__DATA__
line one
second line
more lines
still more

enough lines

we can't test long handle slurps from DATA since i would have to type
too much stuff

so we will stop here
