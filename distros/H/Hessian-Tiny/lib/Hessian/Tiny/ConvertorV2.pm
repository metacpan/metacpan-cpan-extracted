package Hessian::Tiny::ConvertorV2;

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

Hessian::Tiny::ConvertorV2 - v2 serializer/deserializer

=head1 SUBROUTINES/METHODS

=head2 write_call

write hessian v2 call string

=cut

sub write_call {
  my($writer,$method_name,@hessian_params) = @_;
  $writer->("H\x02\x00C");
  my $serializer = _make_serializer_v2($writer);
  $serializer->(Hessian::Type::String->new($method_name));
  $serializer->(scalar @hessian_params);
  $serializer->($_) for(@hessian_params);
}


sub _make_serializer_v2 {
  my($wr) = @_;
  my $refs = [];
  my $f;
  $f = sub {
    my $x = shift;
    my $rf = \$f;
    Scalar::Util::weaken($rf);
    unless(defined $x){ $wr->('N'); return}
    given(ref $x){
      when('Hessian::Type::Null')     { $wr->('N') }
      when('Hessian::Type::True')     { $wr->('T') }
      when('Hessian::Type::False')    { $wr->('F') }

      when('DateTime')            { $wr->('J'. Hessian::Tiny::Type::_pack_q($x->epoch . '000')) }
      when('Hessian::Type::Date') { $wr->('J'. Hessian::Tiny::Type::_pack_q($$x{data})) }

      when('Hessian::Type::Integer')    { $wr->('I' . Hessian::Tiny::Type::_l2n(pack 'l', $$x{data})) }
      when('Hessian::Type::Long')   { $wr->('L' . Hessian::Tiny::Type::_pack_q($$x{data})) }
      when('Math::BigInt')          { $wr->('L' . Hessian::Tiny::Type::_pack_q($x))  }
      when('Hessian::Type::Double')     { $wr->('D' . Hessian::Tiny::Type::_l2n(pack 'd', $$x{data})) }

      when('Hessian::Type::Binary') { _write_chunks($wr,$$x{data})       }
      when('Hessian::Type::String') { _write_chunks($wr,$$x{data},1)     }
      when('Unicode::String')       { _write_chunks($wr,$x->as_string,1) }

      when('Hessian::Type::List') { my $idx = _search_ref($refs,$x);
                                    if(defined $idx){
                                      $wr->('QI' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                                    }else{
                                      push @$refs,$x;
                                      _write_list($$rf,$wr,$x);
                                    }
                                  }
      when('Hessian::Type::Map') { my $idx = _search_ref($refs,$x);
                                   if(defined $idx){
                                     $wr->('QI' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                                   }else{
                                     push @$refs,$x;
                                     _write_map($$rf,$wr,$x);
                                   }
                                 }
      when('Hessian::Type::Object') { my $idx = _search_ref($refs,$x);
                                      if(defined $idx){
                                        $wr->('QI' . Hessian::Tiny::Type::_l2n(pack 'l', $idx));
                                      }else{
                                        push @$refs,$x;
                                        _write_map($$rf,$wr,$x);
                                      }
                                    }

      #when('Hessian::Fault')    { _write_fault($wr,$x)  }
      when('REF') { $wr->('QI' . Hessian::Tiny::Type::_l2n(pack'l', first{$$x == $$refs[$_]}(0 .. $#$refs))) }

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
          when /\D/ { _write_chunks($wr,$x, Encode::is_utf8($x,1)) }
          default { die "unknown x: $x, @{[ref $x]}" }
        }
      }
      default { die "_serialize_v2: unrecognized type (@{[ref $x]})" }
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
sub _write_map {
  my($f,$wr,$x) = @_;
  $wr->(defined $$x{type} ? 'M' : 'H');
  _write_chunks($wr,(ref $$x{type} ? $$x{type}->{data} : $$x{type}),1) if defined $$x{type};
  my @ar = 'HASH' eq ref $$x{data} ? (%{$$x{data}}) : (@{$$x{data}});
  $f->($_) for(@ar);
  $wr->('Z');
}
sub _write_list {
  my($f,$wr,$x) = @_;
  if($$x{type} && defined $$x{length}) {
    $wr->('V');
    _write_chunks($wr,(ref $$x{type} ? $$x{type}->{data} : $$x{type}),1);
    $wr->('I' . Hessian::Tiny::Type::_l2n(pack 'l', $$x{length}));
  }elsif(defined $$x{length}) {
    $wr->('XI' . Hessian::Tiny::Type::_l2n(pack 'l', $$x{length}));
  }elsif($$x{type}) {
    $wr->('U');
    _write_chunks($wr,$$x{type},1);
  }else{
    $wr->('W');
  }
  $f->($_) for(@{$$x{data}});
  $wr->('Z') unless defined $$x{length};
}

sub _write_chunks {
  my($wr,$str,$utf8) = @_;
  if(length $str > 0x7fff){
    $wr->($utf8 ? 'R' : 'A');
    $wr->("\x7f\xff");
    $wr->(substr($str,0,0x7fff), $utf8);
    _write_chunks($wr,substr($str,0x7fff),$utf8);
  }else{
    $wr->($utf8 ? 'S' : 'B');
    $wr->(pack('n',length $str));
    $wr->($str, $utf8);
  }
}

# reading 2.0
sub _make_object_reader {
  my $h_flag=shift; # return hessian or perl data
  my($obj_refs,$cls_refs,$typ_refs) = ([],[],[]);
  my $f;
  $f = sub {
    my($rd,$h_flag_override) = @_;
    $h_flag_override = $h_flag unless defined $h_flag_override;
    my $rf = \$f;
    Scalar::Util::weaken($rf);
    my $x = $rd->(1);
    given($x){
      when('N') { return $h_flag_override ? Hessian::Type::Null->new() : undef }
      when('T') { return $h_flag_override ? Hessian::Type::True->new() : 1 }
      when('F') { return $h_flag_override ? Hessian::Type::False->new() : undef }

      when /[I\x80-\xd7]/ {
        my $i;
        given($x) {
          when('I')          { $i = unpack 'l', Hessian::Tiny::Type::_l2n($rd->(4)) }
          when /[\x80-\xbf]/ { $i = -0x90 + ord $x }
          when /[\xc0-\xcf]/ { $i = (-0xc8 + ord $x) * 0x100 + ord($rd->(1)) }
          when /[\xd0-\xd7]/ { $i = (-0xd4 + ord $x) * 0x10000 +
                                       ord($rd->(1)) * 0x100 +
                                       ord($rd->(1)) }
        }
        return $h_flag_override ? Hessian::Type::Integer->new($i) : $i;
      } # int

      when /[LY\x38-\x3f\xd8-\xff]/ {
        my $l;
        given($x) {
          when('L')          { $l = Hessian::Tiny::Type::_unpack_q($rd->(8)) }
          when('Y')          { $l = Math::BigInt->new(unpack 'l', Hessian::Tiny::Type::_l2n($rd->(4))) }
          when /[\xd8-\xef]/ { $l = Math::BigInt->new(-0xe0 + ord $x) }
          when /[\xf0-\xff]/ { $l = Math::BigInt->new((-0xf8 + ord $x) * 0x100 + ord($rd->(1))) }
          when /[\x38-\x3f]/ { $l = Math::BigInt->new((-0x3c + ord $x) * 0x10000 +
                                    ord($rd->(1)) * 0x100 + ord($rd->(1))) }
        }
        return $h_flag_override ? $l : $l->bstr;
      } # long

      when /[D\[\\\]\^_]/ {
        my $i;
        given($x){
          when('D')  { $i = unpack 'd', Hessian::Tiny::Type::_l2n($rd->(8)) }
          when('[')  { $i = 0.0 }
          when('\\') { $i = 1.0 }
          when(']')  { $i = unpack 'c', $rd->(1) }
          when('^')  { $i = unpack 's', Hessian::Tiny::Type::_l2n($rd->(2)) }
          when('_')  { $i = unpack('l', Hessian::Tiny::Type::_l2n($rd->(4)))/1000 }
        }
        return $h_flag_override ? Hessian::Type::Double->new($i) : $i;
      } # double

      when('J') { my$msec = Hessian::Tiny::Type::_unpack_q($rd->(8));
                  return $h_flag_override
                  ? Hessian::Type::Date->new($msec) #milli seconds
                  : $msec->bdiv(1000)->bstr #seconds
                  ;
      } # date
      when('K') { my$ms = Math::BigInt->new(unpack 'l', Hessian::Tiny::Type::_l2n($rd->(4)));
                  $ms->bmul(60*1000); # min to milli sec
                  return $h_flag_override
                  ? Hessian::Type::Date->new($ms) #milli seconds
                  : $ms->bdiv(1000)->bstr #seconds
                  ;
      } # date (compact)

      when /[RS\x00-\x1f\x30-\x33]/ { $rd->(-1);
                                      return $h_flag_override
                                      ? Hessian::Type::String->new(_read_string($rd))
                                      : _read_string($rd)
                                      ;
      } # string
      when /[AB\x20-\x2f\x34-\x37]/ { $rd->(-1);
                                      return $h_flag_override
                                      ? Hessian::Type::Binary->new(_read_binary($rd))
                                      : _read_binary($rd)
                                      ;
      } # binary
      when /[U-X\x70-\x7f]/ { my $v = Hessian::Type::List->new([]);
                              my $res = $h_flag_override ? $v : $v->{data};
                              push @$obj_refs,$res;
                              _read_list($$rf,$rd,$v,$x,$typ_refs);
                              return $res;
      } # list
      when /[MH]/ { tie my %h,'Tie::RefHash::Nestable';
                    my $m = Hessian::Type::Map->new(\%h);
                    my $res = $h_flag_override ? $m : $m->{data};
                    push @$obj_refs,$res;
                    _read_map($$rf,$rd,$m,$x,$typ_refs,$h_flag_override);
                    return $res;
      } # map
      when('C') { my $c = [];
                  push @$cls_refs, $c;
                  _read_class($$rf,$rd,$c);
                  return $$rf->($rd); # keep reading after class-def
      } # class def
      when /[O\x60a-o]/ { tie my %h,'Tie::RefHash::Nestable';
                          my $o = Hessian::Type::Object->new(\%h);
                          my $res = $h_flag_override ? $o : $o->{data};
                          push @$obj_refs,$res;
                          _read_object($$rf,$rd,$o,$cls_refs,$x);
                          return $res;
      } # object

      when('Q') { return $obj_refs->[$$rf->($rd,0)] }
      default   { die "hessian v2 reader: unknown type ($x)" }
    }
  };
  return $f;
}
sub _read_object {
  my($rf,$rd,$o,$c_refs,$x) = @_;
  my $idx;
  if($x eq 'O') { $idx = $rf->($rd,0) }
  else { $idx = -0x60 + unpack 'C', $x }
  die "object class index out of bound $idx: $#$c_refs" if $idx > $#$c_refs;
  my @fields = @{$c_refs->[$idx]};
  $o->{type} = shift @fields;
  $o->{data}->{$_} = $rf->($rd) for @fields;
}
sub _read_class {
  my($rf,$rd,$c) = @_;
  my $c_name = $rf->($rd,0);
  my $len = $rf->($rd,0);
  push @$c, $c_name;
  push @$c, $rf->($rd,0) for(1 .. $len);
}
sub _read_map {
  my($rf,$rd,$v,$x,$typ_refs,$hflg) = @_;
  if($x eq 'M'){ # typed map
    $v->{type} = $rf->($rd,0);
    if(defined $v->{type} and Scalar::Util::looks_like_number($v->{type}) ){
      $v->{type} = $typ_refs->[$v->{type}];
    }elsif(0 < length $v->{type}){
      push @$typ_refs, $v->{type};
    }
  }
  while('Z' ne $rd->(1)){
    $rd->(-1);
    my $k = $rf->($rd,$hflg);
    $v->{data}->{$k} = $rf->($rd,$hflg);
  }
}
sub _read_list {
  my($rf,$rd,$v,$x,$typ_refs) = @_;
  $v->{type} = $rf->($rd,1) if $x =~ /[MUV\x70-\x77]/;
  if(defined $v->{type} and 'Hessian::Type::Integer' eq ref $v->{type} ){
      $v->{type} = $typ_refs->[$v->{type}];
  }elsif(defined $v->{type} and 'Hessian::Type::String' eq ref $v->{type}){
    push @$typ_refs, $v->{type}->{data};
  }

  $v->{length} = $rf->($rd,0) if $x =~ /[VX]/;
  $v->{length} = -0x70 + unpack 'C', $x if $x =~ /[\x70-\x77]/;
  $v->{length} = -0x78 + unpack 'C', $x if $x =~ /[\x78-\x7f]/;

  if(defined $v->{length} and $v->{length} > 0){
    push @{$v->{data}}, $rf->($rd) for(1 .. $v->{length});
  }elsif(not defined $v->{length}){
    while('Z' ne $rd->(1)){
      $rd->(-1);
      push @{$v->{data}}, $rf->($rd);
    }
  }
}
sub _read_binary {
  my $rd = shift;
  my $m = $rd->(1);
  my $len;
  given($m){
    when /[AB]/        { $len = unpack 'n', $rd->(2) }
    when /[\x20-\x2f]/ { $len = -0x20 + unpack 'C', $m }
    when /[\x34-\x37]/ { $len = (-0x34 + unpack'C',$m) * 0x100 + unpack('C',$rd->(1)) }
    default            { die "unknown Binary marker: $m" }
  } # end given $x
  my $buf = $rd->($len,0);
  return $buf . _read_binary($rd) if $m eq 'A';
  return $buf;
}
sub _read_string {
  my $rd = shift;
  my $m = $rd->(1);
  my $len;
  given($m){
    when /[RS]/        { $len = unpack 'n', $rd->(2) }
    when /[\x00-\x1f]/ { $len = unpack 'C', $m }
    when /[\x30-\x33]/ { $len = (unpack('C',$m) - 0x30 ) * 0x100 + unpack('C',$rd->(1)) }
    default            { die "unknown String marker: $m" }
  } # end given $x
  my $buf = $rd->($len,1);
  return $buf . _read_string($rd) if $m eq 'R';
  return $buf;
}
=head1 AUTHOR

Ling Du, C<< <ling.du at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hessian-tiny at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hessian-Tiny>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hessian::Tiny::ConvertorV2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hessian-Tiny>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hessian-Tiny>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hessian-Tiny>

=item * Search CPAN

L<http://search.cpan.org/dist/Hessian-Tiny/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ling Du.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hessian::Tiny::ConvertorV2
