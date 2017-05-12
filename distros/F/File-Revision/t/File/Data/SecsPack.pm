#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Data::SecsPack;

use strict;
use 5.001;
use warnings;
use warnings::register;

use Math::BigInt 1.50 lib => 'GMP';
use Math::BigFloat 1.40;
use Data::Startup;

use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.04';
$DATE = '2004/05/03';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(bytes2int config float2binary 
                ifloat2binary int2bytes 
                pack_float pack_int pack_num  
                str2float  str2int
                unpack_float unpack_int unpack_num);

use vars qw($default_options);
$default_options = new Data::SecsPack;

#######
# Object used to set default, startup, options values.
#
sub new
{
   Data::Startup->new(
 
      ######
      # Make Test variables visible to tech_config
      #  
      big_int_version => Math::BigInt->config()->{'version'},
      big_float_version => $Math::BigFloat::VERSION,
      binary_fraction_bytes => 10,
      decimal_fraction_digits => 25,
      decimal_integer_digits => 20,
      die => 0,
      extra_decimal_fraction_digits => 5,
      version => $VERSION,
      warnings => 0,
   );

}

use SelfLoader;

1

__DATA__


###########
# Transform integer to bytes
#
sub bytes2int
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my @integer_bytes = @_; # copy @_ so do not mangle @_
     return () unless @integer_bytes;
   
     my $integer = Math::BigInt->new('0');
     foreach (@integer_bytes) {   
         $integer->blsft(8); 
         $integer->bior($_); 
     }
     $integer->bstr();
}


######
# Provide a way to module wide configure
#
sub config
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless $default_options;
     $default_options->config(@_);
}


#####
#
#
sub float2binary
{ 
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless ref($default_options);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::float2binary-1\n";
         goto EVENT;
     }

     my ($magnitude,$exponent,@options) = @_;
     my $options = $default_options->override(@options);

     (my $sign,$magnitude) = ($1,$2) if $magnitude =~ /^\s*([+-]?)\s*(\d+)/;
     $exponent = $1 if $exponent =~ /^\s*(\d+)/;
     unless(defined($magnitude) && defined($exponent)) {
         $event = "No inputs\ntData::SecsPack::float2binary-1\n";
         goto EVENT;
     }
     $sign = '' unless defined $sign;

     ########
     # Choose the exponent for the ifloat to minimize the float exponent.
     # For some floats, the entire conversion is done with straingth forward
     # integer arith multiplies, divides and shifts. There is a practical
     # resource limitation for large positive exponents. Limit the resources
     # to exponents under 20. 
     #
     my $ifloat_exponent = 0;
     if(0 < $exponent) {
         my $int_digits = $options->{decimal_integer_digits};
         $ifloat_exponent = ($exponent <= $int_digits) ? $exponent : $int_digits;
         $exponent -= $ifloat_exponent;
     }
     elsif( $exponent < 0) {
         my $frac_digits = $options->{extra_decimal_fraction_digits};
         $ifloat_exponent = ($exponent >= -$frac_digits) ? $exponent : -$frac_digits;
         $options->{decimal_fraction_digits} -= $ifloat_exponent * 2; # - - is a plus
         $exponent -= $ifloat_exponent;
     }

     ########
     # The decimal $integer and $fraction to binary simple float with the first byte
     # of the $binary_magnitude equal to 1 and the binary decimal point between the
     # first and second byte.
     #
     my ($binary_magnitude, $binary_exponent) = ifloat2binary($magnitude, $ifloat_exponent,$options);

     ############
     # Process big decimal exponents. Convert them into integer $exponent_binary_power
     # $exponent_binary_magnitude
     # 
     #
     # 10^$exp = 2^$bin_exp = $bin_exp = $exp * ln(10) / ln(2);
     #
     # ln(10) / ln(2) = 3.32192809488736
     #
     my $exponent_conversion_error;
     if($exponent) {

          ######
          # $exponent is integer while ln(10)/ln(2) has a 25 place fraction. These the resulting
          # integer also has 25 place fraction
          #
          my $exponent_binary_power = Math::BigInt->new($exponent)->bmul(33219280948873623478703194)->bstr();
          my $exponent_factor_magnitude = '0.' . substr($exponent_binary_power, -25, 25);
          $exponent_binary_power = substr($exponent_binary_power, 0,length($exponent_binary_power) - 25);
          $exponent_factor_magnitude = '-' . $exponent_factor_magnitude if ($exponent < 0);

          #################
          # Add the integer part to the exponent 
          # 
          $binary_exponent += $exponent_binary_power;

          #############
          # Determine the decimal float for the fractional base 2 exponent from converting
          # the base 10 exponent to a base 2 exponent. Adjust the signicant digits so
          # that they will not cause an overflow when converting to a binary exponent
          # using the ifloat2binary subroutine.
          # 
          $exponent_factor_magnitude = Math::BigFloat->new(2,$options->{decimal_fraction_digits})
                      ->bpow($exponent_factor_magnitude)->bstr();

          ########
          # Multiply the conversion from power of base 10 to base 2
          # fractional base2 exponent factor with the magnitude.
          # Both are binary floats.
          #
          my $exponent_factor_exponent = index($exponent_factor_magnitude,'.')-1;
          $exponent_factor_magnitude =~ s/\.//;

          ($exponent_factor_magnitude, $exponent_factor_exponent) = 
                 ifloat2binary($exponent_factor_magnitude, $exponent_factor_exponent,$options);

          #############
          # Float multipy the conversion correction and the magnitude
          # 
          ($binary_magnitude,$binary_exponent) = float_multiply( 
                      $binary_magnitude,$binary_exponent,
                      $exponent_factor_magnitude,$exponent_factor_exponent);

     }
     $binary_magnitude =~ s/^\+//;
     return ($sign . $binary_magnitude, $binary_exponent);

EVENT:
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    return (undef,$event);
}


######
#
#
sub float_multiply
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my ($magnitude1, $exponent1, $magnitude2, $exponent2) = @_;
     return (0,0) unless defined($magnitude1) && defined($exponent1) &&
                            defined($magnitude2) && defined($exponent2);

     $exponent1 += $exponent2;
     $magnitude1 = Math::BigInt->new($magnitude1)->bmul($magnitude2);

     #########
     # 1.[0-98888+] * 1.[0-99999+]   = [1.0-4.0]
     #
     # Test to see if the multiplication produce integer bits other than 1 and if
     # so move the binary decimal point so that the integer part is 1
     # 
     my @bytes = int2bytes($magnitude1);
     my $shift;
     if( $bytes[0] > 4 ) {
         $shift = 2;  # should not occure unless have terrible accuracy problem
     }
     elsif( $bytes[0] > 2) {
         $shift = 1;
     }
     if($shift) {
         $magnitude1 = Math::BigInt->new($magnitude1)->brsft($shift);
         $exponent1 += $shift;
     }

     ($magnitude1,$exponent1);
}



#####
#
#
sub ifloat2binary
{   
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless ref($default_options);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::ifloat2binary-1\n";
         goto EVENT;
     }

     my ($magnitude,$exponent,@options) = @_;
     my $options = $default_options->override( @options);

     my $sign = $magnitude =~ s/^([+-])// ? $1 : '';
     unless(defined($magnitude) && defined($exponent)) {
         $event = "No inputs\ntData::SecsPack::ifloat2binary-1\n";
         goto EVENT;
     }
     $sign = '' unless defined $sign;

     ######
     # Break up the magnitude into integer and decimal parts
     #
     # Decimal point placed so one significant decimal digit
     # Move the decimal point to comply to the exponent;
     #
     $magnitude = $1 if $magnitude =~ /^\s*(\S+)/; # comments, leading, trailing white space
     $exponent = $1 if $exponent =~ /^\s*(\S+)/;
     my $decimal_fraction_digits =  $options->{decimal_fraction_digits}; 
     $decimal_fraction_digits = 30 unless $decimal_fraction_digits;  # Beyond quad accuracy
  
     $exponent++;
     my ($integer,$fraction) = (0,$magnitude);
     if(0 < $exponent) {
         if($exponent <= length($magnitude)) {
             $integer = substr($magnitude,0,$exponent);
             $fraction = substr($magnitude,$exponent);
         }
         else {
             $integer .= $magnitude . '0'x ($exponent-length($magnitude));
             $fraction = 0;
         }
     }
     elsif($exponent < 0) {
         $exponent = -$exponent;

         unless( $exponent <= ($decimal_fraction_digits/2) ) {
             $event = "The exponent, $exponent, is out of range for $magnitude.\n" .
                          "\tData::SecsPack::ifloat2binary-2\n";
             goto EVENT;
         }
                 ;
         $integer = 0;
         $fraction = ('0' x $exponent) . $fraction;
     }
     $fraction .= '0' x ($decimal_fraction_digits - length($fraction)) if $fraction;
        
     ########
     # Get the bytes of the integer.
     #
     my @integer_bytes = int2bytes($integer); # MSB first

     #######
     # Determine the bytes for the fraction
     #
     my @fraction_bytes = ();
     if($fraction) {
         my $max_bytes = $options->{binary_fraction_bytes};
         my $base_divider = '1' . '0' x $decimal_fraction_digits;
         $fraction =~ s/^\s*\.?//;  # strip any leadhing dots spaces
         $max_bytes = 8 unless $max_bytes;

         my ($i,$quo,$rem);
         $fraction = Math::BigInt->new($fraction);
         for($i=0; $i < $max_bytes; $i++) {
             $fraction->blsft(8);
             ($quo,$fraction) = $fraction->bdiv($base_divider);
             push @fraction_bytes,$quo->bstr();
             last if ($fraction->is_zero());
         } 
     }

     #######
     # Shift the binary decimal point so that the magnitude, $integer most
     # significant bit is 1
     # 
     while(@integer_bytes && $integer_bytes[0] == 0) {
         shift @integer_bytes;
     }
     while(@fraction_bytes && $fraction_bytes[-1] == 0) {
          pop @fraction_bytes;
     }

     #######
     # Move the binary decimal point so that the decimal point is just after
     # the first byte and the first byte has bits.
     #
     my $binary_exponent = 0;
     if(@integer_bytes) {
         $binary_exponent = (scalar @integer_bytes - 1) << 3;   
     }

     ########
     # Left Shift
     # 
     elsif(@fraction_bytes) {
         while( $fraction_bytes[0] == 0 ) {
             shift @fraction_bytes;
             $binary_exponent -= 8;
         }
     }

     #######
     # Shift right until the last bit of the first byte is 1
     # and all the leading bits are 0. The decimal point is
     # between the first and 2nd bytes.
     #
     my $shift = 0;
     if(@integer_bytes) {
         my $test_byte = $integer_bytes[0];
         while($test_byte && $test_byte ne 1) {
             $test_byte = $test_byte >> 1;
             $test_byte &= 0x7F; # case the shift is arith
             $shift++;
         }
         $binary_exponent += $shift;
          
     }
     else {
         my $test_byte = $fraction_bytes[0];
         while($test_byte && $test_byte ne 1) {
             $test_byte = $test_byte >> 1;
             $test_byte &= 0x7F; # case the shift is arith
             $shift++;
         }
         $binary_exponent += ($shift - 8);
          
     }

     #######
     # Add enough 0 to ensure do not drop bits into the bit bucket and enough
     # space for a extra or two right shifts.
     #
     my $binary_magnitude = bytes2int(@integer_bytes,@fraction_bytes,'0','0');
     $binary_magnitude = Math::BigInt->new($binary_magnitude)->brsft($shift) if $shift;
     $binary_magnitude =~ s/^\+//; # drop BigInt + sign
     return ($sign . $binary_magnitude, $binary_exponent);


