# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Search;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);

    my $in = $args->{in} || 'BODY';
    @$self{ qw/MBS_check_head MBS_check_body/ }
      = $in eq 'BODY'    ? (0,1)
      : $in eq 'HEAD'    ? (1,0)
      : $in eq 'MESSAGE' ? (1,1)
      : ($self->log(ERROR => "Search in BODY, HEAD or MESSAGE not $in."), return);

    $self->log(ERROR => "Cannot search in header."), return
        if $self->{MBS_check_head} && !$self->can('inHead');

    $self->log(ERROR => "Cannot search in body."), return
        if $self->{MBS_check_body} && !$self->can('inBody');

    my $deliver             = $args->{deliver};
    $self->{MBS_deliver}
      = ref $deliver eq 'CODE' ? sub { $deliver->($self, $_[0]) }
      : !defined $deliver      ? undef
      : $deliver eq 'DELETE'
        ? sub {$_[0]->{part}->toplevel->label(deleted => 1)}
      : $self->log(ERROR => "Don't know how to deliver results in $deliver.");

    my $logic               = $args->{logical}  || 'REPLACE';
    $self->{MBS_negative}   = $logic =~ s/\s*NOT\s*$//;
    $self->{MBS_logical}    = $logic;

    $self->{MBS_label}      = $args->{label};
    $self->{MBS_binaries}   = $args->{binaries} || 0;
    $self->{MBS_limit}      = $args->{limit}    || 0;
    $self->{MBS_decode}     = $args->{decode}   || 1;
    $self->{MBS_no_deleted} = not $args->{deleted};
    $self->{MBS_delayed}    = defined $args->{delayed} ? $args->{delayed} : 1;
    $self->{MBS_multiparts}
       = defined $args->{multiparts} ? $args->{multiparts} : 1;

    $self;
}

#-------------------------------------------


sub search(@)
{   my ($self, $object) = @_;

    my $label         = $self->{MBS_label};
    my $limit         = $self->{MBS_limit};

    my @messages
      = ref $object eq 'ARRAY'        ? @$object
      : $object->isa('Mail::Box')     ? $object->messages
      : $object->isa('Mail::Message') ? ($object)
      : $object->isa('Mail::Box::Thread::Node') ? $object->threadMessages
      : croak "Expect messages to search, not $object.";

    my $take = 0;
    if($limit < 0)    { $take = -$limit; @messages = reverse @messages }
    elsif($limit > 0) { $take = $limit }
    elsif(!defined $label && !wantarray && !$self->{MBS_deliver}) {$take = 1 }

    my $logic         = $self->{MBS_logical};
    my @selected;
    my $count = 0;

    foreach my $message (@messages)
    {   next if $self->{MBS_no_deleted} && $message->isDeleted;
        next unless $self->{MBS_delayed} || !$message->isDelayed;

        my $set = defined $label ? $message->label($label) : 0;

        my $selected
          =  $set && $logic eq 'OR'  ? 1
          : !$set && $logic eq 'AND' ? 0
          : $self->{MBS_negative}    ? ! $self->searchPart($message)
          :                            $self->searchPart($message);

        $message->label($label => $selected) if defined $label;
        if($selected)
        {   push @selected, $message;
            $count++;
            last if $take && $count == $take;
        }
    }

    $limit < 0 ? reverse @selected : @selected;
}


#-------------------------------------------


sub searchPart($)
{  my ($self, $part) = @_;

   my $matched = 0;
   $matched  = $self->inHead($part, $part->head)
      if $self->{MBS_check_head};

   return $matched unless $self->{MBS_check_body};
   return $matched if $matched && !$self->{MBS_deliver};

   my $body  = $part->body;
   my @bodies;

   # Handle multipart parts.

   if($body->isMultipart)
   {   return $matched unless $self->{MBS_multiparts};
       my $no_delayed = not $self->{MBS_delayed};
       @bodies = ($body->preamble, $body->epilogue);

       foreach my $piece ($body->parts)
       {   next unless defined $piece;
           next if $no_delayed && $piece->isDelayed;

           $matched += $self->searchPart($piece);
           return $matched if $matched && !$self->{MBS_deliver};
       }
   }
   elsif($body->isNested)
   {   return $matched unless $self->{MBS_multiparts};
       $matched += $self->searchPart($body->nested);
   }
   else
   {   @bodies = ($body);
   }

   # Handle normal bodies.

   foreach (@bodies)
   {   next unless defined $_;
       next if !$self->{MBS_binaries} && $_->isBinary;
       my $body   = $self->{MBS_decode} ? $_->decoded : $_;
       my $inbody = $self->inBody($part, $body);
       $matched  += $inbody;
   }

   $matched;
}

#-------------------------------------------


sub inHead(@) {shift->notImplemented}

#-------------------------------------------


sub inBody(@) {shift->notImplemented}

#-------------------------------------------


sub printMatch($) {shift->notImplemented}

#-------------------------------------------


1;
