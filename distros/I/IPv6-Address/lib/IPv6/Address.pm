use strict;
use warnings;

package IPv6::Address;
$IPv6::Address::VERSION = '0.208';

=head1 NAME

IPv6::Address - IPv6 Address Manipulation Library

=head1 VERSION

version 0.208

=for html
<a href="https://travis-ci.org/aduitsis/IPv6-Address"><img src="https://travis-ci.org/aduitsis/IPv6-Address.svg?branch=master"></a>
<a href='https://coveralls.io/r/aduitsis/IPv6-Address?branch=master'><img src='https://coveralls.io/repos/aduitsis/IPv6-Address/badge.svg?branch=master' alt='Coverage Status' /></a>


=head1 SYNOPSIS

 use IPv6::Address;

 my $ipv6 = IPv6::Address->new('2001:648:2000::/48');

 $ipv6->contains('2001:648:2000::/64'); #true

 say $ipv6->to_string;
 say $ipv6->string; # Same as previous
 say $ipv6; # Same as previous

 say $ipv6->string(nocompress=>1); # do not compress using the :: notation
 say $ipv6->string(ipv4=>1); #print the last 32 bits as an IPv4 address
 
 $ipv6->addr_string; # Returns '2001:648:2000::'
 
 $ipv6->split(4); # Split the prefix into 2^4 smaller prefixes. Returns a list.  

 $ipv6->apply_mask; # Apply the mask to the address. All bits beyond the mask length become 0.

 $ipv6->first_address;

 $ipv6->last_address;

 $a->enumerate_with_offset( 5 , 64 ); #returns 2001:648:2000:4::/64 

=head1 DESCRIPTION

A pure Perl IPv6 address manipulation library. Emphasis on manipulation of
prefixes and addresses. Very easy to understand and modify. The internal
representation of an IPv6::Address is a blessed hash with two keys, a prefix
length (0-128 obviously) and a 128-bit string. A multitude of methods to do
various tasks is provided. 


=head2 Methods

=over 12

=cut

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Sub::Install;

use overload 
	'""' => \&to_string,
	'<=>' => \&n_cmp,
	fallback => 1;
	
my $DEBUG = 0;

sub debug {
	$DEBUG&&print STDERR $_[0];
	$DEBUG&&print STDERR "\n";
	
}

=item C<new( ipv6_string )>

Takes a string representation of an IPv6 address and creates a corresponding
IPv6::Address object.

=cut

#takes a normal address as argument. Example 2001:648:2000::/48
sub new {
	my $class = shift(@_) or croak "incorrect call to new";
	my $ipv6_string = shift(@_) or croak "Cannot use an empty string as argument";
	my ($ipv6,$prefixlen) = ( $ipv6_string =~ /([0-9A-Fa-f:]+)\/(\d+)/ );
	croak "IPv6 address part not parsable" if (!defined($ipv6));
	croak "IPv6 prefix length part not parsable" if (!defined($prefixlen));
	debug("ipv6 is $ipv6, length is $prefixlen");
	my @arr;
	my @_parts = ( $ipv6 =~ /([0-9A-Fa-f]+)/g );
	my $nparts = scalar @_parts;
	if ($nparts != 8) {
		for(my $i=1;$i<=(8-$nparts);$i++) { push @arr,hex "0000" };
	} 

	my @parts = map { ($_ eq '::')? @arr : hex $_ } ( $ipv6 =~ /((?:[0-9A-Fa-f]+)|(?:::))/g ); 
	
	debug(join(":",map { sprintf "%04x",$_ } @parts));

	my $bitstr = pack 'n8',@parts;
	
	return bless { 
		bitstr => $bitstr,
		prefixlen => $prefixlen,
	},$class;		
}

=item C<raw_new( bitstr, length )>

Creates a new IPv6::Address out of a bitstring and a prefix length. The
bitstring must be binary, please do not use a '0' or '1' character string.

=cut

#takes a bitstr (0101010101111010010....) and a prefix length as arguments
sub raw_new {
	my $class = $_[0];
	return bless { 
		bitstr => $_[1],
		prefixlen => $_[2],
	},$class;	
}

=item C<get_bitstr>

Returns the bitstr of the object.

=cut

