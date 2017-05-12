# https://github.com/mnunberg/perl-JSON-SL/issues/2
#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use JSON::SL;

my $j = JSON::SL->new;
$j->set_jsonpointer(["/^"]);

for my $r ($j->feed('[{"a":5},{"a":null}]')) {
    $r->{Value}{a} = (defined $r->{Value}{a})  ? "d" : "not d";
    isnt($r->{Value}->{a}, undef);
}

done_testing();