EVENT:
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    return (undef,$event);
}



###########
# Transform integer to bytes
#
sub int2bytes
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $integer = shift;
     return () unless $integer;
   
     #######
     # Break the integer up into byes
     # 
     my @integer_bytes = ();
    
     if ($integer == 0) {
         push @integer_bytes, 0;
     }
     elsif ($integer == -1) {
         push @integer_bytes, -1;
     }
     else { 
         my $byte;
         $integer = Math::BigInt->new($integer);
         while($integer->is_zero()  == 0  && $integer->bcmp(-1) != 0) {
             $byte = $integer->copy();   
             push @integer_bytes,$byte->band(0xFF)->bstr();
             $integer->brsft(8); 
         }
     }
     reverse @integer_bytes; # MSB first
}


#####
#
#
sub pack_float
{
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless ref($default_options);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::pack_float-1\n";
         goto EVENT;
     }

     my $format = shift;
     my $options = ref($_[-1]) && ref($_[-1]) ne 'ARRAY' ? $default_options->override(pop @_) : $default_options;

     unless($format eq 'F4' || $format eq 'F8' || $format eq 'F') {
         $event = "Format $format is not a floating point format.\n\tData::SecsPack::pack_float-2\n";
         goto EVENT;
     }

     ######
     # Do not use $_ off a @_ array. If do, then modify
     # the input symbol in the calling subroutine name 
     # space. Very hard to predict the outcome.
     #
     my @string_float = @_;
     my @floats = ();
     my $bytes_per_cell = '4';
     my ($sign,$magnitude,$exponent_sign,$exponent);
     foreach (@string_float) {

         ($magnitude, $exponent) = float2binary( @$_, $options );
         return ($magnitude, $exponent) unless defined $magnitude; # error trap      

         if($format eq 'F') {

             #####
             # magnitude is decimal digits
             #
             if($exponent < -128 || $exponent > 128 || length($magnitude) > 10) {
                 $bytes_per_cell = 8;
             }

         }

         push @floats,[$magnitude,$exponent];

    }

    ######
    # Pack the floating points.
    #
    $format = $format . $bytes_per_cell if ($format eq 'F');
    my (@float_bytes);
    my $floats = '';
    my $exponent_excess;
    foreach  (@floats) {

         ($magnitude,$exponent) = @$_;
         $exponent = 0 unless $exponent;
         $exponent =~ s/^\+//;
         $sign = $magnitude =~ s/^([+-])// ? $1 : '';

         ########
         # Pack the sign, magitude(integer) and exponent
         # (Actually the machine dependent part. So here what can
         # do is something like File::Spec to support the different
         # platforms.)
         # 
         # Will be replacing the leading 1 of the magnitude with the sign
         # bit. Thus shift right one to get the magnitude to line up properly
         # for the F4, F8 IEEE format.
         #

         #########
         # Pack the exponent
         #
         if($format eq 'F4') {
             
             #######
             # There are sign bit and eight exp bits in front of
             # of the $magnitude. The first byte contains only a
             # 1 that need to be drop. Shifting one to the right
             # lines up the magitude, not counting the leading one
             # correctly
             #
             $magnitude = Math::BigInt->new($magnitude)->brsft(1)->bstr();
             @float_bytes = int2bytes($magnitude);
             unshift @float_bytes,0;

             #######
             # Using only four bytes
             # 
             while( @float_bytes < 4) {
                 push @float_bytes,0;
             }             

             ######
             # Zero out the leading sign and exponent fields.
             #  
             $float_bytes[0] &= 0x0;
             $float_bytes[1] &= 0x7F;

             ######
             # Or in the sign bit
             #                  
             $float_bytes[0] |= 0x80 if ($sign eq '-');

             ######
             # Or in the exponent
             # 
             $exponent_excess = 127 + $exponent;
             if(255 < $exponent_excess) {  # overflow
                 $event = "F4 exponent overflow\n\tData::SecsPack::pack_float-3\n";
                 goto EVENT;
             }
             if($exponent_excess < 0) {  # underflow
                 $event = "F4 exponent underflow\n\tData::SecsPack::pack_float-4\n";
                 goto EVENT;
             }
             if($magnitude == 0) {
                 $float_bytes[1] = 0;
                 $float_bytes[2] = 0;
                 $float_bytes[3] = 0;
             }
             else {
                 $float_bytes[1] |= ($exponent_excess & 0x01) << 7;
                 $float_bytes[0] |= ($exponent_excess >>1) & 0x7F;
             }
             $floats .= pack 'C4',@float_bytes;
         }             

         #######
         # F8 exponent is 11 bits 2^11 = 2048
         #
         else {

             $magnitude = Math::BigInt->new($magnitude)->brsft(4)->bstr();
             @float_bytes = int2bytes($magnitude);
             unshift @float_bytes,0;

             while( @float_bytes < 8) {
                 push @float_bytes,0;
             }             

             ######
             # Zero out the leading sign and exponent fields.
             #  
             $float_bytes[0] &= 0x00;
             $float_bytes[1] &= 0x0F;

             ######
             # Or in the sign bit
             #                  
             $float_bytes[0] |= 0x80 if ($sign eq '-');

             $exponent_excess = 1023 + $exponent;
             if(2048 < $exponent_excess) {  # overflow
                 $event = "F8 exponent overflow\n\tData::SecsPack::pack_float-5\n";
                 goto EVENT;
             }
             if($exponent_excess < 0) {  # underflow
                 $event = "F8 exponent underflow\n\tData::SecsPack::pack_float-6\n";
                 goto EVENT;
             }
             if($magnitude == 0) {
                 $float_bytes[1] = 0;
                 $float_bytes[2] = 0;
                 $float_bytes[3] = 0;
                 $float_bytes[4] = 0;
                 $float_bytes[5] = 0;
                 $float_bytes[6] = 0;
                 $float_bytes[7] = 0;
             }
             else {
                 $float_bytes[1] |= ($exponent_excess & 0x0F) << 4;
                 $float_bytes[0] |= ($exponent_excess >> 4) & 0x7F;
             }
             $floats .= pack 'C8',@float_bytes;
         }
     }
 
     return ($format, $floats);

EVENT:
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    (undef,$event);
}




