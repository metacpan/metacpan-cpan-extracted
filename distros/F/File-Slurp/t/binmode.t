use strict;
use warnings;

use Carp ;
use File::Spec ();
use File::Slurp;
use File::Temp qw(tempfile);
use IO::Handle ();
use Test::More;

BEGIN {
    plan skip_all => 'Older Perl lacking unicode support' if $] < 5.008001;
}

# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;


plan tests => 4;

my $suf = 'utf8';
my $mode = ":$suf";

# euro symbol with \r\n or \n
my $orig_text = "\x{20ac}\n";
my $win_text = "\x{20ac}\015\012";
my $expected_text = $^O eq 'MSWin32' ? $win_text : $orig_text;
my $unicode_length = length $orig_text;

my (undef, $control_file) = tempfile('ctrlXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);
my (undef, $slurp_file) = tempfile('slurpXXXXX', DIR => File::Spec->tmpdir, OPEN => 0);

{ # print to the control file
    open(my $fh, ">$mode", $control_file) or
        die "cannot create control unicode file '$control_file' $!";
    $fh->print($orig_text);
}

my $slurp_utf = read_file( $control_file, binmode => $mode);
is($slurp_utf, $expected_text, "read_file of $mode file");

my $res = write_file($slurp_file, {binmode => $mode}, $orig_text);
ok($res, "write_file: binmode opt");

my $read_length;
{ # read the slurp file
    open(my $fh, "<$mode", $slurp_file) or
        die "cannot open slurp test file '$slurp_file' $!";
    my $read_length = read($fh, my $utf_text, $unicode_length);
    $fh->close();
    is($read_length, $unicode_length, "read lengths match");
    is($utf_text, $orig_text, "write_file of $mode file");
}
unlink($control_file, $slurp_file);
