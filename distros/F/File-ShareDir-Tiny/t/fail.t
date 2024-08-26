#!perl

use strict;
use warnings;

use lib 't/lib';

use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec;
use Test::More 0.89;

use File::ShareDir::Tiny ':ALL';

sub dies
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($code, $pattern, $message) = @_;
    $message  ||= 'Code dies as expected';
    is(eval { $code->() }, undef);
    like($@, $pattern, $message);
}

dies(sub { module_dir() },   qr/No module given/, 'No params to module_dir dies');
dies(sub { module_dir('') }, qr/No module given/, 'Null param to module_dir dies');
dies(
    sub { module_dir('File::ShareDir::Bad') },
    qr/Failed to find share dir for module 'File::ShareDir::Bad'/,
    'Getting module dir for known non-existent module dies',
);
# test from RT#125582
dies(
    sub { dist_file('File-ShareDir-Tiny', 'file/name.txt') },
    qr/Failed to find share dir for dist 'File-ShareDir-Tiny'/,
    'Getting non-existent file dies'
);

dies(sub { my $dist_dir   = dist_dir('Non-Existent') },    qr/Failed to find share dir for dist/, 'No dist directory');
dies(sub { my $module_dir = module_dir('Non::Existent') },    qr/Failed to find share dir for module/, 'No module directory');

dies(
    sub { my $module_file = module_file('ShareDir::TestClass', 'noehere.txt') },
    qr/does not exist in module dir/,
    'Unavailable module_file'
);

done_testing;
