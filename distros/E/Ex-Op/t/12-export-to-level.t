#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Basic ();
use EO::Twin qw(fresh);

no strict 'refs';

Ex::Op::export('EO::Basic', 'EO::Q1', 'g');
is( \&EO::Q1::g, \&EO::Basic::g, 'export into a named package' );

Ex::Op::export('EO::Basic', 'EO::Q2');
is( \&EO::Q2::f, \&EO::Basic::f, 'export with no list is @EXPORT' );

{
    package EO::Lvl;
    sub import  { my $class = shift; Ex::Op::export_to_level('EO::Basic', 1, $class, @_) }
    sub import0 { my $class = shift; Ex::Op::export_to_level('EO::Basic', 0, $class, @_) }
    sub inner   { my $class = shift; Ex::Op::export_to_level('EO::Basic', 2, $class, @_) }
    sub outer   { inner(@_) }
}

eval q{ package EO::L1; EO::Lvl->import('g'); 1 } or die $@;
ok( defined &EO::L1::g, 'export_to_level 1 reaches the caller of import' );
ok( !defined &EO::Lvl::g, '... not the package calling export_to_level' );

eval q{ package EO::L0; EO::Lvl::import0('EO::Lvl', 'g'); 1 } or die $@;
ok( defined &EO::Lvl::g, 'export_to_level 0 is the package that called it' );

eval q{ package EO::L2; EO::Lvl::outer('EO::Lvl', 'f2'); 1 } or die $@;
ok( defined &EO::L2::f2, 'export_to_level 2 goes two frames up' );

{
    local $@;
    my $ok = eval qq{package EO::L3;\n#line 50 "lvl.pl"\nBEGIN { EO::Lvl->import('nope') }\n1};
    ok( !$ok, 'a bad name through export_to_level' );
    like( $@, qr/^"nope" is not exported by the EO::Basic module\nCan't continue after import errors at lvl\.pl line 50\.\n/,
          '... is reported where the import came from' );
}

{
    package EO::OwnExport;
    our @ISA = ('EO::Basic');
    our @CALLED;
    sub export { my $class = shift; push @CALLED, [@_]; Ex::Op::export('EO::Basic', @_) }
    sub import { my $class = shift; Ex::Op::export_to_level($class, 1, $class, @_) }
}
eval q{ package EO::L4; EO::OwnExport->import('g'); 1 } or die $@;
is_deeply( \@EO::OwnExport::CALLED, [['EO::L4', 'g']], 'export_to_level calls a package\'s own export' );
ok( defined &EO::L4::g, '... which did the work' );

{
    package EO::IsaLvl;
    our @ISA       = ('Ex::Op');
    our @EXPORT_OK = ('h1');
    sub h1 { 'h1' }
    sub import { my $class = shift; $class->export_to_level(1, $class, @_) }
}
eval q{ package EO::L5; EO::IsaLvl->import('h1'); 1 } or die $@;
is( \&EO::L5::h1, \&EO::IsaLvl::h1, 'the method form through @ISA' );

EO::IsaLvl->export('EO::L6', 'h1');
is( \&EO::L6::h1, \&EO::IsaLvl::h1, 'export as a method' );

done_testing;
