#!/usr/bin/perl

#==============================================================================
# Ham::Fldigi::Shell
# v0.002
# (c) 2012 Andy Smith, M0VKG
#==============================================================================
# DESCRIPTION
# This module provides a shell for interacting with Fldigi
#==============================================================================
# SYNOPSIS
# use Ham::Fldigi;
# my $f = new Ham::Fldigi('LogLevel' => 4,
#                         'LogFile' => './debug.log',
#                         'LogPrint' => 1,
#                         'LogWrite' => 1);
# my $client = $f->client('Hostname' => 'localhost',
#                         'Port' => '7362',
#                         'Name' => 'default');
# my $shell = $fldigi->shell($client);
#==============================================================================

# Perl documentation is provided inline in pod format.
# To view, run:-
# perldoc Ham::Fldigi::Shell

=head1 NAME

Ham::Fldigi::Shell - an interactive shell for Fldigi

=head1 SYNOPSIS

  use Ham::Fldigi;
  my $f = new Ham::Fldigi;
	my $c = new Ham::Fldigi::Client('Hostname' => 'localhost', 'Port' => 7362, 'Name' => 'example');
	my $s = $f->shell($c);

=head1 DESCRIPTION

This module is for communicating with individual Fldigi instances.

It uses Fldigi's XMLRPC service, which usually runs on localhost:7362, providing support for it has been compiled in.

=head2 EXPORT

None by default.
=cut

package Ham::Fldigi::Shell;

use 5.012004;
use strict;
use warnings;

use Moose;
use Data::Dumper;
use Time::HiRes qw( usleep );
use Term::ReadLine;
use Switch;
use base qw(Ham::Fldigi::Debug);

our $VERSION = '0.001';

has 'id' => (is => 'ro', isa => 'String');
has 'parent' => (is => 'ro', isa => 'Ref');
has 'client' => (is => 'rw', isa => 'Ref');

=head1 CONSTRUCTORS

=head2 Shell->new(I<Ham::Fldigi::Shell ref>)

Creates a new B<Ham::Fldigi::Shell> object with the specified arguments.

=cut

sub new {
	
	# Get our name, and set an ID
	my $class = shift;
	my (%params) = @_;
	my $g = Data::GUID->new;

	# Fill in the class ID and version
	my $self =  {
		'version' => $VERSION,
		'id' => $g->as_string,
	};

	# Bless self
	bless $self, $class;

	if(!defined($params{'Parent'})) {
		$self->error("Parent is undefined. Ham::Fldigi::Shell should only be called with Ham::Fldigi->shell()!");
		return undef;
	} else {
		$self->{parent} = $params{'Parent'};
	}

	$self->debug("Constructor called. Version ".$VERSION.", with ID ".$self->id.".");

	if(!defined($params{'Client'})) {
		$self->debug("No client passed.");
	} else {
		$self->client($params{'Client'});
		$self->debug("Passed client ref is for client named ".$self->client->name.", with an XML-RPC URL of ".$self->client->url.".");
	}

	$self->debug("Returning...");
	return $self;
}

=head1 METHODS

=head2 Client->shell()

Start an interactive shell, similar to fldigi-shell.

=cut

sub start {

	my ($self) = @_;

	$self->debug("Starting shell...");

	my $term = Term::ReadLine->new('Ham::Fldigi shell');
	print "Ham::Fldigi::Shell v".$VERSION."\n";
	print "(c) 2012 Andy Smith M0VKG\n";

	my $prompt;
	if(defined($self->client)) {
		$prompt = "fldigi(".$self->client->name.")> ";
	} else {
		$prompt = "fldigi> ";
	}

	my $OUT = $term->OUT || \*STDOUT;

	my $running = 1;
	while ($running == 1) {

		my $c = $term->readline($prompt);

		if((defined($c)) && ($c =~ /\S/)) {
			my ($cmd, @args) = split(" ", $c);
			$term->addhistory($_);

			switch ($cmd) {
				case /^connect$|^c$/ {
					if(defined($self->parent->clients))
					{
						if(@args) {
							if(!defined($self->parent->clients->{$args[0]})) {
								print $OUT "No client with name '".$args[0]."'.\n";
							} else {
								$self->client($self->parent->clients->{$args[0]});
								print $OUT "Switched to client '".$args[0]."'.\n";
								$prompt = "fldigi(".$self->client->name.")> ";
							}
						}
					}
				}
				case /^disconnect$|^d$/ {
					if(defined($self->client)) {
						print $OUT "Disconnected from client '".$self->client->name.".\n";
						$self->{client} = undef;
						$prompt = "fldigi> ";
					} else {
						print $OUT "Not connected to a client.\n";
					}
				}
				case /^list$|^l$/ {
					if(defined($self->parent->clients))
					{
						foreach my $client (keys %{$self->parent->clients}) {
							print $OUT "\t".$client."\t\t(".$self->parent->clients->{$client}->url.")\n";
						}
					} else {
						print $OUT "No clients found!";
					}
				}
				case qr/^set|^s$/ {
					if(defined($args[0])) {
						switch ($args[0]) {
							case "debug_level" {
								if(defined($args[1])) {
									$Ham::Fldigi::Debug::debug_level = $args[1];
								}
								print $OUT "debug_level is ".$Ham::Fldigi::Debug::debug_level;
							}
							case "debug_file" {
								if(defined($args[1])) {
									$Ham::Fldigi::Debug::debug_file = $args[1];
								}
								print $OUT "debug_file is ".$Ham::Fldigi::Debug::debug_file;
							}
							case "debug_print" {
								if(defined($args[1])) {
									$Ham::Fldigi::Debug::debug_print = $args[1];
								}
								print $OUT "debug_print is ".$Ham::Fldigi::Debug::debug_print;
							}
							case "debug_write" {
								if(defined($args[1])) {
									$Ham::Fldigi::Debug::debug_write = $args[1];
								}
								print $OUT "debug_write is ".$Ham::Fldigi::Debug::debug_write;
							}
						}
					} else {
						print $OUT "\tdebug_level\t\t".$Ham::Fldigi::Debug::debug_write."\tDebug level (0-4)\n";
						print $OUT "\tdebug_file\t\t".$Ham::Fldigi::Debug::debug_write."\tFile to log to (path)\n";
						print $OUT "\tdebug_print\t\t".$Ham::Fldigi::Debug::debug_write."\tLog to screen (1) or not (0)\n";
						print $OUT "\tdebug_write\t\t".$Ham::Fldigi::Debug::debug_write."\tLog to file (1) or not (0)\n";
					}
				}
				case qr/^quit|^q$/ {
					print $OUT "Exiting shell...";
					$running = 0;
				}
				case qr/\w+/ {
					if(defined($self->client)) {
						my $arg = join(" ", @args);
						chomp($arg);
						my $r = $self->client->command($cmd, $arg);
						print $OUT $r."\n";
					} else {
						print $OUT "Not connected to a client.\n";
					}
				}
			}
	
		}
	}
	
	$self->debug("Shell stopped.");
	return 1;

}

1;
__END__

=head1 SEE ALSO

The source code for this module is hosted on Github at L<https://github.com/m0vkg/Perl-Ham-Fldigi>.

=head1 AUTHOR

Andy Smith M0VKG, E<lt>andy@m0vkg.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andy Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
