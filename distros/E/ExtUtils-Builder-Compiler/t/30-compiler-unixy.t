#! perl

use strict;
use warnings;

use Test::More 0.89;
BEGIN {
	*eq_or_diff = eval { require Test::Differences } ? \&Test::Differences::eq_or_diff : \&Test::More::is_deeply;
}


use ExtUtils::Builder::Compiler::Unixy;

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => 'cc', cccdlflags => [ '-fPIC' ], type => 'loadable-object');
	my $obj = $compiler->compile('file.c', 'file.o');
	eq_or_diff([ $obj->to_command ], [[qw/cc -fPIC -o file.o -c file.c/]], 'Got "cc -fPIC -o file.o -c file.c"') or diag explain $obj;
}

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => [ 'cc' ], cccdlflags => [ '-fPIC' ], type => 'executable');
	eq_or_diff([ $compiler->compile('file.c', 'file.o')->to_command ], [[qw/cc -o file.o -c file.c/]], 'Got "cc -o file.o -c file.c"');
}

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => 'cc', cccdlflags => [ ], type => 'loadable-object');
	eq_or_diff([ $compiler->compile('file.c', 'file.o')->to_command ], [[qw/cc -o file.o -c file.c/]], 'Got "cc -o file.o -c file.c" 2');
}

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => [ 'cc' ], cccdlflags => [ ], type => 'loadable-object');
	$compiler->add_include_dirs([ 'headers' ]);
	eq_or_diff([ $compiler->compile('file.c', 'file.o')->to_command ], [[qw/cc -Iheaders -o file.o -c file.c/]], 'Got "cc -Iheaders -o file.o -c file.c"');
}

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => 'cc89', cccdlflags => [ '-fPIC' ], type => 'executable');
	$compiler->add_include_dirs([ 'headers' ]);
	$compiler->add_defines({ foo => 'bar' });
	eq_or_diff([ $compiler->compile('file.c', 'file.o')->to_command ], [[qw/cc89 -Iheaders -Dfoo=bar -o file.o -c file.c/]], 'Got "cc -Iheaders -Dfoo=bar -o file.o -c file.c"');
}

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => [ qw/cc -std=c89/ ], cccdlflags => [ ], type => 'loadable-object');
	$compiler->add_defines({ foo => '' });
	eq_or_diff([ $compiler->compile('file.c', 'file.o')->to_command ], [[qw/cc -std=c89 -Dfoo -o file.o -c file.c/]], 'Got "cc -Dfoo -o file.o -c file.c"');
}

{
	my $compiler = ExtUtils::Builder::Compiler::Unixy->new(cc => [ 'cc' ], cccdlflags => [ '-fPIC' ], type => 'executable');
	$compiler->add_defines({ foo => undef });
	eq_or_diff([ $compiler->compile('file.c', 'file.o')->to_command ], [[qw/cc -Ufoo -o file.o -c file.c/]], 'Got "cc -Ufoo -o file.o -c file.c"');
}

done_testing;
