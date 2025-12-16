package ExtUtils::Builder::MakeMaker;
$ExtUtils::Builder::MakeMaker::VERSION = '0.019';
use strict;
use warnings;

our @ISA;

use ExtUtils::MakeMaker 6.68;
use ExtUtils::Builder::Planner;
use ExtUtils::Builder::Util 'unix_to_native_path';
use ExtUtils::Config::MakeMaker;
use ExtUtils::Manifest ();
use version ();

sub import {
	my ($class, @args) = @_;
	if (!MM->isa(__PACKAGE__)) {
		@ISA = @MM::ISA;
		@MM::ISA = __PACKAGE__;
		splice @ExtUtils::MakeMaker::Overridable, -1, 0, 'make_plans';
	}
	return;
}

my $escape_command = sub {
	my ($maker, $elements) = @_;
	return join ' ', map { (my $temp = m{[^\w/\$().-]} ? $maker->quote_literal($_) : $_) =~ s/\n/\\\n\t/g; $temp } @{$elements};
};

my %double_colon = map { $_ => 1 } qw/all pure_all subdirs config dynamic static clean distdir test install/;
my $make_entry = sub {
	my ($maker, $target, $dependencies, $actions) = @_;
	my @commands = map { $maker->$escape_command($_) } map { $_->to_command(perl => '$(ABSPERLRUN)') } @{$actions};
	my @dependencies = map { $maker->quote_dep($_) } @{$dependencies};
	my $colon = $double_colon{$target} ? '::' : ':';
	return join "\n\t", join(' ', $target, $colon, @dependencies), @commands;
};

sub postamble {
	my ($maker, %args) = @_;
	my @ret = split "\n\n", $maker->SUPER::postamble(%args);

	my $planner = ExtUtils::Builder::Planner->new;
	$planner->add_delegate('makemaker', sub { $maker });
	$planner->load_extension('ExtUtils::Builder::CPAN::Tool');
	my $config = ExtUtils::Config::MakeMaker->new($maker);
	$planner->add_delegate('config', sub { $config });
	$planner->add_delegate('distribution', sub { $maker->{DIST_NAME} });
	$planner->add_delegate('version', sub { version->new($maker->{VERSION}) });
	$planner->add_delegate('main_module', sub { $maker->{NAME} });
	$planner->add_delegate('pureperl_only', sub { $maker->{PUREPERL_ONLY} });
	$planner->add_delegate('perl_path', sub { $maker->{ABSPERLRUN} });
	$planner->add_delegate('uninst', sub { $maker->{UNINST} });

	$planner->add_seen(unix_to_native_path($_)) for sort keys %{ ExtUtils::Manifest::maniread() };

	$maker->make_plans($planner, %args) if $maker->can('make_plans');
	for my $file (glob 'planner/*.pl') {
		$planner->new_scope->run_dsl($file);
	}

	my $plan = $planner->materialize;
	push @ret, map { $maker->$make_entry($_->target, [ $_->dependencies ], [ $_ ]) } $plan->nodes;

	if ($maker->is_make_type('gmake') || $maker->is_make_type('bsdmake')) {
		my @phonies = grep { !$double_colon{$_} } $plan->phonies;
		push @ret, $maker->$make_entry('.PHONY', \@phonies) if @phonies
	}

	return join "\n\n", @ret;
}

1;

#ABSTRACT: A MakeMaker consumer for ExtUtils::Builder Plan objects

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::MakeMaker - A MakeMaker consumer for ExtUtils::Builder Plan objects

=head1 VERSION

version 0.019

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use ExtUtils::Builder::MakeMaker;
 ...
 WriteMakeFile(
   NAME => 'Foo',
   VERSION => 0.001,
 );

 sub MY::make_plans {
   my ($self, $planner) = @_;
   $planner->load_extension('Some::Module');
   ... # Add plans to $planner
 }

=head1 DESCRIPTION

This MakeMaker extension will call any C<.pl> files in C</planner> as DSL files, these are run in a new scope so delegates don't leak out; these entries will be added to your Makefile.. It will also call your C<MY::make_plans> method with a L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner> as argument so that you can customize the build in the F<Makefile.PL> itself. Typically one would make their target a dependency of a MakeMaker entry like C<code> (for perl) or C<dynamic> (for XS).

=head1 DELEGATES

This will define all delegates of L<ExtUtils::Builder::CPAN::Tool> in your L<planner|ExtUtils::Builder::Planner>:

=over 4

=item * meta

A L<CPAN::Meta|CPAN::Meta> object representing the C<META.json> file.

=item * distribution

The name of the distribution

=item * version

The version of the distribution

=item * main_module

The main module of the distribution.

=item * release_status

The release status of the distribution (e.g. C<'stable'>).

=item * perl_path

The path to the perl executable.

=item * config

The L<ExtUtils::Config::MakeMaker|ExtUtils::Config::MakeMaker> object for this build

=item * is_os(@os_names)

This returns true if the current operating system matches any of the listed ones.

=item * is_os_type($os_type)

This returns true if the type of the OS matches C<$os_type>. Legal values are C<Unix>, C<Windows> and C<VMS>.

=item * verbose

This is always false.

=item * uninst

The value of the C<uninst> command line argument.

=item * jobs

This is always C<1>.

=item * pureperl_only

The value of the C<PUREPERL_ONLY> command line argument.

=back

These are the same ones as L<Dist::Build> sets except C<install_paths> is missing.

=for Pod::Coverage postamble

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
