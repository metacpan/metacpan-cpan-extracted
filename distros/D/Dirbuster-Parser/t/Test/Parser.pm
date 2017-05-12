#!/usr/bin/perl

package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;

    my $parser = $self->{parser1};
    my @results = $parser->get_all_results();
    
    my $item1 = $results[0];
    my $item2 = $results[1];
    my $item3 = $results[2];

    is ( $item1->type, 'Dir', 'item1 type');
    is ( $item1->path, '/', 'item1 path');
    is ( $item1->response_code, '200', 'item1 response_code');

    is ( $item2->type, 'Dir', 'item2 type');
    is ( $item2->path, '/cgi-bin/', 'item2 path');
    is ( $item2->response_code, '403', 'item2 response_code');

    is ( $item3->type, 'Dir', 'item3 type');
    is ( $item3->path, '/icons/', 'item3 path');
    is ( $item3->response_code, '200', 'item3 response_code');
}
1;
