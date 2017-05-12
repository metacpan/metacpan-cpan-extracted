use 5.008001;
use strict;
use warnings;
use Module::Build;

my %supported = map { ( $_ => 1 ) } qw/linux solaris freebsd gnukfreebsd darwin MSWin32/;

my $implementation = $supported{$^O} ? 'Sys::Sendfile' : 'File::Map';

my %module_build_args = (
	  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'IO::Socket::INET' => '0',
    'Module::Build' => '0.3601',
    'Socket' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'requires' => {
    'Carp' => '0',
    'Errno' => '0',
    'Fcntl' => '0',
    'Sub::Exporter::Progressive' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
);

$module_build_args{requires}{$implementation} = 0;

my $builder = Module::Build->new(
	module_name => 'File::Send',
	%module_build_args,
);

$builder->create_build_script();

