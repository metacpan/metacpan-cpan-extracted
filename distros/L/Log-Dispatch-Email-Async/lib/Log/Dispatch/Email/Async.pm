package Log::Dispatch::Email::Async;
use 5.010;
use strict;
use warnings;  # FATAL => 'all';
# use Modern::Perl;
use Carp;

########################################################################################
#  TODOs
#     - add option to silenty fail, not croak, upon network unavailability
#     - in tests
#        - complete test TODOs
#        - group tests into sub-groups, files? or simplify with only 1 test?
#        - write creation-only tests sub-group after ping() - NOT POSSIBLE
#        - change 'detele enails' to 'move to trash - for gmail'
#        - seperate ask() into a own module - NOT NEEDED ANYMORE
#           -  hierarchical args struct? how to self address as in <domain>?
#           - final string in ask() should show secs at close instead of full value
#           - shorten default replys in final string to fit in line
########################################################################################

use threads;
use Thread::Queue;
use Mail::Sender;
use Log::Dispatch::Email;

use parent 'Log::Dispatch::Email';

our $VERSION = '0.01';

sub new {
   my ( $proto, %params ) = @_;
   my $class = ref $proto || $proto;

   my $self = bless {}, $class;
   $self->_basic_init( %params );

   $self->{debug_mode} = $params{debug_mode} || 0;
   delete $params{debug_mode} if exists $params{debug_mode};

   say "creating ", ref( $self ) if $self->{debug_mode} >= 3;

   $self->{timeout} = $params{timeout} || 30;
   delete $params{timeout} if exists $params{timeout};

   $self->{thread_count} = $params{thread_count} || 2;
   delete $params{thread_count} if exists $params{thread_count};

   $self->{stack_size} = $params{stack_size} || 4;
   delete $params{stack_size} if exists $params{stack_size};
   $self->{stack_size} = 4 if $self->{stack_size} < 4;
   # threads->set_stack_size( $self->{stack_size} * 4096 );

   $self->{ident} = 'object';
   $self->{tid} = threads->tid();      
   $self->{ndx} = 0;
   $self->{count} = 0;

   $self->{mailer} = Mail::Sender->new( \%params );
   if ( ref( $self->{mailer} ) eq 'Mail::Sender' ) {
      say ref($self), "\tcreated ", ref( $self->{mailer} ) if $self->{debug_mode} >= 3;
   } else {
      croak ref($self), ": cannot create Mail::Sender: $Mail::Sender::Error"
   }

   $self->{mailq} = Thread::Queue->new();
   if ( ref( $self->{mailq} ) eq 'Thread::Queue' ) {
      say ref($self), "\tcreated ", ref( $self->{mailq} ) if $self->{debug_mode} >= 3;
   } else {
      croak ref($self), ": cannot create email Thread::Queue:$!"
   }

   $self->{thread}[0] = threads->self();

   for my $n ( 1 .. $self->{thread_count} ) {   
      $self->{thread}[$n] = threads->create( 
         sub {
            my $self = shift;
            threads->yield();

            $self->{ident} = 'thread';
            $self->{tid} = threads->tid();      
            $self->{ndx} = $n;      

            my $RUN = 1;
            $SIG{TERM} = sub { $RUN = 0; };

            while ( $RUN and defined (my $args = $self->{mailq}->dequeue()) ) {

               my $sndr = $self->{mailer}->MailMsg( $args ); 

               if ( $sndr == $self->{mailer} ) {
                  $self->{count} += 1;
                  say ref($self), ":\tdequeued, sent $self->{count}: '$args->{subject}' on thread ", 
                     threads->tid() if $self->{debug_mode} >= 4;
               } else {
                  carp ref($self), ": cannot send mail '$args->{subject}' on thread "
                     , threads->tid(), " :$self->{mailer}{error_msg}";
               }
            }
            say ref($self), ":\tthread ", threads->tid(), " ready to join" 
               if $self->{debug_mode} >= 2;
            return $self->{count};
         }, $self 
      );
      if ( ref( $self->{thread}[$n] ) eq 'threads' ) {
         say ref($self), ": \tcreated ", ref( $self->{thread}[$n] )
            , " at ndx $n w/ tid ", $self->{thread}[$n]->tid()
            if $self->{debug_mode} >= 3;
      } else {
         croak ref($self), ": cannot create thread at ndx $n:$!";
      }
   }
   return $self;
}

