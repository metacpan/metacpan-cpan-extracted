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

use Cwd                   qw( getcwd );
use File::Basename        qw( basename dirname );
use File::Find            qw( find );
use File::Path            qw( make_path );
use File::Spec::Functions qw( abs2rel catdir catfile );
use File::Temp            qw( tempdir );
use IPC::Open3            qw( open3 );
use Test::More;
use YAML::Tiny;

########################################################################
# the BEGIN block above locates the module's lib from $0, validates
# it, and adds it to @INC.  every test holds the same block.
#
# layouts: each row builds a checkout in a tempdir, writes a probe
# script holding this file's copy of the block, runs it with $^X, and
# checks the first line of output: the number of @INC entries for lib,
# or the die message.  PERL5LIB and PERL5OPT are cleared so that a
# blib from "make test" or "prove -b" does not reach the probe.
#
# consistency: every test file, and the 02-perl_t template, holds an
# identical copy of the block, so testing this copy tests them all.
# the generated groups in t/etc/tests.yaml use _stub_t and Testy.pm.

my $block_re
= qr
{
    ^ \# [ ] test [ ] the [ ] current [ ] module: .*?
    ^ [ ]+ or [ ] unshift [ ] \@INC, [ ] \$lib_d; \n
    \} \n
}xms;

sub lib_block( $path )
{
    open my $fh, '<', $path
    or die "open '$path': $!\n";

    local $/;

    my $text    = readline $fh;

    $text =~ m{ ( $block_re ) }x
    ? $1
    : undef
}

my $block   = lib_block $0
// die "Bogus test: no lib block in '$0'.\n";

my $probe_code
= "use v5.40;\n\n"
. $block
. <<'END_PROBE';

say 'count=', scalar grep { ! ref $_ && rel2abs( $_ ) eq $lib_d } @INC;
END_PROBE

########################################################################
# layouts.  paths are relative to the checkout, "dist"; %DIST% in argz
# is replaced with its absolute path.  the probe is run as
# t/x/probe.t from dist, through the t symlink when it is written
# under version/v1.

my @layout_casez =
(
    {
        name    => 'real lib: added once'
      , dirz    => [ 'lib' ]
      , expect  => qr{ ^ count=1 $ }x
    }
  , {
        name    => 'real lib, -Ilib: not added again'
      , dirz    => [ 'lib' ]
      , argz    => [ '-Ilib' ]
      , expect  => qr{ ^ count=1 $ }x
    }
  , {
        name    => 'real lib, -I absolute lib: not added again'
      , dirz    => [ 'lib' ]
      , argz    => [ '-I%DIST%/lib' ]
      , expect  => qr{ ^ count=1 $ }x
    }
  , {
        name    => 'real lib, -Iblib/lib: not added'
      , dirz    => [ 'lib' ]
      , argz    => [ '-Iblib/lib' ]
      , expect  => qr{ ^ count=0 $ }x
    }
  , {
        name    => 't and lib symlinked into version/v1: accepted'
      , dirz    => [ 'version/v1/lib' ]
      , probe   => 'version/v1/t/x/probe.t'
      , linkz   => [ [ 't', 'version/v1/t' ], [ 'lib', 'version/v1/lib' ] ]
      , expect  => qr{ ^ count=1 $ }x
    }
  , {
        name    => 'lib symlink outside the checkout: dies'
      , dirz    => [ '../elsewhere-lib' ]
      , linkz   => [ [ 'lib', '../elsewhere-lib' ] ]
      , expect  => qr{ ^ Bogus [ ] lib: [ ] symlink [ ] '[^']+/dist/lib' [ ] resolves [ ] to [ ] '[^']+/elsewhere-lib', [ ] expected [ ] '[^']+/dist/lib' [ ] next [ ] to [ ] the [ ] test [ ] directory\. $ }x
    }
  , {
        name    => 'lib symlink to another dir in the checkout: dies'
      , dirz    => [ 'other' ]
      , linkz   => [ [ 'lib', 'other' ] ]
      , expect  => qr{ ^ Bogus [ ] lib: [ ] symlink [ ] '[^']+/dist/lib' [ ] resolves [ ] to [ ] '[^']+/dist/other', [ ] expected [ ] '[^']+/dist/lib' }x
    }
  , {
        name    => 'dangling lib symlink: dies'
      , linkz   => [ [ 'lib', 'nonesuch' ] ]
      , expect  => qr{ ^ Bogus [ ] test [ ] path: [ ] '[^']+/dist/lib' [ ] from [ ] 't/x/probe\.t' [ ] is [ ] not [ ] a [ ] directory\. $ }x
    }
  , {
        name    => 'no lib: dies'
      , expect  => qr{ ^ Bogus [ ] test [ ] path: [ ] '[^']+/dist/lib' [ ] from [ ] 't/x/probe\.t' [ ] is [ ] not [ ] a [ ] directory\. $ }x
    }
  , {
        name    => "no 't' directory: dies"
      , dirz    => [ 'lib' ]
      , probe   => 'tests/x/probe.t'
      , run     => 'tests/x/probe.t'
      , expect  => qr{ ^ Bogus [ ] test [ ] path: [ ] no [ ] 't' [ ] directory [ ] in [ ] 'tests/x/probe\.t'\. $ }x
    }
);

