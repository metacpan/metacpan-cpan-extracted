use strict;
use Test::More tests=>7;
use FindBin qw( $Bin );

use_ok('File::SmartTail');
use_ok('File::SmartTail::Logger');

my $testfile = "simple.data";

END {
    unlink $testfile;
    ok( !-f $testfile, "Test file removed" );
}

open( TST, ">$testfile" ) || die "Unable to open $testfile [$!]";
print TST "Line 1\nLine 2\nLine 3\n";
close(TST);

SKIP: {
    eval {require NDBM_File};
    skip "NDBM_File unavailable", 8 if $@;

    my $bindir = "$Bin/../";
    my $rmtenv = "PERL5LIB=${bindir}lib";
    my $tail = new File::SmartTail( -bindir => $bindir, -tietype => 'NDBM_File');
    my $host = `hostname`;
    chomp($host);

    foreach my $ssh ('ssh -o BatchMode=yes -o NoHostAuthenticationForLocalhost=yes' ) {
      SKIP:
        {
            diag("Testing to see if $ssh is enabled on $host");
            skip "$ssh is disabled on $host", 4 if system("$ssh $host ls > /dev/null") != 0;
            $tail->WatchFile(
                -file            => $testfile,
                -request_timeout => 1,
                -reset           => 1,
                -type            => "UNIX-REMOTE",
                -rmtsh           => $ssh,
                -rmtenv          => $rmtenv,
                -host            => $host
              );
              #|| next;
            my $i = 1;
            while ( my $line = $tail->GetLine() ) {
                my ( $host, $file, $content ) = split( /:/, $line );
                last if $content =~ /^_timeout_/;
                chomp($content);
                ok( $content eq "Line $i", "Line Matches" );
                $i++;
            }
        }
    }
}
