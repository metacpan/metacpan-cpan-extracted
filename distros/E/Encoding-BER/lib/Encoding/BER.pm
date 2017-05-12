# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Jan-28 16:03 (EST)
# Function: BER encoding/decoding (also: CER and DER)
#
# $Id: BER.pm,v 1.11 2008/05/31 18:43:11 jaw Exp $

# references: ITU-T x.680 07/2002  -  ASN.1
# references: ITU-T x.690 07/2002  -  BER

package Encoding::BER;
use vars qw($VERSION);
$VERSION = '1.02';
use Carp;
use strict;
# loaded on demand if needed:
#   POSIX
# used if already loaded:
#   Math::BigInt

=head1 NAME

Encoding::BER - Perl module for encoding/decoding data using ASN.1 Basic Encoding Rules (BER)

=head1 SYNOPSIS

  use Encoding::BER;
  my $enc = Encoding::BER->new();
  my $ber = $enc->encode( $data );
  my $xyz = $enc->decode( $ber );

=head1 DESCRIPTION

Unlike many other BER encoder/decoders, this module uses tree structured data
as the interface to/from the encoder/decoder.

The decoder does not require any form of template or description of the
data to be decoded. Given arbitrary BER encoded data, the decoder produces
a tree shaped perl data structure from it.

The encoder takes a perl data structure and produces a BER encoding from it.
    
=head1 METHODS

=over 4

=cut
    ;

################################################################

my %CLASS =
(
 universal	=> { v => 0,	},
 application	=> { v => 0x40, },
 context	=> { v => 0x80, },
 private	=> { v => 0xC0, },
 );

my %TYPE =
(
 primitive	=> { v => 0,	},
 constructed	=> { v => 0x20, },
 );

my %TAG =
(
 universal => {
     content_end       => { v => 0,     },
     boolean           => { v => 1,     e => \&encode_bool,   d => \&decode_bool   },
     integer           => { v => 2,     e => \&encode_int,    d => \&decode_int    },
     bit_string	       => { v => 3,     e => \&encode_bits,   d => \&decode_bits,   dc => \&reass_string, rule => 1 }, 
     octet_string      => { v => 4,     e => \&encode_string, d => \&decode_string, dc => \&reass_string, rule => 1 },
     null              => { v => 5,     e => \&encode_null,   d => \&decode_null   },
     oid	       => { v => 6,     e => \&encode_oid,    d => \&decode_oid    },
     object_descriptor => { v => 7,     implicit => 'octet_string' },
     external	       => { v => 8,     type => ['constructed']    },
     real      	       => { v => 9,     e => \&encode_real,   d => \&decode_real   },
     enumerated        => { v => 0xA,   implicit => 'integer'      },
     embedded_pdv      => { v => 0xB,   e => \&encode_string, d => \&decode_string, dc => \&reass_string },
     utf8_string       => { v => 0xC,   implicit => 'octet_string' },
     relative_oid      => { v => 0xD,   e => \&encode_roid,   d => \&decode_roid   },
     # reserved
     # reserved
     sequence	       => { v => 0x10,  type => ['constructed'] },
     set               => { v => 0x11,  type => ['constructed'] },
     numeric_string    => { v => 0x12,  implicit => 'octet_string' },
     printable_string  => { v => 0x13,  implicit => 'octet_string' },
     teletex_string    => { v => 0x14,  implicit => 'octet_string' },
     videotex_string   => { v => 0x15,  implicit => 'octet_string' },
     ia5_string        => { v => 0x16,  implicit => 'octet_string' },
     universal_time    => { v => 0x17,  implicit => 'octet_string' },
     generalized_time  => { v => 0x18,  implicit => 'octet_string' },
     graphic_string    => { v => 0x19,  implicit => 'octet_string' },
     visible_string    => { v => 0x1a,  implicit => 'octet_string' },
     general_string    => { v => 0x1b,  implicit => 'octet_string' },
     universal_string  => { v => 0x1c,  implicit => 'octet_string' },
     character_string  => { v => 0x1d,  implicit => 'octet_string' },
     bmp_string        => { v => 0x1e,  implicit => 'octet_string' },
 },
 
 private => {
     # extra.
     # no, the encode/decode functions are not mixed up.
     # yes, this module handles large tag-numbers.
     integer32	       => { v => 0xFFF0, type => ['private'], e => \&encode_uint32, d => \&decode_int   }, 
     unsigned_int      => { v => 0xFFF1, type => ['private'], e => \&encode_uint,   d => \&decode_uint  },
     unsigned_int32    => { v => 0xFFF2, type => ['private'], e => \&encode_uint32, d => \&decode_uint  },
 },
);

# synonyms
my %AKATAG =
(
 bool				=> 'boolean',
 int				=> 'integer',
 string				=> 'octet_string',
 object_identifier		=> 'oid',
 relative_object_identifier	=> 'relative_oid',
 roid				=> 'relative_oid',
 float				=> 'real',
 enum				=> 'enumerated',
 sequence_of			=> 'sequence',
 set_of				=> 'set',
 t61_string			=> 'teletex_string',
 iso646_string			=> 'visible_string',
 int32				=> 'integer32',
 unsigned_integer		=> 'unsigned_int',
 uint				=> 'unsigned_int',
 uint32				=> 'unsigned_int32',
 # ...
);

# insert name into above data
my %ALLTAG;
my %REVTAG;

