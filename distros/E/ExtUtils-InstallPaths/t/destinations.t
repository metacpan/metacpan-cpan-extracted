#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 111;

use Config;
use File::Temp 'tempdir';

use File::Spec::Functions 0.83 ':ALL';

my $tmp = tempdir('EIP-XXXXXXXX', CLEANUP => 1, DIR => tmpdir);
my $source = tempdir('EIP-XXXXXXXX', CLEANUP => 1, DIR => tmpdir);
chdir $source;
mkdir 'blib';
for my $subdir (qw/lib arch bin script man1 man3/) {
	mkdir catdir('blib', $subdir);
}

use ExtUtils::Config;
use ExtUtils::InstallPaths;

#########################

# We need to create a well defined environment to test install paths.
# We do this by setting up appropriate Config entries.

my @installstyle = qw(lib perl5);
my $config = ExtUtils::Config->new({
	installstyle	=> catdir(@installstyle),

	installprivlib  => catdir($tmp, @installstyle),
	installarchlib  => catdir($tmp, @installstyle, @Config{qw(version archname)}),
	installbin      => catdir($tmp, 'bin'),
	installscript   => catdir($tmp, 'bin'),
	installman1dir  => catdir($tmp, 'man', 'man1'),
	installman3dir  => catdir($tmp, 'man', 'man3'),
	installhtml1dir => catdir($tmp, 'html'),
	installhtml3dir => catdir($tmp, 'html'),

	installsitelib      => catdir($tmp, 'site', @installstyle, 'site_perl'),
	installsitearch     => catdir($tmp, 'site', @installstyle, 'site_perl', @Config{qw(version archname)}),
	installsitebin      => catdir($tmp, 'site', 'bin'),
	installsitescript   => catdir($tmp, 'site', 'bin'),
	installsiteman1dir  => catdir($tmp, 'site', 'man', 'man1'),
	installsiteman3dir  => catdir($tmp, 'site', 'man', 'man3'),
	installsitehtml1dir => catdir($tmp, 'site', 'html'),
	installsitehtml3dir => catdir($tmp, 'site', 'html'),
});

sub get_ei {
	my %args = @_;
	return ExtUtils::InstallPaths->new(installdirs => 'site', config => $config, dist_name => 'ExtUtils-InstallPaths', %args);
}

isa_ok(get_ei, 'ExtUtils::InstallPaths');

{
	my $elem = catdir(rootdir, qw/foo bar/);
	my $ei = get_ei(install_path => { elem => $elem});
	is($ei->install_path('elem'), $elem, '  can read stored path');
}

{
	my $ei = get_ei(install_base => catdir(rootdir, 'bar'), install_base_relpaths => { 'elem' => catdir(qw/foo bar/) });
 
	is($ei->install_base_relpaths('elem'), catdir(qw/foo bar/), '  can read stored path');
	is($ei->install_destination('lib'), catdir(rootdir, qw/bar lib perl5/), 'destination of other items is not affected');
}
 
 
{
	my $ei = eval { get_ei(prefix_relpaths => { 'site' => { 'elem' => catdir(rootdir, qw/foo bar/)} }) };
	is ($ei, undef, '$ei undefined');
	like($@, qr/Value must be a relative path/, '  emits error if path not relative');
}

{
	my $ei = get_ei(prefix_relpaths => { site => { elem => catdir(qw/foo bar/) } });
 
	my $path = $ei->prefix_relpaths('site', 'elem');
	is($path, catdir(qw(foo bar)), '  can read stored path');
}