#####
# Pack a list of integers, twos complement, MSB first order.
# Assumming the native computer does two's arith.
#
sub pack_int
{
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless ref($default_options);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::pack_int-1\n";
     }
     my $options = ref($_[-1]) ? $default_options->override(pop @_ ) : $default_options ;

     my $format = shift;
     my $format_length;
     ($format,$format_length) = $format =~ /([SUIT])(\d+)?/;
     unless($format && !($format eq 'T' && $format_length)) {
         $event = "Format $format is not an integer format.\ntData::SecsPack::pack_int-2\n";
     }

     ######
     # Do not use $_ off a @_ array. If do, then modify
     # the input symbol in the calling subroutine name 
     # space. Very hard to predict the outcome.
     #
     my @string_integer = @_;

     my @integers=();
     my ($max_bytes, $pos_range) = (0,0);
     my @bytes;
     my ($integer,$num_bytes);
     my $str_format = 'U';
     use integer;
     foreach (@string_integer) {
         $str_format = 'S' if Math::BigInt->new($_)->bcmp(0) < 0;
         if ($str_format eq 'S' && $format =~ /^U/) {
             $event = "Signed number encountered when unsigned specified.\ntData::SecsPack::pack_int-3\n";
         }
         if (Math::BigInt->new($_)->bcmp(0) == 0) {
             push @integers, [0];
             next;
         }
         if (Math::BigInt->new($_)->bcmp(-1) == 0) {
             push @integers, [0xFF];
             next;
         }
         @bytes = int2bytes($_);

         #######
         # Positive number in negative number range
         #
         if($str_format eq 'S' && Math::BigInt->new($_)->bcmp($pos_range) > 0) {
              my $i = $max_bytes;
              while($i--) {
                  unshift @bytes, '0';
              }           
         }
         $num_bytes = scalar(@bytes);
         if($max_bytes < $num_bytes) {
             $max_bytes = $num_bytes;
             if($str_format eq 'S') {
                 $pos_range = Math::BigInt->new(1)->blsft(($max_bytes << 3) - 1);
                 $pos_range = $pos_range->bdec()->bstr();
             }
         }
         push @integers, [@bytes];
     }
     unless(@integers) {
         $event = "No integers in the input.\ntData::SecsPack::pack_int-4\n";
     }

     ####
     # Round up the max length to the nearest power of 2 boundary.
     #
     if( $max_bytes  <= 1) {
         $max_bytes  = 1; 
     }
     elsif( $max_bytes  <= 2) {
         $max_bytes  = 2; 
     }
     elsif( $max_bytes  <= 4) {
         $max_bytes  = 4; 
     }
     elsif( $max_bytes  <= 8) {
         $max_bytes  = 8; 
     }
     else {
         return ("Integer or float out of SECS-II range.\n",undef);
     }
     if ($format_length) {
         if( $format_length < $max_bytes ) {
                 $event = "Integer bigger than format length of $max_bytes bytes.\ntData::SecsPack::pack_int-5\n";
         }
         $max_bytes  = $format_length;
     }

     $format = $str_format if $format eq 'I';
     my $signed = $format eq 'S' ? 1 : 0;
     my ($i, $fill, $length, $integers);
     foreach (@integers) {
         @bytes = @{$_};
         $length = $max_bytes - scalar @bytes;
         if($length) {
             $fill =  $signed && $bytes[0] >= 128 ? 0xFF : 0;
             for($i=0; $i< $length; $i++) {
                 unshift @bytes,$fill;
             }
         }
         $integers .= pack ("C$max_bytes",  @bytes);
     }
     $format .= $max_bytes;
     no integer;

     return ($format, $integers);

EVENT:
   if($options->{warnings} ) {
       warn($event);
   }
   elsif($options->{die}) {
       die($event);
   }
   (undef,$event);
   
}


#####
#  Pack a list of integers, twos complement, MSB first order.
#  Assumming the native computer does two's arith.
#
sub pack_num
{
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless ref($default_options);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::float2binary-1\n";
         goto EVENT;
     }
     my $options = ref($_[-1]) ? $default_options->override(pop @_ ) : $default_options ;

     my $format = shift;
     ($format, my $format_length) = $format =~ /([FSUIT])(\d)?/;
     unless($format) {
         my $event = "Format $format is not an integer or floating point format.\ntData::SecsPack::pack_num-2\n";
         goto EVENT;
     }

     my ($str,@nums,$nums);
     if($format =~ /^F/) {
         ($str, @nums) = str2float(@nums, $str);
         $nums = pack_float($format, @nums, $options);  
     }
     else {
         ($str, @nums) = str2int(@_);
         my $format_hint = $format;
         ($format, $nums) = pack_int($format, @nums, $options) if @nums;

         if($format_hint eq 'I') {
             if((!$options->{nomix} && @$str != 0 && ${$str}[0] =~ /^\s*-?\s*\d+[\.E]/) ||
                     0 == @nums) {
                 my ($float_str, @float_nums) = str2float(@nums, @$str);
                 if(@float_nums) {
                     my ($float_format,$float_nums) = pack_float('F', @float_nums, $options);
                     if( $float_format && $float_format =~ /^F/ &&  $float_nums) {
                         $format = $float_format;
                         $nums = $float_nums;
                         $str = $float_str;
                     }
                 }
                 else {
                     $event = "No numbers in the input.\ntData::SecsPack::pack_num-3\n";
                     goto EVENT;
                 }
             }
         } 
     }
     return ($format,$nums,@$str);

EVENT:
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    (undef,$event);

}



######
# Covert a string to floats.
#
sub str2float
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     return '',() unless @_;

     $default_options = Data::SecsPack->new() unless ref($default_options);
     my $options = $default_options->override(pop @_) if ref($_[-1]);

     #########
     # Drop leading empty strings
     #
     my @strs = @_;
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = () unless(@strs); # do not shift @strs out of existance

     my @floats = ();
     my $early_exit unless wantarray;
     my ($sign,$integer,$fraction,$exponent);
     foreach $_ (@strs) {
         while ( length($_) ) {

             ($sign, $integer,$fraction,$exponent) = ('','','',0);

             #######
             # Parse the integer part
             #
             if($_  =~ s/^\s*(-?)\s*(0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;\n]?//) {
                 $integer = 0+oct($1 . $2);
                 $sign = $1 if $integer =~ s/^\s*-//;
             }
             elsif ($_ =~ s/^\s*(-?)\s*([0-9]+)\s*[,;\n]?//) {
                 ($sign,$integer) = ($1,$2);
             }

             ######
             # Parse the decimal part
             # 
             $fraction = $1 if $_ =~ s/^\.([0-9]+)\s*[,;\n]?// ;

             ######
             # Parse the exponent part
             $exponent = $1 . $2 if $_ =~ s/^E(-?)([0-9]+)\s*[,;\n]?//;

             goto LAST unless $integer || $fraction || $exponent;


             if($options->{ascii_float} ) {
                 $integer .= '.' . $fraction if( $fraction);
                 $integer .= 'E' . $exponent if( $exponent);
                 push @floats,$sign . $integer;  
             }
             else {
                 ############
                 # Normalize decimal float so that there is only one digit to the
                 # left of the decimal point.
                 # 
                 while($integer  && substr($integer,0,1) == 0) {
                    $integer = substr($integer,1);
                 }
                 if( $integer ) {
                     $exponent += length($integer) - 1;
                 }
                 else {
                     while($fraction && substr($fraction,0,1) == 0) {
                         $fraction = substr($fraction,1);
                         $exponent--;
                     }
                     $exponent--;
                 }
                 $integer .= $fraction;
                 while($integer  && substr($integer,0,1) == 0) {
                    $integer = substr($integer,1);
                 }
                 $integer = 0 unless $integer;
                 push @floats,[$sign . $integer,  $exponent];
             }
             goto LAST if $early_exit;
         }
         last if $early_exit;
     }

LAST:
     #########
     # Drop leading empty strings
     #
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = () unless(@strs); # do not shift @strs out of existance

     return (\@strs, @floats) unless $early_exit;
     ($integer,$fraction,$exponent) = @{$floats[0]};
     "${integer}${fraction}E${exponent}"
}


######
# Convert number (oct, bin, hex, decimal) to decimal
#
sub str2int
{
     shift  if UNIVERSAL::isa($_[0],__PACKAGE__);
     unless( wantarray ) {
         return undef unless(defined($_[0]));
         my $str = $_[0];
         return 0+oct($1) if($str =~ /^\s*(-?\s*0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;\n]?$/);
         return 0+$1 if ($str =~ /^\s*(-?\s*[0-9]+)\s*[,;:\n]?$/ );
         return undef;
     }

     #######
     # Pick up input strings
     #
     return [],() unless @_;

     $default_options = Data::SecsPack->new() unless ref($default_options);
     my $options = $default_options->override(pop @_) if ref($_[-1]);
     my @strs = @_;

     #########
     # Drop leading empty strings
     #
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = () unless(@strs); # do not shift @strs out of existance

     my ($int,$num);
     my @integers = ();
     foreach $_ (@strs) {
         while ( length($_) ) {
             if($_  =~ s/^\s*(-?)\s*(0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;\n]?//) {
                 $int = $1 . $2;
                 $num = 0+oct($int);
             }
             elsif ($_ =~ s/^\s*(-?)\s*([0-9]+)\s*[,;\n]?// ) {
                 $int = $1 . $2;
                 $num = 0+$int;
 
             }
             else {
                 goto LAST;
             }

             #######
             # If the integer is so large that Perl converted it to a float,
             # repair the str so that the large integer may be dealt as a string
             # or converted to a float. The using routine may be using Math::BigInt
             # instead of using the native Perl floats and this automatic conversion
             # would cause major damage.
             # 
             if($num =~ /\s*[\.E]\d+/) {
                 $_ = $int;
                 goto LAST;
             }
 
             #######
             # If there is a string float instead of an int  repair the str to 
             # perserve the float. The using routine may decide to use str2float
             # to parse out the float.
             # 
             elsif($_ =~ /^\s*[\.E]\d+/) {
                 $_ = $int . $_;
                 goto LAST;
             }
             push @integers,$num;
         }
     }

LAST:
     #########
     # Drop leading empty strings
     #
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = ('') unless(@strs); # do not shift @strs out of existance

     (\@strs, @integers);
}