# insert name + class into above data
# build reverse map, etc.
init_tag_lookups( \%TAG, \%ALLTAG, \%REVTAG );

my %REVCLASS = map {
    ( $CLASS{$_}{v} => $_ )
} keys %CLASS;

my %REVTYPE = map {
    ( $TYPE{$_}{v} => $_ )
} keys %TYPE;

################################################################

=item new(option => value, ...)

constructor.

    example:
    my $enc = Encoding::BER->new( error => sub{ die "$_[1]\n" } );

the following options are available:

=over 4

=item error

coderef called if there is an error. will be called with 2 parameters,
the Encoding::BER object, and the error message.

    # example: die on error
    error => sub{ die "oops! $_[1]\n" }
    
=item warn

coderef called if there is something to warn about. will be called with 2 parameters,
the Encoding::BER object, and the error message.

    # example: warn for warnings
    warn => sub{ warn "how odd! $_[1]\n" }
    

=item decoded_callback

coderef called for every element decoded. will be called with 2 parameters,
the Encoding::BER object, and the decoded data. [see DECODED DATA]

    # example: bless decoded results into a useful class
    decoded_callback => sub{ bless $_[1], MyBER::Result }
    
=item debug

boolean. if true, large amounts of useless gibberish will be sent to stderr regarding
the encoding or decoding process.

    # example: enable gibberish output
    debug => 1

=back

=cut
    ;

sub new {
    my $cl = shift;
    my $me = bless { @_ }, $cl;

    $me;
}

sub error {
    my $me  = shift;
    my $msg = shift;

    if( my $f = $me->{error} ){
	$f->($me, $msg);
    }else{
	croak ((ref $me) . ": $msg\n");
    }
    undef;
}

sub warn {
    my $me  = shift;
    my $msg = shift;

    if( my $f = $me->{warn} ){
	$f->($me, $msg);
    }else{
	carp ((ref $me) . ": $msg\n");
    }
    undef;
}

sub debug {
    my $me  = shift;
    my $msg = shift;

    return unless $me->{debug};
    print STDERR "  " x $me->{level}, $msg, "\n";
    undef;
}

################################################################

sub add_tag_hash {
    my $me    = shift;
    my $class = shift;
    my $type  = shift;
    my $name  = shift;
    my $num   = shift;
    my $data  = shift;

    return $me->error("invalid class: $class") unless $CLASS{$class};
    return $me->error("invalid type: $type")   unless $TYPE{$type};

    $data->{type} = [$class, $type];
    $data->{v}    = $num;
    $data->{n}    = $name;
    
    # install forward + reverse mappings
    $me->{tags}{$name} = $data;
    $me->{revtags}{$class}{$num} = $name;

    $me;
}

=item add_implicit_tag(class, type, tag-name, tag-number, base-tag)

add a new tag similar to another tag. class should be one of C<universal>,
C<application>, C<context>, or C<private>. type should be either C<primitive>
or C<contructed>. tag-name should specify the name of the new tag.
tag-number should be the numeric tag number. base-tag should specify the
name of the tag this is equivalent to.

    example: add a tagged integer
    in ASN.1: width-index ::= [context 42] implicit integer
    
    $ber->add_implicit_tag('context', 'primitive', 'width-index', 42, 'integer');

=cut
    ;

sub add_implicit_tag {
    my $me    = shift;
    my $class = shift;
    my $type  = shift;
    my $name  = shift;
    my $num   = shift;
    my $base  = shift;

    return $me->error("unknown base tag name: $base")
	unless $me->tag_data_byname($base);

    $me->add_tag_hash($class, $type, $name, $num, {
	implicit => $base,
    });
}

sub add_tag {
    my $me    = shift;
    my $class = shift;
    my $type  = shift;
    my $name  = shift;
    my $num   = shift;
    # possibly optional:
    my $encf  = shift;
    my $decf  = shift;
    my $encfc = shift;
    my $decfc = shift;
    
    $me->add_tag_hash($class, $type, $name, $num, {
	e  => $encf,
	d  => $decf,
	ec => $encfc,
	dc => $decfc,
    });
}

sub init_tag_lookups {
    my $TAG = shift;
    my $ALL = shift;
    my $REV = shift;
    
    for my $class (keys %$TAG){
	for my $name (keys %{$TAG->{$class}}){
	    $TAG->{$class}{$name}{n} = $name;
	    $ALL->{$name} = $TAG->{$class}{$name};
	}
	my %d = map {
	    ($TAG->{$class}{$_}{v} => $_)
	    } keys %{$TAG->{$class}};
	$REV->{$class} = \%d;
    }
}

################################################################

=item encode( data )

BER encode the provided data. [see: ENCODING DATA]

  example:
  my $ber = $enc->encode( [0, 'public', [7.3, 0, 0, ['foo', 'bar']]] );

=cut
    ;

