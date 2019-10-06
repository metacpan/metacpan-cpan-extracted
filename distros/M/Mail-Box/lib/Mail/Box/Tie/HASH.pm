# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Tie::HASH;
use vars '$VERSION';
$VERSION = '3.008';


use strict;
use warnings;

use Carp;


sub TIEHASH(@)
{   my ($class, $folder) = @_;
    croak "No folder specified to tie to."
        unless ref $folder && $folder->isa('Mail::Box');

    bless { MBT_folder => $folder, MBT_type => 'HASH' }, $class;
}

#-------------------------------------------

sub FETCH($) { shift->{MBT_folder}->messageId(shift) }


sub STORE($$)
{   my ($self, $key, $basicmsg) = @_;

    carp "Use undef as key, because the message-id of the message is used."
        if defined $key && $key ne 'undef';

    $self->{MBT_folder}->addMessages($basicmsg);
}


sub FIRSTKEY()
{   my $self   = shift;
    my $folder = $self->{MBT_folder};

    $self->{MBT_each_index} = 0;
    $self->NEXTKEY();
}

#-------------------------------------------


sub NEXTKEY($)
{   my $self   = shift;
    my $folder = $self->{MBT_folder};
    my $nrmsgs = $folder->messages;

    my $msg;
    while(1)
    {   my $index = $self->{MBT_each_index}++;
        return undef if $index >= $nrmsgs;

        $msg      = $folder->message($index);
        last unless $msg->isDeleted;
    }

    $msg->messageId;
}


sub EXISTS($)
{   my $folder = shift->{MBT_folder};
    my $msgid  = shift;
    my $msg    = $folder->messageId($msgid);
    defined $msg && ! $msg->isDeleted;
}


sub DELETE($)
{    my ($self, $msgid) = @_;
     $self->{MBT_folder}->messageId($msgid)->delete;
}

#-------------------------------------------


sub CLEAR()
{   my $folder = shift->{MBT_folder};
    $_->delete foreach $folder->messages;
}

#-------------------------------------------

1;