# Check that we install into the proper default locations.
{
	my $ei = get_ei();

	test_install_destinations($ei, {
		lib     => catdir($tmp, 'site', @installstyle, 'site_perl'),
		arch	=> catdir($tmp, 'site', @installstyle, 'site_perl', @Config{qw(version archname)}),
		bin     => catdir($tmp, 'site', 'bin'),
		script  => catdir($tmp, 'site', 'bin'),
		bindoc  => catdir($tmp, 'site', 'man', 'man1'),
		libdoc  => catdir($tmp, 'site', 'man', 'man3'),
		binhtml => catdir($tmp, 'site', 'html'),
		libhtml => catdir($tmp, 'site', 'html'),
	}, 'installdirs=site');
	test_install_map($ei, {
		read                      => '',
		write                     => catfile($ei->install_destination('arch'), qw/auto ExtUtils InstallPaths .packlist/),
		catdir('blib', 'lib')     => catdir($tmp, 'site', @installstyle, 'site_perl'),
		catdir('blib', 'arch')    => catdir($tmp, 'site', @installstyle, 'site_perl', @Config{qw(version archname)}),
		catdir('blib', 'bin')     => catdir($tmp, 'site', 'bin'),
		catdir('blib', 'script')  => catdir($tmp, 'site', 'bin'),
	}, 'installdirs=site');
}

# Is installdirs honored?
{
	my $ei = get_ei(installdirs => 'core');
	is($ei->installdirs, 'core');

	test_install_destinations($ei, {
		lib     => catdir($tmp, @installstyle),
		arch	=> catdir($tmp, @installstyle, @Config{qw(version archname)}),
		bin     => catdir($tmp, 'bin'),
		script  => catdir($tmp, 'bin'),
		bindoc  => catdir($tmp, 'man', 'man1'),
		libdoc  => catdir($tmp, 'man', 'man3'),
		binhtml => catdir($tmp, 'html'),
		libhtml => catdir($tmp, 'html'),
	});
}

# Check install_base()
{
	my $install_base = catdir('foo', 'bar');
	my $ei = get_ei(install_base => $install_base);

	is($ei->prefix, undef);
	is($ei->install_base, $install_base);

	test_install_destinations($ei, {
		lib     => catdir($install_base, 'lib', 'perl5'),
		arch	=> catdir($install_base, 'lib', 'perl5', $Config{archname}),
		bin     => catdir($install_base, 'bin'),
		script  => catdir($install_base, 'bin'),
		bindoc  => catdir($install_base, 'man', 'man1'),
		libdoc  => catdir($install_base, 'man', 'man3'),
		binhtml => catdir($install_base, 'html'),
		libhtml => catdir($install_base, 'html'),
	});

	test_install_map($ei, {
		read                      => '',
		write                     => catfile($ei->install_destination('arch'), qw/auto ExtUtils InstallPaths .packlist/),
		catdir('blib', 'lib')     => catdir($install_base, 'lib', 'perl5'),
		catdir('blib', 'arch')    => catdir($install_base, 'lib', 'perl5', $Config{archname}),
		catdir('blib', 'bin')     => catdir($install_base, 'bin'),
		catdir('blib', 'script')  => catdir($install_base, 'bin'),
	}, 'install_base');

	test_install_map($ei, {
		read                       => '',
		write                      => catfile($ei->install_destination('arch'), qw/auto ExtUtils InstallPaths .packlist/),
		catdir('blib', 'lib')     => catdir($install_base, 'lib', 'perl5'),
		catdir('blib', 'arch')    => catdir($install_base, 'lib', 'perl5', $Config{archname}),
		catdir('blib', 'bin')     => catdir($install_base, 'bin'),
		catdir('blib', 'script')  => catdir($install_base, 'bin'),
	}, 'install_base', {
		lib    => catdir(qw/blib lib/),
		arch   => catdir(qw/blib arch/),
		bin    => catdir(qw/blib bin/),
		script => catdir(qw/blib script/),
	});
}


# Basic prefix test.  Ensure everything is under the prefix.
{
	my $prefix = catdir(qw/some prefix/);
	my $ei = get_ei(prefix => $prefix);

	ok(!defined $ei->install_base, 'install_base is not defined');
	is($ei->prefix, $prefix, "The prefix is $prefix");

	test_prefix($ei, $prefix);
#	test_prefix($ei, $prefix, $ei->install_sets('site'));
}

