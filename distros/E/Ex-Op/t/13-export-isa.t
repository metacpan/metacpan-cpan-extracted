#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Basic ();
use EO::Twin qw(imp fresh);

no strict 'refs';

{
    package EO::Inh;
    BEGIN { require Ex::Op; our @ISA = ('Ex::Op') }
    our @EXPORT_OK = ('x');
    sub x { 'x' }
}
{
    my $p = fresh();
    is( imp('EO::Inh', $p, 'x'), undef, 'inheriting from Ex::Op' );
    is( \&{"${p}::x"}, \&EO::Inh::x, '... exports' );
    ok( !defined &EO::Inh::import, '... with no import of its own' );
}

{
    package EO::Sub;
    our @ISA       = ('EO::Basic');
    our @EXPORT    = ('s1');
    our @EXPORT_OK = ('s2');
    sub s1 { 's1' }
    sub s2 { 's2' }
}
{
    my $p = fresh();
    is( imp('EO::Sub', $p), undef, 'a subclass of an exporter' );
    is( \&{"${p}::s1"}, \&EO::Sub::s1, '... exports its own @EXPORT' );
    ok( !defined &{"${p}::f"}, '... not its parent\'s' );
    like( imp('EO::Sub', fresh(), 'g'), qr/^"g" is not exported by the EO::Sub module/,
          '... and checks its own lists' );
}

{
    package EO::Own;
    BEGIN { *EO::Own::import = sub { 'mine' } }
    use Ex::Op;
}
is( EO::Own->import, 'mine', 'a package with its own import keeps it' );

{
    package EO::NoImp;
    use Ex::Op qw(-noimport);
}
ok( !defined &EO::NoImp::import, '-noimport installs no import' );

{
    package EO::Empty;
    use Ex::Op ();
}
ok( !defined &EO::Empty::import, 'use Ex::Op () installs nothing' );

is( imp('Ex::Op', fresh()), undef, 'Ex::Op->import from a plain package' );

done_testing;
