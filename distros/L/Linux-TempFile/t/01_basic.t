use strict;
use warnings;

use Test::More;
use Linux::TempFile;
use File::Temp qw(tempdir);

my $tmpfile = Linux::TempFile->new;
isa_ok $tmpfile, 'Linux::TempFile';
isa_ok $tmpfile, 'IO::Handle';

syswrite $tmpfile, "Hello\n";

my $dir = tempdir(CLEANUP => 1);
my $filename = "$dir/test.txt";
$tmpfile->link($filename);
close $tmpfile;

open my $fh, '<', $filename or die $!;
my $content = join '', <$fh>;
is $content, "Hello\n";

done_testing;
