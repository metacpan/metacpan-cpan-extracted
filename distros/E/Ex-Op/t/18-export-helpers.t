#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Basic ();
use EO::BasicX ();
use EO::Twin qw(imp imp_w twin_is fresh);

no strict 'refs';

{
    package EO::H1;
    our @EXPORT;
    our @EXPORT_OK;
    our %EXPORT_TAGS = (t1 => [qw(a b)], t2 => [qw(c)]);
    Ex::Op::export_tags('t1');
    Ex::Op::export_ok_tags('t2');
}
is_deeply( \@EO::H1::EXPORT,    [qw(a b)], 'export_tags pushes a tag onto @EXPORT' );
is_deeply( \@EO::H1::EXPORT_OK, [qw(c)],   'export_ok_tags pushes a tag onto @EXPORT_OK' );

{
    package EO::H2;
    our @EXPORT_OK;
    our %EXPORT_TAGS = (t1 => [qw(a)], t2 => [qw(b)]);
    Ex::Op::export_ok_tags();
}
is_deeply( [sort @EO::H2::EXPORT_OK], [qw(a b)], 'no arguments pushes every tag' );

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    {
        package EO::H3;
        our @EXPORT;
        our %EXPORT_TAGS = (t1 => [qw(a)]);
        Ex::Op::export_tags('t1', 'nope', 'zip');
    }
    is_deeply( \@EO::H3::EXPORT, [qw(a nope zip)], 'a name that is not a tag is pushed as it is' );
    is( scalar @warn, 0, '... quietly without -w' );
    {
        local $^W = 1;
        package EO::H4;
        our @EXPORT;
        our %EXPORT_TAGS = ();
        Ex::Op::export_tags('nope', 'zip');
    }
    like( $warn[0], qr/^nope, zip are not tags of EO::H4 at /, '... and with a warning under -w' );
}

{
    package EO::Ver;
    our $VERSION = '2.5';
    our @ISA = ('Ex::Op');
}
is( EO::Ver->require_version('2'), '2.5', 'require_version returns the version' );
ok( !eval { EO::Ver->require_version('3'); 1 }, 'require_version croaks when too low' );
like( $@, qr/^EO::Ver version 3 required--this is only version 2\.5/, '... with VERSION\'s message' );
is( Ex::Op::require_version(bless({}, 'EO::Ver'), '1'), '2.5', '... and takes an object' );

{
    local $Ex::Op::Verbose = 1;
    local $Exporter::Verbose   = 1;
    twin_is( 'verbose, a name',          'g' );
    twin_is( 'verbose, nothing asked' );
}
{
    local $Ex::Op::Verbose = 1;
    my ($err, $warn) = imp_w('EO::Basic', fresh(), 'g', '$s');
    like( $warn->[-1], qr/^Importing into EO::T\d+ from EO::Basic: \$s, g at /, 'verbose names the import, sorted' );
}

{
    $EO::Twin::BASE = 'EO::Tags';
    require EO::Tags;
    require EO::TagsX;
    local $Ex::Op::Verbose = 1;
    local $Exporter::Verbose   = 1;
    twin_is( 'verbose, a tag and a negation', ':both', '!b1', '/^is_/' );
}

done_testing;
