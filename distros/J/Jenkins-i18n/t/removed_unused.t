use warnings;
use strict;
use Test::More tests => 14;
use File::Spec;
use File::Copy;
use Set::Tiny 0.04;
use Test::TempDir::Tiny 0.018;
use Test::Exception 0.43;

use Jenkins::i18n qw(remove_unused);
use Jenkins::i18n::Properties;

my $removed;
my $required_regex = qr/required\sparameter/;

dies_ok { $removed = remove_unused() } 'dies without file parameter';
like $@, $required_regex, 'get the expected error message';

my $temp_dir  = tempdir();
my $props     = 't/samples/table_pt_BR.properties';
my $tmp_props = File::Spec->catfile( $temp_dir, 'sample.properties' );
copy( $props, $tmp_props ) or die "Copy $!\n";
note("Using $tmp_props for tests");

dies_ok { $removed = remove_unused($tmp_props) }
'dies without keys parameter';
like $@, $required_regex, 'get the expected error message';
dies_ok { $removed = remove_unused( $tmp_props, 'foo' ) }
'dies with invalid keys parameter';
like $@, qr/Set::Tiny/, 'get the expected error message';

my $wanted = Set::Tiny->new(qw(Install compatWarning));
dies_ok { $removed = remove_unused( $tmp_props, $wanted, 'fffff' ) }
'dies with invalid license parameter';
like $@, qr/array\sreference/, 'get the expected error message';

note('Restoring file');
copy( $props, $tmp_props ) or die "Copy $!\n";
my $original_properties = read_and_count($tmp_props);
my $expected_removed    = $original_properties - $wanted->size;

note('With a license');

# due Text::Wrap, this license will be put into a single line
my @license = qw(This is a license something);
$removed = remove_unused( $tmp_props, $wanted, \@license );
is( $removed, $expected_removed, 'got the expected number of keys removed' );
is( read_and_count($tmp_props),
    $wanted->size,
    'resulting properties file has the expected number of properties' );

note('Restoring file');
copy( $props, $tmp_props ) or die "Copy $!\n";

note('With a backup');
$removed = remove_unused( $tmp_props, $wanted, \@license, 1 );
is( $removed, $expected_removed, 'got the expected number of keys removed' );
is( read_and_count($tmp_props),
    $wanted->size,
    'resulting properties file has the expected number of properties' );
my $backup = "$tmp_props.bak";
ok( -s $backup, "File has a backup as expected at $backup" );
is( invalid_count($tmp_props),
    0, 'There are no invalid Java entities in the updated properties file' );

# Text::Wrap will change the way text is saved, so counting the properties
sub read_and_count {
    my $file          = shift;
    my $props_handler = Jenkins::i18n::Properties->new( file => $file );
    my @names         = $props_handler->propertyNames;
    return scalar(@names);
}

sub invalid_count {
    my $file          = shift;
    my $invalid_regex = qr/\\\\u/;
    my $count         = 0;
    open( my $in, '<', $file ) or die "Cannot read $file: $!";
    while (<$in>) {
        if (/$invalid_regex/) {
            my @total = /$invalid_regex/g;
            $count += scalar(@total);
        }
    }
    close($in);
    return $count;
}

# -*- mode: perl -*-
# vi: set ft=perl :
