use strict;
use warnings;
use Test::More tests => 5;
use Path::Class::Dir;
use Class::Load;
use Try::Tiny;

use_ok('Dezi::Test::Indexer');

my $num_tests = 4;

SKIP: {

    my @required = qw(
        Mail::Box
        Dezi::Aggregator::Mail
    );
    for my $cls (@required) {
        diag("Checking on $cls");
        my $missing;
        my $loaded = try {
            Class::Load::load_class($cls);
        }
        catch {
            warn $_;
            if ( $_ =~ m/Can't locate (\S+)/ ) {
                $missing = $1;
                $missing =~ s/\//::/g;
                $missing =~ s/\.pm//;
            }
            return 0;
        };
        if ( !$loaded ) {
            if ($missing) {
                diag( '-' x 40 );
                diag("Do you need to install $missing ?");
                diag( '-' x 40 );
            }
            skip "$cls required for spider test", $num_tests;
            last;
        }
    }

    # is executable present?
    my $indexer = Dezi::Test::Indexer->new( 'invindex' => 't/mail.index' );

    # maildir requires these dirs but makemaker won't package them
    my @dirs;
    for my $dirname (qw( cur tmp new )) {
        my $dir = Path::Class::Dir->new( 't', 'maildir', $dirname );
        $dir->mkpath;
        push( @dirs, $dir );
    }

    ok( my $mail = Dezi::Aggregator::Mail->new(
            indexer => $indexer,
            verbose => $ENV{DEZI_DEBUG},
        ),
        "new mail aggregator"
    );

    ok( $mail->indexer->start, "start" );
    is( $mail->crawl('t/maildir'), 1, "crawl" );
    ok( $mail->indexer->finish, "finish" );

    # clean up
    for my $dir (@dirs) {
        $dir->remove();
    }

}
