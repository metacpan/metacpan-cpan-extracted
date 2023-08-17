# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Head::Delayed;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::Message::Head';

use strict;
use warnings;

use Object::Realize::Later
    becomes          => 'Mail::Message::Head::Complete',
    realize          => 'load',
    believe_caller   => 1;

use Scalar::Util 'weaken';


sub build(@) {shift->log(ERROR => "Cannot build() a delayed header.") }

#------------------------------------------

sub init($$)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    if(defined $args->{message})
    {   $self->{MMHD_message} = $args->{message};
        weaken($self->{MMHD_message});
    }

    $self;
}

#------------------------------------------

sub isDelayed() {1}

#------------------------------------------

sub modified(;$)
{   return 0 if @_==1 || !$_[1];
    shift->forceRealize->modified(1);
}

#------------------------------------------

sub isModified() { 0 }

#------------------------------------------

sub isEmpty() { 0 }

#------------------------------------------


sub get($;$)
{   my $self = shift;
    $self->load->get(@_);
}

#------------------------------------------


sub guessBodySize() {undef}


sub guessTimestamp() {undef}

#------------------------------------------

sub read($)
{   my ($self, $parser, $headtype, $bodytype)  = @_;

#   $parser->skipHeader not implemented... returns where
    $self->{MMH_where}   = 0;
    $self;
}

sub load() {$_[0] = $_[0]->message->loadHead}
sub setNoRealize($) { shift->log(INTERNAL => "Setting field on a delayed?") }

1;
