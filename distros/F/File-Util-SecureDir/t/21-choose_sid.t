########################################################################
# housekeeping
########################################################################
use v5.36;

use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# The Win32 identity chooser: the first source that returns a well
# formed SID wins, a failing source is skipped and reported, and if
# nothing works it dies.  It takes its sources as arguments, so it is
# tested here on every platform with fake sources.

use_ok 'File::Util::SecureDir'
or BAIL_OUT 'File::Util::SecureDir failed to load';

my $choose = do { no warnings 'once'; $File::Util::SecureDir::choose_sid };

is ref $choose, 'CODE', 'choose_sid hook is a coderef'
or BAIL_OUT 'choose_sid hook is missing';

########################################################################
# fixtures: two valid SIDs and sources that fail in different ways
########################################################################

my $make_sid
= sub( @sub )
{
    pack 'C C x4 n V*', 1, scalar @sub, 5, @sub
};

my $sid_a       = $make_sid->( 21, 1, 2, 3 );
my $sid_b       = $make_sid->( 21, 4, 5, 6 );

my $returns_a   = sub { $sid_a };
my $returns_b   = sub { $sid_b };

# collect warnings instead of printing them.

my $run
= sub( @getterz )
{
    my @warnz   = ();
    my $sid;

    {
        local $SIG{ __WARN__ } = sub { push @warnz, @_ };

        $sid = eval { $choose->( @getterz ) };
    }

    ( $sid, \@warnz, $@ )
};

########################################################################
# a working first source is used, quietly
########################################################################

{
    my ( $sid, $warnz ) = $run->( $returns_a, $returns_b );

    is $sid, $sid_a, 'first source valid: its SID is returned';

    is scalar @$warnz, 0, 'first source valid: no warning';
}

{
    my $called = 0;
    my $second = sub { ++$called; $sid_b };

    $run->( $returns_a, $second );

    is $called, 0, 'first source valid: the second is never called';
}

########################################################################
# a failing first source falls back to the second (metadata driven)
########################################################################

my @casez
= (
    {
        name    => 'first source dies'
      , first   => sub { die "boom\n" }
    }
  , {
        name    => 'first source returns undef'
      , first   => sub { undef }
    }
  , {
        name    => 'first source returns an empty string'
      , first   => sub { '' }
    }
  , {
        name    => 'first source returns fewer than 8 bytes'
      , first   => sub { "\x01\x00" }
    }
  , {
        name    => 'first source returns a bad revision'
      , first   => sub { my $bad = $sid_a; substr( $bad, 0, 1 ) = "\x02"; $bad }
    }
  , {
        name    => 'first source returns a length that does not match its count'
      , first   => sub { $sid_a . "\0\0\0\0" }
    }
);

for my $case ( @casez )
{
    my ( $name, $first ) = @{ $case }{ qw( name first ) };

    my ( $sid ) = $run->( $first, $returns_b );

    is $sid, $sid_b, "$name: the second source's SID is returned";
}

########################################################################
# a fallback is never silent
########################################################################

{
    my ( undef, $warnz ) = $run->( sub { die "boom\n" }, $returns_b );

    is scalar @$warnz, 1, 'fallback used: one warning';

    like $warnz->[0], qr{ preferred \s+ source \s+ failed }x
    , 'fallback used: warning says the preferred source failed';

    like $warnz->[0], qr{ \bboom\b }x
    , 'fallback used: warning carries the failure reason';
}

########################################################################
# nothing works
########################################################################

{
    my ( $sid, undef, $err ) = $run->( sub { die "boom\n" }, sub { '' } );

    ok ! defined $sid, 'all sources fail: no SID is returned';

    like $err, qr{ No \s+ usable \s+ process \s+ identity }x
    , 'all sources fail: it dies';

    like $err, qr{ \bboom\b }x
    , 'all sources fail: the first failure is reported';
}

{
    my ( $sid, undef, $err ) = $run->();

    like $err, qr{ No \s+ usable \s+ process \s+ identity }x
    , 'no sources at all: it dies';
}

done_testing;
