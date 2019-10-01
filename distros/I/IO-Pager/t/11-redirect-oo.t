use strict;
use warnings;
use File::Temp;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

#Disable warnings for awkard test file mechanism required by Windows
my(undef, $tempname) = do{ $^W=0; File::Temp::tempfile(OPEN=>0)};
END{ close(TMP); unlink $tempname or die "Could not unlink '$tempname': $!" }

#Print the heredoc in 11-redirect.pl to temp file via redirection
system qq($^X t/11-redirect-oo.pl >$tempname);

open(TMP, $tempname) or die "Could not open tmpfile: $!\n";
my $slurp = do{ undef $/; <TMP> };

TODO:{
  local $TODO = '';

  #Special case for CMD & PowerShell lameness, see diag below
  if( $^O =~ /MSWin32/ ){
    $slurp =~ s/\n\n\z/\n/m;
  }

 SKIP:{
    skip_no_tty();

  our $txt; require './t/08-redirect.pl';
  cmp_ok($txt, 'eq', $slurp, 'Redirection with OO') || $^O =~ /MSWin32/ &&
    diag("If this test fails on Windows and all others pass, things are probably good. CMD appends an extra newline to redirected output.");
  }
}


done_testing;
