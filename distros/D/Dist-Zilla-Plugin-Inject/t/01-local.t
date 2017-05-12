#!perl

use strict;
use warnings;

use Dist::Zilla::Tester ();
use Path::Class         ();
use Directory::Scratch  ();
use Class::Load         ();

use Test::More;

Class::Load::try_load_class('CPAN::Mini::Inject')
	or plan skip_all => 'CPAN::Mini::Inject required to run these tests';

my $tmp = Directory::Scratch->new( DIR => '.' );

my $mcpani_conf = <<'END_CONF';
local: /path/to/minicpan
repository: /path/to/repository
remote: http://favourite.mirror.com/
END_CONF

$tmp->write('mcpani.conf', $mcpani_conf) or die $!;
my $path_to_mcpani_conf = Path::Class::file($tmp->base, 'mcpani.conf')->absolute->stringify;

my $dist_ini = <<"END_INI";
name     = Dist-Zilla-Plugin-Inject-Test
abstract = Testing distribution for Dist::Zilla::Plugin::Inject
version  = 0.001
author   = E. Xavier Ample <example\@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample

[Inject]
config_file = $path_to_mcpani_conf
author_id = EXAMPLE
END_INI

my $tzil = Dist::Zilla::Tester->from_config(
	{ dist_root => $tmp->base->stringify },
	{
		tempdir_root => $tmp->base->stringify,
		add_files => { 'source/dist.ini' => $dist_ini },
	},
);

my $plugin = $tzil->plugin_named('Inject');

ok( !$plugin->is_remote, 'is_remote' );
is( $plugin->config_file, $path_to_mcpani_conf, 'config_file' );
is( $plugin->author_id, 'EXAMPLE', 'author_id' );
is( $plugin->module, 'Dist::Zilla::Plugin::Inject::Test', 'module' );
isa_ok( $plugin->injector, 'CPAN::Mini::Inject', 'injector' );
isa_ok( $plugin->injector->config, 'CPAN::Mini::Inject::Config', 'config' );
is( $plugin->injector->config->get('local'), '/path/to/minicpan', 'local' );
is( $plugin->injector->config->get('remote'), 'http://favourite.mirror.com/', 'remote' );
is( $plugin->injector->config->get('repository'), '/path/to/repository', 'repository' );

done_testing();
