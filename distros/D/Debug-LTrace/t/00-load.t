#!perl 
use Test::More tests=>46;
use lib qw#t#;

BEGIN {
    use_ok( 'Debug::LTrace' ) || print "Bail out!
";
}

diag( "Testing Debug::LTrace $Debug::LTrace::VERSION, Perl $], $^X" );

foreach my $m (qw/new import _new _start_trace _dump/) {
   can_ok('Debug::LTrace', $m);
}

*stderr_fh = *STDERR;
open( MEMORY, '>', \my $output_data ) or die $!; 
*STDERR  = *MEMORY;

require Foo;

*STDERR = *{stderr_fh};
my @output_data = split(/\n/, $output_data);

my @output_re = ( 
qr#\QTRACE C: /-FOO::inner(1) called at t/Foo.pm line 11 sub (eval)\E#,
qr#\QTRACE C: | /-FOO::Dumper(1) called at t/Foo.pm line 37 sub FOO::inner\E#,
qr#\QTRACE R: | \E\\\_\QFOO::Dumper(1) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: | /-FOO::inner2(1) called at t/Foo.pm line 38 sub FOO::inner\E#,
qr#\QTRACE R: | \E\\\_\QFOO::inner2(1) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE R: \E\\\_\QFOO::inner(1) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: /-FOO::inner(2) called at t/Foo.pm line 12 sub (eval)\E#,
qr#\QTRACE C: | /-FOO::Dumper(2) called at t/Foo.pm line 37 sub FOO::inner\E#,
qr#\QTRACE R: | \E\\\_\QFOO::Dumper(2) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: | /-FOO::inner2(2) called at t/Foo.pm line 38 sub FOO::inner\E#,
qr#\QTRACE R: | \E\\\_\QFOO::inner2(2) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE R: \E\\\_\QFOO::inner(2) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: /-FOO::out_outer() called at t/Foo.pm line 13 sub (eval)\E#,
qr#\QTRACE C: | /-FOO::outer(2,{'aaa' => {'yyy' => 'ARRAY(\E\S+\Q)','qqq' => 'www'}}) called at t/Foo.pm line 47 sub FOO::out_outer\E#,
qr#\QTRACE C: | | /-FOO::inner(3) called at t/Foo.pm line 30 sub FOO::outer\E#,
qr#\QTRACE C: | | | /-FOO::Dumper(3) called at t/Foo.pm line 37 sub FOO::inner\E#,
qr#\QTRACE R: | | | \E\\\_\QFOO::Dumper(3) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: | | | /-FOO::inner2(3) called at t/Foo.pm line 38 sub FOO::inner\E#,
qr#\QTRACE R: | | | \E\\\_\QFOO::inner2(3) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE R: | | \E\\\_\QFOO::inner(3) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: | | /-FOO::inner2(4) called at t/Foo.pm line 31 sub FOO::outer\E#,
qr#\QTRACE R: | | \E\\\_\QFOO::inner2(4) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE R: | \E\\\_\QFOO::outer(2,{'aaa' => {'yyy' => 'ARRAY(\E\S+\Q)','qqq' => 'www'}}) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: | /-FOO::inner(111) called at t/Foo.pm line 48 sub FOO::out_outer\E#,
qr#\QTRACE C: | | /-FOO::Dumper(111) called at t/Foo.pm line 37 sub FOO::inner\E#,
qr#\QTRACE R: | | \E\\\_\QFOO::Dumper(111) [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: | | /-FOO::inner2(111) called at t/Foo.pm line 38 sub FOO::inner\E#,
qr#\QTRACE R: | | \E\\\_\QFOO::inner2(111) returned: (112) in \E\S+\Q sec\E#,
qr#\QTRACE R: | \E\\\_\QFOO::inner(111) returned: (112) in \E\S+\Q sec\E#,
qr#\QTRACE R: \E\\\_\QFOO::out_outer() [VOID] in \E\S+\Q sec\E#,
qr#\QTRACE C: /-FOO::recurse(1) called at t/Foo.pm line 23 sub (eval)\E#,
qr#\QTRACE C: | /-FOO::recurse(2) called at t/Foo.pm line 56 sub FOO::recurse\E#,
qr#\QTRACE C: | | /-FOO::recurse(3) called at t/Foo.pm line 56 sub FOO::recurse\E#,
qr#\QTRACE C: | | | /-FOO::recurse(4) called at t/Foo.pm line 56 sub FOO::recurse\E#,
qr#\QTRACE C: | | | | /-FOO::recurse(5) called at t/Foo.pm line 56 sub FOO::recurse\E#,
qr#\QTRACE R: | | | | \E\\\_\QFOO::recurse(5) returned: (6) in \E\S+\Q sec\E#,
qr#\QTRACE R: | | | \E\\\_\QFOO::recurse(4) returned: (6) in \E\S+\Q sec\E#,
qr#\QTRACE R: | | \E\\\_\QFOO::recurse(3) returned: (6) in \E\S+\Q sec\E#,
qr#\QTRACE R: | \E\\\_\QFOO::recurse(2) returned: (6) in \E\S+\Q sec\E#,
qr#\QTRACE R: \E\\\_\QFOO::recurse(1) returned: (6) in \E\S+\Q sec\E#
);

foreach my $i (0..$#output_re) {
    like( $output_data[$i], $output_re[$i], "Call Tracing line $i" );    
}
