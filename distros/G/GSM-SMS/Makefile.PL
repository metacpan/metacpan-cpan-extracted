use strict;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );
use File::stat;
use File::Path;
use File::Spec;
use FindBin qw($Bin);
use lib "$Bin/lib";

our $VERSION = "0.163";

my $term;

WriteMakefile(
    'NAME'			=> 'GSM::SMS',
    'VERSION'		=> $VERSION,
	'ABSTRACT'		=> 'Perl Modules For Smart Messaging',
    'PREREQ_PM'		=> {
		'Test::More'		=> 0,
		'Log::Agent'		=> 0,
		'MIME::Base64'		=> 0,
		'Data::Dumper'		=> 0,
		'Image::Magick'		=> 0,
		'LWP::UserAgent'	=> 0,
		'File::Temp'		=> 0,
		'HTTP::Request'		=> 0,
		'URI::URL'			=> 0,
		'URI::Escape'		=> 0,
		'LWP::Simple'		=> 0,
		'File::stat'		=> 0,
		'File::Path'		=> 0
	},
	'CONFIGURE'		=> \&configure,
	'dist'			=> {
		PREOP => 'pod2text docs/README.pod > $(DISTVNAME)/README',
		DIST_DEFAULT => 'all tardist',
		COMPRESS => 'gzip -9f'
	}
);

sub configure {
	require GSM::SMS::Config;
	my $config = GSM::SMS::Config::_config_wizard();

	if ($config) {
		my $config_file = File::Spec->catfile(
			$Bin, "lib", "GSM", "SMS", "Config", "Default.pm"
		);
		open OUT, ">$config_file" or die "$!: $config_file";
		print OUT $config;
		close OUT;
		print "Configuration done.\n";
	}
	return {};
}

package MY;

sub postamble {
	my $post = shift->SUPER::postamble(@_);

	$post .= <<EOT;

setversion:
	find . -exec perl -pi -e 's/\\\$\$VERSION\\s*=.+;\$\$/\\\$\$VERSION = "0.161";

EOT

	return $post;
}
