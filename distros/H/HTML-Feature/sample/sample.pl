use strict;
use warnings;
use blib;
use HTML::Feature;
use LWP::UserAgent;

my $feature = HTML::Feature->new(
    ## You can set some engine modules serially. ( if one module can't extract text, it calls to next module )
    engines => [
    #    'HTML::Feature::Engine::LDRFullFeed',
        'HTML::Feature::Engine::GoogleADSection',
        'HTML::Feature::Engine::TagStructure',
    ],
);

loop();

sub loop {
    print "Input URL: ";
    my $url = <STDIN>;
    chomp $url;

    my $res = LWP::UserAgent->new->request( HTTP::Request->new( GET => $url ) );
    my $text = $res->content;

    ### Parses the given argument.
    ### The argument can be either a URL, a string of HTML (must be passed as a scalar reference), or an HTTP::Response object.

    #
    # Give an URL.
    my $result = $feature->parse($url);

    #
    # Give a text(scalar reference)
    # And URL optionally (it will be necessary when you use LDRFullFeed).
    #my $result = $feature->parse( \$text, $url );

    #
    # Give a HTTP::Response object
    #my $result = $feature->parse( $res);

    print "\n-------------------\n";
    print $result->text;
    print "\n\n";

    ## Show matched engine
    print "MATCHED ENGINE: ", $result->{matched_engine};
    print "\n-------------------\n";

    loop();
}
