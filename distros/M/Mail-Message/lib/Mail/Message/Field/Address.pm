# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::Address;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Identity';

use strict;
use warnings;

use Mail::Message::Field::Addresses;
use Mail::Message::Field::Full;

my $format = 'Mail::Message::Field::Full';


use overload
    '""' => 'string'
  , bool => sub {1}
  , cmp  => sub { lc($_[0]->address) cmp lc($_[1]) }
  ;

#------------------------------------------


sub coerce($@)
{  my ($class, $addr, %args) = @_;
   return () unless defined $addr;

   ref $addr or return $class->parse($addr);
   $addr->isa($class) and return $addr;

   my $from = $class->from($addr, %args);

   Mail::Reporter->log(ERROR => "Cannot coerce a ".ref($addr)." into a $class"),
      return () unless defined $from;

   bless $from, $class;
}

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{MMFA_encoding} = delete $args->{encoding};
    $self;
}


sub parse($)
{   my $self   = shift;
    my $parsed = Mail::Message::Field::Addresses->new(To => shift);
    defined $parsed ? ($parsed->addresses)[0] : ();
}

#------------------------------------------


sub encoding() {shift->{MMFA_encoding}}

#------------------------------------------


sub string()
{   my $self  = shift;
    my @opts  = (charset => $self->charset, encoding => $self->encoding);
       # language => $self->language

    my @parts;
    my $phrase  = $self->phrase;
    push @parts, $format->createPhrase($phrase, @opts) if defined $phrase;

    my $address = $self->address;
    push @parts, @parts ? '<'.$address.'>' : $address;

    my $comment = $self->comment;
    push @parts, $format->createComment($comment, @opts) if defined $comment;

    join ' ', @parts;
}

1;
