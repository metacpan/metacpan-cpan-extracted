use strict;
use warnings;

use File::Spec ();
use File::Slurp;
use File::Temp qw(tempfile);
use Test::More;

plan(tests => 8);

# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;

my (undef, $tmp) = tempfile('tempXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);

my $short = <<END;
small
file
END

my $long = <<END;
This is a much longer bit of contents
to store in a file.
END

{
    write_file($tmp, $long);
    my $read = read_file($tmp);
    is($read, $long, "read_file: scalar context - long write and read");
}

{
    my @x = read_file($tmp);
    my @y = grep {$_ ne ''} split(/(.*?\n)/, $long);
    while (@x && @y) {
        last unless $x[0] eq $y[0];
        shift @x;
        shift @y;
    }
    ok(@x == @y, "read_file: list context - long read");
    if (@x) {
        is($x[0], $y[0], "read_file: list context - same remaining data");
    }
    else {
        ok(1, "read_file: list context - matched exactly.");
    }
}

{
    append_file($tmp, $short);
    my $read = read_file($tmp);
    is($read, "$long$short", "append_file: got the right long and short");
}

{
    my $iold = (stat($tmp))[1];
    overwrite_file($tmp, $short);
    my $inew = (stat($tmp))[1];
    my $read = read_file($tmp);
    is($read, $short, "overwrite_file: got the right shortened text");
    is($iold, $inew, "overwrite_file: same inode number");
}
unlink($tmp);

{
    overwrite_file($tmp, $long);
    my $read = read_file($tmp);
    is($read, $long, "overwrite_file: no prior data/file");
}
unlink($tmp);

{
    append_file($tmp, $short);
    my $read = read_file($tmp);
    is($read, $short, "append_file: no prior data/file");
}
unlink($tmp);
