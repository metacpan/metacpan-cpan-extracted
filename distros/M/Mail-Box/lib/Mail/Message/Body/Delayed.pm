# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Body::Delayed;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Reporter';

use strict;
use warnings;

use Object::Realize::Later
    becomes          => 'Mail::Message::Body',
    realize          => 'load',
    warn_realization => 0,
    believe_caller   => 1;

use Carp;
use Scalar::Util 'weaken';


use overload '""'    => 'string_unless_carp'
           , bool    => sub {1}
           , '@{}'   => sub {shift->load->lines};

#------------------------------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{MMB_seqnr}    = -1;  # for overloaded body comparison
    $self->{MMBD_message} = $args->{message}
        or $self->log(INTERNAL => "A message must be specified to a delayed body.");

    weaken($self->{MMBD_message});
    $self;
}

#------------------------------------------


sub message() { shift->{MMBD_message} }

#------------------------------------------


sub modified(;$)
{   return 0 if @_==1 || !$_[1];
    shift->forceRealize(shift);
}


sub isModified()  {0}
sub isDelayed()   {1}
sub isMultipart() {shift->message->head->isMultipart}
sub guessSize()   {shift->{MMBD_size}}


sub nrLines()
{   my ($self) = @_;
      defined $self->{MMBD_lines}
    ? $self->{MMBD_lines}
    : $_[0]->forceRealize->nrLines;
}

sub string_unless_carp()
{   my $self = shift;
    return $self->load->string if (caller)[0] ne 'Carp';

    (my $class = ref $self) =~ s/^Mail::Message/MM/g;
    "$class object";
}

#------------------------------------------


sub read($$;$@)
{   my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
    $self->{MMBD_parser} = $parser;

    @$self{ qw/MMBD_begin MMBD_end MMBD_size MMBD_lines/ }
        = $parser->bodyDelayed(@_);

    $self;
}


sub fileLocation(;@) {
   my $self = shift;
   return @$self{ qw/MMBD_begin MMBD_end/ } unless @_;
   @$self{ qw/MMBD_begin MMBD_end/ } = @_;
}


sub moveLocation($)
{   my ($self, $dist) = @_;
    $self->{MMBD_begin} -= $dist;
    $self->{MMBD_end}   -= $dist;
    $self;
}


sub load() {$_[0] = $_[0]->message->loadBody}

#------------------------------------------


1;