#####
#  Unpack a list of floats, IEEC 754-1985, sign bit first.
#
sub unpack_float
{
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::float2binary-1\n";
         goto EVENT;
     }

     my $format_in = shift;
     unless($format_in eq 'F4' || $format_in eq 'F8') {
         $event = "Format $format_in not supported.\n\tData::SecsPack::unpack_float-2\n";
         goto EVENT;
     }
     my ($format, $format_length) = $format_in =~ /(F)(\d)?/;
     my (@bytes,$float);
     my @floats = ();
     my ($binary_magnitude,$sign,$binary_exponent,$decimal_magnitude,$decimal_exponent,$binary_divider);
     my $secsii_floats = shift @_;

     $default_options = Data::SecsPack->new() unless ref($default_options);
     my $options = $default_options->override(@_);

     while ($secsii_floats) {
         @bytes = unpack "C$format_length",$secsii_floats;
         $secsii_floats = substr($secsii_floats,$format_length);
         $sign = $bytes[0] & 0x80 ? '-' : '';
         $bytes[0] &= 0x7F;
         if($format_length == 4) {
             $binary_exponent = (bytes2int($bytes[0],$bytes[1]) >> 7) - 127;
             shift @bytes;
             $bytes[0] &= 0x7F;
             $binary_magnitude = bytes2int(@bytes);
             $binary_magnitude <<= 1;
             $binary_divider =  2 ** 24; # decode into 3 bytes, not 23 bits

         }
         else {
             $binary_exponent = (bytes2int($bytes[0],$bytes[1]) >> 4) - 1023;
             shift @bytes;
             $bytes[0] &= 0x0F;
             $binary_magnitude = bytes2int(@bytes);
             $binary_magnitude = Math::BigInt->new($binary_magnitude)->blsft(4);
             $binary_divider = '72057594037927036';  # 2 ** 56  -  bytes integer too big for Perl
         }

         if($binary_magnitude) {
             $decimal_magnitude = $binary_magnitude . '0'x20; # twenty digit decimal results
             $decimal_magnitude = Math::BigInt->new(bytes2int($decimal_magnitude))->bdiv($binary_divider)->bstr();
         }
         else {
             $decimal_magnitude = 0;
         }

         #########
         # Let Perl do the arith, doing an automatic convert to float if needed.
         # The accuracy suffers again if Perl must convert to float to get the answer.
         #  
         $float = Math::BigFloat->new(2,20)->bpow($binary_exponent)->bmul("${sign}1.$decimal_magnitude")->bsstr();
         ($sign,$decimal_magnitude,$decimal_exponent) = $float =~ /([-+]?)(\d+)E([-+]?\d+)/i;
         $sign = '' unless $sign;
         $decimal_exponent += length($decimal_magnitude) - 1;
         $float = $sign . substr($decimal_magnitude,0,1) . '.' . substr($decimal_magnitude,1) . 'E' . $decimal_exponent;
         push @floats, $float;

     }
     no integer;
     return \@floats;

EVENT:
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    $event;
}


#####
#  Unpack a list of integers, twos complement, MSB first order.
#  Assumming the native computer does two's arith.
#
sub unpack_int
{
     my $event;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     unless(defined($_[0])) {
         $event = "No inputs\ntData::SecsPack::float2binary-1\n";
         goto EVENT;
     }

     my $format_in = shift;
     unless($format_in =~ /(T|U1|U2|U4|U8|S1|S2|S4|S8)/) {
         $event = "Format $format_in not supported.\n\tData::SecsPack::unpack_int-2\n";
         goto EVENT;
     }
     my ($format, $format_length) = $format_in =~ /([TSU])(\d)?/;
     $format_length = 1 if $format eq 'T';
     my $signed = $format =~ /S/ ? 1 : 0;
     my ($twos_complement, @bytes, $int);
     my @integers = ();
     my $secsii_ints = shift @_;

     $default_options = Data::SecsPack->new() unless ref($default_options);
     my $options = $default_options->override(@_);

     if($signed) {
         $twos_complement = Math::BigInt->new(1)->blsft($format_length << 3);
     }
     while ($secsii_ints) {
         @bytes = unpack "C$format_length",$secsii_ints;
         $secsii_ints = substr($secsii_ints,$format_length);
         $int = bytes2int(@bytes);
         if($signed) {
             if(128 <= $bytes[0]) {       
                 $int = Math::BigInt->new($int)->bsub($twos_complement)->bstr();
             }
         }         
         push @integers, $int;
     }
     return \@integers;

EVENT:
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    return ($event);

}


#####
#  Unpack a list of numbers, twos complement, MSB first order.
#  Assumming the native computer does two's arith.
#
sub unpack_num
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::SecsPack->new() unless ref($default_options);
     my $options = ref($_[-1]) ? $default_options->override(pop @_) : $default_options;
     return unpack_float(@_, $options) if($_[0] =~ /^F/);
     unpack_int(@_, $options);
}


1

__END__


=head1 NAME

Data::SecsPack - pack and unpack numbers in accordance with SEMI E5-94

=head1 SYNOPSIS

 #####
 # Subroutine interface
 #  
 use Data::SecsPack qw(bytes2int config float2binary 
                    ifloat2binary int2bytes   
                    pack_float pack_int pack_num  
                    str2float str2int 
                    unpack_float unpack_int unpack_num);

 $big_integer = bytes2int( @bytes );

 $old_value = config( $option );
 $old_value = config( $option => $new_value);

 ($binary_magnitude, $binary_exponent) = float2binary($magnitude, $exponent, @options); 
 
 ($binary_magnitude, $binary_exponent) = ifloat2binary($imagnitude, $iexponent, @options);

 @bytes = int2bytes( $big_integer );

 ($format, $floats) = pack_float($format, @string_floats, [@options]);

 ($format, $integers) = pack_int($format, @string_integers, [@options]);

 ($format, $numbers, @string) = pack_num($format, @strings, [@options]);

 $float = str2float($string, [@options]);
 (\@strings, @floats) = str2float(@strings, [@options]);

 $integer = str2int($string, [@options]);
 (\@strings, @integers) = str2int(@strings, [@options]);

 \@ingegers = unpack_int($format, $integer_string, @options);

 \@floats   = unpack_float($format, $float_string, @options); 

 \@numbers  = unpack_num($format, $number_string), @options; 

 #####
 # Class, Object interface
 #
 # For class interface, use Data::SecsPack instead of $self
 #
 use Data::SecsPack;

 $secspack = 'Data::SecsPack';  # uses built-in config object

 $secspack = new Data::SecsPack(@options);

 $big_integer = bytes2int( @bytes );

 ($binary_magnitude, $binary_exponent) = $secspack->float2binary($magnitude, $exponent, @options); 

 ($binary_magnitude, $binary_exponent) = $secspack->ifloat2binary($imagnitude, $iexponent, @options);

 @bytes = $secspack->int2bytes( $big_integer );

 ($format, $floats) = $secspack->pack_float($format, @string_integers, [@options]);

 ($format, $integers) = $secspack->pack_int($format, @string_integers, [@options]);
 
 ($format, $numbers, @strings) = $secspack->pack_num($format, @strings, [@options]);

 $integer = $secspack->str2int($string, [@options])
 (\@strings, @integers) = $secspack->str2int(@strings, [@options]);

 $float = $secspack->str2float($string, [@options]);
 (\@strings, @floats) = $secspack->str2float(@strings, [@options]);

 \@ingegers = $secspack->unpack_int($format, $integer_string, @options); 

 \@floats   = $secspack->unpack_float($format, $float_string, @options); 

 \@numbers  = $secspack->unpack_num($format, $number_string, @options); 
 
Generally, if a subroutine will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options],
or hash reference, C<\%options>, C<{@options}.
If a subroutine will process an array reference, C<\@options>, C<[@options]>,
that subroutine will also process a hash reference, C<\%options>, C<{@options}>.
See the description for a subroutine for details and exceptions.

=head1 DESCRIPTION

The subroutines in the C<Data::SecsPack> module packs and unpacks
numbers in accordance with SEMI E5-94. The E5-94 establishes the
standard for communication between the equipment used to fabricate
semiconductors and the host computer that controls the fabrication.
The equipment in a semiconductor factory (fab) or any other fab
contains every conceivable known microprocessor and operating system
known to man. And there are a lot of specialize real-time embedded 
processors and speciallize real-time embedded operating systems
in addition to the those in the PC world.

The communcication between host and equipment used packed
nested list data structures that include arrays of characters,
integers and floats. The standard has been in place and widely
used in China, Germany, Korea, Japan, France, Italy and
the most remote corners on this planent for decades.
The basic data structure and packed data formats have not
changed for decades. 

This stands in direct contradiction to the common conceptions
of many in the Perl community and most other communities.
The following quote is taken from
page 761, I<Programming Perl> third edition, discussing the 
C<pack> subroutine:

"Floating-point numbers are in the native machine format only.
Because of the variety of floating format and lack of a standard 
"network" represenation, no facility for interchange has been
made. This means that packed floating-point data written
on one machine may not be readable on another. That is
a problem even when both machines use IEEE floating-point arithmetic, 
because the endian-ness of memory representation is not part
of the IEEE spec."

There are a lot of things that go over the net that have
industry or military standards but no RFCs.
So unless you dig them out, you will never know they exist.
While RFC and military standards may be freely copyied,
industry standards are usually copyrighted.
This means if you want to read the standard,
you have to pay whatever the market bears.
ISO standards, SEMI stardards, American National Standards,
IEEE standards beside being boring are expensive.
In other words, you do not see them flying out the door at
the local Barnes and Nobles. In fact, you will not even
find them inside the door.

