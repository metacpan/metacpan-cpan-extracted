#! perl
use strict;
use warnings;
use Config;

use FindBin;
use lib "$FindBin::Bin"; # required to load filter-util.pl

BEGIN {
    my $foundTR = 0 ;
    if ($^O eq 'MSWin32') {
        # Check if tr is installed
        foreach (split ";", $ENV{PATH}) {
            if (-e "$_/tr.exe") {
                $foundTR = 1;
                last ;
            }
        }
    }
    else {
        $foundTR = 1
            if $Config{'tr'} ne '' ;
    }

    if (! $foundTR) {
        print "1..0 # Skipping tr not found on this system.\n" ;
        exit 0 ;
    }
}

require "filter-util.pl" ;

use vars qw( $Inc $Perl $script ) ;

$script = '';
if (eval {
    require POSIX;
    my $val = POSIX::setlocale(&POSIX::LC_CTYPE);
    $val !~ m{^(C|en)}
}) { # CPAN #41285
  $script = q(BEGIN { $ENV{LANG}=$ENV{LC_ALL}=$ENV{LC_CTYPE}='C'; });
}

$script .= <<'EOF' ;

use Filter::exec qw(tr '[A-E][I-M]' '[a-e][i-m]') ;
use Filter::exec qw(tr '[N-Z]' '[n-z]') ;

EOF

$script .= <<'EOF' ;

$A = 2 ;
PRINT "A = $A\N" ;

PRINT "HELLO JOE\N" ;
PRINT <<EOM ;
MARY HAD
A
LITTLE
LAMB
EOM
PRINT "A (AGAIN) = $A\N" ;
EOF

my $filename = "exec$$.test" ;
writeFile($filename, $script) ;

my $expected_output = <<'EOM' ;
a = 2
Hello joe
mary Had
a
little
lamb
a (aGain) = 2
EOM

$a = `$Perl $Inc $filename 2>&1` ;

print "1..3\n";
ok(1, ($? >> 8) == 0) or diag("$Perl $Inc $filename 2>&1", $?);
if ($^O eq 'cygwin' and $a ne $expected_output) {
    ok(2, 1, "TODO $^O");
    diag($a);
} else {
    ok(2, $a eq $expected_output) or diag($a);
}

unlink $filename;

# RT 101668 double free of BUF_NEXT in SvREFCNT_dec(parser->rsfp_filters)
# because we stole BUF_NEXT from IoFMT_NAME.
#
# echo is fairly common on all shells and archs I think.
$a = `echo __DATA__ | $Perl $Inc -MFilter::exec=cat - 2>&1`;
ok(3, ($? >> 8) == 0) or diag($?);

# Note: To debug this case it is easier to put `echo __DATA__` into a data.sh
# `make MPOLLUTE=-DFDEBUG`
# and `gdb --args perl5.22.0d-nt -DP -Mblib -MFilter::exec=sh data.sh`
