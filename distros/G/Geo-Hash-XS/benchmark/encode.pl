use strict;
use Geo::Hash ;
use Geo::Hash::XS;
use Benchmark qw(:all);

my $lat   = 50;
my $lon   = 30;
my $gh_pp = Geo::Hash->new();
my $gh_xs = Geo::Hash::XS->new();


print "Geo::Hash: $Geo::Hash::VERSION\n",
    "Geo::Hash::XS: $Geo::Hash::XS::VERSION\n\n";

for my $p (0, 5, 10, 20, 30) {
    my @args = ($lat, $lon);
    if ($p != 0) {
        push @args, $p;
        print STDERR "precision = $p...\n";
    } else {
        print STDERR "precision = auto...\n";
    }
    cmpthese( -2, {
        perl => sub {
            my $hash = $gh_pp->encode( @args );
        },
        xs => sub {
            my $hash = $gh_xs->encode( @args );
        }
    });
    print "\n\n";
}