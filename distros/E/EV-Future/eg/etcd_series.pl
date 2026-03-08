use strict;
use warnings;
use EV;
use EV::Future;
use EV::Etcd;
use feature 'say';

# Initialize Etcd client
# Note: Ensure etcd is running on localhost:2379
my $etcd = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my @steps = (
    { key => '/config/step1', val => 'init' },
    { key => '/config/step2', val => 'processing' },
    { key => '/config/step3', val => 'complete' },
);

say "Performing sequential etcd operations...";

series([
    map {
        my $step = $_;
        sub {
            my $done = shift;
            say "  Putting $step->{key}...";
            $etcd->put($step->{key}, $step->{val}, sub {
                my ($resp, $err) = @_;
                if ($err) {
                    warn "    Error putting $step->{key}: $err->{message}";
                } else {
                    say "    Success (rev $resp->{header}{revision})";
                }
                $done->();
            });
        }
    } @steps
], sub {
    say "All sequential PUTs finished.";

    say "Verifying state sequentially...";
    series([
        map {
            my $step = $_;
            sub {
                my $done = shift;
                $etcd->get($step->{key}, sub {
                    my ($resp, $err) = @_;
                    if ($err) {
                        warn "    Error getting $step->{key}: $err->{message}";
                    } else {
                        my $val = $resp->{kvs}[0]{value};
                        say "    Checked $step->{key}: $val";
                    }
                    $done->();
                });
            }
        } @steps
    ], sub {
        say "Verification complete.";
        EV::break;
    });
});

EV::run;
