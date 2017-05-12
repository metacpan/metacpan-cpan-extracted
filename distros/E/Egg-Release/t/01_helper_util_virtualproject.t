use Test::More tests=> 95;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

ok my $e= Egg::Helper->run('vtest'), q{my $e= Egg::Helper->run('Vtest')};
ok my $conf= $e->config, q{my $conf= $e->config};
isa_ok $conf, 'HASH';

ok $conf->{project_name}, q{$conf->{project_name}};
ok $conf->{root}, q{$conf->{root}};
ok $conf->{start_dir}, q{$conf->{start_dir}};

isa_ok $e, 'Egg::Request';
isa_ok $e, 'Egg::Response';
isa_ok $e, 'Egg::Util';
isa_ok $e, 'Egg::Manager::Model';
isa_ok $e, 'Egg::Manager::View';
isa_ok $e, 'Egg::Component';
isa_ok $e, 'Egg::Component::Base';
isa_ok $e, 'Egg::Base';
isa_ok $e, 'Egg::Helper::Util::Base';
isa_ok $e, 'Egg::Helper::Util::VirtualProject';

can_ok $e, '_helper_get_options';
  @ARGV= ("-o", "/test", "-h");
  ok my $opt= $e->_helper_get_options, q{my $opt= $e->_helper_get_options};
  isa_ok $opt, 'HASH';
  is $opt->{output_path}, '/test', q{$opt->{output_path}, '/test'};
  ok $opt->{help}, q{$opt->{help}};

can_ok $e, 'helper_is_platform';
  my %OSTYPE= ( MSWin32=> 'Win32', MacOS=> 'MacOS', Unix=> 'Unix' );
  my $OS= $OSTYPE{$^O} || 'Unix';
  is $e->helper_is_platform, $OS, q{$e->helper_is_platform, $OS};
  for (values %OSTYPE) {
  	my $method= 'helper_is_'. lc($_);
  	can_ok $e, $method;
  	if ($_ eq $OS) {
  		ok $e->$method, qq{\$e->$method};
  	} else {
  		ok ! $e->$method, qq{! \$e->$method};
  	}
  }

can_ok $e, 'helper_perl_path';
can_ok $e, 'helper_temp_dir';
can_ok $e, 'helper_current_dir';

can_ok $e, 'helper_yaml_load';
  ok my $hash= $e->helper_yaml_load(<<END_YAML), q{my $hash= $e->helper_yaml_load(<<END_YAML)};
test1: ok1
test2: ok2
END_YAML
  isa_ok $hash, 'HASH';
  is $hash->{test1}, 'ok1', q{$hash->{test1}, 'ok1'};
  is $hash->{test2}, 'ok2', q{$hash->{test2}, 'ok2'};

can_ok $e, 'helper_stdout';
  ok my $io= $e->helper_stdout( sub { print 'OK' } ),
     q{my $io= $e->helper_stdout( sub { print 'OK' } )};
  isa_ok $io, 'Egg::Util::STDIO::result';
  ok ! $io->error, q{! $io->error};
  is $io->result, 'OK', q{$io->result, 'OK'};
  ok $io= $e->helper_stdout( sub { $e->helper_yaml_load } ),
     q{$io= $e->stdio( sub { $e->helper_yaml_load } )};
  ok $io->error, q{$io->error};
  like $io->error, qr{I want yaml data}, q{qr{I want yaml data}};
  ok ! $io->result, q{! $io->result};

can_ok $e, 'helper_stdin';

can_ok $e, 'helper_load_rc';
  ok my $rc= $e->helper_load_rc, q{my $rc= $e->helper_load_rc};
  isa_ok $rc, 'HASH';

can_ok $e, 'helper_chdir';
  can_ok $e, 'helper_create_dir';
  ok $e->helper_chdir("$conf->{root}/test", 1), q{$e->helper_chdir("$conf->{root}/test", 1)};
  ok -e "$conf->{root}/test", q{-e "$conf->{root}/test"};
  is $e->helper_current_dir, "$conf->{root}/test", q{$e->helper_current_dir, "$conf->{root}/test"};
  ok $e->helper_chdir("$conf->{root}/test/test", 1), q{$e->helper_chdir("$conf->{root}/test/test", 1)};
  ok -e "$conf->{root}/test/test", q{-e "$conf->{root}/test/test"};
  is $e->helper_current_dir, "$conf->{root}/test/test", q{$e->helper_current_dir, "$conf->{root}/test/test"};
  ok $e->helper_chdir($conf->{root}), q{$e->helper_chdir($conf->{root})};
  is $e->helper_current_dir, $conf->{root}, q{$e->helper_current_dir, $conf->{root}};

