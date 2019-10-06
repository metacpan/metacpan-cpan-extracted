# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Message;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Message';

use strict;
use warnings;

use Scalar::Util 'weaken';


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{MBM_body_type} = $args->{body_type};
    $self->{MBM_folder}    = $args->{folder};
    weaken($self->{MBM_folder});

    return $self if $self->isDummy;
    $self;
}

sub head(;$)
{   my $self  = shift;
    return $self->SUPER::head unless @_;

    my $new   = shift;
    my $old   = $self->head;
    $self->SUPER::head($new);

    return unless defined $new || defined $old;

    my $folder = $self->folder
        or return $new;

    if(!defined $new && defined $old && !$old->isDelayed)
    {   $folder->messageId($self->messageId, undef);
        $folder->toBeUnthreaded($self);
    }
    elsif(defined $new && !$new->isDelayed)
    {   $folder->messageId($self->messageId, $self);
        $folder->toBeThreaded($self);
    }

    $new || $old;
}

#-------------------------------------------


sub folder(;$)
{   my $self = shift;
    if(@_)
    {   $self->{MBM_folder} = shift;
        weaken($self->{MBM_folder});
        $self->modified(1);
    }
    $self->{MBM_folder};
}


sub seqnr(;$)
{   my $self = shift;
    @_ ? $self->{MBM_seqnr} = shift : $self->{MBM_seqnr};
}


sub copyTo($@)
{   my ($self, $folder) = (shift, shift);
    $folder->addMessage($self->clone(@_));
}


sub moveTo($@)
{   my ($self, $folder, %args) = @_;

    $args{share} = 1
        unless exists $args{share} || exists $args{shallow_body};

    my $added = $self->copyTo($folder, %args);
    $self->label(deleted => 1);
    $added;
}

#-------------------------------------------


sub readBody($$;$)
{   my ($self, $parser, $head, $getbodytype) = @_;

    unless($getbodytype)
    {   my $folder   = $self->{MBM_folder};
        $getbodytype = sub {$folder->determineBodyType(@_)} if defined $folder;
    }

    $self->SUPER::readBody($parser, $head, $getbodytype);
}


sub diskDelete() { shift }

sub forceLoad() {   # compatibility
   my $self = shift;
   $self->loadBody(@_);
   $self;
}

#-------------------------------------------


sub destruct()
{   require Mail::Box::Message::Destructed;
    Mail::Box::Message::Destructed->coerce(shift);
}

1;
