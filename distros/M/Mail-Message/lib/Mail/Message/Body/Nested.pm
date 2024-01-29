# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body::Nested;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Body';

use strict;
use warnings;

use Mail::Message::Body::Lines;
use Mail::Message::Part;

use Carp;


sub init($)
{   my ($self, $args) = @_;
    $args->{mime_type} ||= 'message/rfc822';

    $self->SUPER::init($args);

    my $nested;
    if(my $raw = $args->{nested})
    {   $nested = Mail::Message::Part->coerce($raw, $self);

        croak 'Data not convertible to a message (type is ', ref $raw,")\n"
            unless defined $nested;
    }

    $self->{MMBN_nested} = $nested;
    $self;
}

sub isNested() {1}

sub isBinary() { shift->nested->body->isBinary }

sub clone()
{   my $self     = shift;

    ref($self)->new
     ( $self->logSettings
     , based_on => $self
     , nested   => $self->nested->clone
     );
}

sub nrLines() { shift->nested->nrLines }

sub size()    { shift->nested->size }

sub string()
{    my $nested = shift->nested;
     defined $nested ? $nested->string : '';
}

sub lines()
{    my $nested = shift->nested;
     defined $nested ? ($nested->lines) : ();
}

sub file()
{    my $nested = shift->nested;
     defined $nested ? $nested->file : undef;
}

sub print(;$)
{   my $self = shift;
    $self->nested->print(shift || select);
}

sub partNumberOf($)
{   my ($self, $part) = @_;
    $self->message->partNumber || '1';
}


sub foreachLine($)
{   my ($self, $code) = @_;
    $self->log(ERROR => "You cannot use foreachLine on a nested");
    confess;
}

sub check() { shift->forNested( sub {$_[1]->check} ) }

sub encode(@)
{   my ($self, %args) = @_;
    $self->forNested( sub {$_[1]->encode(%args)} );
}

sub encoded() { shift->forNested( sub {$_[1]->encoded} ) }

sub read($$$$)
{   my ($self, $parser, $head, $bodytype) = @_;

    my $nest = Mail::Message::Part->new(container => undef);
    $nest->readFromParser($parser, $bodytype)
       or return;

    $nest->container($self);
    $self->{MMBN_nested} = $nest;
    $self;
}

sub fileLocation()
{   my $nested   = shift->nested;

    ( ($nested->head->fileLocation)[0]
    , ($nested->body->fileLocation)[1]
    );
}

sub endsOnNewline() { shift->nested->body->endsOnNewline }

sub moveLocation($)
{   my $self   = shift;
    my $nested = $self->nested;
    my $dist   = shift or return $self;  # no move

    $nested->head->moveLocation($dist);
    $nested->body->moveLocation($dist);
    $self;
}

#-------------------------

sub nested() { shift->{MMBN_nested} }


sub forNested($)
{   my ($self, $code) = @_;
    my $nested    = $self->nested;
    my $body      = $nested->body;

    my $new_body  = $code->($self, $body)
       or return;

    return $self if $new_body == $body;

    my $new_nested  = Mail::Message::Part->new
       ( head      => $nested->head->clone
       , container => undef
       );

    $new_nested->body($new_body);

    my $created = (ref $self)->new
      ( based_on => $self
      , nested   => $new_nested
      );

    $new_nested->container($created);
    $created;
}

sub toplevel() { my $msg = shift->message; $msg ? $msg->toplevel : undef}

1;
