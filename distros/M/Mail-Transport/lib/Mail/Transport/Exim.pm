# Copyrights 2001-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::Exim;
use vars '$VERSION';
$VERSION = '3.006';

use base 'Mail::Transport::Send';

use strict;
use warnings;

use Carp;


sub init($)
{   my ($self, $args) = @_;
    $args->{via} = 'exim';

    $self->SUPER::init($args) or return;

    $self->{MTS_program} = $args->{proxy}
     || ( -x '/usr/sbin/exim4' ? '/usr/sbin/exim4' : undef)
     || $self->findBinary('exim', '/usr/exim/bin')
     || return;

    $self;
}


sub trySend($@)
{   my ($self, $message, %args) = @_;

    my $from = $args{from} || $message->sender;
    $from    = $from->address if ref $from && $from->isa('Mail::Address');
    my @to   = map $_->address, $self->destinations($message, $args{to});

    my $program = $self->{MTS_program};
    my $mailer;
    if(open($mailer, '|-')==0)
    {   { exec $program, '-i', '-f', $from, @to; }  # {} to avoid warning
        $self->log(NOTICE => "Errors when opening pipe to $program: $!");
        exit 1;
    }

    $self->putContent($message, $mailer, undisclosed => 1);

    unless($mailer->close)
    {   $self->log(ERROR => "Errors when closing Exim mailer $program: $!");
        $? ||= $!;
        return 0;
    }

    1;
}

1;
