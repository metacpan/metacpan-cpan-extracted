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
use Test::More;

########################################################################
# a $0 under /dev/ is input via a filehandle (perl /dev/stdin, or
# /dev/fd/N from bash process substitution).  like '-' it has no
# program directory: $Bin_l is pwd() and $Bin_p is abs_path( pwd() ).
#
# $Bin* are computed once per process, so each $0 is run in a child
# that sets $0 before FindBin::Bin is loaded.

require_ok 'FindBin::Bin'
or BAIL_OUT 'Failed require FindBin::Bin';

my $expect_l    = FindBin::Bin::pwd();
my $expect_p    = abs_path $expect_l;

my $child_code
= q{BEGIN { $0 = shift } use FindBin::Bin qw( $Bin_l $Bin_p ); say "$Bin_l\n$Bin_p"};

my @casez =
(
    {
        name    => '/dev/stdin'
      , input   => '/dev/stdin'
    }
  , {
        name    => '/dev/fd/N (process substitution)'
      , input   => '/dev/fd/63'
    }
);

for my $case ( @casez )
{
    my ( $name, $input ) = @{ $case }{ qw( name input ) };

    open my $fh, '-|', $^X, @inc_argz, '-E', $child_code, $input
    or die "Cannot run child: $!";

    chomp( my ( $bin_l, $bin_p ) = <$fh> );
    close $fh;

    is $bin_l, $expect_l, "\$0 '$name': \$Bin_l is pwd()";
    is $bin_p, $expect_p, "\$0 '$name': \$Bin_p is abs_path( pwd() )";
}

done_testing;

__END__

=head1 NAME

05d-Bin-dev-path.t - $Bin_l and $Bin_p when $0 is a path under /dev/

=head1 DESCRIPTION

A C<$0> under C</dev/> (C<perl /dev/stdin>, or C</dev/fd/N> from bash
process substitution) is input via a filehandle.  Like C<->, it has no
program directory, so C<$Bin_l> is C<pwd()> and C<$Bin_p> is
C<abs_path( pwd() )>.  Each C<$0> runs in a child process, since the
values are computed once per process.

=head1 SEE ALSO

L<FindBin::Bin>, F<05b-Bin-stdin-path.t>
