#!/usr/bin/env perl

use lib '../lib';
use Gcis::Client;
use Data::Dumper;
use v5.14;

my $c = Gcis::Client->new;
$c->url($ARGV[0]) if $ARGV[0];
$c->find_credentials->login;
my $findings = $c->get('/report/nca3draft/finding');

for my $f (@$findings) {
    my $finding_identifer = $f->{identifier};
    say $finding_identifer;
    my $existing = $c->get($f->{uri});
    my $i = 1;
    my $post = $f->{uri};
    $post =~ s[finding][finding/keywords];
    for my $this (@{ $existing->{keywords} }) { 
        $this->{_delete_extra} = 1 if $i==1;
        say $i++;
        my $got = $c->post($post, #"/report/nca3draft/chapter/our-changing-climate/finding/keywords/$finding",
            $this
        );
    }
}

