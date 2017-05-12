use strict;
use IO::File;
use File::Temp 0.16 ();
use Test::More;

if ( $^O ne 'MSWin32' ) {
    plan skip_all => "not MSWin32";
} else {
    require File::Spec;
    File::Spec->VERSION(3.27);
}

( my $wperl = $^X ) =~ s/perl\.exe$/wperl.exe/i;

if ( ! -x $wperl ) {
    plan skip_all => "no wperl.exe found";
}

sub _is_vista {
  require Win32;
  my (undef, $major, $minor, $build, $id) = Win32::GetOSVersion();
  return $id == 2 && $major > 5; # 2 for NT, 6 is 2k/XP/Server 2003
}

#--------------------------------------------------------------------------#
# test scripts
#--------------------------------------------------------------------------#

my @scripts = qw(
    wperl-capture.pl
    wperl-exec.pl
);

plan tests => 2 * @scripts;

#--------------------------------------------------------------------------#
# loop over scripts and pass a filename for output
#--------------------------------------------------------------------------#

for my $pl ( @scripts ) {
  TODO: {
    local $TODO = "wperl.exe can't capture child process output on Vista or Win7"
      if _is_vista() && $pl eq 'wperl-exec.pl';

    my $pl_path = File::Spec->catfile('t', 'scripts', $pl);

    my $outputname = File::Temp->new();
    $outputname->close; # avoid Win32 locking it read-only

    system($wperl, $pl_path, $outputname);

    is( $?, 0, "'$pl' no error");

    my $result = IO::File->new( $outputname );

    is_deeply( 
        [ <$result> ], 
        ["STDOUT\n", "STDERR\n"], 
        "'$pl' capture correct" 
    );
  }
}

