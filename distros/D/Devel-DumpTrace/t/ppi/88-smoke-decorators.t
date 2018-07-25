use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 29;
  } else {
    plan skip_all => "PPI not available";
  }
}
use strict;
use warnings;

# check output of Devel::DumpTrace module, compare with reference output.
# run code that uses a core module, and see if we are doing what
# we are supposed to about tracing through that core module

my $dmodule = "-d:DumpTrace::PPI";

open T, '>', "$0.pl";
print T <<'EO_T;';

# test program for t/ppi/88-smoke.t
# that contains a C-style for loop,
# a while loop, an until loop, and a
# complex if-elsif-else block.
for (my $i=1; $i<5; $i++) {
    $j += 2 * $i - 1;
    if ($i < 2) {
	$k += $j;
	$j = 0;
    } elsif ($i > 3) {
        $j = 0;
	do {
	   $k += 2 * $j;
	   $j++;
        } until $k > $j;
    } elsif ($i == 2) {
	until ($j > 50) {
	    $k -= $j;
	    $j *= 2;
            $j++ if $j == 0;
	}
        $t = $i * $j * $k;
    } else {
	while ($j > 0) {
	    $k += sqrt($j);
	    $j = $j / 2 - 1;
	}
        $t = $i + $j + $k;
    }
}
$u = $j - $k;

EO_T;





my $level = 3;
my $file = "$0.out.$level";
$ENV{DUMPTRACE_FH} = $file;
$ENV{DUMPTRACE_LEVEL} = $level;

my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib", "$0.pl");

my $keep = $ENV{KEEP} || 0;

ok($c1 == 0, "ran level $level") or $keep++;

open XH, '<', $file;
my @xh = <XH>; 
close XH;

# tests:
#   C-style for loops:
#     for loop statement appears only on first iteration
#     on other iterations, there are lines matching
#          FOR-UPDATE: {.*} FOR-COND: {.*}
#     the FOR-UPDATE ... lines have file/line information
#     the lines _after_ FOR-UPDATE ... do not have file/line information
#     condition statement for last iteration is observed
#
#   while/until loops
#     while / until keyword appears only on first iteration
#     on other iterations, there are lines matching
#         WHILE:\s*(.*)  or   UNTIL:\s*(.*)
#     WHILE:/UNTIL: lines have file/line information
#     lines _after_ WHILE:/UNTIL: ... do not have file/line information
#     condition statement for last iteration observed
#
#   if/elsif/else blocks
#     line with if keyword has file/line info
#     line after if keyword has file/line info
#     line with ELSEIF has a condition clause
#     line with ELSE or ELSIF either
#         has file/line info, or
#         is preceded by an ELSIF line
#     ELSE/ELSIF line with file/line info is preceded by an if line
#
#   do/while do/until
#     line with DO-UNTIL/DO-WHILE does not have file and line information
#     line before DO-UNTIL/DO-WHILE has file line info
#     first iteration, line says "do {"
#         appears before all other DO-UNTIL/DO-WHILE statements

my $FILELINE_INFO = qr/$0.pl:\d+:/;


############### C-style for loops ################