sub encode {
    my $me   = shift;
    my $data = shift;
    my $levl = shift;
    
    $me->{level} = $levl || 0;
    $data = $me->canonicalize($data) if $me->{acanonical} || !$me->behaves_like_a_hash($data);

    # include pre-encoded data as is
    if( $data->{type} eq 'BER_preencoded' ){
	return $data->{value};
    }
    
    $data = $me->rule_check_and_apply($data) || $data;
    my($typeval, $tagnum, $encfnc) = $me->ident_data_and_efunc($data->{type});
    my $value;

    if( $typeval & 0x20 ){
	$me->debug( "encode constructed ($typeval/$tagnum) [" );
	# constructed - recurse
	my @vs = ref($data->{value}) ? @{$data->{value}} : $data->{value};
	for my $e (@vs){
	    $value .= $me->encode( $e, $me->{level} + 1 );
	}
	$me->{level} = $levl || 0;
	$me->debug("]");
    }else{
	$me->debug( "encode primitive ($typeval/$tagnum)" );
	
	unless( $encfnc ){
	    # try to guess encoding
	    my @t = ref($data->{type}) ? @{$data->{type}} : $data->{type};
	    $me->warn("do not know how to encode identifier [@t] ($typeval/$tagnum)");
	    $encfnc = \&encode_unknown;
	}
	$value = $encfnc->($me, $data);
    }

    my $defp = $me->use_definite_form($typeval, $data);
    my $leng = $me->encode_length(length($value));

    my $res;
    if( $defp && defined($leng) ){
	$me->debug("encode definite form");
	$res = $me->encode_ident($typeval, $tagnum) . $leng . $value;
    }else{
	$me->debug("encode indefinite form");
	$res = $me->encode_ident($typeval, $tagnum) . "\x80" . $value . "\x00\x00";
	# x.690:                                      8.3.6.1           8.1.5
    }
    
    $data->{dlen} = length($value);
    $data->{tlen} = length($res);

    $res;
}

sub encode_null {
    my $me = shift;
    $me->debug('encode null');
    '';
}

sub encode_unknown {
    my $me   = shift;
    my $data = shift;

    $me->debug('encode unknown');
    '' . $data->{value};
}

sub encode_string {
    my $me   = shift;
    my $data = shift;

    # CER splitting of long strings is handled in CER subclass
    $me->debug('encode string');
    '' . $data->{value};
}

sub encode_bits {
    my $me   = shift;
    my $data = shift;

    # x.690 8.6
    $me->debug('encode bitstring');
    "\0" . $data->{value};

}

sub encode_bool {
    my $me   = shift;
    my $data = shift;

    # x.690 11.1
    $me->debug('encode boolean');
    $data->{value} ? "\xFF" : "\x0";
}

sub encode_int {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};

    my @i;
    my $big;

    if( _have_math_bigint() ){
	# value is a bigint or a long string
	$big = 1 if (ref $val && $val->can('as_hex')) || length($val) > 8;
    }
    
    if( $big ){
	my $x = Math::BigInt->new($val);
	$me->debug("bigint $val => $x");
	my $sign = $x->is_neg() ? 0xff : 0;
	if( $sign ){
	    # NB: in 2s comp: -X = ~(X-1) = ~X+1
	    $x = $x->bneg()->bsub(1)->as_hex();
	    $x =~ s/^0x//;
	    $x = '0'.$x if length($x) & 1;
	    @i = map{ ~$_ & 0xff } unpack('C*', pack('H*', $x));
	    unshift @i, 0xff unless $i[0] & 0x80;
	}else{
	    $x = $x->as_hex();
	    $x =~ s/^0x//;
	    $x = '0'.$x if length($x) & 1;
	    @i = unpack('C*', pack('H*', $x));
	    unshift @i, 0 if $i[0] & 0x80;
	}
	$me->debug("encode big int [@i]");
    }else{
	my $sign = ($val < 0) ? 0xff : 0;
	while(1){
	    unshift @i, $val & 0xFF;
	    last if $val >= -128 && $val < 128;
	    # NB: >>= does not preserve sign.
	    $val = int(($val - $sign)/256);
	}
	$me->debug("encode int [@i]");
    }
    pack('C*', @i);
}

sub encode_uint {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};
    
    my @i;
    my $big;

    if( _have_math_bigint() ){
	# value is a bigint or a long string
	$big = 1 if (ref $val && $val->can('bcmp')) || length($val) > 8;
    }

    if( $big ){
	my $x = Math::BigInt->new($val)->as_hex();
	$x =~ s/^0x//;
	$x = '0' . $x if length($x) & 1;
	$me->debug("encode big unsigned int");
	pack('H*', $x);
    }else{
	while($val){
	    unshift @i, $val & 0xFF;
	    $val >>= 8;
	}
	$me->debug("encode unsigned int [@i]");
	pack('C*', @i);
    }
}


sub encode_uint32 {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};

    # signed or unsigned. -1 == 0xffffffff
    $me->debug("encode unsigned int32");
    pack('N', $val);
}