It very easy to run these non RFC standard protocols over the net.
Out of 64,000 ports, pick a  port of opportunity 
(hopefully not one of those low RFC preassigned ports)
and configure the equipment
and host to the same IP and port.
Many times the software will allow a remote console that
is watch only. 
The watch console may even be a web server on port 80.
If there is a remote soft console, you can
call up or e-mail the equipment manufacturer's engineer in
say Glouster, MA, USA and tell him the IP and port so he can watch
his manchine mangle a cassette of wafers with a potential
retail value of half million dollars.

SEMI E5-94 and their precessors do standardize the endian-ness of
floating point, the packing of nested data, used in many programming
languages, and much, much more. 
The endian-ness of SEMI E5-94 is the first MSB byte, 
floats sign bit first. 
Maybe this is because it makes it easy to spot numbers in a packed data
structure.

The nested data has many performance
advantages over the common SQL culture of viewing and representing
data as tables. The automated fabs of the world make use of SEMI E5-94 nested 
data not only for real-time communication (TCP/IP RS-2332 etc) 
between machines but also for snail-time processing as such things as logs
and performance data.

Does this standard communications protocol ensure that
everything goes smoothly without any glitches with this wild
mixture of hardware and software talking to each other
in real time?
Of course not. Bytes get reverse. Data gets jumbled from
point A to point B. Machine time to test software is non-existance.
Big ticket, multi-million dollar fab equipment has to
work to earn its keep. And, then there is the everyday
business of suiting up, with humblizing hair nets,
going through air and other
showers with your favorite or not so favorite co-worker
just to get into the clean room.
And make sure not to do anything that will scatch a wafer
with a lot of Intel Pentiums on them.
It is totally amazing that the product does
get out the door.

=head2 SECSII Format

The L<Data::SecsPack|Data::SecsPack> suroutines 
packs and unpacks numbers in accordance with 
L<SEMI|http://http://www.semiconductor-intl.org> E5-94, 
Semiconductor Equipment Communications Standard 2 (SECS-II),
avaiable from
 
 Semiconductor Equipment and Materials International
 805 East Middlefield Road,
 Mountain View, CA 94043-4080 USA
 (415) 964-5111
 Easylink: 62819945
 http://www.semiconductor-intl.org
 http://www.reed-electronics.com/semiconductor/
 
The format of SEMI E5-94 numbers are established
by below Table 1. 

               Table 1 Item Format Codes

 unpacked   binary  octal  hex   description
 ---------------------------------------------------------
 T          001001   11    0x24  Boolean
 S8         011000   30    0x60  8-byte integer (signed)
 S1         011001   31    0x62  1-byte integer (signed)
 S2         011010   32    0x64  2-byte integer (signed)
 S4         011100   34    0x70  4-byte integer (signed)
 F8         100000   40    0x80  8-byte floating
 F4         100100   44    0x90  4-byte floating
 U8         101000   50    0xA0  8-byte integer (unsigned)
 U1         101001   51    0xA4  1-byte integer (unsigned)
 U2         101010   52    0xA8  2-byte integer (unsigned)
 U4         101100   54    0xB0  4-byte integer (unsigned)

Table 1 complies to SEMI E5-94 Table 1, p.94, with an unpack text 
symbol and hex columns added. The hex column is the upper 
Most Significant Bits (MSB) 6 bits
of the format code in the SEMI E5-94 item header (IH)

In accordance with SEMI E5-94 6.2.2,

=over 4

=item 1

the Most Significat Byte
(MSB) of numbers for formats S2, S4, S8, U2, U4, U8 is
sent first

=item 2

the signed bit for formats F4 and F8 are
sent first. 

=item 3

Signed integer formats S1, S2, S4, S8 are two's complement

=back

The memory layout for Data::SecsPack is the SEMI E5-94
"byte sent first" has the lowest memory address.

=head2 IEEE 754-1985 Standard

The SEMI E5-94 F4 format complies to IEEE 754-1985 float and
the F8 format complies to IEEE 754-1985 double.
The IEEE 754-1985 standard is available from:

 IEEE Service Center
 445 Hoe Lane,
 Piscataway, NJ 08854
  
The SEMI E5-94 F4, IEEE 754-1985 float, is 32 bits
with the bits assigned follows:   
 
 S EEE EEEE EMMM MMMM MMMM MMMM MMMM MMMM

where  S = sign bit, E = 8 exponent bits  M = 23 mantissa bits

The format of the float S, E, and M are as follows:

=over 4

=item Sign of the number

The sign is one bit, 0 for positive and 1 for negative.

=item  exponent

The exponent is 8 bits and may be positive or negative.   
The IEEE 754 exponent uses excess-127 format.
The excess-127 format adds 127 to the exponent.
The exponent is re-created by subtracting 127
from the exponent.

=item Magnitude of the number

The magnitude or mantissa is a 23 bit unsigned binary number
where the radix is adjusted to make the magnitude fall between
1 and 2. The magnitude is stored ignoring the 1 and
filling in the trailing bits until there are
23 of them.

=back

The SEMI E5-94 F4, IEEE 754-1985 double, is 64 bits
with S,E,M as follows: S = sign bit, E = 11 exponent bits
M = 52 mantissa bits

The format of the float S, E, and M are as follows:

=over 4

=item Sign of the number

The sign is one bit, 0 for positive and 1 for negative.

=item  exponent

The exponent is 8 bits and may be positive or negative.   
The IEEE 754 exponent uses excess-1027 format.
The excess-1027 format adds 1027 to the exponent.
The exponent is re-created by subtracting 1027
from the exponent.

=item Magnitude of the number

The magnitude or mantissa is a 52 bit unsigned binary number
where the radix is adjusted to make the magnitude fall between
1 and 2. The magnitude is stored ignoring the 1 and
filling in the trailing bits until there are
52 of them.


=back

For example, to find the IEEE 754-1985 float of -10.5

=over 4

=item *

Convert -10.5 decimal to -1010.1 binary

=item *

Move the radix so magitude is between 1 and 2,
-1010. binary to -1.0101 * 2^ +3

=item *

IEEE 754-1985 sign is 1

=item *

The magnitude dropping the one and filling
in with 23 bits is

 01010000000000000000000

=item *

Add 127 to the exponent of 3 to get

 130 decimal converted to 8 bit binary 

 10000010

=item *

Combining into IEEE 754-1985 format: 

 11000001001010000000000000000000

 1100 0001 0010 1000 0000 0000 0000 0000

 C128 0000 hex

=back

=head1 SUBROUTINES

=head2 bytes2int

 $big_integer = bytes2int( @bytes );

The C<bytes2int> subroutine counvers a C<@bytes> binary number with the
Most Significant Byte (MSB) $byte[0] to a decimal string number C<$big_integer>
using the C<Data::BigInt> program module. As such, the only limitations
on the number of binary bytes and decimal digits is the resources of the 
computer.

=head2 config

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

When Perl loads 
the C<Data::SecsPack> program module,
Perl creates the C<Data::SecsPack>
subroutine C<Data::SecsPack> object
C<$Data::SecsPack::subroutine_secs>
using the C<new> method.
Using the C<config> subroutine writes and reads
the C<$Data::SecsPack::subroutine_secs> object.

Using the C<config> as a class method,

 Data::SecsPack->config( @_ )

also writes and reads the 
C<$Data::SecsPack::subroutine_secs> object.

Using the C<config> as an object method
writes and reads that object.

The C<Data:SecsPack> subroutines used as methods
for that object will
use the object underlying data for their
startup (default options) instead of the
C<$Data::SecsPack::subroutine_secs> object.
It goes without saying that that object
should have been created using one of
the following:

 $object = $class->Data::SecsPack::new(@_)
 $object = Data::SecsPack::new(@_)
 $object = new Data::SecsPack(@_)

The underlying object data for the C<Data::SecsPack>
options defaults is the class C<Data::Startup> object
C<$Data::SecsPack::default_options>.
For object oriented
conservative purist, the C<config> subroutine is
the accessor function for the underlying object
hash.

Since the data are all options whose names and
usage is frozen as part of the C<Data::SecsPack>
interface, the more liberal minded, may avoid the
C<config> accessor function layer, and access the
object data directly by a statement such as

 $Data::SecsPack::default_options->{version};

The options are as follows:

 used by                                     values default  
 subroutine    option                        value 1st
 ----------------------------------------------------------
               big_float_version              \d+\.\d+
               big_int_version                \d+\.\d+
               version                        \d+\.\d+

               warnings                        0 1
               die                             0 1

 bytes2int 

 float2binary  decimal_integer_digits          20 \d+
               extra_decimal_fraction_digits    5 \d+
               decimal_fraction_digits       
               binary_fraction_bytes

 ifloat2binary decimal_fraction_digits         25 \d+
               binary_fraction_bytes           10 \d+

 int2bytes
   
 pack_float    decimal_integer_digits          
               extra_decimal_fraction_digits   
               decimal_fraction_digits       
               binary_fraction_bytes

 pack_int 

 pack_num      nomix                            0 1
               decimal_integer_digits          
               extra_decimal_fraction_digits   
               decimal_fraction_digits       
               binary_fraction_bytes

 str2float     ascii_float                      0 1
 str2int 
 unpack_float
 unpack_int
 unpack_num

