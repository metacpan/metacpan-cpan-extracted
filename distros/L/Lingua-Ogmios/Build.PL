use Module::Build;


 
my $class = Module::Build->subclass(
				    class => "Module::Build::Custom",
    );

my $build = $class->new
    (
     module_name => 'Lingua::Ogmios',
     dist_version_from => 'lib/Lingua/Ogmios.pm',
     license => 'gpl',
     requires => {'perl' => '5.8.0',
	      },
     configure_requires => { 'Module::Build' => 0.28,
     },
    build_requires => {
        "Module::Build"     => 0.28,
	"Getopt::Long" => 0,
	"Config::General" => 0,
	"File::MMagic" => 0,
	"XML::LibXML" => 0,
	"Lingua::Identify" => 0,
	"Lingua::YaTeA" => 0,
	"Alvis::TermTagger" => 0,
	"Math::Trig" => 0,
	"Scalar::Util" => 0,
	"Text::Affixes" => 0,
	"Text::Ngram" => 0,
	"XML::Entities" => 0,
	"Encode" => 0,
	"Parse::Yapp" => 0,
	Test::Pod::Coverage => 0,
	Test::Pod => 0,
	"Pod::Usage" => 0,
	"Data::Dumper" => 0,
	"Storable" => 0,
	"Class::Factory::Util" => 0,
	"File::Basename" => 0,
	"Test::More" => 0,
	"Fcntl" => 0,
	"File::Copy" => 0,
	"File::Path" => 0,
	"File::Touch" => 0,
	"Sys::Hostname" => 0,
	"Time::HiRes" => 0,
	"HTML::FormatRTF" => 0,
	"Lingua::NegEx" => 0,
    },
     etc_files => {
	 'etc/ogmios/nlpplatform.rc' => 'etc/ogmios/nlpplatform.rc',
	 'etc/ogmios/xsd' => 'etc/ogmios/xsd',
	 'etc/ogmios/xsl' => 'etc/ogmios/xsl',
	 'etc/ogmios/dtd' => 'etc/ogmios/dtd',
	 },
     );


# $build->install_base_relpaths( etc => 'etc' );
# $build->prefix_relpaths('site', etc => 'etc' );
# $build->prefix_relpaths('core', etc => 'etc' );
# $build->prefix_relpaths('vendor', etc => 'etc' );
# $build->add_build_element('etc');


# foreach my $type (keys(%{$build->install_sets})) {
#     $build->install_sets->{$type}->{'etc'} = '/etc';
# }

# $build->install_sets->{'site'}->{'etc'} = '/usr/local/etc';

# # same thing with prefix
# if (((defined $build->install_base()) && ($build->install_base() eq "/usr")) ||
#     ((defined $build->prefix()) && ($build->prefix() eq "/usr")))
#  {
# 	$build->install_path->{'etc'} = '/etc';
# }

$build->create_build_script;

