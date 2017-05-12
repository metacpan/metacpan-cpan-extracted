use inc::Module::Install;


perl_version    '5.008';
name            'Devel-Module-Trace';
all_from        'lib/Devel/Module/Trace.pm';
author          'Sven Nierlein <nierlein@cpan.org>';
license         'perl';
repository      'http://github.com/sni/perl-devel-module-trace';

requires        'POSIX';
requires        'Time::HiRes';
requires        'Devel::OverrideGlobalRequire';
requires        'Mojolicious::Lite';
requires        'Template';
requires        'JSON::XS';

build_requires  'Test::More';

install_script  'devel_module_trace_result_server';

no_index package => 'DB';

makemaker_args(
    dist => {
        PREOP => 'rm $(DISTVNAME)/script/devel_module_trace_result_server && \
	cp -rp script/devel_module_trace_result_server $(DISTVNAME)/script/devel_module_trace_result_server && \
	cat templates/index.tt >> $(DISTVNAME)/script/devel_module_trace_result_server'
        #PREOP => 'ls -ila $(DISTVNAME)/script/devel_module_trace_result_server script/devel_module_trace_result_server'
    },
);

WriteAll;