For options with a default value and subroutine, see the subroutine for
a description of the option.  Each subroutine that
uses an option or uses a subroutine that
uses an option has an option input.
The option input overrides the startup option from
the <Data::SecsPack> object.

The description of the options without a subroutine are as follows:

 option              description
 --------------------------------------------------------------
 big_float_version   Math::BigFloat version
 big_int_version     Math::BigInt version
 version             Data::SecsPack version

 warnings            issue a warning on subroutine events
 die                 die on subroutine events

They really versions should not be changed unless the intend is to provided
fraudulent versions.

=head2 float2binary

 ($binary_magnitude, $binary_exponent) = float2binary($magnitude, $exponent); 
 ($binary_magnitude, $binary_exponent) = float2binary($magnitude, $exponent, @options); 
 ($binary_magnitude, $binary_exponent) = float2binary($magnitude, $exponent, [@options]); 
 ($binary_magnitude, $binary_exponent) = float2binary($magnitude, $exponent, {@options}); 

The C<ifloat2binary> subroutine converts a decimal float with a base ten
C<$magnitude> and C<$exponent> to a binary float
with a base two C<$binary_magnitude> and C<$binary_exponent>.

The C<ifloat2binary> assumes that the decimal point is set by
C<iexponent> so that there is one decimal integer digit in C<imagnitude>
The C<ifloat2binary> produces a C<$binary_exponent> so that the first
byte of C<$binary_magnitude> is 1 and the rest of the bytes are
a base 2 fraction.

The C<float2binary> subroutine uses the C<ifloat2binary> for the small
C<$exponent> part and the C<Math::BigFloat> subroutines to correct the
C<ifloat2binary> for the remaing exponent factor outside the range
of the C<ifloat2binary> subroutine.

The C<float2binary> subroutine uses the options C<decimal_integer_digits>,
C<$decial_fraction_digits>, C<extra_decimal_fraction_digits> in determining
the C<$iexponent> passed to the C<ifloat2binary> subroutine. 
The option C<decimal_integer_digits>
is the largest positive base ten C<$iexponent> 
while smallest C<$ixponent> is
the half C<$decial_fraction_digits> + C<extra_decimal_fraction_digits>.
The C<float2binary> subroutine C<extra_decimal_fraction_digits> only
for negative C<$iexponent>.
The C<float2binary> subroutine uses any base ten C<$exponent> from C<$iexponent>
breakout to adjust the C<ifloat2binary> subroutine results using 
native float arith.

If the C<float2binary> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

  (undef,$event)

The events are as follows:

 "No inputs\n\tData::SecsPack::float2binary-1\n"
 
The C<float2binary> also passes on any C<ifloat2binary> events.
Check the C<$binary_magnitude> for an C<undef>, to see if the subroutine 
cannot process the decimal exponent.

=head2 ifloat2binary
 
 ($binary_magnitude, $binary_exponent) = ifloat2binary($imagnitude, $iexponent);
 ($binary_magnitude, $binary_exponent) = ifloat2binary($imagnitude, $iexponent, @options);
 ($binary_magnitude, $binary_exponent) = ifloat2binary($imagnitude, $iexponent, [@options]);
 ($binary_magnitude, $binary_exponent) = ifloat2binary($imagnitude, $iexponent, {@options});

The C<$ifloat2binary> subroutine converts a decimal float with a base ten
C<$imagnitude> and C<$iexponent> using the C<Math::BigInt> program
module to a binary float with a base two C<$binary_magnitude> and a base
two C<$binary_exponent>.
The C<$ifloat2binary> assumes that the decimal point is set by
C<iexponent> so that there is one decimal integer digit in C<imagnitude>
The C<ifloat2binary> produces a C<$binary_exponent> so that the first
byte of C<$binary_magnitude> is 1 and the rest of the bytes are
a base 2 fraction.

Since all the calculations use basic integer arith, there are 
practical limits on the computer resources.  Basically the limit is that
with a zero exponent, the decimal point is within the significant 
C<imagnitude> digits. Within these limitations, the accuracy, by 
chosen large enough limits for the binary fraction, is perfect.

If the C<ifloat2binary> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

  (undef,$event)

The events are as follows:

 "No inputs\n\tData::SecsPack::ifloat2binary-1\n"
 "The exponent, $exponent, is out of range for $magnitude.\n\tData::SecsPack::ifloat2binary-2\n"

Check the C<$binary_magnitude> for an C<undef>, to see if the subroutine 
cannot process the decimal exponent.

The first step of the C<ifloat2binary> subroutine is zero out 
C<iexponent> by breaking up the 
C<imagnitude> into an integer part C<integer> and fractional part C<fraction>
consist with the C<iexponent>. 
The c<ifloat2binary> will add as many significant decimal zeros to the
right of C<integer> in order to zero out C<iexponent>; likewise it will
add as many decimal zeros to the left of C<integer> to zero out
C<exponent> within the limit set by the option C<decimal_fraction_digits>.
If C<ifloat2binary> cannot zero out C<iexponent> without violating the
C<decimal_fraction_digits>,  C<ifloat2binary> will discontinue processing
and return an C<undef> C<$binary_magnitude> with and error message in
C<$binary_exponent>.  

This design is based on the fact that the conversion of integer decimal
to binary decimal is one to one, while the conversion of fractional decimal
to binary decimal is not.
When converting from decimal fractions with finite digits to binary fractions
repeating binary fractions of infinity size are possible, 
and do happen quite frequently. 
An unlimited repeating binary fraction will quickly use all computer
resources.  The C<binary_fraction_bytes> option provides this ungraceful
event by limiting the number of fractional binary bytes.
The default limits of 20 C<decimal_fraction_digits> and
C<binary_fraction_bytes> 10 bytes provides a full range of 0 - 255 for
each binary byte. The ten bytes are three more bytes then are ever
used in the largest F8 SEMI float format.

The the following example illustrates the method used by C<ifloat2binary>
to convert decimal fracional digits to binary fractional bytes.
Convert a 6 digit decimal fraction string into
a binary fraction as follows:

 N[0-999999]      
 -----------  =  
   10^6          

 byte0    byte1   byte2    256         R2
 ----- +  ----- + ----- + ----- * ------------
 256^1    256^2   256^3   256^4     10 ^ 6

Six digits was chosen so that the integer arith,
using a 256 base, does not over flow 32 bit
signed integer arith

 256 *   99999     =   25599744
 256 *  999999     =  255999744
 signed 32 bit max = 2147483648 / 256 = 8377608
 256 * 9999999     = 2559999744

Note with quad arith this technique would yield 16 decimal
fractional digits as follows:

 256 * 9999999999999999  =  2559999999999999744
 signed 64 bit max       =  9223372036854775808 / 256 = 36028797018963868
 256 * 99999999999999999 = 25599999999999999744

 Thus, need to get quad arith running.

 Basic step

  1      256 * N[0-999999]     1                     R0[0-999744]
 --- *   ----------------  =  ---- ( byte0[0-255] + ------------ ) 
 256         10 ^ 6           256                     10^6

The results will have a range of 

  1
 ---- ( 0.000000 to 255.999744)
 256 

The fractional part, R0 is a six-digit decimal. 
Repeating the basic step three types gives the
desired results. QED.

 2nd Iteration

  1      256 * R0[0-999744]       1                   R1[0-934464]
 --- *   --------------      =  ---- ( byte1[0-255] + ------------) 
 256         10 ^ 6              256                    10^6

 3rd Iteration

  1      256 * R1[0-934464]       1                   R2[0-222784]
 --- *   --------------      =  ---- ( byte2[0-239] + ------------) 
 256         10 ^ 6              256                    10^6

Taking this out to ten bytes the first six decimal digits N[0-999999]
yields bytes in the following ranges:

 byte    power      range    10^6 remainder
 ------------------------------------------ 
   0     256^-1     0-255    [0-999744]
   1     256^-2     0-255    [0-934464]
   2     256^-3     0-239    [0-222784]
   3     256^-4     0-57     [0-032704]
   4     256^-5     0-8      [0-372224]
   5     256^-6     0-95     [0-293440]
   6     256^-7     0-75     [0-120640]
   7     256^-8     0-30     [0-883840]
   8     256^-9     0-226    [0-263040]
   9     256^-10    0-67     [0-338249]

The first two binary fractional bytes have full range. The rest except for
byte 9 are not very close. This makes one wonder about the accuracy loss
in translating from binary fractions to decimal fractions. One wonders
just why have all theses problems with not just binary and decimal factions
but fractions in general. Isn't mathematics wonderful.

For example in convert from decimal to binary fractions there is no clean
one to one conversion as for integers. For example, look at the below table
of conversions: 
   
 -1    -2     -3     -4     -5     binary power as a decimal   
 0.5   0.25  0.125 0.0625 0.03125  decimal power 
                                   decimal 
  0     0      0      0      0     0.00000
  0     0      0      0      1     0.03125
  0     0      0      1      1     0.0625
  0     0      1      0      0     0.125
  0     0      1      0      1     0.15625
  0     0      1      1      0     0.1875
  0     0      1      1      1     0.21875
  1     0      0      0      0     0.50000

=head2 int2bytes

 @bytes = int2bytes( $big_integer );

The C<int2bytes> subroutine uses the C<Data:BigInt> program module to 
convert an integer text string C<$bit_integer> into a byte array, 
C<@bytes>, the Most Significant Byte (MSB) being C<$bytes[0]>. There is
no limits on the size of C<$big_integer> or C<@bytes> except for
the resources of the computer.

