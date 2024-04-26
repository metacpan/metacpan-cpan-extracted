package ExtUtils::Builder::MakeMaker;
$ExtUtils::Builder::MakeMaker::VERSION = '0.002';
use strict;
use warnings;

our @ISA;

use ExtUtils::MakeMaker;
use ExtUtils::Builder::Planner;
use ExtUtils::Config::MakeMaker;

sub import {
	my ($class, @args) = @_;
	if (!MM->isa('ExtUtils::Builder::MakeMaker')) {
		@ISA = @MM::ISA;
		@MM::ISA = qw/ExtUtils::Builder::MakeMaker/;
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
	my $quote_dep = $maker->can('quote_dep') || sub { $_[1] };
	my @dependencies = map { $maker->$quote_dep($_) } @{$dependencies};
	my $colon = $double_colon{$target} ? '::' : ':';
	return join "\n\t", join(' ', $target, $colon, @dependencies), @commands;
};

sub postamble {
	my ($maker, %args) = @_;
	my @ret = split "\n\n", $maker->SUPER::postamble(%args);

	my $planner = ExtUtils::Builder::Planner->new;
	$planner->add_delegate('makemaker', sub { $maker });
	my $config = ExtUtils::Config::MakeMaker->new($maker);
	$planner->add_delegate('config', sub { $config });
	$planner->add_delegate('dist_name', sub { $maker->{DIST_NAME} });
	$planner->add_delegate('dist_version', sub { $maker->{VERSION} });
	$planner->add_delegate('pureperl_only', sub { $maker->{PUREPERL_ONLY} });
	$planner->add_delegate('release_status', sub { $maker->{VERSION} =~ /_/ ? 'unstable' : 'stable' });

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

version 0.002

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
   $planner->load_module('Some::Module');
   ... # Add plans to $planner
 }

=head1 DESCRIPTION

This MakeMaker extension will call your C<MY::make_plans> method with a L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner> as argument so that you can add entries to it; these entries will be added to your Makefile. It will also call any C<.pl> files in C</planner> as DSL files, these are run in a new scope so delegates don't leak out. Entries may depend on existing MakeMaker entries and vice-versa. Typically one would make their target a dependency of a MakeMaker entry like C<pure_all> or C<dynamic>.

=for Pod::Coverage postamble

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
