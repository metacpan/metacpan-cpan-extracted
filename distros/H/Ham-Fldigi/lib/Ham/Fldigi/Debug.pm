#==============================================================================
# Ham::Fldigi::Debug
# v0.002
# (c) 2012 Andy Smith, M0VKG
#==============================================================================
# DESCRIPTION
# Colourful debug messages for Ham::Fldigi
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
# $client->modem("BPSK125");
# $client->send("CQ CQ CQ DE M0VKG M0VKG M0VKG KN");
#==============================================================================

# Perl documentation is provided inline in pod format.
# To view, run:-
# perldoc Ham::Fldigi::Debug

=head1 NAME

Ham::Fldigi::Debug - Colourful debug messages for Ham::Fldigi

=head1 SYNOPSIS

  use Ham::Fldigi;
	use base qw(Ham::Fldigi::Debug)

	...
	$self->debug("This is a debug message!");

=head1 DESCRIPTION

Colourful debug/error messages for Ham::Fldigi.

By default, none of the calls output anything - either to screen or to a logfile. This is intentional so as not to interfere when Ham::Fldigi is used by third-party scripts.

If you do want to make use of the logging functions, see the documentation for C<Ham::Fldigi>'s B<new()>.

=head2 EXPORT

B<debug>, B<error>, B<warning> and B<notice>.

=cut

package Ham::Fldigi::Debug;

use 5.012004;
use strict;
use warnings;

use Term::ANSIColor;
use Data::Dumper;
use DateTime;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(debug error warning notice);
our $VERSION = 0.002;

our $debug_level = 0;
our $debug_print = 0;
our $debug_file = "/dev/null";
our $debug_write = 0;

# _timestamp
# Create timestamps for our log messages
sub _timestamp {

	my ($self) = @_;

	my $dt = DateTime->now;

	my $timestamp = $dt->ymd." ".$dt->hms;

	return $timestamp;
}

=head1 METHODS

=head2 debug(I<message>)

Print a debug message.

=cut

sub debug {
  
  my ($self, $msg) = @_;

	my $class;
  if(ref($self)) {
		$class = ref $self;
  } else {
		$class = $self;
  }

	my @caller = split('::', (caller(1))[3]);
	my $sub = $caller[$#caller];

	my $logmsg = "[".$self->_timestamp."] ".(color 'blue')."+++".(color 'reset')." ".(color 'magenta').$class.(color 'reset')." (".(color 'green').$sub.color('reset')."): ".$msg."\n";

	if($debug_level ge 4) {
		if($debug_print eq 1) {
			print STDERR "\r".$logmsg;
		}
		if($debug_write eq 1) {
			open (LOGFILE, '>>'.$debug_file);
			print LOGFILE $logmsg;
		}
	}
}

=head2 error(I<message>)

Print an error message.

=cut

sub error {
  
  my ($self, $msg) = @_;

	my $class;
  if(ref($self)) {
		$class = ref $self;
  } else {
		$class = $self;
  }

	my @caller = split('::', (caller(1))[3]);
	my $sub = $caller[$#caller];

	my $logmsg = "[".$self->_timestamp."] ".(color 'red')."!!!".(color 'reset')." ".(color 'magenta').$class.(color 'reset')." (".(color 'green').$sub.color('reset')."): ".$msg."\n";

	if($debug_level ge 1) {
		if($debug_print eq 1) {
			print STDERR "\r".$logmsg;
		}
		if($debug_write eq 1) {
			open (LOGFILE, '>>'.$debug_file);
			print LOGFILE $logmsg;
		}
	}
}


=head2 warning(I<message>)

Print a warning message.

=cut

sub warning {
  
  my ($self, $msg) = @_;

	my $class;
  if(ref($self)) {
		$class = ref $self;
  } else {
		$class = $self;
  }

	my @caller = split('::', (caller(1))[3]);
	my $sub = $caller[$#caller];

	my $logmsg = "[".$self->_timestamp."] ".(color 'yellow')."xxx".(color 'reset')." ".(color 'magenta').$class.(color 'reset')." (".(color 'green').$sub.color('reset')."): ".$msg."\n";

	if($debug_level ge 2) {
		if($debug_print eq 1) {
			print STDERR "\r".$logmsg;
		}
		if($debug_write eq 1) {
			open (LOGFILE, '>>'.$debug_file);
			print LOGFILE $logmsg;
		}
	}
}


=head2 notice(I<message>)

Print a notice message.

=cut

sub notice {
  
  my ($self, $msg) = @_;

	my $class;
  if(ref($self)) {
		$class = ref $self;
  } else {
		$class = $self;
  }

	my @caller = split('::', (caller(1))[3]);
	my $sub = $caller[$#caller];

	my $logmsg = "[".$self->_timestamp."] ".(color 'green')."---".(color 'reset')." ".(color 'magenta').$class.(color 'reset')." (".(color 'green').$sub.color('reset')."): ".$msg."\n";

	if($debug_level ge 3) {
		if($debug_print eq 1) {
			print STDERR "\r".$logmsg;
		}
		if($debug_write eq 1) {
			open (LOGFILE, '>>'.$debug_file);
			print LOGFILE $logmsg;
		}
	}
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
