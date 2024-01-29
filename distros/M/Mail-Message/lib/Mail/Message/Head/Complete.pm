# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Head::Complete;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Head';

use strict;
use warnings;

use Mail::Box::Parser;
use Mail::Message::Head::Partial;

use Scalar::Util  qw/weaken/;
use List::Util    qw/sum/;
use Sys::Hostname qw/hostname/;


sub clone(;@)
{   my $self   = shift;
    my $copy   = ref($self)->new($self->logSettings);

    $copy->addNoRealize($_->clone) for $self->grepNames(@_);
    $copy->modified(1);
    $copy;
}


sub build(@)
{   my $class = shift;
    my $self  = $class->new;
    while(@_)
    {   my $name = shift;
        defined $name or next;

        if($name->isa('Mail::Message::Field'))
        {   $self->add($name);
            next;
        }

        my $content = shift;
        defined $content or next;

        if(ref $content && $content->isa('Mail::Message::Field'))
        {   $self->log(WARNING => "Field objects have an implied name ($name)");
            $self->add($content);
            next;
        }

        $self->add($name, $content);
    }

    $self;
}

#------------------------------------------


sub isDelayed() {0}


sub nrLines() { sum 1, map $_->nrLines, shift->orderedFields }
sub size() { sum 1, map $_->size, shift->orderedFields }


sub wrap($)
{   my ($self, $length) = @_;
    $_->setWrapLength($length) for $self->orderedFields;
}

#------------------------------------------


sub add(@)
{   my $self = shift;

    # Create object for this field.

    my $field
      = @_==1 && ref $_[0] ? shift     # A fully qualified field is added.
      : ($self->{MMH_field_type} || 'Mail::Message::Field::Fast')->new(@_);

    return if !defined $field;

    $field->setWrapLength;

    # Put it in place.

    my $known = $self->{MMH_fields};
    my $name  = $field->name;  # is already lower-cased

    $self->addOrderedFields($field);

    if(defined $known->{$name})
    {   if(ref $known->{$name} eq 'ARRAY') { push @{$known->{$name}}, $field }
        else { $known->{$name} = [ $known->{$name}, $field ] }
    }
    else
    {   $known->{$name} = $field;
    }

    $self->{MMH_modified}++;
    $field;
}


sub count($)
{   my $known = shift->{MMH_fields};
    my $value = $known->{lc shift};

      ! defined $value ? 0
    : ref $value       ? @$value
    :                    1;
}


sub names() {shift->knownNames}


sub grepNames(@)
{   my $self = shift;
    my @take;
    push @take, (ref $_ eq 'ARRAY' ? @$_ : $_) foreach @_;

    return $self->orderedFields unless @take;

    my $take;
    if(@take==1 && ref $take[0] eq 'Regexp')
    {   $take    = $take[0];   # one regexp prepared already
    }
    else
    {   # I love this trick:
        local $" = ')|(?:';
        $take    = qr/^(?:(?:@take))/i;
    }

    grep {$_->name =~ $take} $self->orderedFields;
}


my @skip_none = qw/content-transfer-encoding content-disposition
                   content-description content-id/;

my %skip_none = map { ($_ => 1) } @skip_none;

sub set(@)
{   my $self = shift;
    my $type = $self->{MMH_field_type} || 'Mail::Message::Field::Fast';
    $self->{MMH_modified}++;

    # Create object for this field.
    my $field = @_==1 && ref $_[0] ? shift->clone : $type->new(@_);

    my $name  = $field->name;         # is already lower-cased
    my $known = $self->{MMH_fields};

    # Internally, non-existing content-info are in the body stored as 'none'
    # The header will not contain these lines.

    if($skip_none{$name} && $field->body eq 'none')
    {   delete $known->{$name};
        return $field;
    }

    $field->setWrapLength;
    $known->{$name} = $field;

    $self->addOrderedFields($field);
    $field;
}