sub encode_real {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};

    return '' unless $val;		# x.690 8.5.2
    return "\x40" if $val eq 'inf';	# x.690 8.5.8
    return "\x41" if $val eq '-inf';	# x.690 8.5.8

    # POSIX required. available?
    eval {
	require POSIX;
    };
    return $me->error("POSIX not available. cannot encode type real")
	unless defined &POSIX::frexp;

    my $sign = 0;
    my($mant, $exp) = POSIX::frexp($val);
    if( $mant < 0 ){
	$sign = 1;
	$mant = - $mant;
    }

    #$me->debug("encode real: $mant ^ $exp");
    
    # go byte-by-byte
    my @mant;
    while($mant > 0){
	my($frac, $int) = POSIX::modf(POSIX::ldexp($mant, 8));
	push @mant, $int;
	$mant = $frac;
	$exp -= 8;
	# $me->debug("encode real: [@mant] ^ $exp");
    }
    #$me->debug("encode real: [@mant] ^ $exp");

    if( $data->{flavor} || $me->{flavor} ){
	# x.690 8.5.6.5, 11.3.1 - CER + DER require N has a 1 in the lsb
	# normalize
	while( ! ($mant[-1] & 1) ){
	    # shift right
	    my $c = 0;
	    for (@mant){
		my $l = $_ & 1;
		$_ = ($_>>1) | ($c?0x80:0);
		$c = $l;
	    }
	    $exp ++;
	}
	#$me->debug("encode real normalized: [@mant] ^ $exp");
    }

    # encode exp
    my @exp;
    my $exps = ($exp < 0) ? 0xff : 0;
    while(1){
	unshift @exp, $exp & 0xFF;
	last if $exp >= -128 && $exp < 128;
	# >>= does not preserve sign.
	$exp = int(($exp - $exps)/256);
    }
    
    $me->debug("encode real: [@mant] ^ [@exp]");

    my $first = 0x80 | ($sign ? 0x40 : 0);

    if(@exp == 2){
	$first |= 1;
    }
    if(@exp == 3){
	$first |= 2;
    }
    if(@exp > 3){
	# should not happen using ieee-754 doubles
	$first |= 3;
	unshift @exp, scalar(@exp);
    }
    
    pack('C*', $first, @exp, @mant);
}

sub encode_oid {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};
    # "1.3.6.1.2.0" | [1, 3, 6, 1, 2, 0]

    # x.690 8.19
    my @o = ref($val) ? @$val : (split /\./, $val);
    shift @o if $o[0] eq ''; # remove empty in case specified with leading .

    if( @o > 1 ){
	# x.690 8.19.4
	my $o = shift @o;
	$o[0] += $o * 40;
    }

    $me->debug("encode oid [@o]");
    pack('w*', @o);
}

sub encode_roid {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};
    # "1.3.6.1.2.0" | [1, 3, 6, 1, 2, 0]

    # x.690 8.20
    my @o = ref($val) ? @$val : (split /\./, $val);
    shift @o if $o[0] eq ''; # remove empty in case specified with leading .
    # no special encoding of 1st 2

    $me->debug("encode relative-oid [@o]");
    pack('w*', @o);
}


################################################################

sub encode_ident {
    my $me   = shift;
    my $type = shift;
    my $tnum = shift;

    if( $tnum < 31 ){
	return pack('C', $type|$tnum);
    }
    $type |= 0x1f;
    pack('Cw', $type, $tnum);
}

sub encode_length {
    my $me  = shift;
    my $len = shift;

    return pack('C', $len)        if $len < 128;	# x.690 8.1.3.4
    return pack('CC', 0x81, $len) if $len < 1<<8;	# x.690 8.1.3.5
    return pack('Cn', 0x82, $len) if $len < 1<<12;
    return pack('CCn',0x83, ($len>>16), ($len&0xFFFF)) if $len < 1<<16;
    return pack('CN', 0x84, $len) if $len <= 0xFFFFFFFF;
    
    # items larger than above will be encoded in indefinite form
    return;
}

# override me in subclass
sub rule_check_and_apply {
    my $me   = shift;
    my $data = shift;

    undef;
}

# convert DWIM values => canonical form
sub canonicalize {
    my $me   = shift;
    my $data = shift;
    
    # arrayref | int | float | string | undef

    unless( defined $data ){
	return {
	    type	=> 'null',
	    value	=> undef,
	};
    }
    
    if( $me->behaves_like_an_array($data) ){
	return {
	    type	=> 'sequence',
	    value	=> $data,
	};
    }

    if( $me->behaves_like_a_hash($data) ){
	return {
	    type	=> ['application', 'constructed', 3],
	    value	=> [ %$data ],
	};
    }
    
    if( $me->smells_like_a_number($data) ){
	return {
	    type	=> ( int($data) == $data ? 'integer' : 'real'),
	    value	=> $data,
	};
    }

    # call it a string
    return {
	type	=> 'octet_string',
	value	=> $data,
    };
}

# tags added via add_tag method
sub app_tag_data_byname {
    my $me    = shift;
    my $name  = shift;

    $me->{tags}{$name};
}

# override me in subclass
sub subclass_tag_data_byname {
    my $me    = shift;
    my $name  = shift;

    undef;
}

# from the table up top
sub univ_tag_data_byname {
    my $me    = shift;
    my $name  = shift;

    $ALLTAG{$name} || ($AKATAG{$name} && $ALLTAG{$AKATAG{$name}});
}

sub tag_data_byname {
    my $me    = shift;
    my $name  = shift;

    my $th;
    # application specific tag name
    $th = $me->app_tag_data_byname($name);
    
    # subclass specific tag name
    $th = $me->subclass_tag_data_byname($name) unless $th;
    
    # universal tag name
    $th = $me->univ_tag_data_byname($name) unless $th;

    $th;
}

sub class_and_type_from_speclist {
    my $me = shift;
    my($class, $type);
    for my $t (@_){
	if( $CLASS{$t} ){ $class = $t; next }
	if( $TYPE{$t}  ){ $type  = $t; next }
	$me->error("unknown type specification [$t] not a class or type");
    }
    ($class, $type);
}

