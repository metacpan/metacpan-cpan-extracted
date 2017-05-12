# Todd Wylie [Sun Oct 23 11:18:45 CDT 2005]
# $Id: EOL.t 238 2006-10-31 19:08:15Z twylie $

use strict;
use warnings;
use File::Copy;
use Test::More tests => 25;

# SOURCE THE MODULE
use_ok('EOL');

# ----------------------------------------------------------------------
# DOS to UNIX
my $DOS = "t/dracula.DOS.txt";
my $out = "/tmp/dracula.DOS2UNIX.txt";
ok(EOL::eol_new_file(
                     in  => $DOS,
                     out => $out,
                     eol => "LF"
                     ), "DOS to Unix: eol_new_file.") or exit;
my $crlf_i = 0;
my $cr_i   = 0;
my $lf_i   = 0;
open(TEST, "$out") or die "$!";
while(<TEST>) {
    ($_ =~ /\r\n/) ? ($crlf_i++) 
    : ($_ =~ /\r/) ? ($cr_i++  ) 
    : ($_ =~ /\n/) ? ($lf_i++  ) 
    : next;
}
close(TEST);
print "LINES: CRLF:$crlf_i, CR:$cr_i, LF:$lf_i\n";
is($crlf_i, "0",     "Value assessment: CRLF") or exit;
is($cr_i,   "0",     "Value assessment: CR"  ) or exit;
is($lf_i,   "16557", "Value assessment: LF"  ) or exit;

# ----------------------------------------------------------------------
# UNIX TO DOS
my $rollback = "/tmp/dracula.UNIX2DOS.txt";
ok(EOL::eol_new_file(
                     in  => $out,
                     out => $rollback,
                     eol => "CRLF"
                     ), "Unix to DOS: eol_new_file.") or exit;
$out = "/tmp/dracula.UNIX2DOS.txt";
$crlf_i = 0;
$cr_i   = 0;
$lf_i   = 0;
{
    local $/ = "\r\n";
    open(TEST, "$out") or die "$!";
    while(<TEST>) {
        ($_ =~ /\r\n/) ? ($crlf_i++) 
        : ($_ =~ /\r/) ? ($cr_i++  ) 
        : ($_ =~ /\n/) ? ($lf_i++  ) 
        : next;
    }
    close(TEST);
}
print "LINES: CRLF:$crlf_i, CR:$cr_i, LF:$lf_i\n";
is($crlf_i, "16557", "Value assessment: CRLF") or exit;
is($cr_i,   "0",     "Value assessment: CR"  ) or exit;
is($lf_i,   "0",     "Value assessment: LF"  ) or exit;

# ----------------------------------------------------------------------
# DOS TO OLD MAC
$out = "/tmp/dracula.DOS2MAC.txt";
ok(EOL::eol_new_file(
                     in  => $DOS,
                     out => $out,
                     eol => "CR"
                     ), "DOS to old Mac: eol_new_file.") or exit;
$crlf_i = 0;
$cr_i   = 0;
$lf_i   = 0;
{
    local $/ = "\r";
    open(TEST, "$out") or die "$!";
    while(<TEST>) {
        ($_ =~ /\r\n/) ? ($crlf_i++) 
        : ($_ =~ /\r/) ? ($cr_i++  ) 
        : ($_ =~ /\n/) ? ($lf_i++  ) 
        : next;
    }
    close(TEST);
}
print "LINES: CRLF:$crlf_i, CR:$cr_i, LF:$lf_i\n";
is($crlf_i, "0",     "Value assessment: CRLF") or exit;
is($cr_i,   "16557", "Value assessment: CR"  ) or exit;
is($lf_i,   "0",     "Value assessment: LF"  ) or exit;

# ----------------------------------------------------------------------
# OLD MAC TO DOS
$rollback = "/tmp/dracula.MAC2DOS.txt";
ok(EOL::eol_new_file(
                     in  => $out,
                     out => $rollback,
                     eol => "CRLF"
                     ), "old Mac to DOS: eol_new_file.") or exit;
$crlf_i = 0;
$cr_i   = 0;
$lf_i   = 0;
{
    local $/ = "\r\n";
    open(TEST, "$rollback") or die "$!";
    while(<TEST>) {
        ($_ =~ /\r\n/) ? ($crlf_i++) 
        : ($_ =~ /\r/) ? ($cr_i++  ) 
        : ($_ =~ /\n/) ? ($lf_i++  ) 
        : next;
    }
    close(TEST);
}
print "LINES: CRLF:$crlf_i, CR:$cr_i, LF:$lf_i\n";
is($crlf_i, "16557", "Value assessment: CRLF") or exit;
is($cr_i,   "0",     "Value assessment: CR"  ) or exit;
is($lf_i,   "0",     "Value assessment: LF"  ) or exit;

# ----------------------------------------------------------------------

# IN-PLACE-EDIT
# With backup...
copy($DOS, "/tmp/dracula.txt") or die "$!\n";
($DOS) = $ARGV[0] = "/tmp/dracula.txt";
ok(EOL::eol_same_file(
                      in     => $DOS,
                      eol    => "LF",
                      backup => ".bak"
                      ), "DOS to Unix: eol_same_file.") or exit;
ok(-f "/tmp/dracula.txt.bak", "Backup file check.") or exit;

# ----------------------------------------------------------------------

# RETURN ARRAY ROUTINE
ok(my $aref = EOL::eol_return_array(
                                    in  => $DOS,
                                    eol => "LF",
                                    ), "Dos to Unix: eol_return_array.") or exit;
is(ref($aref), "ARRAY", "Array ref tested.") or exit;
my $entries = @{$aref};
is($entries, "33114", "Testing number of array entries in memory.") or exit;
$crlf_i = 0;
$cr_i   = 0;
$lf_i   = 0;
foreach my $line (@{$aref}) {
    ($line =~ /\r\n/) ? ($crlf_i++) 
    : ($line =~ /\r/) ? ($cr_i++  ) 
    : ($line =~ /\n/) ? ($lf_i++  ) 
    : next;
}
print "LINES: CRLF:$crlf_i, CR:$cr_i, LF:$lf_i\n";
is($crlf_i, "0",     "Value assessment: CRLF") or exit;
is($cr_i,   "0",     "Value assessment: CR"  ) or exit;
is($lf_i,   "16557", "Value assessment: LF"  ) or exit;

# ----------------------------------------------------------------------

__END__
