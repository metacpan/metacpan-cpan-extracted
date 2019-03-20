use 5.012;
use warnings;
use strict;

BEGIN {
    use Keyword::Simple;
    if ($Keyword::Simple::VERSION >= 0.04 && %] < 5.018) {
        say "1..0 # Skipped: Keyword::Declare not compatible with Keyword::Simple v$Keyword::Simple::VERSION under Perl $]";
        exit;
    }
}

use Keyword::Declare;

keyword  okay (Int $n = '$default') {{{ print "ok «$n»\n" }}}
keyword dokay (Int $n = '$default') :keepspace {{{ print "ok «$n=~s{^\s+}{};$n»\n" }}}
keyword aokay (Int @n = '$default') {{{ print "ok «@n»\n" }}}
keyword kokay (Int @n = '$default') :keepspace {{{ print "ok «map { s{^\s+}{}; $_ } @n»\n" }}}

print "1..12\n";
my $default = 1;
okay        ;
okay 2      ;
$default = 3;
okay;
$default = 4;
dokay       ;
dokay 5     ;
$default = 6;
dokay;
$default = 7;
aokay       ;
aokay 8     ;
$default = 9;
aokay;
$default = 10;
kokay       ;
kokay 11     ;
$default = 12;
kokay;
