package Echo::StreamServer::EQLShell;

use 5.008008;
use strict;
use warnings;

# Multiple Inheritance...whoa!
use Echo::StreamServer::Items;
use Echo::StreamServer::KVS;
our @ISA = qw(
	Echo::StreamServer::Items
	Echo::StreamServer::KVS
);

use Term::ReadLine;
use Data::Dumper;

our $VERSION = '0.03';

sub _history_file {
	my $self = shift;
	my $filename = $ENV{'HOME'};

	# Only open a history_file when $HOME exists.
	if (defined $filename) {
		$self->{'history'} = "$filename/.eqlhist";
	}
}

sub _intro {
	# Introduction Text on start-up.
	my ($self, $term) = @_;
	my $acct = $self->{'account'}->name;
	my $rl_support = $term->ReadLine;
	my $help_text = $self->_help;

	my $INTRO_TEXT=<<"INTRO";

Echo Query Language Shell (version $VERSION)
Account: $acct
ReadLine Support: $rl_support

Send an EQL text string to Stream Server and display the results.
SEARCH> url:http://example.com/index.html

Prompts:
SEARCH> "This prompt means execute a search."
COUNT>  "This prompt means execute a count."

$help_text

HELP: Show help text.

INTRO

}

sub _help {
	# Help Text
	my ($self, $cmd_name) = @_;

	my $HELP_TEXT=<<"HELP";
Shell Commands
COUNT:  Set to COUNT> mode.
SEARCH: Set to SEARCH> mode.
USERS:  Set to USERS> mode.
QUIT:   Quit (or EXIT) the shell.
HELP

}

# Start Read-Execute Loop:
# ============================================================
my $cmd_mode_start = 'SEARCH';
my @cmd_mode_list = ( 'COUNT', 'SEARCH', 'USERS' );

sub start {
	my $self = shift;
	$self->{'cmd_mode'} = $cmd_mode_start;

	# Add Term::ReadLine terminal for shell.
	my $term = new Term::ReadLine('EQLShell'); ## , $self->_history_file);

	# Open history file, when possible.
	eval {
		if (defined ($self->_history_file) and not -f ($self->_history_file)) {
			$term->write_history($self->_history_file);
		}
		$term->read_history($self->_history_file);
	};
	warn("ReadLine History file is not available.\n") if ($@);

	print $self->_intro($term);

	my $shell_input;
	while (defined ($shell_input = $term->readline($self->{'cmd_mode'} . "> "))) {
		print STDERR "Input: [$shell_input]\n";

		# Trim whitespace
		$shell_input =~ s/^\s*(.*)\s*$/$1/;

		# Skip empty lines.
		next if ($shell_input =~ m/^\s*$/);

		# HELP Text:
		if ($shell_input =~ m/^\s*HELP\s*$/i) {
			print $self->_help;
			next;
		}

		# Shell Commands:
		if (grep(m/^\s*$shell_input\s*$/i, @cmd_mode_list)) {
			$self->{'cmd_mode'} = uc($shell_input);
			next;
		}

		# QUIT Shell:
		last if ($shell_input =~ m/^\s*QUIT\s*$/i);
		last if ($shell_input =~ m/^\s*EXIT\s*$/i);

		$term->addhistory($shell_input) if ($shell_input =~ m/\S/);

		# Based on the prompt, execute the command, e.g. a "count" or "search" query.
		eval {
			if ('COUNT' eq $self->{'cmd_mode'}) {
				my $n = $self->count($shell_input);
				print "\tCOUNT: $n\n";
			}
			elsif ('SEARCH' eq $self->{'cmd_mode'}) {
				my $r = $self->search($shell_input);
				print Dumper($r) . "\n";
			}
			elsif ('USERS' eq $self->{'cmd_mode'}) {
				my $r = $self->get($shell_input);
				print Dumper($r) . "\n";
			}
		};
		print "Error: $@\n" if ($@);
	}

	# Close history file, when possible.
	# Add the last 20 items to history.
	eval {
		$term->append_history(20, $self->_history_file);
	};

	print "\nQUIT\n";
}

1;
__END__

=head1 NAME

Echo::StreamServer::EQLShell - Echo Query Language Shell

=head1 SYNOPSIS

  use Echo::StreamServer::Account;
  use Echo::StreamServer::EQLShell;

  my $acct = new Echo::StreamServer::Account($appkey, $secret);
  my $shell = new Echo::StreamServer::EQLShell($acct);

  # Start EQLShell prompt.
  $shell->start;

=head1 DESCRIPTION

The Echo::StreamServer::EQLShell is the C<Echo Query Language Shell>. It requires an Echo::StreamServer::Account.
The EQL Shell supports queries on the C<Items API> and the C<Users API>.

The Echo::StreamServer::Account parameter is optional. Echo::StreamServer::Settings loads
the default account otherwise.

=head1 SEE ALSO

Echo::StreamServer::Items
Echo::StreamServer::Users

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
