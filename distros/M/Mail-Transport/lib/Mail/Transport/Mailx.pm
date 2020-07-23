# Copyrights 2001-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::Mailx;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Transport::Send';

use strict;
use warnings;

use Carp;


sub init($)
{   my ($self, $args) = @_;

    $args->{via} = 'mailx';

    $self->SUPER::init($args) or return;

    $self->{MTM_program}
      = $args->{proxy}
     || $self->findBinary('mailx')
     || $self->findBinary('Mail')
     || $self->findBinary('mail')
     || return;

    $self->{MTM_style}
      = defined $args->{style}                       ? $args->{style}
      : $^O =~ m/linux|freebsd|bsdos|netbsd|openbsd/ ? 'BSD'
      :                                                'RFC822';

    $self;
}

#------------------------------------------


sub _try_send_bsdish($$)
{   my ($self, $message, $args) = @_;

    my @options = ('-s' => $message->subject);

    {   local $" = ',';
        my @cc  = map {$_->format} $message->cc;
        push @options, ('-c' => "@cc")  if @cc;

        my @bcc = map {$_->format} $message->bcc;
        push @options, ('-b' => "@bcc") if @bcc;
    }

    my @to      = map {$_->format} $message->to;
    my $program = $self->{MTM_program};

    if((open MAILER, '|-')==0)
    {   close STDOUT;
        { exec $program, @options, @to }
        $self->log(NOTICE => "Cannot start contact to $program: $!");
        exit 1;
    }
 
    $self->putContent($message, \*MAILER, body_only => 1);

    my $msgid = $message->messageId;

    if(close MAILER) { $self->log(PROGRESS => "Message $msgid send.") }
    else
    {   $self->log(ERROR => "Sending via mailx mailer $program failed: $! ($?)");
        return 0;
    }

    1;
}

sub trySend($@)
{   my ($self, $message, %args) = @_;

    return $self->_try_send_bsdish($message, \%args)
        if $self->{MTM_style} eq 'BSD';

    my $program = $self->{MTM_program};
    unless(open MAILER, '|-', $program, '-t')
    {   $self->log(NOTICE => "Cannot start contact to $program: $!");
        return 0;
    }
 
    $self->putContent($message, \*MAILER);

    unless(close MAILER)
    {   $self->log(ERROR => "Sending via mailx mailer $program failed: $! ($?)");
        return 0;
    }

    1;
}

#------------------------------------------

1;
