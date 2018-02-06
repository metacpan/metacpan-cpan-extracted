#!perl
use strict;
use warnings;

use Test::More;

use Test::DZil;
use JSON::PP qw(decode_json);
use File::Slurper qw(read_text);

my %wanted = (
	# prereqs from AutoPrereqs
	strict     => '0',
	warnings   => '0',
	# prereq from metamerge file
	'Foo::Bar' => '1',
);

my $tzil = Builder->from_config(
	{ dist_root => 'corpus' },
	{ },
);
$tzil->build;
my $meta = decode_json(read_text($tzil->tempdir->path('build/META.json')));

is_deeply($meta->{prereqs}{runtime}{requires}, \%wanted, 'Prerequisites are as expected');

is($meta->{name}, 'DZT-Sample', 'name is as expected');
is($meta->{resources}{homepage}, 'http://example.com/', 'homepage is correctly set');

done_testing;
