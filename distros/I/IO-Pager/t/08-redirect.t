use strict;
use warnings;
use File::Temp;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

#Disable warnings for awkard test file mechanism required by Windows
my(undef, $tempname) = do{ $^W=0; File::Temp::tempfile(OPEN=>0)};
END{ close(TMP); unlink $tempname or die "Could not unlink '$tempname': $!" }

#Print the heredoc in 08-redirect.pl to temp file via redirection
my $q = q['];
$q = q["] if $^O =~ /MSWin32/;
system qq($^X -Mblib -MIO::Pager::Page -e $q require q[./t/08-redirect.pl]; print \$txt $q >$tempname);

open(TMP, $tempname) or die "Could not open tmpfile: $!\n";
my $slurp = do{ undef $/; <TMP> };

our $txt; require './t/08-redirect.pl';
ok($txt eq $slurp, 'Redirection (IO::Pager::Page)');

done_testing;
