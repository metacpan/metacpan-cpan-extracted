#!./perl

## Snarfed from the perl test suite.

#chdir 't' if -d 't';
$Is_MSWin32 = $^O eq 'MSWin32';

$|=1;

undef $/;
@prgs = split "\n########\n", <DATA>;
print "1..", scalar @prgs, "\n";

$tmpfile = "runltmp000";
1 while -f ++$tmpfile;
END { if ($tmpfile) { 1 while unlink $tmpfile; } }

$i=0;
#$inc = join(' ', map {'-I '.$_} @INC);
$inc='-Iblib/arch -Iblib/lib -MException::Cxx ';
for (@prgs){
    my $switch = '';
    if (s/^\s*(-\w+)//){
       $switch = $1;
    }
    my($prog,$expected) = split(/\nEXPECT\n/, $_);
    open TEST, ">$tmpfile";
    print TEST "$prog\n";
    close TEST;
    my $results = ($Is_MSWin32 ?  
		   `.\\$^X $inc $switch $tmpfile 2>&1` :
		   `sh -c '$^X $inc $switch $tmpfile' 2>&1`);
    my $status = $?;
    $results =~ s/\n+$//;
    # allow expected output to be written as if $prog is on STDIN
    $results =~ s/runltmp\d+/-/g;
    $expected =~ s/\n+$//;
    if ($results ne $expected) {
       print STDERR "PROG: $switch\n$prog\n";
       print STDERR "EXPECTED:\n$expected\n";
       print STDERR "GOT:\n$results\n";
       print "not ";
    }
    print "ok ", ++$i, "\n";
}

##
##
## The real tests begin here
##
##

__END__
@a = (1, 2, 3);
{
  @a = sort { last ; } @a;
}
EXPECT
Can't "last" outside a block at - line 3.
########
package TEST;
 
sub TIESCALAR {
  my $foo;
  return bless \$foo;
}
sub FETCH {
  eval 'die("test")';
  print "still in fetch\n";
  return ">$@<";
}
package main;
 
tie $bar, TEST;
print "- $bar\n";
EXPECT
still in fetch
- >test at (eval 1) line 1.
<
########
package TEST;
 
sub TIESCALAR {
  my $foo;
  eval('die("foo\n")');
  print "after eval\n";
  return bless \$foo;
}
sub FETCH {
  return "ZZZ";
}
 
package main;
 
tie $bar, TEST;
print "- $bar\n";
print "OK\n";
EXPECT
after eval
- ZZZ
OK
########
package TEST;
 
sub TIEHANDLE {
  my $foo;
  return bless \$foo;
}
sub PRINT {
print STDERR "PRINT CALLED\n";
(split(/./, 'x'x10000))[0];
eval('die("test\n")');
}
 
package main;
 
open FH, ">&STDOUT";
tie *FH, TEST;
print FH "OK\n";
print STDERR "DONE\n";
EXPECT
PRINT CALLED
DONE
########
sub warnhook {
  print "WARNHOOK\n";
  eval('die("foooo\n")');
}
$SIG{'__WARN__'} = 'warnhook';
warn("dfsds\n");
print "END\n";
EXPECT
WARNHOOK
END
########
package TEST;
 
use overload
     "\"\""   =>  \&str
;
 
sub str {
  eval('die("test\n")');
  return "STR";
}
 
package main;
 
$bar = bless {}, TEST;
print "$bar\n";
print "OK\n";
EXPECT
STR
OK
########
sub foo {
  $a <=> $b unless eval('$a == 0 ? bless undef : ($a <=> $b)');
}
@a = (3, 2, 0, 1);
@a = sort foo @a;
print join(', ', @a)."\n";
EXPECT
0, 1, 2, 3
########
sub foo {
  goto bar if $a == 0 || $b == 0;
  $a <=> $b;
}
@a = (3, 2, 0, 1);
@a = sort foo @a;
print join(', ', @a)."\n";
exit;
bar:
print "bar reached\n";
EXPECT
Can't "goto" outside a block at - line 2.
