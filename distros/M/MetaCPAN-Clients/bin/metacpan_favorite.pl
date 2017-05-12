#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Path::Tiny;

my ($token, $list) = @ARGV;
die "Usage: $0 <token> <file>\n" if not $list;

my $ua = HTTP::Tiny->new;

for my $d ( reverse path($list)->lines( { chomp => 1 } ) ) {
    my ($dist, $author, $release) = split ' ', $d;
    my %data = (distribution => $dist);
    if ($author) {
        $data{author} = $author;
    }
    if ($release) {
        $data{release} = $release;
    }
    my $post = to_json( \%data );
    my $res = $ua->post(
        "https://api.metacpan.org/user/favorite?access_token=$token",
        { content => $post, headers => {'content-type' => 'application/json' }},
    );
    if ( $res->{success} ) {
        say "Favorited $dist";
    }
    else {
        warn "Could not favorite $dist ($res->{status} $res->{reason})\n";
    }
}

