use warnings;
use strict;
use Test::More tests => 9;
use File::Spec;
use Test::Exception 0.43;

use Jenkins::i18n qw(find_files);

my $files_ref;
dies_ok { $files_ref = find_files() } 'dies without directory parameter';
like $@, qr/invalid\sdirectory\sparameter/, 'get the expected error message';
dies_ok { $files_ref = find_files( [] ) } 'dies without directory parameter';
like $@, qr/reference/, 'get the expected error message';
dies_ok { $files_ref = find_files('/tmp/foobar') }
'dies with non-existing directory parameter';
like $@, qr/must\sexists/, 'get the expected error message';
my $samples_dir = File::Spec->catdir( 't', 'samples' );
note("Using $samples_dir as samples source");
ok( $files_ref = find_files($samples_dir), 'find_files works' );
is( ref($files_ref), 'ARRAY', 'find_files returns an array reference' );

my $expected_ref = [
    File::Spec->catfile(qw(t samples Messages.properties)),
    File::Spec->catfile(qw(t samples config.jelly)),
    File::Spec->catfile(qw(t samples message.jelly))
];
is_deeply( $files_ref, $expected_ref,
    'find_files returns the expected files' )
    or diag( explain($files_ref) );

# -*- mode: perl -*-
# vi: set ft=perl :