sub ident_data_and_efunc {
    my $me   = shift;
    my $typd = shift;
    my $func = shift;

    $func ||= 'e';
    my @t = ref($typd) ? @$typd : ($typd);
    
    # type: name | [class, type, name] | [class, type, num]
    # if name resolves, specified class+type for validation only

    my $tname = pop @t;
    if( $me->smells_like_a_number($tname) ){
	my($class, $type) = $me->class_and_type_from_speclist( @t );
	$class ||= 'universal';
	$type  ||= 'primitive';
	my $tv = $CLASS{$class}{v} | $TYPE{$type}{v};
	my $tm = $tname + 0;
	$me->debug("numeric specification [@t $tname] resolved to [$class $type $tm]");
	return ( $tv, $tm, undef );
    }

    my $th = $me->tag_data_byname($tname);

    unless( $th ){
	$me->error("unknown type [$tname]");
    }
    unless( ref $th ){
	$me->error("programmer botch. tag data should be hashref: [$tname] => $th");
	$th = undef;
    }

    my( $class, $type, $rclass, $rtype, $tnum, $encf );

    # parse request
    ($rclass, $rtype) = $me->class_and_type_from_speclist( @t );
    # parse spec
    if( my $ts = $th->{type} ){
	($class,  $type) = $me->class_and_type_from_speclist( @$ts );
    }

    # use these values for identifier-value
    $class ||= 'universal';
    $type  = $rtype || $type || 'primitive';
    $tnum  = $th->{v};

    $me->debug("specificication [@t $tname] resolved to [$class $type $tname($tnum)]");
    # warn if mismatched
    $me->warn("specificication [$rclass $tname] resolved to [$class $tname]")
	if $rclass && $rclass ne $class;
    
    # indirect via implicit to find encoding func
    $encf = $th->{$func};
    if( my $impl = $th->{implicit} ){
	# only one level of indirection
	$th = $me->tag_data_byname($impl);

	if( ref $th ){
	    $me->debug("specificication [$class $type $tname($tnum)] is implictly $impl ");
	    $encf ||= $th->{$func};
	}else{
	    $me->error("programmer botch. implicit indirect not found: [$class $tname] => $impl");
	}
    }

    my $tv = $CLASS{$class}{v} | $TYPE{$type}{v};
    return( $tv, $tnum, $encf );
}

sub use_definite_form {
    my $me   = shift;
    my $type = shift;
    my $data = shift;
    
    return 1 unless $type & 0x20;		# x.690 8.1.3.2 - primitive - always definite

    my $fl = $data->{flavor} || $me->{flavor};
    return 1 unless $fl;
    return 1 if $fl eq 'DER';			# x.690 10.1 - DER - always definite
    return 0 if $fl eq 'CER';			# x.690 9.1  - CER + constructed - indefinite
    1;						# otherwise, prefer definite
}

################################################################

sub behaves_like_an_array {
    my $me = shift;
    my $d  = shift;

    return unless ref $d;
    return UNIVERSAL::isa($d, 'ARRAY');
}

sub behaves_like_a_hash {
    my $me = shift;
    my $d  = shift;

    return unless ref $d;

    # treat as if it is a number
    return if UNIVERSAL::isa($d, 'Math::BigInt');
    return UNIVERSAL::isa($d, 'HASH');
}

sub smells_like_a_number {
    my $me = shift;
    my $d  = shift;

    return 1 if ref $d && UNIVERSAL::isa($d, 'Math::BigInt');
    # NB: 5.00503 does not have 'no warnings';
    local $^W = 0;
    return ($d + 0 eq $d);
}

################################################################

=item decode( ber )

Decode the provided BER encoded data. returns a perl data structure.
[see: DECODED DATA]

  example:
  my $data = $enc->decode( $ber );

=cut
    ;

sub decode {
    my $me   = shift;
    my $data = shift;

    $me->{level} = 0;
    my($v, $l) = $me->decode_item($data, 0);
    $v;
}

sub decode_items {
    my $me   = shift;
    my $data = shift;
    my $eocp = shift;
    my $levl = shift;
    my @v;
    my $tlen = 0;

    $me->{level} = $levl;
    $me->debug("decode items[");
    while($data){
	my($val, $len) = $me->decode_item($data, $levl+1);
	$tlen += $len;
	unless( $val && defined $val->{type} ){
	    # end-of-content
	    $me->debug('end of content');
	    last if $eocp;
	}

	push @v, $val;
	$data = substr($data, $len);
    }

    $me->{level} = $levl;
    $me->debug(']');
    return (\@v, $tlen);
}

