#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Twin qw(imp imp_w fresh);

no strict 'refs';

{ package EO::Lvl;    use Ex::Op; our @EXPORT = ('lvl'); sub lvl { 'lvl' } }
{ package EO::Holes;  use Ex::Op; our @EXPORT_OK = ('h1', 'h2'); $#EXPORT_OK = 4; our @EXPORT_FAIL = ('h2'); $#EXPORT_FAIL = 2; sub h1 { 'h1' } sub h2 { 'h2' } }
{ package EO::Odd;    use Ex::Op; our @EXPORT_OK = ('+plus', '*FOO', 'foo-bar'); our $FOO = 'foo'; sub plus { 'plus' } *{'EO::Odd::foo-bar'} = sub { 'fb' }; }
{ package EO::BadTag; use Ex::Op; our @EXPORT_OK = ('bt'); our %EXPORT_TAGS = (bad => 'nope', one => ['bt']); sub bt { 'bt' } }
{ package EO::NoTags; use Ex::Op; our @EXPORT_OK = ('nt'); sub nt { 'nt' } }
{ package EO::OneTag; use Ex::Op; our @EXPORT_OK = ('ot'); our %EXPORT_TAGS = (one => ['ot']); sub ot { 'ot' } }
{ package EO::Sigil;  use Ex::Op; our @EXPORT_OK = ('sg', '$sv'); our @EXPORT_FAIL = ('$sv'); our $sv = 1; sub sg { 'sg' } }
{ package EO::Num;    use Ex::Op; our $VERSION = '1.5'; our @EXPORT = ('num'); sub num { 'num' } }
{ package EO::Empty;  use Ex::Op; our @EXPORT = (''); }

{
    my $p = fresh();
    {
        local $Ex::Op::ExportLevel = 50;
        is( imp('EO::Lvl', $p, 'lvl'), undef, 'an export level beyond the call stack' );
    }
    ok( defined &main::lvl, '... exports into main, where Exporter puts it with no caller to find' );
    ok( !defined &{"${p}::lvl"}, '... and not into the package that asked' );
}

{
    my $p = fresh();
    is( imp('EO::Holes', $p, 'h1'), undef, 'holes in @EXPORT_OK and @EXPORT_FAIL are skipped' );
    is( &{"${p}::h1"}(), 'h1', '... and the name imports' );
    my ($err, $warn) = imp_w('EO::Holes', fresh(), '/h/');
    like( $err, qr/^Can't continue after import errors at /, 'a pattern over the holes finds the name export_fail refuses' );
    like( $warn->[0], qr/^"h2" is not implemented by the EO::Holes module on this architecture at /, '... and says which' );
}

{
    my $p = fresh();
    like( imp('EO::Odd', $p, '+plus'), qr/^Can't export symbol: \+plus at /, 'a name with a sigil that is none of the five dies as under Exporter' );
    is( imp('EO::Odd', $p, '*FOO'), undef, 'a glob whose name starts upper case' );
    is( ${"${p}::FOO"}, 'foo', '... is aliased in full' );
    is( imp('EO::Odd', $p, 'foo-bar'), undef, 'a name with a character no identifier has' );
    is( &{"${p}::foo-bar"}(), 'fb', '... is installed all the same' );
}

{
    like( imp('EO::BadTag', fresh(), ':bad'), qr/^Not an ARRAY reference at /, 'a tag that is not an array reference dies on import' );
    like( eval { package EO::BadTag; Ex::Op::export_tags('bad'); 1 } ? '' : $@, qr/^Not an ARRAY reference at /, '... and in export_tags' );
    is( imp('EO::BadTag', fresh(), ':one'), undef, '... while a proper tag beside it imports' );
}

{
    package EO::NoTags;
    Ex::Op::export_tags();
    main::is_deeply( \@EO::NoTags::EXPORT, [], 'export_tags with no arguments and no %EXPORT_TAGS adds nothing' );
    package EO::OneTag;
    Ex::Op::export_tags();
    main::is_deeply( \@EO::OneTag::EXPORT, ['ot'], 'export_tags with no arguments takes the one tag there is' );
}

{
    my $p = fresh();
    is( imp('EO::Sigil', $p, 'sg'), undef, 'an @EXPORT_FAIL entry with a sigil' );
    is( &{"${p}::sg"}(), 'sg', '... leaves the other names alone' );
    my ($err) = imp_w('EO::Sigil', fresh(), '$sv');
    like( $err, qr/^Can't continue after import errors at /, '... and refuses its own' );
}

{
    my $p = fresh();
    is( imp('EO::Num', $p, 1), undef, 'a version that is a number, not a string' );
    is( &{"${p}::num"}(), 'num', '... checks the version and imports the defaults' );
    like( imp('EO::Num', fresh(), 2), qr/version 2 required/, '... and dies when it is too new' );
}

{
    is( imp('EO::Empty', fresh()), undef, 'an empty name in @EXPORT imports into a fresh package, as under Exporter' );
    like( eval { package main; EO::Empty->import; 1 } ? '' : $@, qr/read-only value/, '... and into main dies as it does under Exporter' );
}

{
    like( eval { Ex::Op->import('bad1', 'bad2'); 1 } ? '' : $@,
          qr/^"bad1" is not exported by the Ex::Op module\n"bad2" is not exported by the Ex::Op module\nCan't continue after import errors at /,
          'two unknown options to Ex::Op are both named' );
    is( scalar(() = Ex::Op::import()), 0, 'Ex::Op::import with nothing at all does nothing' );
}

done_testing;