sub reset($@)
{   my ($self, $name) = (shift, lc shift);

    my $known = $self->{MMH_fields};

    if(@_==0)
    {   $self->{MMH_modified}++ if delete $known->{$name};
        return ();
    }

    $self->{MMH_modified}++;

    # Cloning required, otherwise double registrations will not be
    # removed from the ordered list: that's controled by 'weaken'

    my @fields = map $_->clone, @_;

    if(@_==1) { $known->{$name} = $fields[0] }
    else      { $known->{$name} = [@fields]  }

    $self->addOrderedFields(@fields);
    $self;
}


sub delete($) { $_[0]->reset($_[1]) }


sub removeField($)
{   my ($self, $field) = @_;
    my $name  = $field->name;
    my $known = $self->{MMH_fields};

    if(!defined $known->{$name})
    { ; }  # complain
    elsif(ref $known->{$name} eq 'ARRAY')
    {    for(my $i=0; $i < @{$known->{$name}}; $i++)
         {
             return splice @{$known->{$name}}, $i, 1
                 if $known->{$name}[$i] eq $field;
         }
    }
    elsif($known->{$name} eq $field)
    {    return delete $known->{$name};
    }

    $self->log(WARNING => "Cannot remove field $name from header: not found.");

    return;
}


sub removeFields(@)
{   my $self = shift;
    (bless $self, 'Mail::Message::Head::Partial')->removeFields(@_);
}


sub removeFieldsExcept(@)
{   my $self = shift;
    (bless $self, 'Mail::Message::Head::Partial')->removeFieldsExcept(@_);
}


sub removeContentInfo() { shift->removeFields(qr/^Content-/, 'Lines') }


sub removeResentGroups(@)
{   my $self = shift;
    (bless $self, 'Mail::Message::Head::Partial')->removeResentGroups(@_);
}


sub removeListGroup(@)
{   my $self = shift;
    (bless $self, 'Mail::Message::Head::Partial')->removeListGroup(@_);
}


sub removeSpamGroups(@)
{   my $self = shift;
    (bless $self, 'Mail::Message::Head::Partial')->removeSpamGroups(@_);
}


sub spamDetected()
{   my $self = shift;
    my @sgs = $self->spamGroups or return undef;
    grep { $_->spamDetected } @sgs;
}


sub print(;$)
{   my $self  = shift;
    my $fh    = shift || select;

    $_->print($fh)
        foreach $self->orderedFields;

    if(ref $fh eq 'GLOB') { print $fh "\n" }
    else                  { $fh->print("\n") }

    $self;
}


sub printUndisclosed($)
{   my ($self, $fh) = @_;

    $_->print($fh)
       foreach grep {$_->toDisclose} $self->orderedFields;

    if(ref $fh eq 'GLOB') { print $fh "\n" }
    else                  { $fh->print("\n") }

    $self;
}


sub printSelected($@)
{   my ($self, $fh) = (shift, shift);

    foreach my $field ($self->orderedFields)
    {   my $Name = $field->Name;
        my $name = $field->name;

        my $found;
        foreach my $pattern (@_)
        {   $found = ref $pattern?($Name =~ $pattern):($name eq lc $pattern);
            last if $found;
        }

           if(!$found)           { ; }
        elsif(ref $fh eq 'GLOB') { print $fh "\n" }
        else                     { $fh->print("\n") }
    }

    $self;
}


sub toString() {shift->string}
sub string()
{   my $self  = shift;

    my @lines = map {$_->string} $self->orderedFields;
    push @lines, "\n";

    wantarray ? @lines : join('', @lines);
}


sub resentGroups()
{   my $self = shift;
    require Mail::Message::Head::ResentGroup;
    Mail::Message::Head::ResentGroup->from($self);
}


