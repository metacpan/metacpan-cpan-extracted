# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use strict;
use warnings;

package Mail::Message::Field::Address;
use vars '$VERSION';
$VERSION = '3.003';

use base 'Mail::Identity';

use Mail::Message::Field::Addresses;
use Mail::Message::Field::Full;
my $format = 'Mail::Message::Field::Full';


use overload
      '""' => 'string'
    , bool => sub {1}
    , cmp  => sub { lc($_[0]->address) eq lc($_[1]) }
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
    my $parsed = Mail::Message::Field::Addresses->new('To' => shift);
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
    my $name    = $self->phrase;
    push @parts, $format->createPhrase($name, @opts) if defined $name;

    my $address = $self->address;
    push @parts, @parts ? '<'.$address.'>' : $address;

    my $comment = $self->comment;
    push @parts, $format->createComment($comment, @opts) if defined $comment;

    join ' ', @parts;
}

1;
