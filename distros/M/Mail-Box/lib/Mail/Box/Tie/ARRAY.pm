# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Tie::ARRAY;
use vars '$VERSION';
$VERSION = '3.010';


use strict;
use warnings;

use Carp;


sub TIEARRAY(@)
{   my ($class, $folder) = @_;
    croak "No folder specified to tie to."
        unless ref $folder && $folder->isa('Mail::Box');

    bless { MBT_folder => $folder }, $class;
}

#-------------------------------------------


sub FETCH($)
{   my ($self, $index) = @_;
    my $msg = $self->{MBT_folder}->message($index);
    $msg->isDeleted ? undef : $msg;
}

#-------------------------------------------


sub STORE($$)
{   my ($self, $index, $msg) = @_;
    my $folder = $self->{MBT_folder};

    croak "Cannot simply replace messages in a folder: use delete old, then push new."
        unless $index == $folder->messages;

    $folder->addMessages($msg);
    $msg;
}


sub FETCHSIZE()  { scalar shift->{MBT_folder}->messages }


sub PUSH(@)
{   my $folder = shift->{MBT_folder};
    $folder->addMessages(@_);
    scalar $folder->messages;
}
 

sub DELETE($) { shift->{MBT_folder}->message(shift)->delete }


sub STORESIZE($)
{   my $folder = shift->{MBT_folder};
    my $length = shift;
    $folder->message($_) foreach $length..$folder->messages;
    $length;
}

# DESTROY is implemented in Mail::Box

#-------------------------------------------


1;