#returns the bitstr (11010111011001....)
sub get_bitstr {
	return $_[0]->{bitstr};
}


=item C<get_prefixlen>

Returns the prefix length of the address.

=cut

#returns the length of the IPv6 address prefix
sub get_prefixlen {
	return $_[0]->{prefixlen};
}

=item C<get_mask_bitstr(length)>

Returns a 128-bit string with the first prefix-length bits equal
to 1, rest equal to 0. Essentially takes the prefix length of the object and
returns a corresponding bit mask.

=cut

#returns a 1111100000 corresponding to the prefix length
sub get_mask_bitstr {
	generate_bitstr( $_[0]->get_prefixlen )
}	

=item C<get_masked_address_bitstr>

Returns the bitstring, after zeroing out all the bits after the prefix length.
Essentially applies the prefix mask to the address.

=cut
sub get_masked_address_bitstr {
	generate_bitstr( $_[0]->get_prefixlen ) & $_[0]->get_bitstr;
}

=item C<generate_bitstr( number )>

Not a method, returns 128-bit string, first n-items are 1, rest is 0. 

=cut

sub generate_bitstr { 
	#TODO trick bellow is stupid ... fix
	pack 'B128',join('',( ( map { '1' } ( 1 .. $_[0] ) ) , ( map { '0' } ( 1 .. 128-$_[0] ) ) ));
}

=item C<bitstr_and( bitstr1 , bitstr2 )>

Not a method, AND's two bitstrings, returns result.

=cut
#takes two bitstrs as arguments and returns their logical or as bitstr
sub bitstr_and {
	return $_[0] & $_[1]
}

=item C<bitstr_or( bitstr1 , bitstr2)>

Not a method, OR's two bitstrings, returns result.

=cut
#takes two bitstrs as arguments and returns their logical or as bitstr
sub bitstr_or {
	return $_[0] | $_[1]
}

=item C<bitstr_not( bitstr )>

Not a method, inverts a bitstring.

=cut
#takes a bitstr and inverts it
sub bitstr_not {
	return ~ $_[0]
}

=item C<from_str( string_bitstring )>

Not a method, takes a string of characters 0 or 1, returns corresponding binary
bitstring.  Please do not use more than 128 characters, rest will be ignored.

=cut

#converts a bitstr (111010010010....)  to a binary string 
sub from_str {
	my $str = shift(@_);
	return pack("B128",$str);
}

=item C<to_str( bitstring )>

Not a method, takes a binary bitstring, returns a string composed of 0's and
1's. Please supply bitstrings of max. 128 bits, rest of the bits will be
ignored.

=cut

#converts from binary to literal bitstr
sub to_str {
	my $bitstr = shift(@_);
	return join('',unpack("B128",$bitstr));
}

=item C<contains( other_address )>

This method takes an argument which is either an IPv6::Address or a plain string
that can be promoted to a valid IPv6::Address, and tests whether the object
contains it. Obviously returns true or false.

=cut

sub contains {
	defined( my $self = shift(@_) ) or die 'incorrect call';
	defined( my $other = shift(@_) ) or die 'incorrect call';
	if (ref($other) eq '') {
		$other = __PACKAGE__->new($other);
	}
	return if ($self->get_prefixlen > $other->get_prefixlen);
	return 1 if $self->get_masked_address_bitstr eq ( generate_bitstr( $self->get_prefixlen ) & $other->get_bitstr );
	#return 1 if (substr($self->get_bitstr,0,$self->get_prefixlen) eq substr($other->get_bitstr,0,$self->get_prefixlen));
	return;
}

=item C<addr_string>

Returns the address part of the IPv6::Address. Using the option ipv4=>1 like 

 $a->addr_string(ipv4=>1) 

will make the last 32-bits appear as an IPv4 address. Also, using nocompress=>1
like 

 $a->addr_string( nocompress => 1 ) 

will prevent the string from containing a '::' part. So it will be 8 parts
separated by ':' colons. 

=cut

