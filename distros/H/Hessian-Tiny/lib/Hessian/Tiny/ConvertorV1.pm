package Hessian::Tiny::ConvertorV1;

use warnings;
use strict;

use Encode ();
use Switch 'Perl6';
use List::Util qw(first);
use IO::Handle ();
use Scalar::Util ();
use Math::BigInt ();
use Tie::RefHash ();

use Hessian::Tiny::Type ();

=head1 NAME

Hessian::Tiny::ConvertorV1 - v1 serializer/deserializer

=head1 SUBROUTINES/METHODS

=head2 write_call

write hessian v1 call string

=cut

sub write_call {
  my($writer,$method_name,@hessian_params) = @_;
  $writer->("c\x01\x00m");
  $writer->(pack 'n', length $method_name);
  $writer->($method_name,1);
  my $serializer_v1 = _make_serializer_v1($writer);
  $serializer_v1->($_) for(@hessian_params);
  $writer->('z');
}
sub __write_reply { # for future server use
  my($writer,$value) = @_;
  $writer->("r\x01\x00");
  my $serializer_v1 = _make_serializer_v1($writer);
  $serializer_v1->($value);
  $writer->('z');
}
sub _make_serializer_v1 {
  my($wr) = @_;
  my $refs = [];
  my $f;
  $f = sub {
    my $x = shift;
    my $rf = \$f;
    Scalar::Util::weaken($rf);
    unless(defined $x){ $wr->('N'); return}
    given(ref $x){
      when('Hessian::Type::Null')  { $wr->('N') }
      when('Hessian::Type::True')  { $wr->('T') }
      when('Hessian::Type::False') { $wr->('F') }
      when('Hessian::Type::Date')  { $wr->('d');
                                     $wr->('Math::BigInt' eq ref $$x{data}
                                       ? Hessian::Tiny::Type::_pack_q($$x{data})
                                       : Hessian::Tiny::Type::_l2n(pack 'q', $$x{data})
                                     );
                                   }
      when('DateTime') { $wr->('d'.Hessian::Tiny::Type::_pack_q(Math::BigInt->new($x->epoch)->bmul(1000)))}

      when('Hessian::Type::Integer') { $wr->('I' . Hessian::Tiny::Type::_l2n(pack 'l', $$x{data})) }
      when('Hessian::Type::Long')    { $wr->('L' . Hessian::Tiny::Type::_pack_q($$x{data})) }
      when('Math::BigInt')           { $wr->('L' . Hessian::Tiny::Type::_pack_q($x))  }
      when('Hessian::Type::Double')  { $wr->('D' . Hessian::Tiny::Type::_l2n(pack 'd', $$x{data})) }

      when('Hessian::Type::Binary') { _write_chunks($wr,$$x{data})       }
      when('Hessian::Type::String') { _write_chunks($wr,$$x{data},1)     }
      when('Unicode::String')       { _write_chunks($wr,$x->as_string,1) }
      when('Hessian::Type::XML')    { _write_xml($wr,$x->as_string)      }

      when('Hessian::Type::List') { my $idx = _search_ref($refs,$x);
                                    if(defined $idx){
                                      $wr->('R' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                                    }else{
                                      push @$refs,$x;
                                      _write_list($$rf,$wr,$x);
                                    }
                                  }
      when('ARRAY') { my $idx = _search_ref($refs,$x);
                      if(defined $idx){
                        $wr->('R' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                      }else{
                        push @$refs,$x;
                        my $y = Hessian::Type::List->new(length=>scalar @$x,data=>$x);
                        _write_list($$rf,$wr,$y);
                      }
                    }
      when('Hessian::Type::Map')      { my $idx = _search_ref($refs,$x);
                                        if(defined $idx){
                                          $wr->('R' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                                        }else{
                                          push @$refs,$x;
                                          _write_map($$rf,$wr,$x);
                                        }
                                      }
      when('Hessian::Type::Fault') {
                                   }
      when('HASH') { my $idx = _search_ref($refs,$x);
                     if(defined $idx){
                       $wr->('R' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                     }else{
                       push @$refs,$x;
                       my $y = Hessian::Type::Map->new($x);
                       _write_map($$rf,$wr,$x);
                     }
                   }
      #when('Hessian::Type::Remote')   { _write_remote($wr,$x) }
      #when('Hessian::Type::Fault')    { _write_fault($wr,$x)  }
      when('REF') { $wr->('R' . Hessian::Tiny::Type::_l2n(pack'l', first{$$x == $$refs[$_]}(0 .. $#$refs))) }

      when('') { # guessing begins
        given($x){
          when /^[\+\-]?(0x)?\d+$/ { my $bi = Math::BigInt->new($x);
                                     if(Math::BigInt->new('-0x80000000')->bcmp($bi) <= 0 &&
                                        Math::BigInt->new(' 0x7fffffff')->bcmp($bi) >= 0
                                     ){ # Integer
                                       $wr->('I' . Hessian::Tiny::Type::_l2n(pack 'l', $x));
                                     }elsif(Math::BigInt->new('-0x8000000000000000')->bcmp($bi) <=0 &&
                                            Math::BigInt->new(' 0x7fffffffffffffff')->bcmp($bi) >=0
                                     ){ # Long
                                       $wr->('L' . Hessian::Tiny::Type::_pack_q($x));
                                     }else{ # too large to be number
                                       _write_chunks($wr,$x,Encode::is_utf8($x,1));
                                     }
                                   }
          when /^[\+\-]?\d*(\d+\.|\.\d+)\d*$/ { $wr->('D' . Hessian::Tiny::Type::_l2n(pack 'd', $x)) }
          when /\D/ { _write_chunks($wr,$x,Encode::is_utf8($x,1)) }
        }
      }
      default { die "_serialize_v1: unrecognized type (@{[ref $x]})" }
    } # end given
  };
  return $f;
}
sub _search_ref { # return index, or undef if not found
  my($refs,$r) = @_;
  for my $i (0 .. $#$refs){
    return $i if $refs->[$i] == $r;
  }
  return undef;
}
sub _write_xml {
  my($wr,$str) = @_;
  if(length $str > 0x7fff){
    $wr->('x');
    $wr->("\x7f\xff");
    $wr->(substr($str,0,0x7fff));
    _write_xml($wr,substr($str,0x7fff));
  }else{
    $wr->('X');
    $wr->(pack('n',length $str));
    $wr->($str);
  }
}
sub _write_chunks {
  my($wr,$str,$utf8) = @_;
  if(length $str > 0x7fff){
    $wr->($utf8 ? 's' : 'b');
    $wr->("\x7f\xff");
    $wr->(substr($str,0,0x7fff), $utf8);
    _write_chunks($wr,substr($str,0x7fff),$utf8);
  }else{
    $wr->($utf8 ? 'S' : 'B');
    $wr->(pack('n',length $str));
    $wr->($str, $utf8);
  }
}

sub _write_list { # 'Hessian::Type::List'
  my($f,$wr,$x) = @_;
  $wr->('V');
  if($$x{type}){
    $wr->('t' . pack('n', length  $$x{type}));
    $wr->($$x{type},1);
  }
  $wr->('l' . pack('N', $$x{length})) if($$x{length});
  $f->($_) for(@{$$x{data}});
  $wr->('z');
}

sub _write_map { # 'Hessian::Type::Map'
  my($f,$wr,$x) = @_;

  $wr->('M');
  if($$x{type}){
    $wr->('t' . pack('n', length $$x{type}));
    $wr->($$x{type},1);
  }
  my @ar = 'HASH' eq ref $$x{data} ? (%{$$x{data}}) : (@{$$x{data}});
  $f->($_) for(@ar);
  $wr->('z');
}

# de-serializer
sub _make_object_reader {
  my $h_flg=shift; # return all hessian structure
  my $refs = [];
  my $f;
  $f = sub {
    my($rd,$h_flg_override) = @_;
    $h_flg_override = $h_flg unless defined $h_flg_override;
    my $rf = \$f;
    Scalar::Util::weaken($rf);
    given($rd->(1)){
      when('N') { return $h_flg_override ? Hessian::Type::Null->new() : undef }
      when('T') { return $h_flg_override ? Hessian::Type::True->new() : 1 }
      when('F') { return $h_flg_override ? Hessian::Type::False->new() : undef }

      when('I') { my $i = unpack 'l', Hessian::Tiny::Type::_l2n($rd->(4));
                  return $h_flg_override
                  ? Hessian::Type::Integer->new($i)
                  : $i
                  ;
                } # int
      when('L') { my $l = Hessian::Tiny::Type::_unpack_q($rd->(8));
                  return $h_flg_override
                  ? $l
                  : $l->bstr
                  ;
                } # long
      when('D') { my $i = unpack 'd', Hessian::Tiny::Type::_l2n($rd->(8));
                  return $h_flg_override
                  ? Hessian::Type::Double->new($i)
                  : $i
                  ;
                } # double
      when('d') { my$msec = Hessian::Tiny::Type::_unpack_q($rd->(8));
                  return $h_flg_override
                  ? Hessian::Type::Date->new($msec)
                  : $msec->bdiv(1000)->bstr
                  ;
                } # date
      when /([BbSsXx])/ { $rd->(-1);
                          my $t = $rd->(1);
                          $rd->(-1);
                          my $chunks = _read_chunks($rd);
                          return $chunks unless $h_flg_override;
                          given($t){
                            when /[Bb]/ { return Hessian::Type::Binary->new($chunks) }
                            when /[Ss]/ { return Hessian::Type::String->new($chunks) }
                            when /[Xx]/ { return Hessian::Type::XML->new($chunks) }
                          }
                        } # string/binary/xml
      when('V') { my $v = Hessian::Type::List->new([]);
                  my $res = $h_flg_override ? $v : $v->{data};
                  push @$refs, $res;
                  _read_list($$rf,$rd, $v);
                  return $res;
                } # list
      when('M') { tie my %h, 'Tie::RefHash::Nestable';
                  my $m = Hessian::Type::Map->new(\%h);
                  my $res = $h_flg_override ? $m : $m->{data};
                  push @$refs, $res;
                  _read_map( $$rf,$rd,$m,$h_flg_override);
                  return $res;
                } # map
      when('R') { return $refs->[unpack 'l', Hessian::Tiny::Type::_l2n($rd->(4))] }
      when('H') { tie my %h, 'Tie::RefHash::Nestable';
                  my $hdr = Hessian::Type::Header->new(\%h);
                  _read_map($$rf,$rd, $hdr);
                  return $hdr;
                } # header
      when('r') { tie my %h, 'Tie::RefHash::Nestable';
                  my $r = Hessian::Type::Remote->new(\%h);
                  _read_map($$rf,$rd, $r);
                  return $r;
                } # remote
      when('f') { tie my %h, 'Tie::RefHash::Nestable';
                  my $fault = Hessian::Type::Fault->new(\%h);
                  _read_map($$rf,$rd,$fault,0);
                  return bless $fault->{data},'Hessian::Type::Fault';
                } # fault
      when('z') { die "_reader: z encountered" }
      default { die "_reader: unknown type $_" }
    }
  };
  return $f;
}
sub _read_chunks {
  my($rd) = @_;
  my $marker = $rd->(1);
  my $len = unpack('n', $rd->(2));
  if($marker =~ /[bsx]/){
    return $rd->($len, $marker =~ /[sx]/) . _read_chunks($rd);
  }else{
    return $rd->($len, $marker =~ /[SX]/);
  }
}
sub _read_list {
  my($obj_reader,$rd,$list) = @_;
  if('t' eq $rd->(1)){
    my $len = unpack('n', $rd->(2));
    $list->{type} = $rd->($len,1);
  }else{ $rd->(-1) }

  if('l' eq $rd->(1)){
    $list->{length} = unpack 'l', Hessian::Tiny::Type::_l2n($rd->(4));
  }else{ $rd->(-1) }

  while('z' ne $rd->(1)){
    $rd->(-1);
    push @{$$list{data}}, $obj_reader->($rd);
  }
  return $list;
}
sub _read_map {
  my($obj_reader,$rd,$map,$hflg) = @_;
  if('t' eq $rd->(1)){
    my $len = unpack('n', $rd->(2));
    $map->{type} = $rd->($len,1);
  }else{ $rd->(-1) }

  while('z' ne $rd->(1)){
    $rd->(-1);
    my $k = $obj_reader->($rd,$hflg);
    $map->{data}->{$k} = $obj_reader->($rd,$hflg);
  }
  return $map;
}

1; # End of Hessian::Tiny::ConvertorV1
