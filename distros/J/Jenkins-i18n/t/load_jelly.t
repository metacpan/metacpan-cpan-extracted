use warnings;
use strict;
use Test::More tests => 4;
use File::Spec;

use Jenkins::i18n qw(load_jelly);

my $sample = File::Spec->catfile( 't', 'samples', 'message.jelly' );
note("Using $sample");
my $result = load_jelly($sample);
is( ref $result, 'HASH', 'result is a hash reference' );
is_deeply( $result, { 'blurb' => 1 }, 'result has the expected content' )
    or diag( explain($result) );

$sample = File::Spec->catfile( 't', 'samples', 'config.jelly' );
note("Using sample $sample for complex keys");
$result = load_jelly($sample);
is( ref $result, 'HASH', 'result is a hash reference' );
is_deeply(
    $result,
    {
        'Disabled\\ jobs\\ only' => 1,
        'Enabled\\ jobs\\ only'  => 1,
        'Status\\ Filter'        => 1
    },
    'result has the expected content'
) or diag( explain($result) );

# -*- mode: perl -*-
# vi: set ft=perl :

