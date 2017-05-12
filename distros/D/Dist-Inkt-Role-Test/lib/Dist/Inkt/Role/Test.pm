use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use File::chdir;
use Try::Tiny;
use Types::Standard -types;
use namespace::autoclean;

for my $category (qw( prebuild_test build_test tarball_test ))
{
	has "${category}s" => (
		traits   => ["Array"],
		is       => "ro",
		isa      => ArrayRef[CodeRef],
		default  => sub { [] },
		handles  => { "setup_${category}" => "push" },
		init_arg => undef,
		lazy     => 1,
	);
	
	has "skip_${category}s" => (
		is       => "ro",
		isa      => Bool,
		default  => 0,
	);
}

has _build_tests_already_run => (is => "rw", isa => Bool, default => 0);

before BuildTargets => sub
{
	my $self = shift;
	
	return unless @{$self->prebuild_tests};
	return $self->log("Skipping pre-build tests")
		if $self->skip_prebuild_tests;
	$self->log("Running pre-build tests...");
	
	my $die = 0;
	for my $test (@{ $self->prebuild_tests })
	{
		try {
			$self->$test();
		}
		catch {
			$self->log("ERROR: $_");
			++$die;
		};
	}
	die "Failed pre-build test; stopped" if $die;
	
	$self->_build_tests_already_run(0); # reset bool
};

my $tmp = sub
{
	my $self = shift;
	return if $self->_build_tests_already_run;
	
	return unless @{$self->build_tests};
	return $self->log("Skipping build tests")
		if $self->skip_build_tests;
	$self->log("Running build tests...");
	
	my $die = 0;
	my $dir = $self->targetdir->absolute;
	for my $test (@{ $self->build_tests })
	{
		try {
			local $CWD = $dir->stringify;
			$self->$test($dir);
		}
		catch {
			$self->log("ERROR: $_");
			++$die;
		};
	}
	die "Failed build test; stopped" if $die;
	
	$self->_build_tests_already_run(1);
};
# Numerous opportunities to try to run these tests
after [qw/BuildManifest BuildAll/] => $tmp;
before [qw/BuildTarball/] => $tmp;

after BuildTarball => sub
{
	my $self = shift;
	
	return unless @{$self->tarball_tests};
	return $self->log("Skipping tarball tests")
		if $self->skip_tarball_tests;
	$self->log("Running tarball tests...");
	
	my $die  = 0;
	my $file = Path::Tiny::path($_[0] || sprintf('%s.tar.gz', $self->targetdir));
	
	for my $test (@{ $self->tarball_tests })
	{
		try {
			$self->$test($file);
		}
		catch {
			$self->log("ERROR: $_");
			++$die;
		};
	}
	die "Failed tarball test; stopped" if $die;
	
	$self->_build_tests_already_run(1);
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Role::Test - run various tests on a distribution at build time

=head1 SYNOPSIS

   package Dist::Inkt::Profile::JOEBLOGGS;
   
   use Moose;
   extends qw(Dist::Inkt);
   with (
      ...,
      "Dist::Inkt::Role::Test",
      ...,
   );
   
   after BUILD => sub {
      my $self = shift;
      
      # Run a test before attempting to build
      # the dist dir.
      #
      $self->setup_prebuild_test(sub {
         die "rude!" if $self->name =~ /Arse/;
      });
      
      # Run a test after building the dist dir.
      #
      $self->setup_build_test(sub {
         die "missing change log" unless -f "Changes";
      });
      
      # Run a test after tarballing the dist dir.
      #
      $self->setup_tarball_test(sub {
         my $tarball = $_[1]
         die "too big" if $tarball->stat->size > 1_000_000;
      });
   };
   
   1;

=head1 DESCRIPTION

This role exists to provide hooks for L<Dist::Inkt> subclasses and
other roles to run tests.

Bundled with this role are a few other roles that consume it in
useful ways.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt-Role-Test>.

=head1 SEE ALSO

L<Dist::Inkt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

