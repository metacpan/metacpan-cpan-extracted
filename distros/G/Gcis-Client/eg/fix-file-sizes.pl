#!/usr/bin/env perl

# usage :
#   echo "1" | ./fix-file-sizes.pl http://localhost:3000

use v5.14;
use Data::Dumper;
use Mojo::Util qw/sha1_sum/;
use Gcis::Client;

my $url = shift @ARGV or die 'need url';
my $c = Gcis::Client->connect(url => $url);

while (<>) {
    s/^\s+//;
    chomp(my $id = $_);
    my $file = $c->get("/file/$id") or do {
        say "# nothing for $id";
        next;
    };
    say "file $id";
    next if $file->{size} && $file->{sha1};
    my $href = $file->{href} or do {
       say "missing href for $file";
       next;
   };
   my $tx = $c->ua->get($href);
   my $res = $tx->success or do {
       say $tx->error;
       next;
   };
   my $size = $res->headers->content_length;
   my $sha1 = sha1_sum($res->body);
   $file->{size} = $size;
   $file->{sha1} = $sha1;
   delete $file->{uri};
   delete $file->{href};
   delete $file->{url};
   $c->post("/file/$id" => $file) or do {
       say  "# error : ".$c->error;
   };
}
