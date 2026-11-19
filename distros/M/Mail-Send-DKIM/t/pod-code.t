#!/usr/bin/env perl
#
# The page is the specification, so this holds the code against it: an option
# the programme accepts and OPTIONS does not list, an option OPTIONS lists and
# the programme does not accept, an environment variable it reads and
# ENVIRONMENT does not name, or an exit status it can leave with and EXIT
# STATUS does not mention, is a page that misdescribes the programme.
# dmarc-weekly.sh's --dry-run - documented, never implemented - is the mistake
# this is here to catch.
#
# Only what can be read out of the text is compared.  A programme that leaves
# with somebody else's status has that said in words on its page rather than in
# a list, and words are not testable.  Settings taken from a module are
# followed into it: a programme that builds the signer with nothing given is
# configured entirely by what that module reads from the environment, and a
# page that does not name those variables leaves its reader guessing.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use FindBin qw($Bin);

my $BIN = File::Spec->catdir($Bin, File::Spec->updir(), 'bin');
my $LIB = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

# Every programme the distribution installs, each with the page that describes
# it.  The shell wrapper keeps its page in a here-document, because POD lines
# are not shell comments; the rest keep it at the end of the file.
my @PROGRAMMES = qw(mail-dkim dmarc-report.pl dmarc-weekly.sh dmarc-check-mail.pl);

# The page and the programme, from one file: what is between the POD markers
# is the specification, and everything else is the code it describes.
sub split_pod
{
	my $path = shift;

	open(my $fh, '<', $path) or BAIL_OUT("Cannot read $path: $!");
	local $/;
	my $text = <$fh>;
	close($fh);

	if($path =~ /\.sh\z/) {
		my ($pod) = $text =~ /^: <<'POD'\n(.*?)\nPOD\n/ms
			or BAIL_OUT("$path has no POD here-document");
		(my $code = $text) =~ s/^: <<'POD'\n.*?\nPOD\n//ms;

		return ($pod, $code);
	}

	if($text =~ /^__END__\n(.*)\z/ms) {
		my $pod = $1;
		(my $code = $text) =~ s/^__END__\n.*\z//ms;

		return ($pod, $code);
	}

	my ($pod) = $text =~ /^=pod\n(.*)\z/ms
		or BAIL_OUT("$path has no POD");
	(my $code = $text) =~ s/^=pod\n.*\z//ms;

	return ($pod, $code);
}

# The sections of the page by heading, so that "in OPTIONS" can be asked
# precisely: an option named in DESCRIPTION is not an option that is listed.
sub sections
{
	my $pod = shift;

	my (%section, $current);
	foreach my $line (split(/\n/, $pod, -1)) {
		if($line =~ /\A=head[1-4]\s+(.+?)\s*\z/) {
			$current = lc($1);
			$current =~ s/\s+\z//;
			$section{$current} = '' unless(defined($section{$current}));
			next;
		}
		$section{$current} .= "$line\n" if(defined($current));
	}

	return \%section;
}

# What the programme accepts: GetOptions' own list where there is one, and
# otherwise the long options it looks for by hand, which is how the shell
# wrapper takes --crontab.
sub options_in_code
{
	my $code = shift;

	my (%every, @canonical);

	if(my ($block) = $code =~ /\bGetOptions\s*\((.*?)\n\)/s) {
		while($block =~ /'([^']+)'\s*=>/g) {
			my $spec = $1;
			$spec =~ s/[=:][si]\z//;
			my @names = split(/\|/, $spec);
			next unless(@names);
			push @canonical, $names[0];
			$every{$_} = 1 foreach(@names);
		}
	}

	# The shell wrapper compares the argument to a quoted word, which is what
	# tells its own options from the ones it passes on to dmarc-report.pl.
	if(!%every) {
		while($code =~ /['"]--([a-z][a-z0-9-]*)['"]/g) {
			$every{$1} = 1;
			push @canonical, $1;
		}
	}

	return (\@canonical, \%every);
}

