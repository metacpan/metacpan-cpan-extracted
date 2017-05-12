#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse;
my $jp = JSON::Parse->new ();
$jp->detect_collisions (1);
eval {
    $jp->run ('{"animals":{"cat":"moggy","cat":"feline","cat":"neko"}}');
};
print "$@\n" if $@;