can_ok $e, 'helper_remove_dir';
  ok -e "$conf->{root}/test/test", q{-e "$conf->{root}/test/test"};
  ok $e->helper_remove_dir("$conf->{root}/test"), q{$e->helper_remove_dir("$conf->{root}/test")};
  ok ! -e "$conf->{root}/test/test", q{! -e "$conf->{root}/test/test"};
  ok ! -e "$conf->{root}/test", q{! -e "$conf->{root}/test"};

can_ok $e, 'helper_prepare_param';
  ok my $pm= $e->helper_prepare_param, q{my $param= $e->helper_prepare_param};
  isa_ok $pm, 'HASH';
  is $pm->{project_name}, $conf->{project_name}, q{$pm->{project_name}, $conf->{project_name}};
  is $pm->{project_name}, $e->namespace, q{$pm->{project_name}, $e->namespace};
  is $pm->{project_name}, $e->{namespace}, q{$pm->{project_name}, $e->{namespace}};
  is $pm->{dir}, $e->config->{dir}, q{$pm->{dir}, $e->config->{dir}};
  is $pm->{output_path}, $e->config->{root}, q{$pm->{output_path}, $e->config->{root}};
  is $pm->{root}->(), $e->config->{root}, q{$pm->{root}->(), $e->config->{root}};
  is $pm->{year}->(), (localtime time)[5]+ 1900, q{$pm->{year}->(), (localtime time)[5]+ 1900};
  is $pm->{perl_path}->(), $e->helper_perl_path, q{$pm->{perl_path}->(), $e->helper_perl_path};
#  is $pm->{gmtime_string}->(), gmtime time, q{$pm->{gmtime_string}->(), gmtime time};
  isa_ok $pm->{document}, 'CODE';
  isa_ok $pm->{dist}, 'CODE';

can_ok $e, 'helper_prepare_param_module';
  ok $pm= $e->helper_prepare_param_module($pm, 'MY::MODULE::NAME'),
     q{$pm= $e->helper_prepare_param_module($pm, 'MY::MODULE::NAME')};
  is $pm->{module_name}, 'MY-MODULE-NAME', q{$pm->{module_name}, 'MY-MODULE-NAME'};
  is $pm->{module_filepath}, 'MY/MODULE/NAME.pm', q{$pm->{module_filepath}, 'MY/MODULE/NAME.pm'};
  is $pm->{module_filename}, 'NAME.pm', q{$pm->{module_filename}, 'NAME.pm'};
  is $pm->{module_distname}, 'MY::MODULE::NAME', q{$pm->{module_distname}, 'MY::MODULE::NAME'};
  is $pm->{module_basedir}, 'MY/MODULE', q{$pm->{module_basedir}, 'MY/MODULE'};
  is $pm->{target_path}, "$pm->{output_path}/$pm->{module_name}",
     q{$pm->{target_path}, "$pm->{output_path}/$pm->{module_name}"};
  is $pm->{lib_dir}, "$pm->{output_path}/MY-MODULE-NAME/lib", q{$pm->{lib_dir}, "$pm->{output_path}/MY-MODULE-NAME/lib"};
  is $pm->{lib_basedir}, "$pm->{lib_dir}/$pm->{module_basedir}",
     q{$pm->{lib_basedir}, "$pm->{lib_dir}/$pm->{module_basedir}"};

can_ok 'Egg::Helper', 'helper_script';
  can_ok 'Egg::Helper', 'out';
  ok $io= $e->helper_stdout( sub { Egg::Helper->helper_script } ),
    q{$io= $e->helper_stdout( sub { Egg::Helper->helper_script } )};
  ok ! $io->error, q{! $io->error};
  like $io->result, qr{^#\!.+}, q{qr{^#\!.+}};
  like $io->result, qr{\buse Egg\:+Helper\;}, q{qr{\buse Egg\:+Helper\;}};
  like $io->result, qr{\bEgg\:+Helper\->run\(.+}, q{qr{\bEgg\:+Helper\->run\(.+}};