sub send_email {
   my $self = shift;
   my %p = @_;

   my @args = split '\n\n', $p{message};
   my $args = {};
   if ( scalar @args == 3 ) {
      @{$args}{qw/subject to msg/} = @args;
   } elsif ( scalar @args == 2 ) {
      @{$args}{qw/subject msg/} = @args;
   } elsif ( scalar @args == 1 ) {
      @{$args}{qw/subject msg/} = ( "message from $0", $args[0] );
   }  
   $args->{msg} = "\nMsg. Number :\t" . ++$self->{count} . "\n$args->{msg}";
   say ref($self), ":\tqueueing Msg.No.$self->{count}: $args->{subject}" 
      if $self->{debug_mode} >= 4;
   $self->{mailq}->enqueue( $args );
}

sub DESTROY {  # called on object, and on each thread
   my $self = shift;

   if ( ref $self->{mailer} ne 'Mail::Sender' ) {
      warn "Mailer was not created.  The network may not be available.\n";
      return -1; 
   }

   if ( $self->{ident} eq 'object' ) {
      my $timeleft = $self->{timeout};
      my $pending = $self->{mailq}->pending();
      while ( $pending and $timeleft ) {
         say "\r", ref($self), ": $pending emails still in queue; waiting for $timeleft secs" 
            if $self->{debug_mode} >= 2 and not $timeleft % ($self->{timeout}/6);
         sleep 1;
         $timeleft -= 1;
         $pending = $self->{mailq}->pending();
      }

      $self->{mailer}->Close(1);
      $self->{mailq}->end();
      my @left = (); 
      unless ( $timeleft ) {
         $_->kill('TERM') for threads->list( threads::running );
         my $args; push @left, $args while defined ($args = $self->{mailq}->dequeue());
      }
      my $sent = 0;
      for my $n ( 1 .. $self->{thread_count} ) {
         $sent += $self->{thread}[$n]->join();
         say ref($self), ": thread ", $self->{thread}[$n]->tid(), " has been joined" 
            if $self->{debug_mode} >= 2;
      }
      if ( $self->{count} != $sent ) { # number queued in main vs. total sent from all threads
         my $left = scalar(@left)." emails\n\t".join("\n\t", map {$_->{subject}} @left);
         carp ref($self), ": queued $self->{count}; sent $sent; throwing away after $self->{timeout} secs, $left\n";
      } else {
         say ref($self), ": closing $self->{ident} \\w tid $self->{tid} after $self->{count} emails queued"
            if $self->{debug_mode} >= 1;
      }
      
      # unless ( $timeleft ) {
      #    $_->kill('TERM') for threads->list( threads::running );
      # }
      # $self->{mailer}->Close(1);
      # $self->{mailq}->end();
      # my ( $sent, @left, $args ) = ( 0, () ); 
      # push @left, $args while defined ($args = $self->{mailq}->dequeue());
      # for my $n ( 1 .. $self->{thread_count} ) {
      #    $sent += $self->{thread}[$n]->join();
      #    say ref($self), ": thread ", $self->{thread}[$n]->tid(), " has been joined" if $self->{debug_mode} >= 1;
      # }
      # if ( $self->{count} != $sent ) { # number queued in main vs. total sent from all threads
      #    my $left = scalar(@left)." emails\n\t".join("\n\t", map {$_->{subject}} @left);
      #    carp ref($self), ": queued $self->{count}; sent $sent; throwing away $left\n";
      # } else {
      #    say ref($self), ": closing $self->{ident} \\w tid $self->{tid} after $self->{count} emails queued"
      #       if $self->{debug_mode} >= 1;
      # }

   } else {
      say ref($self), ": closing $self->{ident} \\w tid $self->{tid} after $self->{count} emails sent"
         if $self->{debug_mode} >= 1;
   }
}

1; # End of Log::Dispatch::Email::Async

__END__

=head1 NAME