sub decode_item {
    my $me   = shift;
    my $data = shift;
    my $levl = shift;
    
    # hexdump($data, 'di:');
    $me->{level} = $levl;
    my($typval, $typlen, $typmore)         = $me->decode_ident($data);
    my($typdat, $decfnc, $pretty, $tagnum) = $me->ident_descr_and_dfuncs($typval, $typmore);
    my($datlen, $lenlen)                   = $me->decode_length(substr($data,$typlen));
    my $havlen = length($data);
    my $tlen   = $typlen + $lenlen + ($datlen || 0);
    my $doff   = $typlen + $lenlen;
    my $result;
    
    $me->error("corrupt data? data appears truncated")
	if $havlen < $tlen;

    if( $typval & 0x20 ){
	# constructed
	my $vals;
	
	if( defined $datlen ){
	    # definite
	    $me->debug("decode item: constructed definite [@$typdat($tagnum)]");
	    my($v, $t) = $me->decode_items( substr($data, $doff, $datlen), 0, $levl);
	    $me->{level} = $levl;
	    $me->warn("corrupt data? item len != data len ($t, $datlen)")
		unless $t == $datlen;
	    $vals = $v;
	}else{
	    # indefinite
	    $me->debug("decode item: constructed indefinite [@$typdat($tagnum)]");
	    my($v, $t) = $me->decode_items( substr($data, $doff), 1, $levl );
	    $me->{level} = $levl;
	    $tlen += $t;
	    $tlen += 2; # eoc
	    $vals = $v;
	}
	if( $decfnc ){
	    # constructed decode func: reassemble
	    $result = $decfnc->( $me, $vals, $typdat );
	}else{
	    $result = {
		value   => $vals,
	    };
	}
    }else{
	# primitive
	my $ndat;
	if( defined $datlen ){
	    # definite
	    $me->debug("decode item: primitive definite [@$typdat($tagnum)]");
	    $ndat = substr($data, $doff, $datlen);
	}else{
	    # indefinite encoding of a primitive is a violation of x.690 8.1.3.2(a)
	    # warn + parse it anyway
	    $me->debug("decode item: primitive indefinite [@$typdat($tagnum)]");	    
	    $me->warn("protocol violation - indefinite encoding of primitive. see x.690 8.1.3.2(a)");
	    my $i = index($data, "\0\0", $doff);
	    if( $i == -1 ){
		# invalid encoding.
		# no eoc found.
		# go back to protocol school.
		$me->error("corrupt data - content terminator not found. see x.690 8.1.3.6, 8.1.5, et al. ");
		return (undef, $tlen);
	    }
	    my $dl = $i - $doff;
	    $tlen += $dl;
	    $tlen += 2; # eoc
	    $ndat = substr($data, $doff, $dl);
	}

	unless( $typval || $typmore ){
	    # universal-primitive-tag(0) => end-of-content
	    return ( { }, $tlen );
	}

	# decode it
	$decfnc ||= \&decode_unknown;
	my $val = $decfnc->( $me, $ndat, $typdat );
	
	# format value in a special pretty way?
	if( $pretty ){
	    $val = $pretty->( $me, $val ) || $val;
	}
	$result = $val;
    }    

    $result->{type}     = $typdat;
    $result->{tagnum}   = $tagnum;
    $result->{identval} = $typval;
    
    if( my $c = $me->{decoded_callback} ){
	$result = $c->( $me, $result ) || $result;  # make sure the brain hasn't fallen out
    }
    return( $result, $tlen );
}

sub app_tag_data_bynumber {
    my $me    = shift;
    my $class = shift;
    my $tnum  = shift;
    
    my $name = $me->{revtags}{$class}{$tnum};
    return unless $name;

    $me->{tags}{$name};
}

# override me in subclass
sub subclass_tag_data_bynumber {
    my $me    = shift;
    my $class = shift;
    my $tnum  = shift;

    undef;
}

sub univ_tag_data_bynumber {
    my $me    = shift;
    my $class = shift;
    my $tnum  = shift;

    $TAG{$class}{ $REVTAG{$class}{$tnum} };
}

sub tag_data_bynumber {
    my $me    = shift;
    my $class = shift;
    my $tnum  = shift;

    my $th;
    # application specific tag name
    $th = $me->app_tag_data_bynumber($class, $tnum);
    
    # subclass specific tag name
    $th = $me->subclass_tag_data_bynumber($class, $tnum) unless $th;

    # from universal
    $th = $me->univ_tag_data_bynumber($class, $tnum) unless $th;

    $th;
}

sub ident_descr_and_dfuncs {
    my $me   = shift;
    my $tval = shift;
    my $more = shift;

    my $tag = $more || ($tval & 0x1f) || 0;
    my $cl  = $tval & 0xC0;
    my $ty  = $tval & 0x20;
    my $class  = $REVCLASS{$cl};
    my $pctyp  = $REVTYPE{$ty};

    my( $th, $tn, $tf, $tp );

    $th = $me->tag_data_bynumber($class, $tag);

    if( ref $th ){
	$tn = $th->{n};
	$tp = $th->{pretty};
	
	if( my $impl = $th->{implicit} ){
	    # indirect. we support only one level.
	    my $h = $me->tag_data_byname($impl);
	    if( ref $h ){
		$th = $h;
	    }else{
		$me->error("programmer botch. implicit indirect not found: $class/$tn => $impl");
	    }
	}
	# primitive decode func or constructed decode func?
	$tp ||= $th->{pretty};
	$tf   = $ty ? $th->{dc} : $th->{d};
    }elsif( $th ){
	$me->error("programmer botch. tag data should be hashref: $class/$tag => $th");
    }else{
        $me->warn("unknown type [$class $tag]");
    }

    $tn = $tag unless defined $tn;

    $me->debug("identifier $tval/$tag resolved to [$class $pctyp $tn]");
    # [class, type, tagname], decodefunc, tagnumber
    ([$class, $pctyp, $tn], $tf, $tp, $tag);
}

