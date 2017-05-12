package Importer::Test;
use strict;
use warnings;

{
    package main;
    use Importer '0.001', 'Test::More';
}

use Importer 0.001, 'Test::More' => qw/0.88 pass ok $TODO/;
use Importer 'Data::Dumper';

pass("Loaded Test::More");

our $ok = 'ok';
our %ok = ( 1 => 1 );
our @ok = qw/o k/;
ok(1, "imported ok");

ok(eval '$TODO = undef; 1', '$TODO was imported') || Test::More::diag($@);

no Importer;

::ok(!__PACKAGE__->can($_), "removed sub $_") for qw/pass ok Dumper/;

::ok(eval '$TODO = undef; 1', '$TODO was not removed') || Test::More::diag($@);

::is($ok, 'ok', 'did not remove $ok');
::is_deeply(\%ok, {1 => 1}, 'Did not remove %ok' );
::is_deeply(\@ok, [qw/o k/], 'Did not remove @ok' );

::done_testing();