# What it reads from the environment.  In Perl that is $ENV{...}; in the shell
# it is an expansion of a name the script does not set itself.
sub environment_in_code
{
	my ($code, $programme) = @_;

	my %names;
	if($programme =~ /\.sh\z/) {
		my %read;
		while($code =~ /\$\{?([A-Z_][A-Z0-9_]*)/g) {
			$read{$1} = 1;
		}

		# Anything the script assigns is its own variable rather than something
		# handed to it - except NAME=${NAME:-default}, which is exactly what a
		# read with a fallback looks like.
		my %own;
		while($code =~ /^[ \t]*(?:local[ \t]+)?([A-Z_][A-Z0-9_]*)=([^\n]*)/mg) {
			my ($name, $value) = ($1, $2);
			next if($value =~ /\A"?\$\{?\Q$name\E(?![A-Za-z0-9_])/);
			$own{$name} = 1;
		}

		%names = map { $_ => 1 } grep { !$own{$_} } keys %read;
	} else {
		while($code =~ /\$ENV\{\s*'?([A-Z_][A-Z0-9_]*)'?\s*\}/g) {
			$names{$1} = 1;
		}
	}

	return sort keys %names;
}

# The settings a programme takes from a module instead of reading itself.
# Mail::Send::DKIM->new() with nothing given takes every setting from the
# environment, so what the module reads is configuration of the programme that
# builds it that way - and the scan above cannot see it, because the reading is
# not in the programme.  new() called with arguments supplies them itself, and
# is left alone: dmarc-check-mail.pl names its domain, key and selector.
sub module_environment
{
	my $code = shift;

	return () unless($code =~ /\bMail::Send::DKIM->new\(\s*\)/);

	my $path = File::Spec->catfile($LIB, 'Mail', 'Send', 'DKIM.pm');
	open(my $fh, '<', $path) or BAIL_OUT("Cannot read $path: $!");
	local $/;
	my $text = <$fh>;
	close($fh);

	my %names;
	while($text =~ /\$ENV\{\s*'?([A-Z_][A-Z0-9_]*)'?\s*\}/g) {
		$names{$1} = 1;
	}

	return sort keys %names;
}

# The statuses the programme can leave with.  A computed one - exit "$status",
# exit($dkim->send(@ARGV)) - is somebody else's and cannot be listed.
sub exit_codes_in_code
{
	my $code = shift;

	my %codes;
	while($code =~ /\bexit\s*\(\s*(\d+)\s*\)/g) {
		$codes{$1} = 1;
	}
	# A usage error goes through usage(N) or pod2usage(-exitval => N).
	while($code =~ /\busage\s*\(\s*(\d+)\s*\)/g) {
		$codes{$1} = 1;
	}
	while($code =~ /exitval\s*=>\s*(\d+)/g) {
		$codes{$1} = 1;
	}
	while($code =~ /^[ \t]*exit\s+(\d+)\s*\z/mg) {
		$codes{$1} = 1;
	}

	return sort { $a <=> $b } keys %codes;
}

foreach my $programme (@PROGRAMMES) {
	subtest $programme => sub {
		my $path = File::Spec->catfile($BIN, $programme);
		my ($pod, $code) = split_pod($path);
		my $section = sections($pod);

		my ($canonical, $every) = options_in_code($code);
		my $options = $section->{'options'} // '';

		foreach my $name (@{$canonical}) {
			like($options, qr/--\Q$name\E(?![-\w])/, "--$name is in OPTIONS");
		}

		# The long options are what a page writes; the one-letter aliases are
		# written beside them, as -t or C<-t>.
		foreach my $name (sort grep { length($_) == 1 } keys %{$every}) {
			like($options, qr/(?<![-\w])-\Q$name\E(?![-\w])/, "-$name is in OPTIONS");
		}

		if(length($options)) {
			foreach my $name ($options =~ /--([a-z][a-z0-9-]*)/g) {
				ok($every->{$name}, "--$name is one the programme takes");
			}
		}

		my @env = environment_in_code($code, $programme);
		my @shared = module_environment($code);
		if(@env || @shared) {
			my $environment = $section->{'environment'};
			ok(defined($environment), 'it has an ENVIRONMENT section to name them in');
			foreach my $name (@env) {
				like($environment // '', qr/\b\Q$name\E\b/, "$name is in ENVIRONMENT");
			}
			foreach my $name (@shared) {
				like($environment // '', qr/\b\Q$name\E\b/,
					"$name, read for it by Mail::Send::DKIM->new(), is in ENVIRONMENT");
			}
		} else {
			note('it reads nothing from the environment itself');
		}

		my @codes = exit_codes_in_code($code);
		my $exit = $section->{'exit status'};
		ok(defined($exit), 'it has an EXIT STATUS section');
		foreach my $code (@codes) {
			like($exit // '', qr/(?<!\d)\Q$code\E(?!\d)/, "exit $code is in EXIT STATUS");
		}
	};
}

done_testing();