sub decode_length {
    my $me   = shift;
    my $data = shift;

    my($l1) = unpack('C', $data);

    unless( $l1 & 0x80 ){
	# x.690 8.1.3.4 - short form
	return ($l1, 1);
    }
    if( $l1 == 0x80 ){
	# x.690 8.1.3.6 - indefinite form
	return (undef, 1);
    }

    # x.690 8.1.3.5 - long form
    my $llen = $l1 & 0x7f;
    my @l = unpack("C$llen", substr($data, 1));

    my $len = 0;
    for my $l (@l){
	$len <<= 8;
	$len += $l;
    }
    
    ($len, $llen + 1);
}

sub decode_ident {
    my $me   = shift;
    my $data = shift;

    my($tag) = unpack('C', $data);
    return ($tag, 1) unless ($tag & 0x1f) == 0x1f;	# x.690 8.1.2.3

    # x.690 8.1.2.4 - tag numbers > 30
    my $i = 1;
    $tag &= ~0x1f;
    my $more = 0;
    while(1){
	my $c = unpack('C', substr($data,$i++,1));
	$more <<= 7;
	$more |= ($c & 0x7f);
	last unless $c & 0x80;
    }

    ($tag, $i, $more);
}

sub decode_bool {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    my $v = unpack('C', $data);
    
    {
	value => $v,
    };
}

sub decode_null {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    {
	value => undef,
    };
}

# reassemble constructed string
sub reass_string {
    my $me   = shift;
    my $vals = shift;
    my $type = shift;

    my $val = '';
    for my $v (@$vals){
	$val .= $v->{value};
    };

    $me->debug('reassemble constructed string');
    return {
	type  => [ $type->[0], 'primitive', $type->[2] ],
	value => $val,
    };
    
}

sub decode_string {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    {
	value => $data,
    };
}

sub decode_bits {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    my $pad = unpack('C', $data);
    # QQQ - remove padding?
    
    $data = substr($data, 1);
    
    {
	value => $data,
    };
}

sub decode_int {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    my $val = $me->part_decode_int($data, 1);
    $me->debug("decode integer: $val");
    {
	value => $val,
    };    
}

sub decode_uint {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    my $val = $me->part_decode_int($data, 0);
    $me->debug("decode unsigned integer: $val");
    {
	value => $val,
    };    
}

sub part_decode_int {
    my $me   = shift;
    my $data = shift;
    my $sgnd = shift;

    my $val;
    my $big;
    $big = 1 if _have_math_bigint() && length($data) > 4;

    if( $big ){
	my $sign = unpack('c', $data) < 0;
	if( $sgnd && $sign ){
	    # make negative
	    $val = Math::BigInt->new('0x' . unpack('H*', pack('C*', map {~$_ & 0xff} unpack('C*', $data))));
	    $val->bneg()->bsub(1);
	}else{
	    $val = Math::BigInt->new('0x' . unpack('H*', $data));
	}
	
    }else{
	$val  = unpack(($sgnd ? 'c' : 'C'),  $data);
	my @o    = unpack('C*', $data);
	shift @o;
	for my $i (@o){
	    $val *= 256;
	    $val += $i;
	}
    }

    $val;
}

sub decode_real {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    $me->debug('decode real');
    return { value => 0.0 } unless $data;

    # POSIX required. available?
    eval {
	require POSIX;
    };
    return $me->error("POSIX not available. cannot decode type real")
	unless defined &POSIX::frexp;

    my $first = unpack('C', $data);
    return { value => POSIX::HUGE_VAL()   } if $first == 0x40;
    return { value => - POSIX::HUGE_VAL() } if $first == 0x41;

    if( $first & 0x80 ){
	# binary encoding
	my $sign = ($first & 0x40) ? -1 : 1;
	my $base = ($first & 0x30) >> 4;
	my $scal = [0, 1, -2, -1]->[($first & 0x0C) >> 2];
	my $expl = ($first & 0x03) + 1;

	$data = substr($data, 1);

	if( $expl == 4 ){
	    $expl = unpack('C', $data);
	    $data = substr($data, 1);
	}

	my $exp  = $me->part_decode_int( substr($data, 0, $expl), 1 );
	$data = substr($data, $expl);
	my @mant = unpack('C*', $data);
	$me->debug("decode real: [@mant] $exp");

	# apply scale factor
	$exp *= 3 if $base == 1;
	$exp *= 4 if $base == 2;
	$me->error('corrupt data: invalid base for real') if $base == 3;
	$exp += $scal;

	# put it together
	my $val = 0;
	$exp += (@mant - 1) * 8;
	for my $m (@mant){
	    $val += POSIX::ldexp($m, $exp);
	    # $me->debug("decode real: $val ($m, $exp)");
	    $exp -= 8;
	}
	$val *= $sign;
	
	$me->debug("decode real: => $val");
	return { value => $val };
    }else{
	# decimal encoding
	# x.690 8.5.7 - see iso-6093
	$me->debug('decode real decimal');
	$data = substr($data, 1);
	$data =~ s/^([+-]?)0+/$1/;	# remove leading 0s
	$data =~ s/\s//g;		# remove spaces
	$data += 0;			# make number
	
	return { value => $data };
    }
    
}

sub decode_oid {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    my @o = unpack('w*', $data);
    
    if( $o[0] < 40 ){
	unshift @o, 0;
    }elsif( $o[0] < 80 ){
	$o[0] -= 40;
	unshift @o, 1;
    }else{
	$o[0] -= 80;
	unshift @o, 2;
    }

    my $val = join('.', @o);
    $me->debug("decode oid: $val");
    
    {
	value => $val,
    };    
}

