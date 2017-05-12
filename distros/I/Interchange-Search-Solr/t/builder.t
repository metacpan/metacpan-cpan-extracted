#!perl

use strict;
use warnings;

use Interchange::Search::Solr::Builder;
use Test::More;
use Test::Exception;

my $builder = Interchange::Search::Solr::Builder->new(
    terms => [qw/pinco pallino/],
    filters => {    
        manufacturer => [qw/piko/]
    },
    page => 3
);

is($builder->url_builder, 'words/pinco/pallino/manufacturer/piko/page/3','Url builder works');

throws_ok { $builder->terms('berlin') } qr/did not pass type constraint "ArrayRef"/, 'Term must be arrayref';
throws_ok { $builder->filters([1]) } qr/did not pass type constraint "HashRef"/, 'Filters must be hashref';
throws_ok { $builder->facets(1) } qr/did not pass type constraint "ArrayRef"/, 'Facets must be arrayref';
throws_ok { $builder->page('a') } qr/a is not integer/, 'Page must be number';
throws_ok { $builder->page(0) } qr/must be positive number/, 'Page number must be more than 1';

done_testing;