=head2 new

 $secspack = new Data::Secs2( @options );
 $secspack = new Data::Secs2( [@options] );
 $secspack = new Data::Secs2( {options} );

The C<new> subroutine provides a method to set local options
once for any of the other subroutines. 
The options may be modified at any time by
C<$secspack->config($option => $new_value)>.
Calling any of the subroutines as a
C<$secspack> method will perform that subroutine
with the options saved in C<secspack>.

=head2 pack_float

 ($format, $floats) = pack_float($format, @string_integers);
 ($format, $floats) = pack_float($format, @string_integers, [@options]);
 ($format, $floats) = pack_float($format, @string_integersm {@options});

The C<pack_float> subroutine takes an array of strings, <@string_integers>,
and a float format code, as specifed in the above C<Item Format Code Table>,
and packs all the integers, decimals and floats as a float
 the C<$format> in accordance with C<SEMI E5-94>.
The C<pack_int> subroutine also accepts the format code C<F>
and format codes with out the bytes-per-element number and packs the
numbers in the format using the less space. 
In any case, the C<pack_int> subroutine returns
the correct C<$format> of the packed C<$integers>.

If the C<pack_float> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

  (undef,$event)

The events are as follows:

 "No inputs.\n\tData::SecsPack::pack_float-1\n"
 "Format $format is not a floating point format.\n\tData::SecsPack::pack_float-2\n"
 "F4 exponent overflow.\n\tData::SecsPack::pack_float-3\n"
 "F4 xponent underflow.\n\tData::SecsPack::pack_float-4\n"
 "F8 exponent overflow.\n\tData::SecsPack::pack_float-5\n"
 "F8 xponent underflow.\n\tData::SecsPack::pack_float-6\n"

The C<float2binary> also passes on any C<float2binary> and C<ifloat2binary> events.
Check the C<$format> for an C<undef>, to see if the subroutine 
cannot continue processing.

=head2 pack_int

 ($format, $integers) = pack_int($format, @string_integers);
 ($format, $integers) = pack_int($format, @string_integers, [@options]);
 ($format, $integers) = pack_int($format, @string_integers, {options});

The C<pack_int> subroutine takes an array of strings, <@string_integers>,
and a format code, as specifed in the above C<Item Format Code Table>
and packs the integers, C<$integers> in the C<$format> in accordance with C<SEMI E5-94>.
The C<pack_int> subroutine also accepts the format code C<I I1 I2 I8>
and format codes with out the bytes-per-element number and packs the
numbers in the format using the less space, with unsigned preferred over
signed. In any case, the C<pack_int> subroutine returns
the correct C<$format> of the packed C<$integers>.

If the C<pack_int> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

  (undef,$event)

The events are as follows:

 "No inputs.\n\tData::SecsPack::pack_int-1\n"
 "Format $format is not an integer format.\ntData::SecsPack::pack_int-2\n"
 "No integers in the input.\ntData::SecsPack::pack_int-3\n"
 "Signed number encountered when unsigned specified.\ntData::SecsPack::pack_int-4\n"
 "Integer bigger than format length of $max_bytes bytes.\ntData::SecsPack::pack_int-5\n"

Check the C<$format> for an C<undef>, to see if the subroutine 
cannot continue processing.

=head2 pack_num

 ($format, $numbers, @strings) = pack_num($format, @strings);
 ($format, $numbers, @strings) = pack_num($format, @strings, [@options]);
 ($format, $numbers, @strings) = pack_num($format, @strings, {@options});

The C<pack_num> subroutine takes leading numbers in C<@strings> and
packs them in the C<$format> in accordance with C<SEMI E5-94>.
The C<pack_num> subroutine returns the stripped C<@strings>
data naked of all leading numbers in C<$format>.

The C<pack_num> subroutine also accepts C<$format> of C<I I1 I2 I4 F>
For these format codes, C<pack_num> is extremely liberal and accepts
processes all numbers consistence with the C<$format> and packs one
or more numbers in the C<SEMI E5-94> format that takes the least
space. In this case, the return $format is changed to the C<SEMI E5-94>
from the C<Item FOrmat Code Table> of the packed numbers.

For the C<I> C<$format>,
if the C<nomix> option is set, the C<pack_num> subroutine will 
pack all leading, integers, decimals and floats as multicell float
with the smallest space; otherwise, it will stop at the first
decimal or float encountered and just pack the integers. 

The C<pack_num> subroutine processes C<@strings> in two steps.
In the first step, the
C<pack_num> subroutine uses C<str2int> and/or C<str2float> 
subroutines to parse the leading
numbers from the C<@strings> as follows:

 ([@strings], @integers) = str2int(@strings); 
 ([@strings], @floats) = str2float(@strings); 

In the second step, 
the C<pack_num> subroutine uses C<pack_int> and/or C<pacK_float>
to pack the parsed numbers.

If the C<pack_nym> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

  (undef,$event)

The events are as follows:

 "No inputs.\n\tData::SecsPack::pack_num-1\n"
 "Format $format is not an integer or floating point format.\ntData::SecsPack::pack_num-2\n"
 "No numbers in the input.\ntData::SecsPack::pack_num-3\n"

The C<float2binary> also passes on any 
C<float2binary> C<ifloat2binary> C<pack_int> C<pack_float> events.
Check the C<$format> for an C<undef>, to see if the subroutine 
cannot continue processing.

=head2 str2float

 $float = str2float($string);
 $float = str2float($string, [@options]);
 $float = str2float($string, {@options});

 (\@strings, @floats) = str2float(@strings);
 (\@strings, @floats) = str2float(@strings, [@options]);
 (\@strings, @floats) = str2float(@strings, {@options});

The C<str2float> subroutine, in an array context, supports converting multiple run of
integers, decimals or floats in an array of strings C<@strings> to an array
of integers, decimals or floats, C<@floats>.
It keeps converting the strings, starting with the first string in C<@strings>,
continuing to the next and next until it fails an conversion.
The C<str2int> returns the stripped string data, naked of all integers,
in C<@strings> and the array of floats C<@floats>.
For the C<ascii_float> option, the members of the C<@floats> are scalar
strings of the float numbers; otherwise, the members are a reference
to an array of C<[$decimal_magnitude, $decimal_exponent]> where the decimal
point is set so that there is one decimal digit to the right of the decimal
point for $decimal_magnitude.

In a scalar context, it parse out any type of $number in the leading C<$string>.
This is especially useful for C<$string> that is certain to have a single number.

=head2 str2int

 $integer = str2int($string);
 $integer = str2int($string, [@options]);
 $integer = str2int($string, {@options});

 (\@strings, @integers) = str2int(@strings); 
 (\@strings, @integers) = str2int(@strings, [@options]); 
 (\@strings, @integers) = str2int(@strings, {@options}); 

In a scalar context,
the C<Data::SecsPack> program module translates an scalar string to a scalar integer.
Perl itself has a documented function, '0+$x', that converts a scalar to
so that its internal storage is an integer
(See p.351, 3rd Edition of Programming Perl).
If it cannot perform the conversion, it leaves the integer 0.
Surprising not all Perls, some Microsoft Perls in particular, may leave
the internal storage as a scalar string.

What is C<$x> for the following:

  my $x = 0 + '0x100';  # $x is 0 with a warning

Instead use C<str2int> uses a few simple Perl lines, without
any C<evals> starting up whatevers or firing up the
regular expression engine with its interpretative overhead,
to provide a slightly different response as follows:>.

 $x = str2int('033');   # $x is 27
 $x = str2int('0xFF');  # $x is 255
 $x = str2int('255');   # $x is 255
 $x = str2int('hello'); # $x is undef no warning
 $x = str2int(0.5);     # $x is undef no warning
 $x = str2int(1E0);     # $x is 1 
 $x = str2int(0xf);     # $x is 15
 $x = str2int(1E30);    # $x is undef no warning

The scalar C<str2int> subroutine performs the conversion to an integer
for strings that look like integers and actual integers without
generating warnings. 
A non-numeric string, decimal or floating string returns an "undef" 
instead of the 0 and a warning
that C<0+'hello'> produces.
This makes it not only useful for forcing an integer conversion but
also for testing a scalar to see if it is in fact an integer scalar.
The scalar C<str2int> is the same and supercedes C&<Data::StrInt::str2int>.
The C<Data::SecsPack> program module superceds the C<Data::StrInt> program module. 

The C<str2int> subroutine, in an array context, supports converting multiple run of
integers in an array of strings C<@strings> to an array of integers, C<@integers>.
It keeps converting the strings, starting with the first string in C<@strings>,
continuing to the next and next until it fails a conversion.
The C<str2int> returns the remaining string data in C<@strings> and
the array of integers C<@integers>.

=head2 unpack_float

 \@floats   = unpack_float($format, $float_string);
 \@floats   = unpack_float($format, $float_string, @options);
 \@floats   = unpack_float($format, $float_string, [@options]);
 \@floats   = unpack_float($format, $float_string, {@options});

The C<unpack_num> subroutine unpacks an array of floats C<$float_string>
packed in accordance with SEMI-E5 C<$format>. 
A valid C<$format>, in accordance with the above C<Item Format Code Table>,
is C<F4 F8>.

If the C<unpack_float> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

 $event

The events are as follows:

 "No inputs\ntData::SecsPack::unpack_float-1\n"
 "Format $format_in not supported.\n"tData::SecsPack::unpack_float-2\n"