Log::Dispatch::Email::Async - A L<Log::Log4Perl> appender for async email

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

   #!/usr/bin/perl
   use Modern::Perl;
   
   use Log::Log4perl qw/:levels/;
   use Log::Log4perl::Layout;
   use Proc::Daemon;
   
   Log::Log4perl::init( 'log4perl.conf' );
   my $fa = Log::Log4perl->appender_by_name( 'File' );
   my $logger = Log::Log4perl->get_logger( 'main' );
   
   Proc::Daemon::Init( {
      dont_close_fh  => [ $fa->{LDF}{fh},  ],   # for File log appender
      dont_close_fd  => [ 1, 2,  ],             # for Screen log appender
   } );
   
   my $email_appender = Log::Log4perl::Appender->new(
      'Log::Dispatch::Email::Async',

      # options for Log::Dispatch::Email::Async
      timeout        => 30,  # optional, default 30 secs
      thread_count   =>  2,  # optional, default 2 thread
      stack_size     => 16,  # optional, default 16 kilobyte
      debug_mode     =>  0,  # optional, default 0

      # options for Mail::Sender
      smtp           => 'smtp.example.com',	
      port           => 587,
      auth           => 'LOGIN',
      tls_required   => 1,
      authid         => 'username',
      authpwd        => 'password',

      # options for Log::Dispatch::Email
      buffered       => 0,
      subject        => "message logged from '$0'",
      from           => 'sender@example.com',
      to             => 'receipent@cpan.org', # reqd.

      # options for Log::Dispatch::Output
      name           => 'Email',              # reqd.
      min_level      => 1,
      max_level      => 5,
   );

   $email_appender->layout( 
      Log::Log4perl::Layout::PatternLayout->new('%p: %m%n%l' );
   $logger->add_appender( $email_appender );
   $logger->level($INFO);

   $logger->info( "start $0\n\nreceipient@domain.org\n\nMessage body . . ." );   

   my $RUN = 1;
   $SIG{TERM} = sub { $RUN = 0; };

   while ( $RUN ) {
      . . .
   }

=head1 DESCRIPTION

=head2 Introduction

This module is an extension for the Log::Dispatch::Email module.  It is an 
appender for Log::Log4perl.  It emails logged messages in seperate threads 
from the main one where logging occurs.  This enables the main thread to 
remain unblocked, while the emails are sent.  

A specified number of threads are started on creation of the module.  Emails 
are rapidly added to a queue in the main thread.  The multiple created 
threads race each other to empty the queue and email the content.  Each 
delivery may take upto several seconds but the main thread remains unblocked 
throughtout.  

At shutdown the module waits for a maximum specified timeout to allow the 
emails in queue to get sent.

=head2 Options

Perl threads are created with a seperate interpreter for each thread.  This 
is not the most most memory efficient.  Since the threads are created and 
remain in memory throughtout, unnecessarily large number of thread creation 
should be avoided.  

Depending on the number of threads and the anticipated volume of emails, an 
appropriate timeout should be set to allow for clearing any backlog, but also 
enabling the program to end if emails cannot be sent for some reason.

The stack size option is currently unused as its use appears to make the 
system unstable.

Options for other modules are documented in their own perldocs.  These modules 
are: Log::Dispatch::Email, Log::Dispatch::Output, Mail::Sender.

=head2 Daemons

Logging is an efficient way to display the state of long running daemons.  
Creating daemons involves forking two times to loose references of the 
starting shell.  Often it is required to initialize the logger before 
forking.  

Unfortunately, initialization of the mailing module does not survive this 
double forking.  The work arounds are: 1) initialize the logger after the 
forking is complete; and 2) initialize this appender in code as shown in 
the  SYNOPSIS.  (To preserve file and screen appenders across forkings, their 
file handles or descriptors also need to be preserved, somehow.)


=head1 METHODS

You will not be calling any of these methods explicitly.  The following is 
provided for help in understanding and in proper usage of this module.

=head2 new

Creates the object, the threads and the mailer.  It accepts and requires all 
options for Mail::Sender, Log::Dispatch::Email and Log::Dispatch::Output.  

This modules accepts these optional parameters: 

=head3 thread_count 

number of threads to create at the start; should be kept to a small number depending on email volume; default: 2 threads

=head3 timeout

seconds to waith for email backlog to clear on shutdown; must be kept large enough to clear anticipated backlog; default: 30 secs

=head3 stack_size

currently unused due to unstability; default: 16 kilobytes

=head3 debug_mode
   0 blocks all debug messaging; defaults is 0
   1 only print exit messages from DESTROY()
   2 also print detailed exist messages
   3 also print messages for object and threads creation 
   4 also print messages for enqueue, dequeue and emailing


=head2 send_email

Log::Dispatch::Email allows only a single string to be passed in.  If this
string contains double newlines, the string is split at these points.  Three 
parts are recognized - the subject line, receipients, and the message body.

If there is only a single split, the two field are assumed to be the Subject 
line and the message body; the reciepents in the mailer object set at creation
are used.

If there are no splits, the entire string string is used as the message body,
and a subject line is synthesised.

After determining the subject line, receipients, and the message body, 
they are simply added to the email queue for extraction and sending by the 
existing threads.


=head2 DESTROY

DESTROY is called for the main thread and once for each thread created.  If 
option debug_mode is set to a true value in the main routine, a line 
showing the emails handled by each thread is printed on STDERR.  The main 
thread (called object) shows the total number of emails queued.  This should 
equal the sum of the values in the threads.

=head1 TODOs

   DONE - create levels of debug messages for all methods; controlled by debug_mode
   - write tests
   - package and upload


=head1 AUTHOR

Raja Guha, C<< <rajag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-dispatch-email-async at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-Email-Async>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::Email::Async


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-Email-Async>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-Email-Async>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-Email-Async>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-Email-Async/>

=back


=head1 ACKNOWLEDGEMENTS

The entire Perl community, the Linux community, and all the good people 
of the world.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Raja Guha.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
