use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => 'corpus' ),
    "new object";

ok my $metadata = $cpo->metadata, "got metadata";

my %md = (
    'AUTHOR'                 => 'ORDNANCE SURVEY',
    'PRODUCT'                => 'OS CODE-POINT_OPEN',
    'DATASET VERSION NUMBER' => '2013.4.0',
    'COPYRIGHT DATE'         => '20131027',
    'RM UPDATE DATE'         => '20131018',
);

is $metadata->{$_}, $md{$_}, "$_ ok" foreach sort keys %md;

is $metadata->{counts}->{XX}, 16644, 'sample count ok';

done_testing();

