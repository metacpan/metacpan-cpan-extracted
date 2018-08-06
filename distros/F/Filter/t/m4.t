# m4.t

use strict;
use warnings;
use Config;

use FindBin;
use lib "$FindBin::Bin"; # required to load filter-util.pl

BEGIN {
    my $m4;
    my $sep;

    if ($^O eq 'MSWin32') {
        $m4 = 'm4.exe';
        $sep = ';';
    }
    else {
        $m4 = 'm4';
        $sep = ':';
    }
    if (!$m4) {
        print "1..0 # Skipping m4 not found on this system.\n" ;
        exit 0 ;
    }

    # Check whether m4 is installed
    if (!-x $m4) {
        my $foundM4 = 0;
        foreach my $dir (split($sep, $ENV{PATH}), '') {
            if (-x "$dir/$m4") {
                $foundM4 = 1;
                last;
            }
        }
        if (!$foundM4) {
            print "1..0 # Skipping m4 not found on this system.\n" ;
            exit 0;
        }
    }
}

use vars qw($Inc $Perl);

require "filter-util.pl";


# normal module invocation

my $script = <<'EOF';
use Filter::m4;

define(`bar2baz', `$1 =~ s/bar/baz/')

$a = "foobar";
bar2baz(`$a');
print "a = $a\n";
EOF

my $m4_script = 'm4.script';
writeFile($m4_script, $script);

my $expected_output = <<'EOM';
a = foobaz
EOM


# module invocation with argument 'prefix'

my $prefix_script = <<'EOF';
use Filter::m4 'prefix';

m4_define(`bar2baz', `$1 =~ s/bar/baz/')

$a = "foobar";
bar2baz(`$a');
print "a = $a\n";
EOF

my $m4_prefix_script = 'm4_prefix.script';
writeFile($m4_prefix_script, $prefix_script);

my $expected_prefix_output = <<'EOM';
a = foobaz
EOM


print "1..3\n";
ok(1, ($? >>8) == 0);

$a = `$Perl $Inc $m4_script 2>&1`;
ok(2, $a eq $expected_output);

$a = `$Perl $Inc $m4_prefix_script 2>&1`;
ok(3, $a eq $expected_prefix_output);


unlink $m4_script;
unlink $m4_prefix_script;

# EOF
