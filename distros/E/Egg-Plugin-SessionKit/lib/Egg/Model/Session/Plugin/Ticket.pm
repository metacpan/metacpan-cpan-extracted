package Egg::Model::Session::Plugin::Ticket;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Ticket.pm 264 2008-02-22 08:53:00Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Digest::SHA1 qw/ sha1_hex /;

our $VERSION= '0.02';

sub _setup {
	my($class, $e)= @_;
	$class->config->{ticket_length} ||= 32;
	$class->next::method($e);
}
sub ticket {
	my $self  = shift;
	my($name, $flag)= @_ ? do {
		@_== 1 ? do {
			$_[0]=~m{^[01]$} ? ($self->__ticket_name, $_[0]): (shift, undef);
		  }: @_;
	  }: ($self->__ticket_name, undef);
	my $ticket= $self->data->{_session_ticket} ||= {};
	unless (defined($flag)) {
		return $ticket->{$name} ? $ticket->{$name}[0]: "";
	}
	unless ($flag) {
		my $i= $ticket->{$name} || return "";
		$self->e->debug_out("# + !! Ticket '$name' is remove. [$i->[0]]");
		delete $ticket->{$name};
		return "";
	}
	my $id= substr(
	  sha1_hex( time. $$. rand(1000). {} ), 0, $self->config->{ticket_length},
	  );
	$ticket->{$name}= [ $id , time ];
	$self->is_update(1);
	$self->e->debug_out("# + Ticket '$name' is create. [$id]");
	$id;
}
sub ticket_check {
	my $self  = shift;
	my($name, $value)= @_ ? do {
		@_== 1 ? ($self->__ticket_name, shift) : @_;
	  }: do {
		my $i= $self->valid_ticket(shift) || return -3;
		( $self->__ticket_name, $i );
	  };
	my $ticket= $self->data->{_session_ticket} || return -2;
	my $id= $ticket->{$name} || return do {
		$self->e->debug_out("# + Ticket '$name' is unset.");
		-1;
	  };
	return $id->[0] eq $value ? do {
		$self->e->debug_out("# + Ticket '$name' is match. [$value]");
		1;
	  }: do {
		$self->e->debug_out
		      ("# + !! Ticket '$name' is unmatch. [$id->[0]] - [$value]");
		0;
	  };
}
sub ticket_remove {
	my $self  = shift;
	my $name  = shift || $self->__ticket_name;
	my $ticket= $self->data->{_session_ticket} || return 0;
	my $id    = $ticket->{$name} || return 0;
	$self->e->debug_out("# + Ticket '$name' is remove. [$id->[0]]");
	delete $ticket->{$name};
	$self->is_update(1);
	1;
}
sub ticket_clear {
	my $self  = shift;
	my $ticket= $self->data->{_session_ticket} || return 0;
	my $count = scalar(keys %$ticket);
	$self->e->debug_out("# + !! Ticket is all clear.");
	$self->DELETE('_session_ticket');
	$count;
}
sub ticket_purge {
	my $self  = shift;
	my $lapse = shift || 60* 10;   # default is 10 minute.
	my $ticket= $self->data->{_session_ticket} || return 0;
	$lapse= time- $lapse;
	my $count;
	while (my($name, $v)= each %$ticket) {
		next if $v->[1] >= $lapse;
		delete $ticket->{$name};
		++$count;
	}
	if ($count) {
		$self->is_update(1);
		$self->e->debug_out("# + !! $count tickets are deleted.");
	}
	$self->DELETE('_session_ticket') unless %$ticket;
	$count || 0;
}
sub valid_ticket {
	my $self = shift;
	my $value= shift || return 0;
	my $len  = $self->config->{ticket_length};
	$value=~m{^[a-f0-9]{$len}$} ? 1: 0;
}
sub __ticket_name { $_[0]->e->request->path || 'default' }

1;

__END__

=head1 NAME

Egg::Model::Session::Plugin::Ticket - Plugin for session to handle ticket temporarily.

=head1 SYNOPSIS

  package MyApp::Model::Sesion::MySession;
  
  __PACKAGE__->startup(
   Plugin::Ticket
   .....
   );

  my $session= $e->model('session_label_name');
  
  # The ticket is temporarily issued.
  my $ticket= $session->ticket(1);
  
  # The ticket name is specified.
  my $ticket= $session->ticket( myticket => 1 );
  
  # The ticket received from the form is checked.
  my $result= $session->ticket_check;
  if ($result > 0) {
     
     ...... The ticket is corresponding.
     
  } else {
     my $error= $result== -3 ? 'The ticket cannot be received or it makes an error the format.'
                $result== -2 ? 'The ticket is not set. # 1'
                $result== -1 ? 'The ticket is not set. # 2'
                               'The ticket is not corresponding.';
     return $e->error($error);
  }
  
  # The format of the ticket is checked.
  if ($session->valid_ticket($ticket_value)) {
     ...... Correct ticket.
  } else {
     ...... The problem is in the format of the ticket.
  }
  
  # The ticket is temporarily deleted.
  $session->ticket(0);
    Or
  $session->ticket_remove;
  
  # It deletes it specifying the ticket name.
  $session->ticket( myticket => 0);
    Or
  $session->ticket_remove('myticket');  
  
  # All tickets are annulled.
  $session->ticket_clear;
  
  # The ticket that passes 30 minutes or more is annulled.
  $session->ticket_purge( 30 * 60 );

