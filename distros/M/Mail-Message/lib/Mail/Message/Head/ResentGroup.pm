# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Head::ResentGroup;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Head::FieldGroup';

use strict;
use warnings;

use Scalar::Util 'weaken';
use Mail::Message::Field::Fast;

use Sys::Hostname 'hostname';
use Mail::Address;


# all lower cased!
my @ordered_field_names =
  ( 'return-path', 'delivered-to' , 'received', 'resent-date'
  , 'resent-from', 'resent-sender', , 'resent-to', 'resent-cc'
  , 'resent-bcc', 'resent-message-id'
  );

my %resent_field_names = map { ($_ => 1) } @ordered_field_names;

sub init($$)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);

    $self->{MMHR_real}  = $args->{message_head};

    $self->set(Received => $self->createReceived)
        if $self->orderedFields && ! $self->received;

    $self;
}


sub from($@)
{   return $_[0]->resentFrom if @_ == 1;   # backwards compat

    my ($class, $from, %args) = @_;
    my $head = $from->isa('Mail::Message::Head') ? $from : $from->head;

    my (@groups, $group, $return_path, $delivered_to);

    foreach my $field ($head->orderedFields)
    {   my $name = $field->name;
        next unless $resent_field_names{$name};

        if($name eq 'return-path')              { $return_path  = $field }
        elsif($name eq 'delivered-to')          { $delivered_to = $field }
        elsif(substr($name, 0, 7) eq 'resent-')
        {   $group->add($field) if defined $group }
        elsif($name eq 'received')
        {
            $group = Mail::Message::Head::ResentGroup
                          ->new($field, message_head => $head);
            push @groups, $group;

            $group->add($delivered_to) if defined $delivered_to;
            undef $delivered_to;

            $group->add($return_path) if defined $return_path;
            undef $return_path;
        }
    }

    @groups;
}

#------------------------------------------


sub messageHead(;$)
{   my $self = shift;
    @_ ? $self->{MMHR_real} = shift : $self->{MMHR_real};
}


sub orderedFields()
{   my $head = shift->head;
    map { $head->get($_) || () } @ordered_field_names;
}


sub set($;$)
{   my $self  = shift;
    my $field;

    if(@_==1) { $field = shift }
    else
    {   my ($fn, $value) = @_;
        my $name  = $resent_field_names{lc $fn} ? $fn : "Resent-$fn";
        $field = Mail::Message::Field::Fast->new($name, $value);
    }

    $self->head->set($field);
    $field;
}

sub fields()     { shift->orderedFields }
sub fieldNames() { map { $_->Name } shift->orderedFields }

sub delete()
{   my $self   = shift;
    my $head   = $self->messageHead;
    $head->removeField($_) foreach $self->fields;
    $self;
}


sub add(@) { shift->set(@_) }


sub addFields(@) { shift->notImplemented }

#-------------------------------------------


sub returnPath() { shift->{MMHR_return_path} }


sub deliveredTo() { shift->head->get('Delivered-To') }


sub received() { shift->head->get('Received') }


sub receivedTimestamp()
{   my $received = shift->received or return;
    my $comment  = $received->comment or return;
    Mail::Message::Field->dateToTimestamp($comment);
}


sub date($) { shift->head->get('resent-date') }


sub dateTimestamp()
{   my $date = shift->date or return;
    Mail::Message::Field->dateToTimestamp($date->unfoldedBody);
}


sub resentFrom()
{   my $from = shift->head->get('resent-from') or return ();
    wantarray ? $from->addresses : $from;
}


sub sender()
{   my $sender = shift->head->get('resent-sender') or return ();
    wantarray ? $sender->addresses : $sender;
}


sub to()
{   my $to = shift->head->get('resent-to') or return ();
    wantarray ? $to->addresses : $to;
}


sub cc()
{   my $cc = shift->head->get('resent-cc') or return ();
    wantarray ? $cc->addresses : $cc;
}


sub bcc()
{   my $bcc = shift->head->get('resent-bcc') or return ();
    wantarray ? $bcc->addresses : $bcc;
}


sub destinations()
{   my $self = shift;
    ($self->to, $self->cc, $self->bcc);
}


sub messageId() { shift->head->get('resent-message-id') }


sub isResentGroupFieldName($) { $resent_field_names{lc $_[1]} }

#------------------------------------------


my $unique_received_id = 'rc'.time;

sub createReceived(;$)
{   my ($self, $domain) = @_;

    unless(defined $domain)
    {   my $sender = ($self->sender)[0] || ($self->resentFrom)[0];
        $domain    = $sender->host if defined $sender;
    }

    my $received
      = 'from ' . $domain
      . ' by '  . hostname
      . ' with SMTP'
      . ' id '  . $unique_received_id++
      . ' for ' . $self->head->get('Resent-To')  # may be wrong
      . '; '. Mail::Message::Field->toDate;

    $received;
}

#-------------------------------------------


1;
