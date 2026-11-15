########################################################################
# housekeeping
########################################################################
package Testophile;
use v5.40;

########################################################################
# test the current module: $0 is */t/X/foo.t, the module is in */lib.
#
# lib must exist; if it is a symlink it must resolve to the lib next
# to the physical t directory, code outside the checkout is not
# loaded.  add it to @INC unless it is already there, or a blib is
# ("make test", "prove -b").

my $lib_d;

BEGIN
{
    use Cwd                   qw( abs_path );
    use File::Spec::Functions qw( catdir catpath rel2abs splitdir splitpath );
    use List::Util            qw( first );

    my ( $vol, $dir )   = splitpath rel2abs $0;
    my @dirz            = splitdir $dir;

    pop @dirz
    while @dirz && $dirz[-1] ne 't';

    @dirz
    or die "Bogus test path: no 't' directory in '$0'.\n";

    my $t_d     = catpath $vol, ( catdir @dirz ), '';

    $dirz[-1]   = 'lib';
    $lib_d      = catpath $vol, ( catdir @dirz ), '';

    -d $lib_d
    or die "Bogus test path: '$lib_d' from '$0' is not a directory.\n";

    if( -l $lib_d )
    {
        my ( $t_vol, $t_phys )  = splitpath abs_path( $t_d ), 1;
        my @t_dirz              = splitdir $t_phys;

        $t_dirz[-1] = 'lib';

        my $expect  = catpath $t_vol, ( catdir @t_dirz ), '';
        my $found   = abs_path $lib_d;

        $found eq $expect
        or die "Bogus lib: symlink '$lib_d' resolves to '$found', "
        . "expected '$expect' next to the test directory.\n";
    }

    first
    {
        ! ref $_
        and
        (
            m{ (?: ^ | / ) blib / }x
            or rel2abs( $_ ) eq $lib_d
        )
    }
    @INC
    or unshift @INC, $lib_d;
}

# pass the lib to child processes only if this test added it: with
# "prove -b" or "make test" they inherit blib via PERL5LIB.

my @inc_argz    = map { "-I$_" } grep { $_ eq $lib_d } @INC;

use Cwd                   qw( abs_path );
use Encode                qw( encode );
use File::Spec::Functions qw( catdir catpath splitpath );
use File::Temp            qw( tempdir );
use Test::More;

########################################################################
# driver script printed into each special-char directory.
# 6 output lines: Bin_l, Bin_p, Bin from glob vars, then same via subs.

my $driver_code
= <<'END_DRIVER';
package TestDriver;
use v5.40;
use FindBin::Bin;

no warnings qw( once uninitialized );

print $FindBin::Bin::Bin_l // 'UNDEF_l', "\n";
print $FindBin::Bin::Bin_p // 'UNDEF_p', "\n";
print $FindBin::Bin::Bin   // 'UNDEF',   "\n";

my $can_l = FindBin::Bin->can( 'Bin_l' );
my $can_p = FindBin::Bin->can( 'Bin_p' );
my $can   = FindBin::Bin->can( 'Bin'   );

print( $can_l ? $can_l->() : 'NOSUB_l', "\n" );
print( $can_p ? $can_p->() : 'NOSUB_p', "\n" );
print( $can   ? $can->()   : 'NOSUB',   "\n" );
END_DRIVER

########################################################################

my $tmpdir  = tempdir CLEANUP => 1;
my ( $vol ) = splitpath $tmpdir, 1;

my $run_case = sub( $label, $dir )
{
    SKIP:
    {
        mkdir $dir
        or skip "cannot mkdir '$label': $!", 6;

        my $driver = catpath $vol, catdir( $dir, 'driver.pl' ), '';

        open my $wfh, '>', $driver
        or skip "cannot write driver for '$label': $!", 6;

        print $wfh $driver_code;
        close $wfh;

        my $exp_l = $dir;
        my $exp_p = abs_path $dir;

        open my $rfh, '-|', $^X, @inc_argz, $driver
        or skip "cannot run driver for '$label': $!", 6;

        chomp( my @lines = <$rfh> );
        close $rfh;

        is $lines[0], $exp_l, "\$Bin_l glob: $label";
        is $lines[1], $exp_p, "\$Bin_p glob: $label";
        is $lines[2], $exp_p, "\$Bin  glob: $label";
        is $lines[3], $exp_l, "Bin_l() sub: $label";
        is $lines[4], $exp_p, "Bin_p() sub: $label";
        is $lines[5], $exp_p, "Bin()  sub: $label";
    }
};

########################################################################
# Unicode code points from Latin and Cyrillic ranges, filtered to
# punctuation (P), symbol (S), and separator (Z) categories.
#
# UTF-8 encoding for codepoints above U+007F never produces 0x23 ('#')
# or 0x5C ('\') as a byte -- continuation bytes are always 0x80-0xBF
# and leading bytes for multi-byte sequences are 0xC0-0xFF -- so the
# q#...# quoting in Bin.pm needs no extra escaping for these chars.
#
# encode( 'UTF-8', chr $cp ) produces a byte string.  Passing byte
# strings to catdir/mkdir/open avoids wide-character warnings and
# matches what the kernel stores on disk.

my @codepoints
= grep
  {
      chr( $_ ) =~ /[\p{P}\p{S}\p{Z}]/u
  }
  (
      ( 0x00A0 .. 0x00FF )   # Latin-1 Supplement
    , ( 0x0100 .. 0x017F )   # Latin Extended-A
    , ( 0x0180 .. 0x024F )   # Latin Extended-B
    , ( 0x0400 .. 0x04FF )   # Cyrillic
    , ( 0x0500 .. 0x052F )   # Cyrillic Supplement
  )
;

ok scalar @codepoints > 0
  , "Unicode punct/sym/sep chars found in Latin/Cyrillic ranges";

for my $cp ( @codepoints )
{
    my $utf8  = encode( 'UTF-8', chr $cp );
    my $base  = "foo${utf8}bar";
    my $dir   = catpath $vol, catdir( $tmpdir, $base ), '';

    $run_case->( sprintf( "U+%04X", $cp ), $dir );
}

done_testing;
__END__
