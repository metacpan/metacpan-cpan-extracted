use Module::Build;
use File::Spec;

my $build = Module::Build->new(
			       module_name => 'MP3::PodcastFetch',
			       license     => 'perl',
			       requires => {
					    LWP                => '5.8',
					    'Date::Parse'      => '2.20',
					    'HTML::Parser'     => '3.50',
					    'Config::IniFiles' => '2.00',
					    'URI::Escape'      => 0,
					    },
			       PL_files => {
					    'bin/fetch_pods.PLS' => 'bin/fetch_pods.pl',
					    },
			       script_files => ['bin/fetch_pods.pl'],
			       conf_files   => {'conf/fetchpods.conf' => 'conf/fetchpods.conf'},
			       sign => 1,
			       dist_abstract => 'This is a library of tools for managing podcast subscriptions. It comes with a command-line tool, fetch_pods.pl, that can run under Cron to keep a directory of subscribed Podcasts feeds up to date.',
			      );
$build->add_build_element('conf');
$build->install_path(conf => File::Spec->catfile($build->install_base(),'etc'));
$build->create_build_script;
exit 0;
