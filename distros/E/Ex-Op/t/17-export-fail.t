#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Tags ();
use EO::TagsX ();
use EO::Twin qw(imp imp_w twin_is fresh);

no strict 'refs';
$EO::Twin::BASE = 'EO::Tags';

{
    @EO::Tags::FAILED = ();
    my $p = fresh();
    my ($err, $warn) = imp_w('EO::Tags', $p, 'risky', 'b1');
    is_deeply( \@EO::Tags::FAILED, [['risky']], 'export_fail is called with the listed names asked for' );
    like( $err, qr/^Can't continue after import errors at /, 'a name it returns fails the import' );
    is( scalar @$warn, 1, '... after one warning' );
    like( $warn->[0], qr/^"risky" is not implemented by the EO::Tags module on this architecture at /,
          '... with Exporter\'s text' );
    ok( !defined &{"${p}::b1"}, '... and nothing is installed' );
}

{
    @EO::Tags::FAILED = ();
    my $p = fresh();
    is( imp('EO::Tags', $p, 'risky2'), undef, 'a name export_fail allows' );
    is( \&{"${p}::risky2"}, \&EO::Tags::risky2, '... is imported' );
}

{
    @EO::Tags::FAILED = ();
    imp('EO::Tags', fresh(), '&risky2');
    is_deeply( \@EO::Tags::FAILED, [['risky2']], 'a & name is checked as the bare name' );
}

{
    package EO::FailNoMethod;
    use Ex::Op;
    our @EXPORT_OK   = qw(x);
    our @EXPORT_FAIL = qw(x);
    sub x { 'x' }
}
{
    my ($err, $warn) = imp_w('EO::FailNoMethod', fresh(), 'x');
    like( $err, qr/^Can't continue after import errors/, 'with no export_fail method every listed name fails' );
    like( $warn->[0], qr/^"x" is not implemented by the EO::FailNoMethod module on this architecture/,
          '... as Exporter\'s default export_fail would have it' );
}

{
    package EO::FailDefault;
    use Ex::Op;
    our @EXPORT      = qw(d);
    our @EXPORT_FAIL = qw(d);
    sub d { 'd' }
    sub export_fail { my $class = shift; () }
}
{
    my $p = fresh();
    is( imp('EO::FailDefault', $p), undef, 'a default export that export_fail allows' );
    ok( defined &{"${p}::d"}, '... is imported' );
}

is_deeply( [Ex::Op::export_fail('Any', qw(a b))], [qw(a b)], 'Ex::Op::export_fail returns its list' );

twin_is( 'a failing name',          'risky' );
twin_is( 'an allowed listed name',  'risky2' );
twin_is( 'both listed names',       'risky', 'risky2' );
twin_is( 'a & failing name',        '&risky' );
twin_is( 'a tag and a failing name', ':both', 'risky' );

done_testing;