# And now that prefix honors installdirs.
{
	my $prefix = catdir(qw/some prefix/);
	my $ei = get_ei(prefix => $prefix, installdirs => 'core');

	is($ei->installdirs, 'core');
	test_prefix($ei, $prefix);
}

{
	my $ei = get_ei;
# Try a config setting which would result in installation locations outside
# the prefix.  Ensure it doesn't.
	# Get the prefix defaults
	my @types = $ei->install_types;

	# Create a configuration involving weird paths that are outside of
	# the configured prefix.
	my @prefixes = ([qw(foo bar)], [qw(biz)], []);

	my %test_config;
	foreach my $type (@types) {
		my $prefix = shift @prefixes || [qw(foo bar)];
		$test_config{$type} = catdir(rootdir, @$prefix, @{$ei->prefix_relpaths('site', $type)});
	}

	# Poke at the innards of E::IP to change the default install locations.
	my $prefix = catdir('another', 'prefix');
	my $config = ExtUtils::Config->new({ siteprefixexp => catdir(rootdir, 'wierd', 'prefix')});
	$ei = get_ei(install_sets => { site => \%test_config }, config => $config, prefix => $prefix);

	test_prefix($ei, $prefix, \%test_config);
}

# Check that we can use install_base after setting prefix.
{
	my $install_base = catdir('foo', 'bar');
	my $ei = get_ei(install_base => $install_base, prefix => 'whatever');

	test_install_destinations($ei, {
		lib     => catdir($install_base, 'lib', 'perl5'),
		arch	=> catdir($install_base, 'lib', 'perl5', $Config{archname}),
		bin     => catdir($install_base, 'bin'),
		script  => catdir($install_base, 'bin'),
		bindoc  => catdir($install_base, 'man', 'man1'),
		libdoc  => catdir($install_base, 'man', 'man3'),
		binhtml => catdir($install_base, 'html'),
		libhtml => catdir($install_base, 'html'),
	});
}

sub dir_contains {
	my ($first, $second) = @_;
	# File::Spec doesn't have an easy way to check whether one directory
	# is inside another, unfortunately.

	($first, $second) = map { canonpath($_) } ($first, $second);
	my @first_dirs = splitdir($first);
	my @second_dirs = splitdir($second);

	return 0 if @second_dirs < @first_dirs;

	my $is_same = ( case_tolerant() ? sub { lc(shift()) eq lc(shift()) } : sub { shift() eq shift() });

	while (@first_dirs) {
		return 0 unless $is_same->(shift @first_dirs, shift @second_dirs);
	}

	return 1;
}


sub test_prefix {
	my ($ei, $prefix, $test_config) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	foreach my $type (qw/lib arch bin script bindoc libdoc binhtml libhtml/) {
		my $dest = $ei->install_destination($type);
		ok dir_contains($prefix, $dest), "$type prefixed";

		SKIP: {
			skip("'$type' not configured", 1) unless $test_config && $test_config->{$type};

			have_same_ending($dest, $test_config->{$type}, "  suffix correctish ($test_config->{$type} + $prefix = $dest)");
		}
	}
}

sub have_same_ending {
	my ($dir1, $dir2, $message) = @_;

	$dir1 =~ s{/$}{} if $^O eq 'cygwin'; # remove any trailing slash
	my (undef, $dirs1, undef) = splitpath $dir1;
	my @dir1 = splitdir $dirs1;

	$dir2 =~ s{/$}{} if $^O eq 'cygwin'; # remove any trailing slash
	my (undef, $dirs2, undef) = splitpath $dir2;
	my @dir2 = splitdir $dirs2;

	is $dir1[-1], $dir2[-1], $message;
}

sub test_install_destinations {
	my ($build, $expect) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	while(my ($type, $expect) = each %$expect) {
		is($build->install_destination($type), $expect, "$type destination");
	}
}

sub test_install_map {
	my ($paths, $expect, $case, @args) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $map = $paths->install_map(@args);
	while(my ($type, $expect) = each %$expect) {
		is($map->{$type}, $expect, "$type destination for $case");
	}
}