my @for_lines = grep {
  $xh[$_] =~ /for(each)?\s*\(.*;.*;.*\)\s*\{/
} 0 .. $#xh;
my @for_upds = grep {
  $xh[$_] =~ /FOR-UPDATE:\s*\{.*\}\s*FOR-COND:\s*\{.*\}/
} 0 .. $#xh;
my @for_cond = grep {
  $xh[$_] =~ /\s*FOR-COND:\s*\{.*\}/
} 0 .. $#xh;

ok(@for_lines == 1,
   "source for (...;...;...) statement appears only once")
  or $keep++;
ok(@for_upds > 1,
   "for loop decorators appear and appear more than once")
  or $keep++;
ok($for_lines[0] < $for_upds[0],
   "keyword for appears first, before decorators")
  or $keep++;
ok($xh[$for_upds[0]] =~ $FILELINE_INFO &&
   $xh[$for_upds[-1]] =~ $FILELINE_INFO,
   "for loop decorators have file and line information")
  or $keep++;
ok($xh[1+$for_upds[0]] !~ $FILELINE_INFO
   && $xh[1+$for_upds[-1]] !~ $FILELINE_INFO,
   "lines following for loop decoratorrs do not have file/line info")
    or $keep++;
ok(@for_cond == @for_upds + 1,
   "single FOR-COND without FOR-UPDATE found") or $keep++;
ok(" @for_upds " !~ / $for_cond[-1] / && $xh[$for_cond[-1]] !~ /FOR-UPD/,
   "final FOR-COND exits the loop") or do { $keep++; diag $xh[$for_cond[-1]] };

################# while/until loops ##################

my @until_lines = grep {
  $xh[$_] =~ /until\s*\(/
} 0 .. $#xh;
my @until_upds = grep {
  $xh[$_] =~ /\bUNTIL:\s*\(.*\)/
} 0 .. $#xh;

ok(@until_lines == 1,
   "keyword until appears once, at first iteration")
  or $keep++;
ok(@until_upds > 0,
   "until decorators appear")
  or $keep++;
ok($until_lines[0] < $until_upds[0],
   "keyword until appears before until decorators")
  or $keep++;
ok($xh[$until_upds[0]] =~ $FILELINE_INFO
   && $xh[$until_upds[-1]] =~ $FILELINE_INFO,
   "until decorators have file and line information")
  or $keep++;
ok($xh[1+$until_upds[0]] !~ $FILELINE_INFO
   && $xh[1+$until_upds[-1]] !~ $FILELINE_INFO,
   "lines after until decorators do not have file/line info")
    or $keep++;
my @un_lines = map { /:(\d+):/ } @xh[@until_upds];
ok(@un_lines > 1 && $un_lines[-1] > $un_lines[-2],
   "separate until decorator for exiting the loop") or $keep++;

my @while_lines = grep {
  $xh[$_] =~ /while\s*\(/
} 0 .. $#xh;
my @while_upds = grep {
  $xh[$_] =~ /WHILE:\s*\(.*\)/
} 0 .. $#xh;

ok(@while_lines == 1,
   "keyword while appears once, at first iteration")
  or $keep++;
ok(@while_upds > 0,
   "while decorators appear")
  or $keep++;
ok($while_lines[0] < $while_upds[0],
   "keyword while appears before while decorators")
  or $keep++;
ok($xh[$while_upds[0]] =~ $FILELINE_INFO
   && $xh[$while_upds[-1]] =~ $FILELINE_INFO,
   "while decorators have file and line information")
  or $keep++;
ok($xh[1+$while_upds[0]] !~ $FILELINE_INFO
   && $xh[1+$while_upds[-1]] !~ $FILELINE_INFO,
   "lines after while decorators do not have file/line info")
    or $keep++;
my @wh_lines = map { /:(\d+):/ } @xh[@while_upds];
ok(@wh_lines > 1 && $wh_lines[-1] > $wh_lines[-2],
   "separate while decorator for exiting the loop") or $keep++;

######################## if-elsif-else #######################

my @if = grep { $xh[$_] =~ /\s*if\s*\(/ } 0 .. $#xh;
my @if_with_fileline_info = grep { $xh[$_] =~ $FILELINE_INFO } @if;
my @after_if_with_fileline_info = grep { $xh[1+$_] =~ $FILELINE_INFO } @if;
my @elseif = grep { $xh[$_] =~ /ELSEIF/ } 0 .. $#xh;
my @elseif_with_condition = grep { $xh[$_] =~ /ELSEIF\s*\(.*\)/ } @elseif;
my @else_and_elseif = grep {
  $xh[$_] =~ /ELSEIF/ || $xh[$_] =~ /ELSE/
} 0 .. $#xh;
my @else_and_elseif_with_fileline_info = grep {
  $xh[$_] =~ $FILELINE_INFO
} @else_and_elseif;
my @else_and_elseif_preceded_by_elseif = grep {
  $xh[$_ - 1] =~ /ELSEIF/
} @else_and_elseif;
my @else_and_elseif_with_fileline_info_preceded_by_if = grep {
  $xh[$_ - 1] =~ /if\s*\(/;
} @else_and_elseif_with_fileline_info;

ok(@if == @if_with_fileline_info,
   "if line always has file and line information")
  or $keep++;
ok(@if == @after_if_with_fileline_info,
   "line after if always has file and line information")
  or $keep++;
ok(@elseif == @elseif_with_condition,
   "ELSEIF line contains condition clause")
  or $keep++;
ok(@else_and_elseif == @else_and_elseif_with_fileline_info +
                       @else_and_elseif_preceded_by_elseif,
   "ELSEIF/ELSE either has file/line info, or follows an earlier ELSEIF")
  or $keep++;
ok(@else_and_elseif_with_fileline_info ==
   @else_and_elseif_with_fileline_info_preceded_by_if,
   "ELSEIF/ELSE with file/line info always preceded by if (...)")
  or $keep++;

################# do-while / do-until ####################

my @do_whileuntil_lines = grep {
  $xh[$_] =~ /DO-[A-Z]{5}/
} 0..$#xh;
my @do_whileuntil_lines_with_fileinfo = grep {
    $xh[$_] =~ /$0.pl:\d+:/
} @do_whileuntil_lines;
my @precede_dowhile_lines_with_fileinfo = grep {
    $xh[$_ - 1] =~ /$0.pl:\d+:/
} @do_whileuntil_lines;

my @do = grep { $xh[$_] =~ /do\s*\{/ } 0 .. $#xh;

ok(@do_whileuntil_lines > 0,
   "output has DO-WHILE/DO-UNTIL decorators") or $keep++;
ok(@do_whileuntil_lines_with_fileinfo == 0,
   "lines with DO-WHILE/DO-UNTIL do not have file & line info")
   or $keep++;
ok(@precede_dowhile_lines_with_fileinfo == @do_whileuntil_lines,
   "lines that precede DO-WHILE/DO-UNTIL have file & line info")
   or $keep++;
ok(@do == 1 && $do[0] < $do_whileuntil_lines[0],
   "'do' statement appears first")
  or $keep++;


unlink "$0.pl", $file unless $keep;