=head1 DESCRIPTION

It is a plugin for the session to handle the ticket temporarily to use it from 
the input form etc.

The use of temporarily confirming the agreement of the ticket sent together when
 the ticket is temporarily issued when the input form is displayed, and it is 
transmitted from the form is assumed.

  1... The ticket is temporarily issued, and the ticket ID is buried under the input form etc.
  2... When the client transmits the input form, the ticket is temporarily sent to the application.
  3... When the ticket is not temporarily corresponding it, the application plays it.

To use it, 'Plugin::Ticket' is added to 'startup'.

Then, the method of this plugin is added to the session object.

The character length of ticket ID is temporarily decided to 'ticket_length' by 
the configuration.

  __PACKAGE__->config (
    ticket_length => 32,
    );

L<Digest::SHA1> is used for ticket ID generation.

=head1 METHODS

=head2 ticket ([ID_KEY], [FLAG_BOOL])

The ticket is issued temporarily new and invalidated.

ID_KEY is a name of the issued key that temporarily preserves the ticket in the
session. 'default' is used at the unspecification.

FLAG_BOOL is temporarily issues the ticket or an existing flag whether to 
invalidate the ticket temporarily.

  # Receipt of session object.
  my $session= $e->model('session_name');
  
  # Temporary issue of ticket.
  my $ticket_id = $session->ticket( ticket_name => 1 );
  
  # The ticket is temporarily invalid.
  $session->ticket( ticket_name => 0 );

When ID_KEY is omitted, request URI is used as a key.

  # Temporary issue of ticket.
  my $ticket_id = $session->ticket(1);
    
  # The ticket is temporarily invalid.
  $session->ticket(0);

=head2 ticket_check ([ID_KEY], [TICKET_ID])

It confirms whether the ticket is temporarily corresponding to the existing one
and the result is returned.

ID_KEY is a name of the issued key that temporarily preserves the ticket in the 
session. 'default' is used at the unspecification.

TICKET_ID is already issued temporarily ID of the ticket. When TICKET_ID is 
unspecification, the exception is generated.

The result returns by the following numerical values.

  -3 = The ticket for the confirmation cannot be received or it is in the format the problem.
  -2 = When the data confidence to become the origin of the ticket preservation is not found temporary.
  -1 = When data concerning ID_KEY is not preserved.
   0 = When not agreeing.
   1 = When agreeing.


  if ( 0 < $session->ticket_check( ticket_name => $e->request->param('ticket_name') ) ) {
     ... The ticket is a code when agreeing.
  } else {
     ... The ticket is a code when not agreeing.
  }

When ID_KEY is omitted, request URI is used as a key.

  if ( 0 < $session->ticket_check($e->request->param('ticket_name')) {
     ... The ticket is a code when agreeing.
  } else {
     ... The ticket is a code when not agreeing.
  }

=head2 ticket_remove ([ID_KEY])

The ticket is temporarily deleted specification.

0 returns when the ticket to be deleted is not registered.

  $session->ticket_remove('ticket_name');

When ID_KEY is omitted, request URI is used as a key.

  $session->ticket_remove;

One similar movement is done to pass 0 to the flag of 'ticket' method, and after
it deletes it, here sets 'is_update'.
Therefore, please use here when you want surely to delete it.

=head2 ticket_clear ([ID_KEY])

All registered tickets are annulled.
And, the annulled number of tickets is returned.

  my $count= $session->ticket_clear;

=head2 ticket_purge ([TIME_VALUE])

TIME_VALUE is deleted and passage annuls all tickets temporarily.
And, the annulled number of tickets is returned.

  # All the passage of ten minutes is deleted.
  $session->ticket_purge( 10* 60 );
  
  # All the passage of 1 hour is deleted.
  $session->ticket_purge( 1* 60* 60 );
  
  # All the passage of a 1 day is deleted.
  $session->ticket_purge( 1* 24* 60* 60 );

=head2 valid_ticket ([TICKET_ID])

The format of TICKET_ID is checked and the result is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Session::Manager::TieHash>,
L<Digest::SHA1>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

