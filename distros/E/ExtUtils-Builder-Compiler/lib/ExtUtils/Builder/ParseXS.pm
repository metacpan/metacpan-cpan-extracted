package ExtUtils::Builder::ParseXS;
$ExtUtils::Builder::ParseXS::VERSION = '0.012';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/curdir catfile catdir splitdir/;

sub add_methods {
	my ($self, $planner, %options) = @_;

	my $config = $options{config} || ($planner->can('config') ? $planner->config : ExtUtils::Config->new);

	$self->add_delegate($planner, 'parse_xs', sub {
		my ($source, $destination, %options) = @_;

		my @actions;
		if ($options{mkdir}) {
			my $dirname = dirname($destination);
			push @actions, ExtUtils::Builder::Action::Function->new(
				module    => 'File::Path',
				function  => 'make_path',
				arguments => [ $dirname ],
				exports   => 'explicit',
				message   => "mkdir $dirname",
			);
		}
		push @actions, ExtUtils::Builder::Action::Function->new(
			module    => 'ExtUtils::ParseXS',
			function  => 'process_file',
			arguments => [ filename => $source, prototypes => 0, output => $destination ],
			message   => "parse-xs $source",
		);

		my @dependencies = @{ $options{dependencies} || [] };

		ExtUtils::Builder::Node->new(
			target       => $destination,
			dependencies => [ $source, @dependencies ],
			actions      => \@actions,
		);
	});

	$self->add_helper($planner, 'c_file_for_xs', sub {
		my ($source, $outdir) = @_;
		$outdir ||= dirname($source);
		my $file_base = basename($source, '.xs');
		return catfile($outdir, "$file_base.c");
	});

	$self->add_helper($planner, 'module_for_xs', sub {
		my ($source, $relative) = @_;
		my @parts = splitdir(dirname(abs2rel($source, $relative)));
		push @parts, basename($source, '.xs');
		return join '::', @parts;
	});

	require DynaLoader;
	my $mod2fname = defined &DynaLoader::mod2fname ? \&DynaLoader::mod2fname : sub { return $_[0][-1] };

	$self->add_helper($planner, 'extension_filename', sub {
		my ($module) = @_;
		my @parts = split '::', $module;
		my $archdir = catdir(qw/blib arch auto/, @parts);

		my $basename = $mod2fname->(\@parts);
		my $filename = "$basename." . $config->get('dlext');
		return catfile($archdir, $filename);
	});
}

1;

# ABSTRACT: Essential functions for implementing XS in a Plan

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::ParseXS - Essential functions for implementing XS in a Plan

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 $planner->load_module("ExtUtils::Builder::ParseXS");
 $planner->parse_xs("foo.xs", "foo.c");

=head1 DESCRIPTION

This module implements several helper methods used in implementing XS.

It takes one optional argument C<config>, which should be an C<ExtUtils::Config> compatible object. If your C<$planner> has a C<config> delegate, that will be used as default value.

=head2 DELEGATES

=head3 parse_xs($source, $destination, %options)

This will parse the XS file C<$source> and write the resulting C file to C<$destination>.

=over 4

=item * mkdir

If set this will mkdir the base of the target before running the parse.

=item * dependencies

This lists additional dependencies that will be added to the target.

=back

=head3 c_file_for_xs($filename, $dir = dirname($filename))

This returns the path to the C file for a certain XS file.

=head3 module_for_xs($filename)

This returns the module corresponding to a specific XS files.

=head3 extension_filename($module_name)

This will return the path for the loadable object of an extension for C<$module>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
