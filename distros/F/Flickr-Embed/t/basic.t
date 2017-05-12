use strict;
use warnings;
use Flickr::Embed;
use Data::Dumper;
use Test::More tests => 4;

my $key = $ENV{FLICKRKEY};
my $secret = $ENV{FLICKRSECRET};

if (!$key && !$secret && -t STDIN) {
    print "Please give an API key and secret for testing.\n";
    print "You may supply these automatically in the future\n";
    print "by setting the FLICKRKEY and FLICKRSECRET environment\n";
    print "variables.\n\nFlickr API key? ";

    $key = <>;
    chomp $key;

    print "Flickr API secret? ";

    $secret = <>;
    chomp $secret;
}

sub evalled_embed {
    my $w = wantarray;
    my $result = eval {
	if ($w) {
	    return [ Flickr::Embed::embed(@_) ];
	} else {
	    return Flickr::Embed::embed(@_);
	}
    };

    return $@ if $@;

    return @$result if $w;
    return $result;
}

my @params = (
    tags=>'abbey,st albans',
    key=>$key,
    secret=>$secret,
    per_page=>10,
    );

like(evalled_embed(tags=>'abbey,st albans'),
     qr/key parameter is required/,
     'Flickr rejects requests without API key');

SKIP: {
    skip 'No API key given', 3 unless $key && $secret;

    my $single = scalar( evalled_embed(@params) );

    isnt (index($single->{html}, $single->{source}), -1, 'Photo URL is in HTML');

    my @multiple = evalled_embed(@params);

    ok(scalar(grep { $_->{id} eq $single->{id} } @multiple),
        'single is returned in multiple');

    my @multiple_excluded = evalled_embed(@params,
            exclude => [1, 2, $single->{id}, 9],
    );

    ok(!scalar( grep { $_->{id} eq $single->{id} } @multiple_excluded ),
        'single is not returned in multiple if excluded');

}

