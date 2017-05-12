package Dist::Zilla::Role::ModuleIncluder;
$Dist::Zilla::Role::ModuleIncluder::VERSION = '0.008';
# vim: ts=4 sts=0 sw=0 noet
use Moose::Role;
use MooseX::Types::Moose qw/Bool/;

use Dist::Zilla::File::InMemory 5.000;
use File::Slurper 'read_binary';
use Scalar::Util qw/reftype/;
use List::Util 1.45 'uniq';
use Module::CoreList 5.20160520;
use Module::Metadata;
use Perl::PrereqScanner;

use namespace::autoclean;

with 'Dist::Zilla::Role::FileInjector';

sub _mod_to_filename {
	my $module = shift;
	return File::Spec->catfile('inc', split / :: | ' /x, $module) . '.pm';
}

my $version = \%Module::CoreList::version;

## no critic (Variables::ProhibitPackageVars)

has include_dependencies => (
	is => 'ro',
	isa => Bool,
	default => 1,
);

{
	# cache of Module::Metadata objects
	my %module_files;
	sub _find_module_by_name {
		my $module = shift;
		return $module_files{$module} if exists $module_files{$module};
		$module_files{$module} = Module::Metadata->find_module_by_name($module)
			or confess "Can't locate $module";
	}
}

around dump_config => sub
{
	my ($orig, $self) = @_;
	my $config = $self->$orig;

	my $data = {
		version => __PACKAGE__->VERSION || '<self>',
		include_dependencies => ($self->include_dependencies ? 1 : 0),
		'Module::CoreList' => Module::CoreList->VERSION,
	};
	$config->{+__PACKAGE__} = $data;

	return $config;
};

sub _get_reqs {
	my ($self, $reqs, $scanner, $module, $background, $blacklist) = @_;
	my $module_file = _find_module_by_name($module);
	my %new_reqs = %{ $scanner->scan_file($module_file)->as_string_hash };
	$self->log_debug([ 'found dependency of %s: %s %s', $module, $_, $new_reqs{$_} ]) foreach keys %new_reqs;

	my @real_reqs = grep {
		!$blacklist->{$_} && !Module::CoreList::is_core($_, $new_reqs{$_} ? $new_reqs{$_} : undef, $background)
	} keys %new_reqs;
	for my $req (@real_reqs) {
		if (defined $reqs->{$module}) {
			next if $reqs->{$module} >= $new_reqs{$req};
			$reqs->{$req} = $new_reqs{$req};
		}
		else {
			$reqs->{$req} = $new_reqs{$req};
			$self->_get_reqs($reqs, $scanner, $req, $background, $blacklist);
		}
		$self->log_debug([ 'adding to requirements list: %s %s', $req, $new_reqs{$req} ]);
	}
	return;
}

sub _version_normalize {
	my $version = shift;
	return $version >= 5.010 ? sprintf "%1.6f", $version->numify : $version->numify;
}

sub include_modules {
	my ($self, $modules, $background, $options) = @_;
	my %modules = reftype($modules) eq 'HASH' ? %{$modules} : map { $_ => 0 } @{$modules};
	my %reqs;
	my $scanner = Perl::PrereqScanner->new;
	my %blacklist = map { ( $_ => 1 ) } 'perl', @{ $options->{blacklist} || [] };
	if ($self->include_dependencies) {
		$self->_get_reqs(\%reqs, $scanner, $_, _version_normalize($background), \%blacklist) for keys %modules;
	}
	my @modules = grep { !$modules{$_} } keys %modules;
	my %location_for = map { _mod_to_filename($_) => _find_module_by_name($_) } uniq(@modules, keys %reqs);
	return map {
		my $filename = $_;
		$self->log_debug([ 'copying for inclusion: %s', $location_for{$filename} ]);
		my $file = Dist::Zilla::File::InMemory->new({name => $filename, encoded_content => read_binary($location_for{$filename})});
		$self->add_file($file);
		$file;
	} keys %location_for;
}

1;

#ABSTRACT: Include modules and their dependencies in inc/

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ModuleIncluder - Include modules and their dependencies in inc/

=head1 VERSION

version 0.008

=head1 DESCRIPTION

This role allows your plugin to include one or more modules into the distribution for build time purposes. The modules will not be installed.

=head1 ATTRIBUTES

=head2 include_dependencies

This decides if dependencies should be included as well. This defaults to true.

=head1 METHODS

=head2 include_modules($modules, $background_perl, $options)

Include all modules (and possibly their dependencies) in C<@$modules>, in F<inc/>, except those that are core modules as of perl version C<$background_perl> (which is expected to be a version object). C<$options> is a hash that currently has only one possible key, C<blacklist>, to specify dependencies that shouldn't be included.

All the file objects that were added to the distribution are returned as a list.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
