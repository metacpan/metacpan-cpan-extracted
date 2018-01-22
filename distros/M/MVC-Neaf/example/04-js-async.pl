#!/usr/bin/env perl

# This is a small example showing XMLHttpRequest interoperation of
#     Not Even A Framework
# It displays a static page with some javascript that queries
#     a backend procedure
# The page runs a regular expression against a set of lines
#     and highlights the matching parts.
# The task was chosen because it's Perl-dependent and involves no state.
# Imagine a dozen calls instead of just one poor backend,
#     and a big & hairy model behind them.

use strict;
use warnings;
use MVC::Neaf::Util qw(decode_json); # Just 'use JSON' in real code
use MVC::Neaf qw(:sugar);

# Finally an example where not everything is in one file.
neaf static => '/04/main.js' => __FILE__.'.data/main.js';

# TT view sends all uppercase options to the real Template
# Now this is unsafe, templates should be in a separate directory...
#     But who cares for now.
neaf view   => TT => TT => INCLUDE_PATH => __FILE__.".data";

# display static page - don't even need a $request here
get '/04/async' => sub {
    return {};
}, default => {
    -view => 'TT',
    -template => "main.html",
    title => 'Javascript async request - example/04 NEAF '.MVC::Neaf->VERSION,
    root  => '/04',
}, description => "Async JSON-based request";

# TODO oh well, this MUST be a plug-in to NEAF
neaf pre_logic => sub {
    my $req = shift;

    my $body = $req->body;
    return unless $body;
    eval {
        $req->stash->{body} = decode_json( $body ); 1;
    } or die 400;
}, method => ['POST', 'PUT'], path => '/04';

# This is the logic part
post '/04/backend' => sub {
    my $req = shift;

    my $payload = $req->stash->{body};
    my $regex   = $payload->{regex};
    my $sample  = $payload->{sample};

    # The -serial tells JS to render the contained structure instead of
    # the return hash itself.
    return { -serial => [] } unless $regex and $sample;

    # Try to compile regular expression before using it
    $regex   = eval{ qr($payload->{regex}) } or die 400;

    # Got here = process the data
    my @res;
    foreach my $line (split /\n/, $sample) {
        my @parts;
        while (length $line && $line =~ $regex) {
            # This was taken from `perldoc perlvar` with minimal changes...
            my ($start, $end) = ($-[0], $+[0] || 1);
            push @parts, substr( $line, 0, $start ), substr( $line, $start, $end -$start);
            $line = substr $line, $end;
        };
        push @res, [ @parts, $line ];
    };

    return { -serial => \@res };
};

# Run as always
neaf->run;
