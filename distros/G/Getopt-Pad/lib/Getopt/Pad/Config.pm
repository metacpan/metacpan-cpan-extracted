use v5.26;
use Object::Pad;

use Getopt::Pad::Error;

class Getopt::Pad::Config :strict(params) {
	use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
	use Feature::Compat::Try;
	use Getopt::Pad::Util qw(expandTilde);

	our $VERSION = '0.05';

	field $format      :param;
	field $formatName  :param;
	field $paths       :param;
	field $defaultPath :param;
	field $autoload    :param;

	# The key of a Level's section that holds its command sections.
	use constant COMMANDS_KEY => 'commands';

	# Config files are UTF-8 on disk. The layer is applied here, on every
	# read and write, so a Format only ever sees text.
	my $fileLayer = ':encoding(UTF-8)';

	# Every load returns the option values each Level of the Spec gets from
	# config files, keyed by Level path (the root's is ''): a mapping of
	# Primary names to raw values per Level.
	method explicitValues($root, $rawPath) {
		my $path = length $rawPath ? $rawPath : $defaultPath;
		Getopt::Pad::Error->throw("--config without a path, and the spec sets no defaultPath") if !defined $path || !length $path;
		return $self->loadFile($root, $path, 1);
	}

	# Later files override earlier ones option by option, on every Level.
	method autoloadValues($root) {
		return {} if !$autoload;

		my %merged;
		foreach my $path ($paths->@*) {
			next if !-e expandTilde($path);
			my $loaded = $self->loadFile($root, $path, 0);
			$merged{$_} = { ($merged{$_} // {})->%*, $loaded->{$_}->%* } foreach keys $loaded->%*;
		}
		return \%merged;
	}

	method loadFile($root, $path, $isExplicit) {
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
		return $self->levelValues($root, $path, $data);
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

	# A config file mirrors the Level tree. Each key of a Level's section is
	# a group name holding a mapping of option names, except the
	# COMMANDS_KEY of a Level with commands: it holds one section per
	# command name. Every section is validated, whether this run selects
	# its Level or not; the values are checked by the Levels that are.
	method levelValues($level, $path, $section) {
		my %groups         = $section->%*;
		my $hasCommandsKey = $level->hasCommands && exists $groups{+COMMANDS_KEY};
		my %valuesBelow    = $hasCommandsKey ? $self->commandValues($level, $path, delete $groups{+COMMANDS_KEY})->%* : ();
		my %values         = map { $self->groupValues($level, $path, $_, $groups{$_})->%* } sort keys %groups;
		return { %valuesBelow, $level->path => \%values };
	}

	method commandValues($level, $path, $sections) {
		Getopt::Pad::Error->throw("config file '%s': '%s'%s must contain a mapping of command names", $path, COMMANDS_KEY, $self->ofCommand($level)) if ref $sections ne 'HASH';

		my %valuesBelow;
		foreach my $name (sort keys $sections->%*) {
			my $command = $level->command($name);
			if (!defined $command) {
				my $wordPath = $level->isRoot ? $name : $level->path . ' ' . $name;
				Getopt::Pad::Error->throw("config file '%s': unknown command '%s', expected one of: %s", $path, $wordPath, join(', ', $level->commandNames));
			}

			my $section = $sections->{$name};
			Getopt::Pad::Error->throw("config file '%s': command '%s' must contain a mapping of group names", $path, $command->path) if ref $section ne 'HASH';
			%valuesBelow = (%valuesBelow, $self->levelValues($command, $path, $section)->%*);
		}
		return \%valuesBelow;
	}

	method groupValues($level, $path, $group, $entries) {
		my $ofCommand = $self->ofCommand($level);
		Getopt::Pad::Error->throw("config file '%s': group '%s'%s must contain a mapping of option names", $path, $group, $ofCommand) if ref $entries ne 'HASH';

		foreach my $name (sort keys $entries->%*) {
			my $option = $level->optionByName($name);
			Getopt::Pad::Error->throw("config file '%s': unknown option '%s' in group '%s'%s", $path, $name, $group, $ofCommand) if !defined $option || $option->auto;
			Getopt::Pad::Error->throw("config file '%s': option '%s'%s belongs to group '%s', not '%s'", $path, $name, $ofCommand, $option->group, $group) if $option->group ne $group;
		}
		return { $entries->%* };
	}

	method ofCommand($level) {
		return $level->isRoot ? '' : sprintf(" of command '%s'", $level->path);
	}

	method writeDefaultFile($root, $target) {
		Getopt::Pad::Error->throw("config format '%s' cannot write config files", $formatName) if !$format->can('dump');

		# Serialize first, so a failing dump leaves no empty file behind.
		my $text = $format->dump($self->defaultSection($root));
		$self->createFile($target, expandTilde($target), $text);
		return $target;
	}

	# The defaults of $level and every Level below it, in the config file
	# structure. Groups and command sections without defaults are left out.
	method defaultSection($level) {
		my %section;
		$section{$_->group}{$_->name} = $_->default foreach grep { $_->hasDefault } $level->declaredOptions;
		foreach my $name ($level->commandNames) {
			my $commandSection = $self->defaultSection($level->command($name));
			$section{+COMMANDS_KEY}{$name} = $commandSection if %$commandSection;
		}
		return \%section;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config - Reads and writes config files (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

The only module that knows the layout of config files (described for
users in L<Getopt::Pad/File layout>): a section per level, holding its
groups (group, then option name, then value), and on a level with
commands a C<commands> key holding one such section per command, as deep
as the commands are nested.

It is created by L<Getopt::Pad::Spec::Config> and handed out through its
C<io> reader.

=head2 Loading

C<explicitValues($root, $path)> loads the file given with C<--config>
(or C<defaultPath> for a bare C<--config>). C<autoloadValues($root)>
loads every existing file in C<paths>, a later file overriding an earlier
one option by option on every level. Both return the raw option values
per level, keyed by command path (the top level's is the empty string),
each a hashref of primary names to values.

Every section of every loaded file is checked, whether the command line
selects its level or not: unknown commands, unknown options, options
under the wrong group and sections that are not mappings are thrown as
L<Getopt::Pad::Error> naming the file and the command. The values
themselves are checked later, by the option specs of the selected levels.

A format's parse error is reported without the Perl source location the
parser appended to it.

=head2 Writing

C<writeDefaultFile($root, $path)> writes the defaults of every level in
the same layout, leaving out groups and command sections without
defaults. The text is produced before the file is created, so a failing
C<dump> leaves no file behind. The file is created exclusively
(C<O_EXCL>): an existing file or a symbolic link at the target is refused
without a gap between check and creation. Symbolic links are also refused
explicitly, because Windows follows a dangling one even with C<O_EXCL>.
The file is written with LF line endings on every platform.

=head2 Encoding

Every config file is read and written as UTF-8 here. A format
(L<Getopt::Pad::Config::Format>) only translates between that text and
the data structure.

=head1 SEE ALSO

L<Getopt::Pad::Spec::Config>, L<Getopt::Pad::Config::Format>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
