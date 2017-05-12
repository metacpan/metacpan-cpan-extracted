use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test::TestSuite;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Types::Standard -types;
use File::chdir;
use namespace::autoclean;

with qw(Dist::Inkt::Role::Test);

has is_xs => (is => "ro", isa => Bool, lazy => 1, builder => "_build_is_xs");

sub _build_is_xs {
	my $self = shift;
	!!grep { $_->is_file and /\.(xs|c|h)$/ } $self->rootdir->children;
}

my $_test_suite_via_prove = sub
{
	my $self = shift;
	local $CWD = $self->rootdir;
	local $ENV{RELEASE_TESTING}  = 1;
	local $ENV{EXTENDED_TESTING} = 1;
	require App::Prove;
	my $app = App::Prove->new;
	$app->process_args(qw( -Iinc -Ilib -r ), grep -d, qw( t xt ));
	$app->run;
};

my $_test_suite_via_maketest = sub
{
	my $self = shift;
	require Path::Tiny;
	require File::Copy;
	
	my $temp = Path::Tiny->tempdir;
	$self->log("Copying dist to $temp");
	system("cp", "-r", $self->targetdir, $temp);
	local $CWD = $temp->child( $self->targetdir->basename );
	local $ENV{RELEASE_TESTING}  = 1;
	local $ENV{EXTENDED_TESTING} = 1;
	die "`perl Makefile.PL` failed" if system("perl", "Makefile.PL");
	die "`make test` failed"        if system("make", "test");
	return 1;
};

after BUILD => sub {
	my $self = shift;
	
	$self->setup_prebuild_test(sub {
		return if $self->is_xs;
		$self->$_test_suite_via_prove(@_)
			or die("failed test suite!");
	});
	
	$self->setup_build_test(sub {
		return unless $self->is_xs;
		$self->$_test_suite_via_maketest(@_)
			or die("failed test suite!");
	});
};

1;

