# Copyrights 2001-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::Qmail;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Transport::Send';

use strict;
use warnings;

use Carp;


sub init($)
{   my ($self, $args) = @_;

    $args->{via} = 'qmail';

    $self->SUPER::init($args) or return;

    $self->{MTM_program}
      = $args->{proxy}
     || $self->findBinary('qmail-inject', '/var/qmail/bin')
     || return;

    $self;
}

#------------------------------------------


sub trySend($@)
{   my ($self, $message, %args) = @_;

    my $program = $self->{MTM_program};
    if(open(MAILER, '|-')==0)
    {   { exec $program; }
        $self->log(NOTICE => "Errors when opening pipe to $program: $!");
        exit 1;
    }
 
    $self->putContent($message, \*MAILER, undisclosed => 1);

    unless(close MAILER)
    {   $self->log(ERROR => "Errors when closing Qmail mailer $program: $!");
        $? ||= $!;
        return 0;
    }

    1;
}

#------------------------------------------

1;