#returns the address part (2001:648:2000:0000:0000....)
sub addr_string {
	my $self = shift(@_);
	my $str = join(':',map { sprintf("%x",$_) } (unpack("nnnnnnnn",$self->get_bitstr)) );
	my $str2 = join(':',map { sprintf("%04x",$_) } (unpack("nnnnnnnn",$self->get_bitstr)) );
	#print Dumper(@_);
	my %option = (@_) ;
	#print Dumper(\%option);
	if (defined($option{ipv4}) && $option{ipv4}) {
		###print "string:",$str,"\n";
		$str = join(':',map { sprintf("%x",$_) } (unpack("nnnnnn",$self->get_bitstr)) ).':'.join('.',  map {sprintf("%d",hex $_)} ($str2 =~ /([0-9A-Fa-f]{2})([0-9A-Fa-f]{2}):([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/));
		#print STDERR $ipv4,"\n";
		
	}
	#print 'DEBUG:' . $str,"\n";
	return $str2 if $option{full};
	return $str if $option{nocompress};
	return '::' if($str eq '0:0:0:0:0:0:0:0');
	for(my $i=7;$i>1;$i--) {
		my $zerostr = join(':',split('','0'x$i));
		###print "DEBUG: $str $zerostr \n";
		if($str =~ /:$zerostr$/) {
			$str =~ s/:$zerostr$/::/;
			return $str;
		}
		elsif ($str =~ /:$zerostr:/) {
			$str =~ s/:$zerostr:/::/;
			return $str;
		}
		elsif ($str =~ /^$zerostr:/) {
			$str =~ s/^$zerostr:/::/;	
			return $str;
		} 
	}
	return $str;
}

=item C<string>

Returns the full IPv6 address, with the prefix in its end.

=cut

#returns the full IPv6 address 
sub string {
	my $self = shift(@_);
	return $self->addr_string(@_).'/'.$self->get_prefixlen;
}

=item C<to_string>

Used internally by the overload module.

=cut
#to be used by the overload module
sub to_string {
	return $_[0]->string();
}

=item C<split( exponent , target_length )>

Splits the address to the order of two of the number given as first argument.
Example: if argument is 3, 2^3=8, address is split into 8 parts. The final parts
have prefix length equal to the target_length specified in the second argument.

=cut
sub split {
	my $self = shift(@_);
	my $split_length = shift(@_);#example: 3
	my $networks = 2**$split_length;#2**3 equals 8 prefixes
	my @bag = ();
	for(my $i=0;$i<$networks;$i++) { #from 0 to 7
		my $b_str = sprintf("%0${split_length}b",$i); # 001,010,011 and so on util 111 (7)
		my $addr_str = $self->get_bitstr; #get the original bitstring of the address
		substr($addr_str,$self->get_prefixlen,$split_length) = $b_str; #replace the correct 3 bits with $b_str
		debug $addr_str,"\n";
		push @bag,(__PACKAGE__->raw_new($addr_str,$self->get_prefixlen + $split_length)); #create and store the new addr
	}
	return @bag;
}

	
=item C<apply_mask>

Applies the prefix length mask to the address. Does not return anything. Works on $self. 
B<WARNING:>This will alter the object.

=cut
sub apply_mask {
	my $self = shift(@_);
	$self->{bitstr} = bitstr_and($self->get_bitstr,$self->get_mask_bitstr);
}	

=item C<first_address>

Returns the first address of the prefix that is represented by the object. E.g.
consider 2001:648:2000::1234/64. First address will be 2001:648:2000::/64. 

=cut

sub first_address {
	my $bitstr = bitstr_and( $_[0]->get_bitstr , $_[0]->get_mask_bitstr );
	IPv6::Address->raw_new( $bitstr, $_[0]->get_prefixlen);
}

=item C<last_address>

Returns the last address of the prefix that is represented by the object. E.g.
consider 2001:648:2000::1234/64. Last address will be
2001:648:2000::ffff:ffff:ffff:ffff/64. 

=cut
sub last_address {
	my $bitstr = bitstr_or( $_[0]->get_bitstr , bitstr_not( $_[0]->get_mask_bitstr ) );
	IPv6::Address->raw_new( $bitstr, $_[0]->get_prefixlen);
}
	

=item C<is_unspecified> , C<is_loopback> , C<is_multicast>

Returns true or false depending on whether the address falls into the
corresponding category stated by the method name. E.g. 

 IPv6::Address->new('::1')->is_loopback # returns true

=cut

my %patterns = (
	unspecified => "^::\$",
	loopback => "^::1\$",
	multicast => "^ff",
);
#@TODO: implement this
my %binary_patterns = (
	"link-local unicast" => "^",
);


for my $item (keys %patterns) {
	Sub::Install::install_sub({
		code => sub {
			return ( shift(@_)->addr_string =~ /$patterns{$item}/i )? 1 : 0;
		},
		into => __PACKAGE__,
		as => 'is_'.$item,
	});
}

use strict;

=item C<ipv4_to_binarray>

Not a method, takes an IPv4 address, returns a character string consisting of 32
characters that are 0 or 1. Used internally, not too useful for the end user.

=cut
sub ipv4_to_binarray {
	defined( my $ipv4 = shift ) or die 'Missing IPv4 address argument';
	my @parts = ( split('\.',$ipv4) );
	my @binarray = split('',join('',map { sprintf "%08b",$_ } @parts));
	#debug(Dumper(\@binarray));
	return @binarray;
}



=item C<enumerate_with_IPv4( ipv4, mask )>

Takes an IPv4 address and uses a part of it to enumerate inside the Ipv6 prefix
of the object. E.g.

 IPv6::Address->new('2001:648:2001::/48')->enumerate_with_IPv4('0.0.0.1',0x0000ffff) #will yield 2001:648::2001:0001::/64

The return value will be a new IPv6::Address object, so the original object
remains intact. The part that will be used as an offset is extracted from the
ipv4 by using the mask. 

=cut

sub enumerate_with_IPv4 {
	my ($self,$IPv4,$mask) = (@_) or die 'Incorrect call';
	my $binmask = sprintf "%032b",$mask;
	
	my @IPv4 = ipv4_to_binarray($IPv4);
	my $binary = '';
	for(my $i=0;$i<32;$i++) {
		#debug("$i ".substr($binmask,$i,1));
		$binary = $binary.$IPv4[$i] if substr($binmask,$i,1) == 1;
	}
	debug($binary);
	my $new_prefixlen = $self->get_prefixlen + length($binary);
	my $new_bitstr = to_str( $self->get_bitstr );
	debug($new_bitstr);
	substr($new_bitstr, ($self->get_prefixlen), length($binary)) = $binary;
	debug("old bitstring is ".$self->get_bitstr);
	debug("new bitstring is $new_bitstr");
	debug($new_prefixlen);
	
	return __PACKAGE__->raw_new(from_str($new_bitstr),$new_prefixlen);
}

=item C<enumerate_with_offset( offset, desired_length )>

Takes a non-negative integer offset and returns a prefix whose relative position
inside the object is defined by the offset. The prefix length of the result is
defined by the second argument. E.g.

 IPv6::Address->new('2001:648:2000::/48')->enumerate_with_offset( 5 , 64 ) #2001:648:2000:4::/64

=cut

sub enumerate_with_offset {
	my ($self,$offset,$desired_length) = (@_) or die 'Incorrect call';
	my $to_replace_len = $desired_length - $self->get_prefixlen;
	my $new_bitstr = to_str( $self->get_bitstr );
	my $offset_bitstr = sprintf("%0*b",$to_replace_len,$offset);
	debug("offset number is $offset (or: $offset_bitstr)");
	#consistency check
	die "Tried to replace $to_replace_len bits, but for $offset, ".length($offset_bitstr)." bits are required"
		if(length($offset_bitstr) > $to_replace_len);
	substr($new_bitstr, ($self->get_prefixlen), length($offset_bitstr) ) = $offset_bitstr;
	return __PACKAGE__->raw_new(from_str($new_bitstr),$desired_length);
}

=item C<increment( offset )>

Increments the IPv6::Address object by offset. Offsets larger than 2^32-1 are
not acceptable. This method is probably not too useful, but is provided for
completeness.

=cut

sub increment {
	my ( $self , $offset ) = (@_) or die 'Incorrect call';

	my $max_int = 2**32-1;
	die 'Sorry, offsets beyond 2^32-1 are not acceptable' if( $offset > $max_int );
	die 'Sorry, cannot offset a /0 prefix. ' if ( $self->get_prefixlen == 0 );

	my $new_bitstr = to_str( $self->get_bitstr ); #will use it to store the new bitstr

	$DEBUG && print STDERR "Original bitstring is $new_bitstr\n";

	# 0..127
	my $start = ($self->get_prefixlen>=32)? $self->get_prefixlen - 32 : 0 ;
	my $len = $self->get_prefixlen - $start;

	$DEBUG && print STDERR "will replace from pos $start (from 0) and for $len len\n";

	# extract start..start+len part, 0-pad to 32 bits, pack into a network byte order $n
	my $n = unpack('N',pack('B32',sprintf("%0*s",32,substr($new_bitstr, $start , $len ))));

	$DEBUG && print STDERR "Original n=".$n."\n";
	$n += $offset;
	$DEBUG && print STDERR "Result n=".$n."\n";

	die "Sorry, address part exceeded $max_int" if( $n > $max_int ); #just a precaution

	# repack the $n into a 32bit network ordered integer, convert into "1000101010101..." string
	my $bstr = unpack( "B32", pack( 'N' , $n )  );

	$DEBUG && print STDERR "Replacement bitstr is $bstr\n";
	die 'internal error. Address should be 32-bits long' unless (length($bstr) == 32); #another precaution
			
	#replace into new_bitstr from start and for len with bstr up for len bytes counting from the *end*
	substr( $new_bitstr , $start , $len ) = substr( $bstr, - $len); 

	# result is ready, return it
	return __PACKAGE__->raw_new(from_str($new_bitstr),$self->get_prefixlen);
}

=item C<nxx_parts(unpack_format)>

Takes the bitstring of the address and unpacks it using the first argument.
Internal use mostly.

=cut

sub nxx_parts {
	unpack($_[1],$_[0]->get_bitstr)  
}

=item C<n16_parts>

Splits the address into an 8-item array of unsigned short integers. Network byte
order is implied, a short integer is 16-bits long.

=cut

#@TODO add tests for this method
sub n16_parts {
	( $_[0]->nxx_parts('nnnnnnnn') )
}

=item C<n16_parts>

Splits the address into an 4-item array of unsigned long integers. Network byte
order is implied, a long integer is 32-bits long.

=cut
#@TODO add tests for this method
sub n32_parts {
	( $_[0]->nxx_parts('NNNN') )
}

=item C<n_cmp( a , b )>

Takes two 128-bit bitstr arguments, compares them and returns the result as -1,
0 or 1. The semantics are the same as that of the spaceship operator <=>. 

This method will overload the <=> operator for IPv6::Address objects, so
comparing IPv6::Address objects like they were integers produces the correct
results.

=cut

#@TODO add tests for this method
sub n_cmp { 
	my @a = $_[0]->n32_parts;
	my @b = $_[1]->n32_parts;
	for ( 0 .. 3 ) {
		my $cmp = ( $a[$_] <=> $b[$_] ); 
		return $cmp if ( $cmp != 0 );
	} 
	return 0;
}

=item C<n_sort( array )>

Sorts an array of bitstrs using the n_cmp function.

=cut

sub n_sort { 
	sort { $a <=> $b } @_;
}

=item C<radius_string>

Returns a string suitable to be returned as an IPv6 Radius AV-pair. See RFC 3162
for an explanation of the format. 

=back 
=cut

sub radius_string {
	defined(my $self = shift) or die 'Missing argument';
	#Framed-IPv6-Prefix := 0x0040200106482001beef
	my $partial_bitstr = substr(to_str( $self->get_bitstr ),0,$self->get_prefixlen);
	my $remain = $self->get_prefixlen % 8;
	if($remain > 0) {
		$partial_bitstr = $partial_bitstr . '0'x(8 - $remain);
	}
	return '0x00'.sprintf("%02x",$self->get_prefixlen).join('',map {unpack("H",pack("B4",$_))}  ($partial_bitstr =~ /([01]{4})/g) );
}

package IPv4Subnet;
$IPv4Subnet::VERSION = '0.208';
use Socket;
use strict;
use Carp;
use warnings;
use Data::Dumper;


sub new {
	defined ( my $class = shift ) or die "missing class";
	defined ( my $str = shift ) or die "missing string";
	my ( $ip , $length_n ) = ( $str =~ /^(\d+\.\d+\.\d+\.\d+)\/(\d+)$/ ) or croak "Cannot parse $str";
	bless { ip_n => my_aton($ip) , length_n => $length_n } , $class	;
}

sub new_from_start_stop { 
	$_[0]->new( $_[1].'/'.(32 - log(  ( my_aton($_[1]) ^ my_aton($_[2]) )  + 1)/log(2)))
}

sub to_string { 
	$_[0]->get_start_ip . '/' . $_[0]->get_length_n
}

sub get_ip_n {
	return $_[0]->{ip_n} ;
}

sub get_start {
	return $_[0]->get_ip_n & $_[0]->get_mask_n;
}

sub get_stop {
	return $_[0]->get_start + $_[0]->get_length - 1;
}

sub get_start_ip {
	return my_ntoa($_[0]->get_start);
}

sub get_stop_ip {
	return my_ntoa($_[0]->get_stop);
}

sub get_length {
	return 2**(32-$_[0]->get_length_n);
}

sub enumerate {
	# in 32-bit systems, this seems to fail with error:
	# "Range iterator outside integer range"
	#map { my_ntoa( $_ ) } ($_[0]->get_start .. $_[0]->get_stop)
	my @ret;
	for( my $i = $_[0]->get_start ; $i <= $_[0]->get_stop ; $i++ ) {
		push @ret,my_ntoa( $i )
	}
	return @ret
}

sub get_length_n {
	return $_[0]->{length_n};
}

sub get_mask_n {
	($_[0]->get_length_n == 0 )?
		0 : hex('0xffffffff') << ( 32 - $_[0]->get_length_n )  ;
}	

sub get_mask {
	my_ntoa( $_[0]->get_mask_n );
}

sub get_wildcard {
	my_ntoa( ~ $_[0]->get_mask_n );
}

sub my_aton {
	defined ( my $aton_str = inet_aton( $_[0] ) ) or croak '$_[0] cannot be fed to inet_aton';
	return unpack('N',$aton_str);
}

sub my_ntoa {
	return inet_ntoa(pack('N',$_[0]));
}

sub between {
	my $a = shift // die 'missing 1st argument';
	my $b = shift // die 'missing 2nd argument';
	my $c = shift // die 'missing 3rd argument';
	my $d = IPv4Subnet->new( $a.'/32' );
	my $e = IPv4Subnet->new( $b.'/32' );
	my $f = IPv4Subnet->new( $c.'/32' );

	return ( $d->get_ip_n <= $e->get_ip_n ) && ( $e->get_ip_n <= $f->get_ip_n )
}

sub position { 
	my $self = shift;
	defined ( my  $arg = shift ) or die "Incorrect call";
	my $number = my_aton($arg);
	$DEBUG && print STDERR "number is ",my_ntoa($number)," and start is ",my_ntoa($self->get_start)," and stop is ",my_ntoa($self->get_stop),"\n";
	return $number - $self->get_start;
}

sub contains {
	return ( ($_[0]->position($_[1]) < $_[0]->get_length) && ( $_[0]->position($_[1]) >= 0 ) )? 1 : 0;
}

sub calculate_compound_offset {
	defined( my $address = shift ) or die 'missing address';
	defined( my $blocks = shift ) or die 'missing block reference';
	
	my $offset = 0;
	for my $block (@{$blocks}) {
		my $subnet = IPv4Subnet->new($block);
		if ($subnet->contains($address)) {
			return ( $subnet->position($address) + $offset );
		}
		else {
			$offset = $offset + $subnet->get_length;
		}
	}
	die "Address $address does not belong to range:",join(',',@{$blocks});
	return;
}

=head1 AUTHOR

Athanasios Douitsis C<< <aduitsis@cpan.org> >>

=head1 SUPPORT

Please open a ticket at L<https://github.com/aduitsis/IPv6-Address>. 

=head1 COPYRIGHT & LICENSE
 
Copyright 2008-2015 Athanasios Douitsis, all rights reserved.
 
This program is free software; you can use it
under the terms of Artistic License 2.0 which can be found at 
http://www.perlfoundation.org/artistic_license_2_0
 
=cut

1;
		
	
