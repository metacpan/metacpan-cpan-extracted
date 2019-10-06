# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::File::Message;
use vars '$VERSION';
$VERSION = '3.008';

use base 'Mail::Box::Message';

use strict;
use warnings;

use List::Util   qw/sum/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->fromLine($args->{from_line})
        if exists $args->{from_line};

    $self;
}

sub coerce($)
{   my ($self, $message) = @_;
    return $message if $message->isa(__PACKAGE__);
    $self->SUPER::coerce($message)->labelsToStatus;
}


sub write(;$)
{   my $self  = shift;
    my $out   = shift || select;

    my $escaped = $self->escapedBody;
    $out->print($self->fromLine);

    my $size  = sum 0, map {length($_)} @$escaped;

    my $head  = $self->head;
    $head->set('Content-Length' => $size); 
    $head->set('Lines' => scalar @$escaped);
    $head->print($out);

    $out->print($_) for @$escaped;
    $out->print("\n");
    $self;
}

sub clone()
{   my $self  = shift;
    my $clone = $self->SUPER::clone;
    $clone->{MBMM_from_line} = $self->{MBMM_from_line};
    $clone;
}

#-------------------------------------------


sub fromLine(;$)
{   my $self = shift;

    $self->{MBMM_from_line} = shift if @_;
    $self->{MBMM_from_line} ||= $self->head->createFromLine;
}


sub escapedBody()
{   my @lines = shift->body->lines;
    s/^(\>*From )/>$1/ for @lines;
    \@lines;
}

#------------------------------------------


sub readFromParser($)
{   my ($self, $parser) = @_;
    my ($start, $fromline)  = $parser->readSeparator;
    return unless $fromline;

    $self->{MBMM_from_line} = $fromline;
    $self->{MBMM_begin}     = $start;

    $self->SUPER::readFromParser($parser) or return;
    $self;
}

sub loadHead() { shift->head }


sub loadBody()
{   my $self     = shift;

    my $body     = $self->body;
    return $body unless $body->isDelayed;

    my ($begin, $end) = $body->fileLocation;
    my $parser   = $self->folder->parser;
    $parser->filePosition($begin);

    my $newbody  = $self->readBody($parser, $self->head);
    unless($newbody)
    {   $self->log(ERROR => 'Unable to read delayed body.');
        return;
    }

    $self->log(PROGRESS => 'Loaded delayed body.');
    $self->storeBody($newbody->contentInfoFrom($self->head));

    $newbody;
}


sub fileLocation()
{   my $self = shift;

    wantarray
     ? ($self->{MBMM_begin}, ($self->body->fileLocation)[1])
     : $self->{MBMM_begin};
}


sub moveLocation($)
{   my ($self, $dist) = @_;
    $self->{MBMM_begin} -= $dist;

    $self->head->moveLocation($dist);
    $self->body->moveLocation($dist);
    $self;
}

#-------------------------------------------

1;
