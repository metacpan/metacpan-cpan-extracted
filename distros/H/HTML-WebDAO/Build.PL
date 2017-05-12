use Module::Build;
Module::Build->new
    ( module_name => 'HTML::WebDAO',
    license => 'perl',
   prereq => {
	      'MLDBM'	=> '0',
	      'XML::LibXML'=>'0',
	      'DateTime'=> 0.37,
	      'DateTime::Format::HTTP'=>0.37,
	      'Encode'=> 0,
	      'Getopt::Long'=>2.35,
	      'FCGI'=>0.67
	       },
  script_files=>[qw!
    script/wd_cgi.pl
    script/wd_fcgi.fpl
    script/wd_shell.pl
  !],
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
