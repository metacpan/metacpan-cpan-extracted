#!perl

use strict;
use warnings;

use Dist::Zilla::Tester ();
use Directory::Scratch  ();
use Class::Load         ();

use Test::More;

Class::Load::try_load_class('CPAN::Mini::Inject::Remote')
	or plan skip_all => 'CPAN::Mini::Inject::Remote required to run these tests';

my $tmp = Directory::Scratch->new( DIR => '.' );

my $dist_ini = <<"END_INI";
name     = Dist-Zilla-Plugin-Inject-Test
abstract = Testing distribution for Dist::Zilla::Plugin::Inject
version  = 0.001
author   = E. Xavier Ample <example\@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample

[Inject]
remote_server = http://mcpani.example.com
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

ok( $plugin->is_remote, 'is_remote' );
is( $plugin->remote_server, 'http://mcpani.example.com', 'remote_server' );
is( $plugin->author_id, 'EXAMPLE', 'author_id' );
is( $plugin->module, 'Dist::Zilla::Plugin::Inject::Test', 'module' );
isa_ok( $plugin->injector, 'CPAN::Mini::Inject::Remote', 'injector' );

done_testing();
