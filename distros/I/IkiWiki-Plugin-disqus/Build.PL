use Module::Build;

my $build = Module::Build->new(
    module_name => 'IkiWiki::Plugin::disqus',
    license     => 'gpl',
    requires    => {
	'IkiWiki' => '3.00',
    },
    meta_add => {
	resources => {
	    homepage   => 'http://code.google.com/p/ikiwiki-plugin-disqus/',
	    license    => 'http://www.gnu.org/licenses/old-licenses/gpl-2.0.html',
	    # bugtracker => {
	    # 	web    => 'http://code.google.com/p/ikiwiki-plugin-disqus/issues/list',
	    # 	mailto => 'perlstalker@vuser.org',
	    # },
	    # repository => {
	    # 	type => 'hg',
	    # 	url  => 'https://code.google.com/p/ikiwiki-plugin-disqus/',
	    # 	web  => 'http://code.google.com/p/ikiwiki-plugin-disqus/source/browse/',
	    # },
	},
    },
);

$build->create_build_script;

