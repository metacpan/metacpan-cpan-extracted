#! perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

use ExtUtils::BuildRC qw/parse_file read_config/;
use Cwd;
use File::Spec::Functions qw/catdir catfile/;

my $example1 = parse_file('t/files/example1');
is_deeply($example1, { install => ['--install_base', '/home/user/perl5'] }, 'parse_file seems to be sane');

{
	local $ENV{MODULEBUILDRC} = 't/files/example1';
	my $second_try = read_config();
	is_deeply($second_try, { install => ['--install_base', '/home/user/perl5'] }, 'Reading it from $ENV{MODULEBUILDRC} works too');
}

my $example2 = parse_file('t/files/example2');
is_deeply($example2, { install => ['--install_base', '/home/user/perl5', '--prefix', '/home/user'], '*' => [ '--verbose' ] }, 'Embedded newlines are handled too');

{
	local $ENV{MODULEBUILDRC};
	local $ENV{HOME} = catdir(cwd, qw/t files/);

	my $config = read_config();
	is_deeply($config, { install => ['--prefix', '/home/user/perl5'] }, 'Config file is found in home directory');
}

{
	local $ENV{MODULEBUILDRC};
	local $ENV{HOME};
	local $ENV{USERPROFILE} = 't/files';

	my $config = read_config();
	is_deeply($config, { install => ['--prefix', '/home/user/perl5'] }, 'Config file is found in USERPROFILE too');
}
