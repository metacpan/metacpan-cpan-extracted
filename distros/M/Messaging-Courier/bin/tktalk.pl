#!/usr/bin/perl

use strict;
use warnings;

use Tk;
use Messaging::Courier;
use Messaging::Courier::ChatMessage;

my $message = '';

our $COURIER = Messaging::Courier->new();

my $mw = MainWindow->new();

my $sent = $mw->Text(
		     #-state => 'disabled'
		    )->pack();

my $write =$mw->Entry(
		      -textvariable => \$message
		     )->pack(
			     -expand => 1
			    );

my $button => $mw->Button(
			  -text => 'Send',
			  -command => \&onSend
			 )->pack();

$mw->repeat( 500 => \&check_for_messages );

sub check_for_messages {
  my $message = $COURIER->receive( 0.1 );
  if (UNIVERSAL::isa($message, 'Messaging::Courier::ChatMessage')) {
    $sent->insert(
		  'end',
		  sprintf(
			  "[%s]: %s\n",
			  $message->nick,
			  $message->text
			 )
		 );
    ## make sure we process everything that need to
    ## arrive.
    check_for_messages();
  }
}

sub onSend {
  $COURIER->send(
		 Messaging::Courier::ChatMessage->new()
		                     ->text( $message )
		);
  $message = '';

  ## make sure we pick up the message straight away
  check_for_messages();
}



MainLoop;

1;