sub decode_roid {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    my @o = unpack('w*', $data);
    
    my $val = join('.', @o);
    $me->debug("decode relative-oid: $val");
    
    {
	value => $val,
    };    
}

sub decode_unknown {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    $me->debug("decode unknown");
    {
	value => $data,
    };    
}

sub _have_math_bigint {

    return unless defined &Math::BigInt::new;
    return unless defined &Math::BigInt::is_neg;

    1;
}
    
################################################################

sub hexdump {
    my $b   = shift;
    my $tag = shift;
    my( $l, $t );

    print STDERR "$tag:\n" if $tag;
    while( $b ){
	$t = $l = substr($b, 0, 16, '');
	$l =~ s/(.)/sprintf('%0.2X ',ord($1))/ges;
	$l =~ s/(.{24})/$1 /;
	$t =~ s/[[:^print:]]/./gs;
	my $p = ' ' x (49 - (length $l));
	print STDERR "    $l  $p$t\n";
    }
}

sub import {
    my $pkg    = shift;
    my $caller = caller;

    for my $f (@_){
	no strict;
	my $fnc = $pkg->can($f);
	next unless $fnc;
	*{$caller . '::' . $f} = $fnc;
    }
}

=back

=head1 ENCODING DATA

You can give data to the encoder in either of two ways (or mix and match).

You can specify simple values directly, and the module will guess the
correct tags to use. Things that look like integers will be encoded as
C<integer>, things that look like floating-point numbers will be encoded
as C<real>, things that look like strings, will be encoded as C<octet_string>.
Arrayrefs will be encoded as C<sequence>.

  example:
  $enc->encode( [0, 1.2, "foobar", [ "baz", 37.94 ]] );

Alternatively, you can explicity specify the type using a hashref
containing C<type> and C<value> keys.

  example:
  $enc->encode( { type  => 'sequence',
                  value => [
                             { type  => 'integer',
                               value => 37 } ] } );

The type may be specfied as either a string containg the tag-name, or
as an arryref containing the class, type, and tag-name.

  example:
  type => 'octet_string'
  type => ['universal', 'primitive', 'octet_string']

Note: using the second form above, you can create wacky encodings
that no one will be able to decode. 
    
The value should be a scalar value for primitive types, and an
arrayref for constructed types.

  example:
  { type => 'octet_string', value => 'foobar' }
  { type => 'set', value => [ 1, 2, 3 ] }

  { type  => ['universal', 'constructed', 'octet_string'],
    value => [ 'foo', 'bar' ] }

=head1 DECODED DATA

The values returned from decoding will be similar to the way data to
be encoded is specified, in the full long form. Additionally, the hashref
will contain: C<identval> the numeric value representing the class+type+tag
and C<tagnum> the numeric tag number.

  example: 
  a string might be returned as:
  { type     => ['universal', 'primitive', 'octet_string'],
    identval => 4,
    tagnum   => 4,
    value    => 'foobar',
  }


=head1 TAG NAMES

The following are recognized as valid names of tags:

    bit_string bmp_string bool boolean character_string embedded_pdv
    enum enumerated external float general_string generalized_time
    graphic_string ia5_string int int32 integer integer32 iso646_string
    null numeric_string object_descriptor object_identifier octet_string
    oid printable_string real relative_object_identifier relative_oid
    roid sequence sequence_of set set_of string t61_string teletex_string
    uint uint32 universal_string universal_time unsigned_int unsigned_int32
    unsigned_integer utf8_string videotex_string visible_string 

=head1 Math::BigInt

If you have Math::BigInt, it can be used for large integers. If you want it used,
you must load it yourself:

    use Math::BigInt;
    use Encoding::BER;

It can be used for both encoding and decoding. The encoder can be handed either
a Math::BigInt object, or a "big string of digits" marked as an integer:

    use math::BigInt;

    my $x = Math::BigInt->new( '12345678901234567890' );
    $enc->encode( $x )

    $enc->encode( { type => 'integer', '12345678901234567890' } );

During decoding, a Math::BigInt object will be created if the value "looks big".

    
=head1 EXPORTS

By default, this module exports nothing. This can be overridden by specifying
something else:

    use Encoding::BER ('import', 'hexdump');

=head1 LIMITATIONS

If your application uses the same tag-number for more than one type of implicitly
tagged primitive, the decoder will not be able to distinguish between them, and will
not be able to decode them both correctly. eg:

    width ::= [context 12] implicit integer
    girth ::= [context 12] implicit real

If you specify data to be encoded using the "short form", the module may
guess the type differently than you expect. If it matters, be explicit.

This module does not do data validation. It will happily let you encode
a non-ascii string as a C<ia5_string>, etc.

    
=head1 PREREQUISITES

If you wish to use C<real>s, the POSIX module is required. It will be loaded
automatically, if needed.

Familiarity with ASN.1 and BER encoding is probably required to take
advantage of this module.

=head1 SEE ALSO
    
    Yellowstone National Park
    Encoding::BER::CER, Encoding::BER::DER
    Encoding::BER::SNMP, Encoding::BER::Dumper
    ITU-T x.690
    
=head1 AUTHOR

    Jeff Weisberg - http://www.tcp4me.com

=cut
    ;

################################################################
1;

