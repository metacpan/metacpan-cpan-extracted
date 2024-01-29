# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Part;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message';

use strict;
use warnings;

use Scalar::Util    'weaken';
use Carp;


sub init($)
{   my ($self, $args) = @_;
    $args->{head} ||= Mail::Message::Head::Complete->new;

    $self->SUPER::init($args);

    confess "No container specified for part.\n"
        unless exists $args->{container};

    weaken($self->{MMP_container})
       if $self->{MMP_container} = $args->{container};

    $self;
}


sub coerce($@)
{   my ($class, $thing, $container) = (shift, shift, shift);
    if($thing->isa($class))
    {   $thing->container($container);
        return $thing;
    }

    return $class->buildFromBody($thing, $container, @_)
        if $thing->isa('Mail::Message::Body');

    # Although cloning is a Bad Thing(tm), we must avoid modifying
    # header fields of messages which reside in a folder.
    my $message = $thing->isa('Mail::Box::Message') ? $thing->clone : $thing;

    my $part    = $class->SUPER::coerce($message);
    $part->container($container);
    $part;
}


sub buildFromBody($$;@)
{   my ($class, $body, $container) = (shift, shift, shift);
    my @log  = $body->logSettings;

    my $head = Mail::Message::Head::Complete->new(@log);
    while(@_)
    {   if(ref $_[0]) {$head->add(shift)}
        else          {$head->add(shift, shift)}
    }

    my $part = $class->new
      ( head      => $head
      , container => $container
      , @log
      );

    $part->body($body);
    $part;
}

sub container(;$)
{   my $self = shift;
    return $self->{MMP_container} unless @_;

    $self->{MMP_container} = shift;
    weaken($self->{MMP_container});
}

sub toplevel()
{   my $body = shift->container or return;
    my $msg  = $body->message   or return;
    $msg->toplevel;
}

sub isPart() { 1 }

sub partNumber()
{   my $self = shift;
    my $body = $self->container or confess 'no container';
    $body->partNumberOf($self);
}

sub readFromParser($;$)
{   my ($self, $parser, $bodytype) = @_;

    my $head = $self->readHead($parser)
     || Mail::Message::Head::Complete->new
          ( message     => $self
          , field_type  => $self->{MM_field_type}
          , $self->logSettings
          );

    my $body = $self->readBody($parser, $head, $bodytype)
     || Mail::Message::Body::Lines->new(data => []);

    $self->head($head);
    $self->storeBody($body->contentInfoFrom($head));
    $self;
}

#-----------------

sub printEscapedFrom($)
{   my ($self, $out) = @_;
    $self->head->print($out);
    $self->body->printEscapedFrom($out);
}


sub destruct()
{  my $self = shift;
   $self->log(ERROR =>'You cannot destruct message parts, only whole messages');
   undef;
}

1;
