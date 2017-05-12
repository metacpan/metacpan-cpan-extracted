use Module::Build;
use 5.10.0;
Module::Build->new
    ( module_name => 'HTTP::Server::Simple::WebDAO',
    license => 'perl',
   prereq => {
	'HTTP::Server::Simple'=>0.44,
	'WebDAO'=>2.20
	     },
   dist_version_from=>'lib/HTTP/Server/Simple/WebDAO.pm',
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
