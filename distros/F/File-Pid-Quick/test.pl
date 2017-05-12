use Test;
use strict;
use warnings;
BEGIN { plan tests => 3 };
use File::Pid::Quick;
ok(1);

use File::Spec::Functions qw[tmpdir catfile];

my $expected_file_1 = catfile(tmpdir, 'test.pl.pid');
ok($File::Pid::Quick::pid_files_created[0], $expected_file_1);
my $expected_file_2 = catfile(tmpdir, 'test.alt.pid');
File::Pid::Quick->check($expected_file_2);
ok($File::Pid::Quick::pid_files_created[1], $expected_file_2);
