# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-IMAP4.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::IMAP4::Head;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Message::Head';

use warnings;
use strict;

use Date::Parse;


sub init($$)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->{MBIH_c_fields} = $args->{cache_fields};
    $self;
}


sub get($;$)
{   my ($self, $name, $index) = @_;

       if(not $self->{MBIH_c_fields}) { ; }
    elsif(wantarray)
    {   my @values = $self->SUPER::get(@_);
        return @values if @values;
    }
    else
    {   my $value  = $self->SUPER::get(@_);
        return $value  if defined $value;
    }

    # Something here, playing with ENVELOPE, may improve the performance
    # as well.
    my $imap   = $self->message->folder->transporter;
    my $uidl   = $self->message->unique;
    my @fields = $imap->getFields($uidl, $name);

    if(@fields && $self->{MBIH_c_fields})
    {   $self->addNoRealize($_) for @fields
    }

      defined $index ? $fields[$index]
    : wantarray      ? @fields
    :                  $fields[0];
}

sub guessBodySize() {undef}

sub guessTimestamp() {undef}

#------------------------------------------

1;
