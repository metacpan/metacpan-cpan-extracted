use strict;
use warnings;

use Test::More;

use FindBin;
use ElasticSearchX::Model::Generator qw( generate_model );

my $instance = generate_model(
  mapping_url          => 'http://api.metacpan.org/v0/_mapping',
  base_dir             => "$FindBin::Bin/gen/",
  generated_base_class => 'MyMetaCPANModel'
);
use Data::Dump qw( pp );
for my $document ( $instance->documents() ) {
  $document->evaluate();
  pass( "Loaded a generated document : " . $document->package );
}

done_testing;
