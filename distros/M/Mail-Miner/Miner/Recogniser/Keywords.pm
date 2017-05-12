use strict;
package Mail::Miner::Recogniser::Keywords;
use Lingua::EN::Keywords;

$Mail::Miner::recognisers{"".__PACKAGE__} =
    {
     title => "Keywords",
     help  => "Match messages containing the given keywords",
     keyword => "about",
     type => "=s",
     nodisplay => 1,
    };

sub process {
    my ($class, %hash) = @_;
    my $string = $hash{getbody}->();
    return if length $string > 1024*80; # 80k of text is too much.

    # add keywords to database
    return keywords( $string );
}

1;
