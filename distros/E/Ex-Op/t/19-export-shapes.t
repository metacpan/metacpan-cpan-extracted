#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Twin qw(imp imp_w fresh);

no strict 'refs';
our ($kept_import);

{ package EO::Sig;      use Ex::Op; our @EXPORT_OK = ('$', "foo'bar", 'plain'); sub plain { 'plain' } }
{ package EO::Sig::foo; sub bar { 'fb' } }
{ package EO::Blank;    use Ex::Op; our @EXPORT_OK = ('', 'b1'); $#EXPORT_OK = 3; our @EXPORT_FAIL = ('', 'none'); sub b1 { 'b1' } }
{ package EO::Dflt;     use Ex::Op; our @EXPORT = ('d1'); $#EXPORT = 2; our @EXPORT_OK = (''); sub d1 { 'd1' } }
{ package EO::Swap;     use Ex::Op; our @EXPORT = ('s1'); our @EXPORT_OK = ('s2'); sub s1 { 's1' } sub s2 { 's2' } sub s3 { 's3' } }
{ package EO::Tagged;   use Ex::Op; our @EXPORT_OK = ('t1', 't2'); our %EXPORT_TAGS = (sevenxx => ['t1'], nil => undef, hash => {}); sub t1 { 't1' } sub t2 { 't2' } }
{ package EO::Isa;      use Ex::Op; our @ISA = ('Ex::Op'); our @EXPORT_OK = ('i1'); our @EXPORT_FAIL = ('i1'); sub i1 { 'i1' } }
{ package EO::Hole0;    use Ex::Op; our @EXPORT_OK = ('z1'); our @EXPORT_FAIL; $#EXPORT_FAIL = 0; sub z1 { 'z1' } }
{ package EO::Keeps;    sub import { $main::kept_import++ } use Ex::Op; our @EXPORT = ('k1'); sub k1 { 'k1' } }
{ package EO::XSImp;    BEGIN { *import = \&Ex::Op::import } use Ex::Op; our @EXPORT = ('x1'); sub x1 { 'x1' } }
{ package EO::Stub;     sub import { 1 } BEGIN { undef &import } use Ex::Op; our @EXPORT = ('u1'); sub u1 { 'u1' } }
{ package EO::NoTags2;  use Ex::Op; our @EXPORT_OK = ('nt'); sub nt { 'nt' } }
{ package EO::NoVer;    use Ex::Op; sub VERSION { return } }
{ package EO::Ver;      use Ex::Op; our $VERSION = '2.0'; our @EXPORT = ('v1'); sub v1 { 'v1' } }
{ package EO::TiedItem; sub TIESCALAR { bless {}, shift } sub FETCH { 'd1' } }

{
    my $p = fresh();
    is( imp('EO::Sig', $p, '$'), undef, 'a name that is a sigil alone' );
    is( imp('EO::Sig', $p, "foo'bar"), undef, 'a name with the old package separator' );
    is( &{"${p}::foo::bar"}(), 'fb', '... reaches the sub it names' );
}

{
    my $p = fresh();
    is( imp('EO::Blank', $p, 'b1'), undef, 'an empty name among the exports and the failures' );
    is( &{"${p}::b1"}(), 'b1', '... is passed over' );
    like( (imp_w('EO::Blank', fresh(), ''))[0], qr/^Can't continue after import errors at /, '... and asked for by name it is checked as any name, and fails as one of the failures' );
    tie our $item, 'EO::TiedItem';
    $p = fresh();
    is( eval "package $p; my \$read = \$main::item; EO::Dflt->import(\$main::item); 1" ? undef : $@, undef, 'a tied scalar as an import item, read once already' );
    is( &{"${p}::d1"}(), 'd1', '... is read and imported' );
}

{
    my $p = fresh();
    my ($err) = imp_w('EO::Dflt', $p);
    is( $err, undef, 'holes in @EXPORT on a default import' );
    is( &{"${p}::d1"}(), 'd1', '... are skipped' );
    is( imp('EO::Dflt', fresh(), ''), undef, 'an empty name that is exportable is installed by the short way' );
}

{
    is( imp('EO::Swap', fresh(), 's2'), undef, 'an import builds the cache' );
    @EO::Swap::EXPORT = ('s1', 's3');
    my $p = fresh();
    is( imp('EO::Swap', $p, 's3'), undef, '... and an @EXPORT of a new length rebuilds it' );
    is( &{"${p}::s3"}(), 's3', '... with the new name exportable' );
}

{
    my $p = fresh();
    is( imp('EO::Tagged', $p, ':sevenxx'), undef, 'a seven letter tag that is not DEFAULT' );
    is( &{"${p}::t1"}(), 't1', '... imports its names' );
    my ($err, $warn) = imp_w('EO::Tagged', fresh(), ':nil');
    like( $err, qr/^Can't continue after import errors at /, 'a tag with no value' );
    like( $warn->[0], qr/^"nil" is not defined in %EO::Tagged::EXPORT_TAGS at /, '... is not defined' );
    like( imp('EO::Tagged', fresh(), ':hash'), qr/^Not an ARRAY reference at /, 'a tag that is a hash reference' );
    $p = fresh();
    is( imp('EO::Tagged', $p, "/t1/\n"), undef, 'a pattern with a trailing newline' );
    is( &{"${p}::t1"}(), 't1', '... imports what it matches' );
    like( imp('EO::Tagged', fresh(), '/x'), qr/^"\/x" is not exported by the EO::Tagged module/, 'a slash and one character is a name, not a pattern' );
    like( imp('EO::Tagged', fresh(), '/foo'), qr/^"\/foo" is not exported by the EO::Tagged module/, 'a pattern with no closing slash is a name' );
    like( imp('EO::Tagged', fresh(), "/t1\n"), qr/^"\/t1\n" is not exported by the EO::Tagged module/, 'a newline after anything but a slash makes it a name too' );
    { package EO::Tagged; Ex::Op::export_tags('nil'); }
    ok( (grep { $_ eq 'nil' } @EO::Tagged::EXPORT), 'export_tags takes a tag with no value as a name' );
    like( eval { package EO::Tagged; Ex::Op::export_tags('hash'); 1 } ? '' : $@, qr/^Not an ARRAY reference at /, '... and dies on a hash reference' );
}

{
    my ($err) = imp_w('EO::Isa', fresh(), 'i1');
    like( $err, qr/^Can't continue after import errors at /, 'a package inheriting export_fail from Ex::Op fails its @EXPORT_FAIL names' );
}

{
    my $p = fresh();
    is( imp('EO::Hole0', $p, 'z1'), undef, 'an @EXPORT_FAIL of one hole' );
    is( &{"${p}::z1"}(), 'z1', '... fails nothing' );
}

{
    like( eval { Ex::Op->import('nineninex', 'sixsix'); 1 } ? '' : $@,
          qr/^"nineninex" is not exported by the Ex::Op module\n"sixsix" is not exported by the Ex::Op module\n/,
          'options of the lengths of the real ones are checked in full' );
}

{
    EO::Keeps->import;
    is( $kept_import, 1, 'a package with an import of its own keeps it' );
    ok( !defined &main::k1, '... so nothing is exported through it' );
    EO::XSImp->import;
    ok( defined &main::x1, 'an import that is already the XS one is kept and works' );
    EO::Stub->import;
    ok( defined &main::u1, 'a forward declared import is given the body' );
}

{
    package EO::NoTags2;
    Ex::Op::export_tags('nt');
    main::is_deeply( \@EO::NoTags2::EXPORT, ['nt'], 'export_tags names a non tag with no %EXPORT_TAGS at all' );
}

{
    is( scalar(() = Ex::Op::unimport()), 0, 'unimport with nothing at all does nothing' );
    is( scalar(() = Ex::Op::unimport({})), 0, '... nor with a reference' );
}

{
    Ex::Op::export_to_level('EO::Dflt', 50, 'x', 'd1');
    ok( defined &main::d1, 'export_to_level beyond the stack lands in main' );
    my $p = fresh();
    my $r = eval "package $p; sub lvl1 { Ex::Op::export_to_level('EO::Dflt', 1) } lvl1(); 1";
    ok( $r, 'export_to_level with the level alone' ) or diag $@;
    is( &{"${p}::d1"}(), 'd1', '... exports the defaults to that level' );
    is( eval { Ex::Op::export_to_level('EO::Nowhere', 1); 1 }, 1, 'export_to_level from a package that does not exist exports nothing' );
    is( eval { bless({}, 'EO::Dflt')->import; 1 }, 1, 'import on an object' );
}

{
    is( Ex::Op::require_version(bless({}, 'EO::Ver'), 1), '2.0', 'require_version on an object asks its class' );
    is( Ex::Op::require_version('EO::NoVer', 0), undef, 'a VERSION that returns nothing' );
}

done_testing;
