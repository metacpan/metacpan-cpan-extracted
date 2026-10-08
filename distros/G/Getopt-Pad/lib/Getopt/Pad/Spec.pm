use v5.26;
use Object::Pad;

use Getopt::Pad::Spec::Level;
use Getopt::Pad::Spec::Option;
use Getopt::Pad::Spec::Config;
use Getopt::Pad::Config;
use Getopt::Pad::ExitRequest;
use Getopt::Pad::Help;
use Getopt::Pad::Completion;

class Getopt::Pad::Spec :strict(params) {
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.06';

	use constant CONFIG_OPTION => 'config';

	# The one table of Auto options: name, placement ('every' Level, the
	# 'root', or the root of a Spec with a 'config' block), option spec, and
	# the Trigger the parser fires when the parsed command line sets it.
	# Every Trigger ends the parse with an ExitRequest carrying its finished
	# output. CONFIG_OPTION carries no Trigger; the parser consumes it for
	# config loading. The config options act on the whole config file, so
	# every Level below the root inherits them.
	my @autoOptions = (
		{
			key       => 'help',
			placement => 'every',
			raw       => sub ($config) { return { hidden => 1, help => 'Print this help text and exit' } },
			trigger   => sub ($helper, $spec, $level, $value) {
				die Getopt::Pad::ExitRequest->new(output => $helper->renderHelp);
			},
		},
		{
			key       => 'version',
			placement => 'root',
			raw       => sub ($config) { return { hidden => 1, help => 'Print the program version and exit' } },
			trigger   => sub ($helper, $spec, $level, $value) {
				die Getopt::Pad::ExitRequest->new(output => $helper->renderVersion . "\n");
			},
		},
		{
			key       => 'create-completions',
			placement => 'root',
			raw       => sub ($config) {
				return {
					type  => 's',
					valid => Getopt::Pad::Completion->SHELLS,
					group => 'Completion',
					help  => 'Print a completion script for this shell to STDOUT and exit',
				};
			},
			trigger   => sub ($helper, $spec, $level, $value) {
				die Getopt::Pad::ExitRequest->new(output => Getopt::Pad::Completion->new(spec => $spec)->renderScript($value));
			},
		},
		{
			key           => CONFIG_OPTION,
			placement     => 'config',
			optionalValue => 1,
			raw           => sub ($config) {
				my $help = sprintf('Load options from this %s config file', $config->formatName);
				$help .= sprintf(' (bare --config loads %s)', $config->defaultPath) if defined $config->defaultPath;
				return { type => 's', group => 'Config', help => $help, inherit => 1 };
			},
		},
		{
			key       => 'create-default-config',
			placement => 'config',
			raw       => sub ($config) {
				return { type => 's', group => 'Config', help => 'Write a config file prefilled with the default values to this path and exit', inherit => 1 };
			},
			trigger   => sub ($helper, $spec, $level, $value) {
				die Getopt::Pad::ExitRequest->new(output => sprintf("Wrote default config to %s\n", $spec->config->io->writeDefaultFile($spec->root, $value)));
			},
		},
	);

	field $raw :param;

	field $root    :reader;
	field $config  :reader;
	field $version :reader;

	ADJUST {
		specError('GetOptions expects key/value pairs') if ref $raw ne 'HASH';

		my %spec = $raw->%*;
		$config  = delete $spec{config};
		$version = delete $spec{version};
		$config  = Getopt::Pad::Spec::Config->new(raw => $config) if defined $config;

		$root = Getopt::Pad::Spec::Level->new(raw => \%spec);
		$self->attachAutoOptions($root, 1);
		$self->passInheritedOptions($root);
		$self->checkCommandsKeyIsFree($root) if defined $config;
	}

	method attachAutoOptions($level, $isRoot) {
		foreach my $entry (@autoOptions) {
			next if $entry->{placement} ne 'every' && !$isRoot;
			next if $entry->{placement} eq 'config' && !defined $config;

			$level->addOption(Getopt::Pad::Spec::Option->new(
				auto    => 1,
				key     => $entry->{key},
				raw     => $entry->{raw}->($config),
				trigger => $entry->{trigger},
				($entry->{optionalValue} ? (optionalValue => 1) : ()),
			));
		}

		$self->attachAutoOptions($level->command($_), 0) foreach $level->commandNames;
	}

	# Every Level below hands on what it received plus its own inheritable
	# options, each paired with the Level declaring it.
	method passInheritedOptions($level, @received) {
		my @passed = (@received, map { [$_, $level] } $level->inheritableOptions);
		foreach my $name ($level->commandNames) {
			my $command = $level->command($name);
			$command->inheritOption($_->@*) foreach @passed;
			$self->passInheritedOptions($command, @passed);
		}
	}

	# A config file holds the command sections of a Level with commands
	# under the COMMANDS_KEY, so no group of such a Level may take its name.
	method checkCommandsKeyIsFree($level) {
		return if !$level->hasCommands;

		my $key = Getopt::Pad::Config->COMMANDS_KEY;
		specError("%sgroup '%s' is reserved for the command sections of config files", $level->where, $key) if grep { $_->group eq $key } $level->declaredOptions;
		$self->checkCommandsKeyIsFree($level->command($_)) foreach $level->commandNames;
	}

	method helperFor($level, %overrides) {
		return Getopt::Pad::Help->new(level => $level, version => $version, %overrides);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Spec - The checked spec of one GetOptions call (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

Getopt::Pad::Spec turns the arguments of C<GetOptions> into a tree of
checked objects before any command line is looked at. Everything after
its construction works with these objects, never with the raw hashes.

Constructing a spec (C<< Getopt::Pad::Spec->new(raw => \%spec) >>):

=over 4

=item 1.

takes the C<config> key out and builds a L<Getopt::Pad::Spec::Config>
from it, and takes the C<version> key out;

=item 2.

builds the top level as a L<Getopt::Pad::Spec::Level>, which builds its
options, args and commands recursively;

=item 3.

attaches the automatic options: C<--help> to every level,
C<--version> and C<--create-completions> to the top level, and with a
config block C<--config> and C<--create-default-config> to the top level,
marked as inherited;

=item 4.

passes every inherited option down to all levels below the level that
declares it;

=item 5.

with a config block, refuses a group named C<commands> on a level with
commands, because config files use that key for the command sections.

=back

This module owns the one table of automatic options. Each entry names
where the option is attached, its option spec, and its trigger: the code
the parser runs when the command line sets the option. Every trigger ends
the parse by throwing a L<Getopt::Pad::ExitRequest> that carries the
finished output, so no other module needs to know what an automatic
option does. C<--config> has no trigger; the parser uses its value to load
config files.

=head1 METHODS

=over 4

=item root

The top level, a L<Getopt::Pad::Spec::Level>.

=item config

The L<Getopt::Pad::Spec::Config>, or C<undef> without a config block.

=item version

The C<version> key of the spec, or C<undef>.

=item helperFor($level, %overrides)

A L<Getopt::Pad::Help> for C<$level>. The only place help renderers are
created. C<%overrides> are passed to its constructor, for example
C<< handle => \*STDERR >>.

=item CONFIG_OPTION

The name of the automatic C<--config> option.

=back

=head1 SEE ALSO

L<Getopt::Pad::Spec::Level>, L<Getopt::Pad::Parser>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
