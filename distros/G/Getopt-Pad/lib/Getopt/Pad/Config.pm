use v5.26;
use Object::Pad;

use Getopt::Pad::Error;

class Getopt::Pad::Config :strict(params) {
	use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
	use Feature::Compat::Try;
	use Getopt::Pad::Util qw(expandTilde);

	our $VERSION = '0.03';

	field $format      :param;
	field $formatName  :param;
	field $paths       :param;
	field $defaultPath :param;
	field $autoload    :param;

	# Config files are UTF-8 on disk. The layer is applied here, on every
	# read and write, so a Format only ever sees text.
	my $fileLayer = ':encoding(UTF-8)';

	method explicitValues($level, $rawPath) {
		my $path = length $rawPath ? $rawPath : $defaultPath;
		Getopt::Pad::Error->throw("--config without a path, and the spec sets no defaultPath") if !defined $path || !length $path;
		return $self->loadFile($level, $path, 1);
	}

	method autoloadValues($level) {
		return {} if !$autoload;

		my %merged;
		foreach my $path ($paths->@*) {
			next if !-e expandTilde($path);
			%merged = (%merged, $self->loadFile($level, $path, 0)->%*);
		}
		return \%merged;
	}

	method loadFile($level, $path, $isExplicit) {
		my $expanded = expandTilde($path);
		Getopt::Pad::Error->throw("config file '%s' does not exist", $path) if $isExplicit && !-e $expanded;

		my $text = $self->readText($path, $expanded);
		my $data;
		try {
			$data = $format->parse($text);
		}
		catch ($error) {
			# The parser's message is for the end user; the Perl source
			# location it ends with is not.
			my $message = "$error" =~ s/ at \S+ line \d+\.?\s*\z//r =~ s/\s+\z//r;
			Getopt::Pad::Error->throw("config file '%s': %s", $path, $message);
		}

		Getopt::Pad::Error->throw("config file '%s' must contain a mapping of group names", $path) if ref $data ne 'HASH';
		return $self->flattenData($level, $path, $data);
	}

	method readText($path, $expanded) {
		open my $handle, "<$fileLayer", $expanded or Getopt::Pad::Error->throw("cannot read config file '%s': %s", $path, $!);
		local $/;
		my $text = readline($handle);
		close $handle;
		return $text // '';
	}

	# Creates the file exclusively: an existing file, or a symlink to
	# anywhere, is refused by the open itself, so nothing can slip in
	# between a check and the creation. Windows follows a dangling symlink
	# even then, so symlinks are refused up front as well. The file is
	# written raw under the encoding layer: LF line endings everywhere.
	method createFile($path, $expanded, $text) {
		Getopt::Pad::Error->throw("config file '%s' already exists", $path) if -l $expanded;
		sysopen(my $handle, $expanded, O_WRONLY | O_CREAT | O_EXCL) or do {
			Getopt::Pad::Error->throw("config file '%s' already exists", $path) if $!{EEXIST};
			Getopt::Pad::Error->throw("cannot write config file '%s': %s", $path, $!);
		};
		binmode $handle, ":raw$fileLayer";
		print {$handle} $text;
		close $handle or Getopt::Pad::Error->throw("cannot write config file '%s': %s", $path, $!);
		return;
	}

	# Config files are structured by group: each top-level key is a group name
	# holding a mapping of option names. Flatten that to option => value,
	# validating group membership on the way.
	method flattenData($level, $path, $data) {
		my %flat;
		foreach my $group (sort keys $data->%*) {
			my $entries = $data->{$group};
			Getopt::Pad::Error->throw("config file '%s': group '%s' must contain a mapping of option names", $path, $group) if ref $entries ne 'HASH';

			foreach my $name (sort keys $entries->%*) {
				my $option = $level->optionByName($name);
				if (!defined $option || $option->auto) {
					my $hint = $level->hasCommands ? ' (config files set top-level options only)' : '';
					Getopt::Pad::Error->throw("config file '%s': unknown option '%s' in group '%s'%s", $path, $name, $group, $hint);
				}
				Getopt::Pad::Error->throw("config file '%s': option '%s' belongs to group '%s', not '%s'", $path, $name, $option->group, $group) if $option->group ne $group;
				$flat{$name} = $entries->{$name};
			}
		}
		return \%flat;
	}

	method writeDefaultFile($level, $target) {
		Getopt::Pad::Error->throw("config format '%s' cannot write config files", $formatName) if !$format->can('dump');

		my %defaults;
		$defaults{$_->group}{$_->name} = $_->default foreach grep { $_->hasDefault } $level->declaredOptions;

		# Serialize first, so a failing dump leaves no empty file behind.
		my $text = $format->dump(\%defaults);
		$self->createFile($target, expandTilde($target), $text);
		return $target;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config - grouped config file reader and writer

=head1 DESCRIPTION

The one owner of the grouped config file structure (group, then option name, then value): loads a file named by an explicit --config (falling back to the defaultPath), merges the autoload chain (later paths override earlier ones), validates group membership while flattening to option/value pairs, and writes the default config file for --create-default-config. It also owns the files themselves: every config file is read and written here as UTF-8, and the Format only translates between that text and the data structure. The default config file is created exclusively (O_EXCL), so an existing file or a symlink at the target is refused without a check-then-create gap (a symlink is also refused explicitly, since Windows follows a dangling one even with O_EXCL), and written with LF line endings on every platform. A parse error is reported without the Perl source location the parser appended. Handed out by the config block via its io reader.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
