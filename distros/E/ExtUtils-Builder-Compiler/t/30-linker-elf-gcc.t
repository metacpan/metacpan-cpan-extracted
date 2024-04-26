#! perl

use strict;
use warnings;

use Test::More 0.89;
BEGIN {
	*eq_or_diff = eval { require Test::Differences } ? \&Test::Differences::eq_or_diff : \&Test::More::is_deeply;
}

use ExtUtils::Builder::Linker::ELF::Any;

{
	my $linker = ExtUtils::Builder::Linker::ELF::Any->new(ld => [ qw/cc/ ], ccdlflags => [ '-Wl,-E' ], lddlflags => ['-shared'], type => 'executable');
	eq_or_diff([ $linker->link(['file.o'], 'file')->to_command ], [[qw/cc -o file file.o/]], 'Got "cc -o file file.o"');
}

{
	my $linker = ExtUtils::Builder::Linker::ELF::Any->new(ld => [ qw/cc/ ], ccdlflags => [ '-Wl,-E' ], lddlflags => ['-shared'], type => 'shared-library');
	eq_or_diff([ $linker->link(['file.o'], 'file.so')->to_command ], [[qw/cc -shared -o file.so file.o/]], 'Got "cc -shared -o file.so file.o"');
}

{
	my $linker = ExtUtils::Builder::Linker::ELF::Any->new(ld => [ qw/cc/ ], ccdlflags => [ '-Wl,-E' ], lddlflags => ['-shared'], type => 'loadable-object');
	eq_or_diff([ $linker->link(['file.o'], 'file')->to_command ], [[qw/cc -shared -o file file.o/]], 'Got "cc -o file -c file.o"');
}

done_testing;
