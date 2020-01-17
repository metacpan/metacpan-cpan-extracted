use strict;
use warnings;

use File::Spec ();
use File::Temp qw(tempfile);
use IO::InnerFile;
use IO::File;
use Test::More;

sub temp_file_path {
    # older EUMMs turn this on. We don't want to emit warnings.
    local $^W;

    my $file;
    (undef, $file) = tempfile('tempXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);
    return $file;
}

plan tests => 7;

# Create a test file
my $temp_file = temp_file_path();
open(my $ofh, '>', $temp_file) || die("Cannot write $temp_file: $!");
binmode $ofh;
my $data = "Here is some dummy content.\n";
$data   .= "Here is some more dummy content\n";
$data   .= "Here is yet more dummy content.\n";
$data   .= "And finally another line.\n";
print {$ofh} $data;
close($ofh);

# Open it as a regular file handle
my $fh = IO::File->new("<$temp_file");

my $inner = IO::InnerFile->new($fh, 28, 64); # Second and third lines

my $line;
$line = <$inner>;
is($line, "Here is some more dummy content\n", "readline: got the right second line");
$line = <$inner>;
is($line, "Here is yet more dummy content.\n", "readline: got the right third line");
$line = <$inner>;
is($line, undef, "readline: undef reached when past our definition");

$inner->close();

$inner = IO::InnerFile->new($fh, 28, 64); # Second and third lines

# Test list context (CPAN ticket #66186)
my @arr;
@arr = <$inner>;
is(scalar(@arr), 2, 'readline: list context: got the right number');
is($arr[0], "Here is some more dummy content\n", 'readline: list context: got the right second line');
is($arr[1], "Here is yet more dummy content.\n", 'readline: list context: got the right third line');

# Make sure slurp mode works as expected
$inner->seek(0, 0);
{
    local $/;
    my $contents = <$inner>;
    is($contents, "Here is some more dummy content\nHere is yet more dummy content.\n", 'readline: slurpy: got full contents');
}

# So we know everything went well...
unlink($temp_file);
