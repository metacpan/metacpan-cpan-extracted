package Graph::Undirected::Hamiltonicity::Wolfram;

use Modern::Perl;
use Carp;
use Config::INI::Reader;
use LWP::UserAgent;

use Exporter qw(import);

our @EXPORT_OK = qw(&is_hamiltonian_per_wolfram
    &get_url_from_config);
our @EXPORT = qw(&is_hamiltonian_per_wolfram);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

##############################################################################

sub is_hamiltonian_per_wolfram {
    my ($g) = @_;

    ### Cover up limitations of Wolfram Language script
    my $vertices = $g->vertices();
    return 0 if $vertices == 0;
    return 1 if $vertices == 1;
    foreach my $vertex ( $g->vertices() ) {
        return 0 if $g->degree($vertex) < 2;
    }

    ### Create a user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("HamiltonCycleFinder/0.1 ");

    my $url = get_url_from_config();

    ### Create a request
    my $req = HTTP::Request->new( POST => $url );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("x=" . $g->stringify() );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ( $res->is_success ) {
        my $output = $res->content;
        return $output;
    } else {
        my $message = "ERROR:" . $res->status_line;
        croak $message;
    }

}

##############################################################################

sub get_url_from_config {
    my $file = $ENV{HOME} . '/hamilton.ini';
    return unless ( -e $file && -f _ && -r _ );

    my $hash;
    eval { 
        $hash = Config::INI::Reader->read_file($file);
    };
    if ( $@ ) {
        carp "EXCEPTION: [$@]\n";
        return;
    }

    my $url  = $hash->{wolfram}->{url};

    if ( $url =~ /^http/ ) {
        $url =~ s{^https://}{http://};
        return $url;
    }

    return;
}

##############################################################################

1;    # End of Graph::Undirected::Hamiltonicity::Wolfram