my $start_d = getcwd;

for my $case ( @layout_casez )
{
    my ( $name, $expect ) = @{ $case }{ qw( name expect ) };

    my $dirz    = $case->{ dirz  } // [];
    my $linkz   = $case->{ linkz } // [];
    my $argz    = $case->{ argz  } // [];
    my $probe   = $case->{ probe } // 't/x/probe.t';
    my $run     = $case->{ run   } // 't/x/probe.t';

    my $dist_d  = catdir tempdir( CLEANUP => 1 ), 'dist';
    my $probe_f = catfile $dist_d, $probe;

    make_path map { catdir $dist_d, $_ } @$dirz, dirname $probe;

    open my $fh, '>', $probe_f
    or die "open '$probe_f': $!\n";

    print $fh $probe_code;

    close $fh;

    for( @$linkz )
    {
        my ( $link, $target ) = @$_;

        symlink $target, catfile $dist_d, $link
        or die "symlink '$link' -> '$target': $!\n";
    }

    my @argz    = map { s{%DIST%}{$dist_d}gr } @$argz;

    chdir $dist_d
    or die "chdir '$dist_d': $!\n";

    my $line
    = do
    {
        local $ENV{ PERL5LIB };
        local $ENV{ PERL5OPT };

        delete $ENV{ PERL5LIB };
        delete $ENV{ PERL5OPT };

        my $pid     = open3 my $in, my $out, undef, $^X, @argz, $run;
        my $first   = readline $out;

        waitpid $pid, 0;

        $first // ''
    };

    chdir $start_d
    or die "chdir '$start_d': $!\n";

    chomp $line;

    like $line, $expect, "lib check: $name";
}

########################################################################
# consistency: real *.t files outside the generated groups, and the
# 02-perl_t template, hold the same block as this file.

my $t_d     = catdir dirname( $lib_d ), 't';
my $yaml_f  = catfile $t_d, 'etc', 'tests.yaml';

my $yaml
= YAML::Tiny->read( $yaml_f )
or die "Bogus test: cannot read '$yaml_f': " . YAML::Tiny->errstr . "\n";

my %generated   = map { ( $_ => 1 ) } keys %{ $yaml->[0] };

my @pathz       = ( catfile $t_d, 'bin', 'install-tests.d', '02-perl_t' );

find
(
    sub
    {
        $File::Find::prune = 1
        if -d $_ && $generated{ $_ };

        push @pathz, $File::Find::name
        if m{ \.t $ }x && -f $_ && ! -l $_;
    }
  , $t_d
);

for my $path ( sort @pathz )
{
    my $rel     = abs2rel $path, dirname $t_d;

    is lib_block( $path ), $block, "lib block: $rel";
}

done_testing;

__END__

=head1 NAME

00-lib-check.t - the lib-locating BEGIN block in every test

=head1 DESCRIPTION

Every test starts with the same BEGIN block.  It walks up C<$0> to the
C<t> directory, replaces it with C<lib>, and dies if that is not a
directory.  If C<lib> is a symlink it must resolve to the C<lib> next
to the physical C<t> directory, so code outside the checkout is not
loaded.  It adds C<lib> to C<@INC> unless C<lib> or a C<blib> is
already there.

The layout tests run this file's copy of the block in a probe script
against real, symlinked, outside, dangling, and missing C<lib>
directories.  The consistency tests check that every test file, and
the F<02-perl_t> template, holds an identical copy.

=head1 SEE ALSO

F<t/lib/FindBin/Testy.pm>, which applies the same checks for the
generated test groups.
