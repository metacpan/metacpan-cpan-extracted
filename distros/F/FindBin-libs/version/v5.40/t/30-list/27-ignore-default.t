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

use Test::More;

########################################################################
# the default ignore list, "/,/usr", skips /lib and /usr/lib.  an
# ignore entry must be an absolute path: a relative "usr" matches
# nothing.
#
# the search starts from the program's directory, computed once per
# process, so each case runs a child with $0 under /usr/bin.

my @inc_argz    = map { "-I$_" } grep { $_ eq $lib_d } @INC;

my $child_code
= q{BEGIN { $0 = '/usr/bin/perl' } use FindBin::libs ( @ARGV, qw( export=found nofail ) ); say for @found};

my @casez =
(
    {
        name    => 'noignore: /usr/lib found'
      , argz    => [ 'noignore' ]
      , path    => '/usr/lib'
      , expect  => 1
    }
  , {
        name    => 'noignore: /lib found'
      , argz    => [ 'noignore' ]
      , path    => '/lib'
      , expect  => 1
    }
  , {
        name    => 'default: /usr/lib skipped'
      , argz    => []
      , path    => '/usr/lib'
      , expect  => ''
    }
  , {
        name    => 'default: /lib skipped'
      , argz    => []
      , path    => '/lib'
      , expect  => ''
    }
  , {
        name    => 'ignore=/,/usr: /usr/lib skipped'
      , argz    => [ 'ignore=/,/usr' ]
      , path    => '/usr/lib'
      , expect  => ''
    }
  , {
        name    => 'ignore=,usr: relative usr matches nothing, /usr/lib found'
      , argz    => [ 'ignore=,usr' ]
      , path    => '/usr/lib'
      , expect  => 1
    }
);

SKIP:
{
    skip "No /lib and /usr/lib directories on $^O", scalar @casez
    unless -d '/lib' && -d '/usr/lib' && $^O !~ m{ ^ (?: MSWin32 | VMS ) $ }x;

    for my $case ( @casez )
    {
        my ( $name, $argz, $path, $expect )
        = @{ $case }{ qw( name argz path expect ) };

        open my $fh, '-|', $^X, @inc_argz, '-E', $child_code, @$argz
        or die "Cannot run child: $!\n";

        chomp( my @found = readline $fh );

        close $fh;

        my $found   = !! grep { $_ eq $path } @found;

        is $found, !! $expect, "ignore: $name";
    }
}

done_testing;

__END__

=head1 NAME

27-ignore-default.t - the default ignore list skips /lib and /usr/lib

=head1 DESCRIPTION

With C<$0> under F</usr/bin>, the default ignore list "/,/usr" skips
F</lib> and F</usr/lib>, as does C<ignore=/,/usr>; C<noignore> finds
both, and the relative C<ignore=,usr> finds F</usr/lib>.  Skipped
where there is no F</lib> or F</usr/lib>.

=head1 SEE ALSO

L<FindBin::libs>, F<24-ignore.t>
