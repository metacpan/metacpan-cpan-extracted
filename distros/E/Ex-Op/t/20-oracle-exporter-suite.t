#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Oracle;

no strict 'refs';

diag( "Exporter $Exporter::VERSION from $INC{'Exporter.pm'}" );

my $testing = <<'BODY';
our %EXPORT_TAGS = (
    This => [qw(stuff %left)],
    That => [qw(Above the @wailing)],
    tray => [qw(Fasten $seatbelt)],
);
our @EXPORT    = qw(lifejacket is);
our @EXPORT_OK = qw(under &your $seat);
our $VERSION   = '1.05';

sub lifejacket { 'lifejacket' }
sub stuff      { 'stuff' }
sub Above      { 'Above' }
sub the        { 'the' }
sub Fasten     { 'Fasten' }
sub your       { 'your' }
sub under      { 'under' }
our ($seatbelt, $seat, @wailing, %left);
$seatbelt = 'seatbelt';
$seat     = 'seat';
@wailing  = qw(AHHHHHH);
%left     = (left => 'right');
BEGIN { *is = \&Is }
sub Is { 'Is' }

&{"$ISA[0]::export_ok_tags"}();
BODY

my $pkgs = EO::Oracle::build('isa', $testing);
my ($E, $X) = @$pkgs{qw(E X)};

is_deeply( [sort @{"${X}::EXPORT_OK"}], [sort @{"${E}::EXPORT_OK"}], 'export_ok_tags() leaves the same @EXPORT_OK' );

for my $P ($E, $X) {
    for my $meth (qw(import export_to_level require_version export_fail)) {
        ok( $P->can($meth), "$P: a subclass can $meth()" );
    }
    ok( $P->require_version(1.05), "$P: require_version()" );
    ok( !eval { $P->require_version(1.11); 1 } && $@, "$P: require_version() fail" );
    ok( $P->require_version(0), "$P: require_version(0)" );
}

my @cases = (
    [ 'simple import' ],
    [ 'import by symbols', qw($seatbelt &Above stuff @wailing %left) ],
    [ 'import by tags',    qw(:This :tray) ],
    [ 'not exported',      qw(first second) ],
    [ 'deny by !',         qw(!lifejacket) ],
    [ 'import by regex',   '/e/' ],
    [ 'deny by regex',     '!/e/' ],
    [ 'every tag',         qw(:This :That :tray) ],
    [ 'everything',        qw(:DEFAULT :This :That :tray under &your $seat) ],
);
for my $case (@cases) {
    my ($desc, @list) = @$case;
    my $r = EO::Oracle::run($pkgs, @list);
    ok( EO::Oracle::same($r), "same as Exporter: $desc" )
        or diag "Exporter:\n" . EO::Oracle::show($r->{E}) . "Ex::Op:\n" . EO::Oracle::show($r->{X});
}

{
    my $r = EO::Oracle::run($pkgs);
    is( $r->{X}{slots}{is}, q{CODE=PKG+imported}, q{is, an alias made with a glob, is imported} );
}

for my $mod (qw(Exporter Ex::Op)) {
    (my $pkg = "OraZero$mod") =~ s/:://g;
    eval "package $pkg; our \@ISA = ('$mod'); our \$VERSION = 0; 1" or die $@;
    ok( eval { $pkg->require_version(0); 1 }, "$mod: require_version(0) and \$VERSION = 0" );
    eval { $pkg->require_version(10); 1 };
    unlike( $@, qr/\(undef\)/, "$mod: require_version(10) and \$VERSION = 0" );
}

for my $mod (qw(Exporter Ex::Op)) {
    require File::Temp;
    my ($fh, $file) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh <<"SCRIPT";
BEGIN {
    package UV;
    require $mod;
    our \@ISA = ('$mod');
    our \@EXPORT = qw(this \$TODO that);
    package Foo;
    UV->import;
}
1;
SCRIPT
    close $fh;
    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $out = qx{"$^X" -w @inc "$file" 2>&1};
    is( $out, '', "$mod: unused variables can be exported without warning" );
}

{
    my $mt = EO::Oracle::build('isa', <<'BODY');
our @EXPORT_OK = qw(foo);
sub foo { 'This is foo' }
sub bar { 'This is bar' }
BODY
    for my $kind (qw(E X)) {
        my $from = $mt->{$kind};
        my $to = "Ora::MT$kind";
        eval "package $to; ${from}->import('foo'); 1" or die $@;
        is( &{"${to}::foo"}(), 'This is foo', "$kind: imported foo before EXPORT_OK changed" );
        push @{"${from}::EXPORT_OK"}, 'bar';
        eval "package $to; ${from}->import('bar'); 1" or die $@;
        is( &{"${to}::bar"}(), 'This is bar', "$kind: imported bar after EXPORT_OK changed" );
    }
}

{
    package The::Import;
    use Ex::Op 'import';
    ::is( \&import, \&Ex::Op::import, 'imported the import routine' );
    our @EXPORT = qw(wibble);
    sub wibble { 'wobble' }

    package Use::The::Import;
    The::Import->import;
    ::is( eval { wibble() }, 'wobble', 'exported importer worked' );
}

{
    package Exporter::for::Tied::_;
    our @ISA = 'Ex::Op';
    our @EXPORT = 'foo';
    sub foo { 'foo' }

    package Tied::_;
    sub TIESCALAR { bless [] }
    tie my $t, __PACKAGE__;
    for ($t) {
        Exporter::for::Tied::_->import;
    }
    ::ok( defined &Tied::_::foo, 'import with tied $_' );
}

{
    package Ora::Warn;
    Ex::Op->import('import');
    our @EXPORT_OK = qw(bar);

    package main;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, join '', @_ };
    eval { Ora::Warn->import(':quux') };
    ok( grep(/"quux" is not defined/, @warn), 'warnings captured by a custom $SIG{__WARN__}' );
}

done_testing;
