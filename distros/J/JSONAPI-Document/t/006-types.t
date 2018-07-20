#! perl -w

use lib 't/lib';

use Test::Most;
use Test::JSONAPI;
use JSONAPI::Document::Builder;

my $t = Test::JSONAPI->new({ api_url => 'http://example.com/api' });
$t->schema;

my $row = $t->schema->resultset('Post')->find(1);

my $builder = JSONAPI::Document::Builder->new(
    kebab_case_attrs => 1,
    row              => $row,
);

is($builder->document_type('EmailTemplate'),  'email-templates');
is($builder->document_type('EmailTemplates'), 'email-templates');
is($builder->document_type('gdk_burger'),     'gdk-burgers');
is($builder->document_type('gdk_burgers'),    'gdk-burgers');

done_testing;
