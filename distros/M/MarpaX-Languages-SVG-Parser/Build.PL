use strict;
use warnings;

use Module::Build;

require 5.014002; # For the utf8 stuff.

# -----------------------------------------------

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'MarpaX::Languages::SVG::Parser',
	license        => 'artistic_2',
	dist_abstract  => 'An SVG parser',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More'    => 0.94,
# 	 	'Test::Pod'     => 1.45, # Make it optional. See xt/author/pod.t
#		'Test::Version' => 1.002003,
	},
	configure_requires =>
	{
		'Module::Build' => 0.3800,
	},
	meta_merge =>
	{
		resources =>
		{
			repository => 'https://github.com/ronsavage/MarpaX-Languages-SVG-Parser',
		},
	},
	requires =>
	{
		'Capture::Tiny'           => 0.22,
#		'Config'                  => undef, # Version is unparsable.
		'Config::Tiny'            => 2.19,
		'Data::Section::Simple'   => 0.05,
		'Date::Simple'            => 3.03,
		'File::Basename'          => 2.82,
		'File::Copy'              => 2.21,
		'File::HomeDir'           => 1.00,
		'File::Slurp'             => 9999.19,
		'File::Spec'              => 3.40,
		'Getopt::Long'            => 2.41,
		'Log::Handler'            => 0.79,
		'Marpa::R2'               => 2.082000,
		'Moo'                     => 1.003001,
		'open'                    => 0,
		'Path::Tiny'              => 0.034,
#		'perl'                    => undef, # For the utf8 stuff. # Version is unparsable.
		'Pod::Usage'              => 1.63,
		'Set::Array'              => 0.30,
		'strict'                  => 0,
		'Text::CSV::Encoded'      => 0.22,
		'Text::Xslate'            => 1.6002,
		'Types::Standard'         => 0.026,
		'utf8'                    => 0,
		'warnings'                => 0,
		'XML::SAX::Base'          => 1.08,
		'XML::SAX::ParserFactory' => 1.01,
	},
	resources =>
	{
		bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-SVG-Parser',
		license    => 'http://www.perlfoundation.org/artistic_license_2_0',
	},
) -> create_build_script();
