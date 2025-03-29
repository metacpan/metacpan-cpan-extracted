package ExtUtils::Builder::ParseXS;
$ExtUtils::Builder::ParseXS::VERSION = '0.026';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/abs2rel curdir catfile catdir splitdir/;

use ExtUtils::Builder::Util 'function';

sub add_methods {
	my ($self, $planner, %options) = @_;

	my $config = $options{config} // ($planner->can('config') ? $planner->config : ExtUtils::Config->new);

	$planner->add_delegate('parse_xs', sub {
		my (undef, $source, $destination, %options) = @_;

		my @actions;
		if ($options{mkdir}) {
			my $dirname = dirname($destination);
			push @actions, function(
				module    => 'File::Path',
				function  => 'make_path',
				arguments => [ $dirname ],
				exports   => 'explicit',
				message   => "mkdir $dirname",
			);
		}
		my %args = (
			filename     => $source,
			output       => $destination,
			prototypes   => 0,
			die_on_error => 1,
		);
		$args{$_} = $options{$_} for grep { defined $options{$_} } qw/typemap hiertype versioncheck linenumbers optimize prototypes/;

		push @actions, function(
			module    => 'ExtUtils::ParseXS',
			function  => 'process_file',
			arguments => [ %args ],
			message   => "parse-xs $source",
		);

		my @dependencies = @{ $options{dependencies} // [] };
		$args{typemap} //= 'typemap' if -f 'typemap';
		push @dependencies, $args{typemap} if $args{typemap};

		$planner->create_node(
			target       => $destination,
			dependencies => [ $source, @dependencies ],
			actions      => \@actions,
		);
	});

	$planner->add_delegate('c_file_for_xs', sub {
		my (undef, $source, $outdir) = @_;
		$outdir //= dirname($source);
		my $file_base = basename($source, '.xs');
		return catfile($outdir, "$file_base.c");
	});

	$planner->add_delegate('module_for_xs', sub {
		my (undef, $source, $relative) = @_;
		my @parts = splitdir(dirname(abs2rel($source, $relative)));
		push @parts, basename($source, '.xs');
		return join '::', @parts;
	});

	require DynaLoader;
	my $mod2fname = defined &DynaLoader::mod2fname ? \&DynaLoader::mod2fname : sub { return $_[0][-1] };

	$planner->add_delegate('extension_filename', sub {
		my (undef, $module) = @_;
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

version 0.026

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

=item * typemap

The name of the typemap file. Defaults to C<typemap> if that file exists.

=item * hiertype

Allow hierarchical types (with double colons) such as used in C++.

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
