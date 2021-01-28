package Test::CheckDeps;
{
  $Test::CheckDeps::VERSION = '0.010';
}
use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT = qw/check_dependencies/;
our @EXPORT_OK = qw/check_dependencies_opts/;
our %EXPORT_TAGS = (all => [ @EXPORT, @EXPORT_OK ] );

use CPAN::Meta 2.120920;
use CPAN::Meta::Check 0.007 qw/check_requirements requirements_for/;
use List::Util qw/first/;
use Test::Builder;

my $builder = Test::Builder->new;

my %level_of = (
	requires   => 0,
	classic    => 1,
	recommends => 2,
	suggests   => 3,
);

sub check_dependencies {
	my $level = $level_of{shift || 'classic'};
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $metafile = first { -e $_ } qw/MYMETA.json MYMETA.yml META.json META.yml/ or return $builder->ok(0, "No META information provided\n");
	my $meta = CPAN::Meta->load_file($metafile);
	check_dependencies_opts($meta, $_, 'requires') for qw/configure build test runtime/;
	check_dependencies_opts($meta, 'runtime', 'conflicts') if $level >= $level_of{classic};
	if ($level >= $level_of{recommends}) {
		$builder->todo_start('recommends are not mandatory');
		check_dependencies_opts($meta, $_, 'recommends') for qw/configure build test runtime/;
		$builder->todo_end();

		if ($level >= $level_of{suggests}) {
			$builder->todo_start('suggests are not mandatory');
			check_dependencies_opts($meta, $_, 'suggests') for qw/configure build test runtime/;
			$builder->todo_end();
		}
	}
	check_dependencies_opts($meta, 'develop', 'requires') if $ENV{AUTHOR_TESTING};

	return;
}

sub check_dependencies_opts {
	my ($meta, $phases, $type) = @_;

	my $reqs = requirements_for($meta, $phases, $type);
	my $raw = $reqs->as_string_hash;
	my $ret = check_requirements($reqs, $type);

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	for my $module (sort keys %{$ret}) {
		$builder->ok(!defined $ret->{$module}, "$module satisfies '" . $raw->{$module} . "'")
			or $builder->diag($ret->{$module});
			# Note: when in a TODO, diag behaves like note
	}
	return;
}

1;

#ABSTRACT: Check for presence of dependencies

# vim: set ts=2 sw=2 noet nolist :

__END__

=pod

=head1 NAME

Test::CheckDeps - Check for presence of dependencies

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 use Test::More 0.94;
 use Test::CheckDeps 0.007;
 
 check_dependencies();

 done_testing();

=head1 DESCRIPTION

This module adds a test that assures all dependencies have been installed properly. If requested, it can bail out all testing on error.

=head1 FUNCTIONS

=head2 check_dependencies( [ level ])

Check dependencies based on a local MYMETA or META file.

The C<level> argument is optional. It can be one of:

=over 4

=item * requires

All 'requires' dependencies are checked (the configure, build, test and
runtime phases are always checked, and the develop phase is also tested when
AUTHOR_TESTING is set)

=item * classic

As C<requires>, but 'conflicts' dependencies are also checked.

=item * recommends

As C<classic>, but 'recommends' dependencies are also checked, as TODO tests.

=item * suggests

As C<recommends>, but 'suggests' dependencies are also checked, as TODO tests.

=back

When not provided, C<level> defaults to C<classic> ('requires' and 'conflicts'
dependencies are checked).

=head2 check_dependencies_opts($meta, $phase, $type)

Check dependencies in L<CPAN::Meta> object $meta for phase C<$phase> (configure, build, test, runtime, develop) and type C<$type>(requires, recommends, suggests, conflicts). You probably just want to use C<check_dependencies> though.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
