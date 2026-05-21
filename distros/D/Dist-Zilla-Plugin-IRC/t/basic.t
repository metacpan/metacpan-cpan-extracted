#!perl
use strict;
use warnings;

use Test::More;

use Test::DZil;
use JSON::PP qw(decode_json);
use File::Slurper qw(read_text);

{
	my $tzil = Builder->from_config(
		{ dist_root => 'corpus/' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					'MetaJSON',
					[ IRC => { channel => 'distzilla' }],
				),
			},
		},
	);

	$tzil->build;

	my $dir = $tzil->tempdir->child('build');
	my $meta = decode_json(read_text($dir->child('META.json')));
	is_deeply($meta->{resources}{x_IRC}, { url => 'irc://irc.perl.org/#distzilla' }, 'Channel is set');
}

done_testing;