sub addResentGroup(@)
{   my $self  = shift;

    require Mail::Message::Head::ResentGroup;
    my $rg = @_==1 ? (shift) : Mail::Message::Head::ResentGroup->new(@_);

    my @fields = $rg->orderedFields;
    my $order  = $self->{MMH_order};

    # Look for the first line which relates to resent groups
    my $i;
    for($i=0; $i < @$order; $i++)
    {   next unless defined $order->[$i];
        last if $rg->isResentGroupFieldName($order->[$i]->name);
    }

    my $known = $self->{MMH_fields};
    while(@fields)
    {   my $f    = pop @fields;

        # Add to the order of fields
        splice @$order, $i, 0, $f;
        weaken( $order->[$i] );
        my $name = $f->name;

        # Adds *before* in the list for get().
           if(!defined $known->{$name})      {$known->{$name} = $f}
        elsif(ref $known->{$name} eq 'ARRAY'){unshift @{$known->{$name}},$f}
        else                       {$known->{$name} = [$f, $known->{$name}]}
    }

    $rg->messageHead($self);

    # Oh, the header has changed!
    $self->modified(1);

    $rg;
}


sub listGroup()
{   my $self = shift;
    eval "require 'Mail::Message::Head::ListGroup'";
    Mail::Message::Head::ListGroup->from($self);
}


sub addListGroup($)
{   my ($self, $lg) = @_;
    $lg->attach($self);
}


sub spamGroups(@)
{   my $self = shift;
    require Mail::Message::Head::SpamGroup;
    my @types = @_ ? (types => \@_) : ();
    my @sgs   = Mail::Message::Head::SpamGroup->from($self, @types);
    wantarray || @_ != 1 ? @sgs : $sgs[0];
}


sub addSpamGroup($)
{   my ($self, $sg) = @_;
    $sg->attach($self);
}

#------------------------------------------


sub timestamp() {shift->guessTimestamp || time}


sub recvstamp()
{   my $self = shift;

    return $self->{MMH_recvstamp} if exists $self->{MMH_recvstamp};

    my $recvd = $self->get('received', 0) or
        return $self->{MMH_recvstamp} = undef;

    my $stamp = Mail::Message::Field->dateToTimestamp($recvd->comment);

    $self->{MMH_recvstamp} = defined $stamp && $stamp > 0 ? $stamp : undef;
}


sub guessTimestamp()
{   my $self = shift;
    return $self->{MMH_timestamp} if exists $self->{MMH_timestamp};

    my $stamp;
    if(my $date = $self->get('date'))
    {   $stamp = Mail::Message::Field->dateToTimestamp($date);
    }

    unless($stamp)
    {   foreach (reverse $self->get('received'))
        {   $stamp = Mail::Message::Field->dateToTimestamp($_->comment);
            last if $stamp;
        }
    }

    $self->{MMH_timestamp} = defined $stamp && $stamp > 0 ? $stamp : undef;
}

sub guessBodySize()
{   my $self = shift;

    my $cl = $self->get('Content-Length');
    return $1 if defined $cl && $cl =~ m/(\d+)/;

    my $lines = $self->get('Lines');   # 40 chars per lines
    return $1 * 40   if defined $lines && $lines =~ m/(\d+)/;

    undef;
}

#------------------------------------------


sub createFromLine()
{   my $self   = shift;
    my $sender = $self->message->sender;
    my $stamp  = $self->recvstamp || $self->timestamp || time;
    my $addr   = defined $sender ? $sender->address : 'unknown';
    "From $addr ".(gmtime $stamp)."\n"
}


my $msgid_creator;

sub createMessageId()
{   $msgid_creator ||= $_[0]->messageIdPrefix;
    $msgid_creator->(@_);
}


sub messageIdPrefix(;$$)
{   my $thing = shift;
    return $msgid_creator
       unless @_ || !defined $msgid_creator;

    return $msgid_creator = shift
       if @_==1 && ref $_[0] eq 'CODE';

    my $prefix   = shift || "mailbox-$$";

    my $hostname = shift;
    if(!defined $hostname)
    {   eval "require Net::Domain";
        $@ or $hostname = Net::Domain::hostfqdn();
    }
    $hostname ||= hostname || 'localhost';

    eval "require Time::HiRes";
    if(Time::HiRes->can('gettimeofday'))
    {
        return $msgid_creator
          = sub { my ($sec, $micro) = Time::HiRes::gettimeofday();
                  "$prefix-$sec-$micro\@$hostname";
                };
    }

    my $unique_id = time;
    $msgid_creator
      = sub { $unique_id++;
              "$prefix-$unique_id\@$hostname";
            };
}

1;
