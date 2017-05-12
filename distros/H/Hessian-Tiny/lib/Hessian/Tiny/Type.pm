package Hessian::Tiny::Type;

use warnings;
use strict;
use Math::BigInt;
use Config;
use fields qw(data type len class);

=head1 NAME

Hessian::Tiny::Type - Hessian Types & utility routines

=head1 SUBROUTINES/METHODS

=head2 new

base class for other types

=cut

sub new {
    my($class,@params) = @_;
    my $self =  1 == scalar @params
    ? {data=>$params[0]}
    : {@params}
    ;
    return bless $self, $class;
}

# Hessian 1.0 Types
{ package Hessian::Type::Null;    use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::True;    use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::False;   use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Date;    use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Integer; use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Long;    use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Binary;  use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::String;  use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::XML;     use base 'Hessian::Tiny::Type'; } # 1.0 only
{ package Hessian::Type::Double;  use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::List;    use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Map;     use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Header;  use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Remote;  use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Fault;   use base 'Hessian::Tiny::Type'; }

# Hessian 2.0 Types
{ package Hessian::Type::Class;   use base 'Hessian::Tiny::Type'; }
{ package Hessian::Type::Object;  use base 'Hessian::Tiny::Type'; }

# helper functions for Convertor use
sub _pack_q { # pack (64-bit) signed long
  my $bi = shift;
  $bi = Math::BigInt->new($bi) unless length(ref $bi) > 0;
  $bi = Math::BigInt->new('0x8000000000000000')->bmul(2)->badd($bi) if $bi->is_neg;
  return pack 'H16', sprintf '%016s',substr($bi->as_hex, 2);
}
sub _unpack_q { # unpack (64-bit) signed long
  my $bytes = shift;
  my $n = Math::BigInt->new('0x' . unpack('H16',$bytes));
  my $m = Math::BigInt->new('0x7fffffffffffffff');
  $n = Math::BigInt->new('0x8000000000000000')->bmul(-2)->badd($n) if $n->bcmp($m) > 0;
  return $n;
}
#local to network order (and back)
sub _l2n { return $Config{'byteorder'} =~ /^1234/ ? scalar reverse $_[0] : $_[0] }

sub _make_reader {
  my $fh = shift;
  binmode $fh, ':bytes';
  return sub {
    my($len,$utf8_flag) = @_;
    binmode $fh, $utf8_flag ? ':utf8' : ':bytes';
    return seek $fh, $len, 1 if $len < 0; #rewind on negative len

    my $buf = '';
    my $l = read $fh, $buf, $len;
    die "_reader: want $len but got $l" unless $len == $l;
    return $buf;
  }
}
sub _make_writer {
  my $fh = shift;
  return sub {
    my($buf,$utf8_flag) = @_;
    binmode $fh, $utf8_flag ? ':utf8' : ':bytes';
    print $fh $buf;
  }
}

1; # End of Hessian::Type