The C<unpack_num> subroutine, thus, returns a reference, C<\@floats>, to the unpacked float array
or scalar error message C<$event>. To determine a valid return or an error,
check that C<ref> of the return exists or is 'C<ARRAY>'.
 
=head2 unpack_int

 \@integers = unpack_int($format, $integer_string); 
 \@integers = unpack_int($format, $integer_string, @options); 
 \@integers = unpack_int($format, $integer_string, [@options]); 
 \@integers = unpack_int($format, $integer_string, {@options}); 

The C<unpack_num> subroutine unpacks an array of numbers C<$string_numbers>
packed in accordance with SEMI-E5 C<$format>. 
A valid C<$format>, in accordance with the above C<Item Format Code Table>,
is C<S1 S2 S4 U1 U2 U4 T>.

The C<unpack_num> returns a reference, C<\@integers>, to the unpacked integer array
or scalar error message C<$error>. To determine a valid return or an error,
check that C<ref> of the return exists or is 'C<ARRAY>'.

If the C<unpack_float> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as

  $event

The events are as follows:

 "No inputs\ntData::SecsPack::unpack_int-1\n"
 "Format $format_in not supported.\n"tData::SecsPack::unpack_int-2\n"

The C<unpack_num> subroutine, thus, returns a reference, C<\@floats>, to the unpacked float array
or scalar error message C<$event>. To determine a valid return or an error,
check that C<ref> of the return exists or is 'C<ARRAY>'.

=head2 unpack_num

 \@numbers  = unpack_num($format, $number_string); 
 \@numbers  = unpack_num($format, $number_string, @options); 
 \@numbers  = unpack_num($format, $number_string, [@options]); 
 \@numbers  = unpack_num($format, $number_string, {@options}); 

The C<unpack_num> subroutine unpacks an array of numbers C<$number_string>
packed in accordance with SEMI E5-94 C<$format>. 
A valid C<$format>, in accordance with the above C<Item Format Code Table>,
is C<S1 S2 S4 U1 U2 U4 F4 F8 T>.
The C<unpack_num> subroutine uses either C<unpack_float> or C<unpack_int>
depending upon C<$format>.

The C<pack_num> subroutine does not generate any events
but the subroutine does pass on any C<pack_int> and C<pack_float> events,
returning them as a string.
The C<unpack_num> subroutine, thus, returns a reference, C<\@numbers>, to the unpacked number array
or scalar error message C<$event>. 
To determine a valid return or an error,
check that C<ref> of the return exists or is 'C<ARRAY>'.

=head1 REQUIREMENTS

Coming.

=head1 DEMONSTRATION

 #########
 # perl SecsPack.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     my $fp = 'File::Package';

     my $uut = 'Data::SecsPack';
     my $loaded;

     #####
     # Provide a scalar or array context.
     #
     my ($result,@result);

 ##################
 # UUT Loaded
 # 

    my $errors = $fp->load_package($uut, 
        qw(bytes2int float2binary 
           ifloat2binary int2bytes   
           pack_float pack_int pack_num  
           str2float str2int 
           unpack_float unpack_int unpack_num) );
 $errors

 # ''
 #

 ##################
 # str2int('0xFF')
 # 

 $result = $uut->str2int('0xFF')

 # '255'
 #

 ##################
 # str2int('255')
 # 

 $result = $uut->str2int('255')

 # '255'
 #

 ##################
 # str2int('hello')
 # 

 $result = $uut->str2int('hello')

 # undef
 #

 ##################
 # str2int(1E20)
 # 

 $result = $uut->str2int(1E20)

 # undef
 #

 ##################
 # str2int(' 78 45 25', ' 512E4 1024 hello world') @numbers
 # 

 my ($strings, @numbers) = str2int(' 78 45 25', ' 512E4 1024 hello world')
 [@numbers]

 # [
 #          '78',
 #          '45',
 #          '25'
 #        ]
 #

 ##################
 # str2int(' 78 45 25', ' 512E4 1024 hello world') @strings
 # 

 join( ' ', @$strings)

 # '512E4 1024 hello world'
 #

 ##################
 # str2float(' 78 -2.4E-6 0.25', ' 512E4 hello world') numbers
 # 

 ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025', ' 512E4 hello world')
 [@numbers]

 # [
 #          [
 #            '78',
 #            '1'
 #          ],
 #          [
 #            '-24',
 #            '-6'
 #          ],
 #          [
 #            '25',
 #            -3
 #          ],
 #          [
 #            '512',
 #            '6'
 #          ]
 #        ]
 #

 ##################
 # str2float(' 78 -2.4E-6 0.25', ' 512E4 hello world') @strings
 # 

 ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025', ' 512E4 hello world')
 join( ' ', @$strings)

 # 'hello world'
 #

 ##################
 # str2float(' 78 -2.4E-6 0.25 0xFF 077', ' 512E4 hello world', {ascii_float => 1}) numbers
 # 

 ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077', ' 512E4 hello world', {ascii_float => 1})
 [@numbers]

 # [
 #          '78',
 #          '-2.4E-6',
 #          '0.0025',
 #          '255',
 #          '63',
 #          '512E4'
 #        ]
 #

 ##################
 # str2float(' 78 -2.4E-6 0.25', ' 512E4 hello world', {ascii_float => 1}) @strings
 # 

 ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025', ' 512E4 hello world')
 join( ' ', @$strings)

 # 'hello world'
 #
      my @test_strings = ('78 45 25', '512 1024 100000 hello world');
      my $test_string_text = join ' ',@test_strings;
      my $test_format = 'I';
      my $expected_format = 'U4';
      my $expected_numbers = '0000004e0000002d000000190000020000000400000186a0';
      my $expected_strings = ['hello world'];
      my $expected_unpack = [78, 45, 25, 512, 1024, 100000];

      my ($format, $numbers, @strings) = pack_num('I',@test_strings);

 ##################
 # pack_num(I, 78 45 25 512 1024 100000 hello world) format
 # 

 $format

 # 'U4'
 #

 ##################
 # pack_num(I, 78 45 25 512 1024 100000 hello world) numbers
 # 

 unpack('H*',$numbers)

 # '0000004e0000002d000000190000020000000400000186a0'
 #

 ##################
 # pack_num(I, 78 45 25 512 1024 100000 hello world) @strings
 # 

 [@strings]

 # [
 #          'hello world'
 #        ]
 #

 ##################
 # unpack_num(U4, 78 45 25 512 1024 100000 hello world) error check
 # 

 ref(my $unpack_numbers = unpack_num($expected_format,$numbers))

 # 'ARRAY'
 #

 ##################
 # unpack_num(U4, 78 45 25 512 1024 100000 hello world) numbers
 # 

 $unpack_numbers

 # [
 #          '78',
 #          '45',
 #          '25',
 #          '512',
 #          '1024',
 #          '100000'
 #        ]
 #

      @test_strings = ('78 4.5 .25', '6.45E10 hello world');
      $test_string_text = join ' ',@test_strings;
      $test_format = 'I';
      $expected_format = 'F8';
      $expected_numbers = '405380000000000040120000000000003fd0000000000000422e08ffca000000';
      $expected_strings = ['hello world'];
      my @expected_unpack = (
           '7.800000000000017486E1', 
           '4.500000000000006245E0',
           '2.5E-1',
           '6.4500000000000376452E10'
      );

      ($format, $numbers, @strings) = pack_num('I',@test_strings);

 ##################
 # pack_num(I, 78 4.5 .25 6.45E10 hello world) format
 # 

 $format

 # 'F8'
 #

 ##################
 # pack_num(I, 78 4.5 .25 6.45E10 hello world) numbers
 # 

 unpack('H*',$numbers)

 # '405380000000000040120000000000003fd0000000000000422e08ffca000000'
 #

 ##################
 # pack_num(I, 78 4.5 .25 6.45E10 hello world) @strings
 # 

 [@strings]

 # [
 #          'hello world'
 #        ]
 #

 ##################
 # unpack_num(F8, 78 4.5 .25 6.45E10 hello world) error check
 # 

 ref($unpack_numbers = unpack_num($expected_format,$numbers))

 # 'ARRAY'
 #

 ##################
 # unpack_num(F8, 78 4.5 .25 6.45E10 hello world) numbers
 # 

 $unpack_numbers

 # [
 #          '7.800000000000017486E1',
 #          '4.500000000000006245E0',
 #          '2.5E-1',
 #          '6.4500000000000376452E10'
 #        ]
 #

=head1 QUALITY ASSURANCE
 
Running the test script C<SecsPack.t>
and C<SecsPackStress.t> verifies
the requirements for this module.

The C<tmake.pl> cover script for C<Test::STDmaker|Test::STDmaker>
automatically generated the
C<SecsPack.t> and C<SecsPackStress.t> 
test scripts,C<SecsPack.d> and C<SecsPackStress.d> demo scripts,
and C<t::Data::SecsPack> and C<t::Data::SecsPackStress> STD program module PODs,
from the C<t::Data::SecsPack> and C<t::Data::SecsPackStress> program module's content.
The C<t::Data::SecsPack> and C<t::Data::SecsPackStress> program modules are
in the distribution file
F<Data-SecsPack-$VERSION.tar.gz>.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds


All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE_ALSO:

=over 4

=item L<Math::BigInt|Math::BigInt>

=item L<Math::BigFloat|Math::BigFloat>

=item L<Data::Secs2|Data::Sec2>

=item L<Docs::Site_SVD::Data_SecsPack|Docs::Site_SVD::Data_SecsPack>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of script  ######