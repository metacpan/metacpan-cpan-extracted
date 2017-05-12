
##################################################################
# Copyright (C) 2000 Greg London   All Rights Reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
##################################################################


require 5;
use strict;


##################################################################
package Hardware::Verilog::StdLogic;
##################################################################
use vars qw ( $VERSION );
$VERSION = '0.03';
##################################################################

use Data::Dumper;
# print Dumper($reference);

# in Parser.pm, use the following line ot access dumper:
# 	Hardware::Verilog::StdLogic::dumper(\$item{module_instance});
sub dumper
{
 print Dumper(shift(@_));
}

sub new
{
 my ($class, $string) = @_;
 $string = "1'b0" unless(defined($string));
 #print "new StdLogic, value is $string \n";

 if ((substr($string,0,1) eq '"') and (substr($string, -1, 1) eq '"'))
	{
 	my $r_hash = { 'width'=>1, 'binary'=>'1' };

 	bless $r_hash, $class;
 	return $r_hash;
	}

 $string =~ s/\s//g;



 my $numsize=undef;
 my $value=undef;
 my $base;

 if ($string =~ /'/)
	{
	#################################################
	# it contains a base identifier
	# such as 3'b001 or 'hf92  or 3'o7  or 8'd9
	# split it apart and decode it.
	# note that numsize is not required.
	#################################################
	($numsize, $value) = split(/'/, $string);
	#print "split numsize is $numsize \n";


	$numsize = undef unless (length($numsize) > 0);

	$base = lc ( substr($value, 0, 1) );
	$value = substr($value, 1, length($value)-1);

	

	   if ($base eq 'h') { $value = $class->HexstrToBinstr($value); }
	elsif ($base eq 'o') { $value = $class->OctstrToBinstr($value); }
	elsif ($base eq 'd') { $value = $class->DecstrToBinstr($value); }
	elsif ($base eq 'b') { $value = $class->BinstrToBinstr($value); }
	}
 else
	{
	#################################################
	# no base identifier given
	# assume number is a raw decimal number.
	#################################################
	$value = $class->DecstrToBinstr($string);
	}


 if (defined($numsize))
	{
	#################################################
	# binary numbers must be exact widths.
	# all others get some slack because
	# 7'h4a 
	# is actually valid, even though hexstrtobinstr will return 8 chars.
	#################################################
	$value =~ /^0*(.*)/;
	my $msb_string = $1;
	my $msb_length = length($msb_string);
	my $total_bits = length($value);
	if ($msb_length > $numsize)
		{
		$class->Error( 
		"specified length is too short for given value. Truncating ($string)." );
		$value = substr($value, $total_bits-$numsize, $numsize);
		}

	elsif ($numsize > $total_bits)
		{ 
		$value = '0'x($numsize - $total_bits) . $value; 
		}
	elsif ($total_bits > $numsize)   
		{
		# do one last trimming for cases when
		# the value is 3'h2, 
		# since hexstrtobinstr will return a 4 bit value
		$value =~ /(.{$numsize})$/;
		$value = $1;
		}

	}

 else
	{
	$numsize='u';
	my $char;
	my $i;
	for($i=0; $i<length($value); $i++)
		{
		$char = substr($value,$i,1);
		#print "i=$i  char = $char \n";
		last if ($char eq '1');
		}
	$numsize = length($value) - $i;
	}

 my $r_hash = { 'width'=>$numsize, 'binary'=>$value };

 bless $r_hash, $class;
 return $r_hash;
} 

############################################################
sub copy
{
 my ($obj)=@_;
 my $new = {};
 my @keys = keys(%$obj);
 foreach my $key (@keys)
  {
  my $value = $obj->{$key};
  $new->{$key} = $value;
  }

 my $class = ref($obj);
 bless $new, $class;
 return $new;
}


############################################################

# assign and return width
sub width
{
 my ($obj,$width) = @_;
 $obj->{'width'} = $width if (@_ > 1);
 return shift->{'width'};
}


############################################################
# return number in binary format for display
# no width indication, no base specifier
sub binary
{
 my ($obj,$binary) = @_;
 $obj->{'binary'} = $binary if (@_ > 1);
 return shift->{'binary'};
}



############################################################
############################################################

my %hex_to_bin_char_converter = (
	'x' => 'xxxx',
	'X' => 'xxxx',
	'z' => 'zzzz',
	'Z' => 'zzzz',
	'0' => '0000',
	'1' => '0001',
	'2' => '0010', 
	'3' => '0011',
	'4' => '0100',
	'5' => '0101',
	'6' => '0110',
	'7' => '0111',
	'8' => '1000',
	'9' => '1001',
	'a' => '1010',
	'A' => '1010',
	'b' => '1011',
	'B' => '1011',
	'c' => '1100',
	'C' => '1100',
	'd' => '1101',
	'D' => '1101',
	'e' => '1110',
	'E' => '1110',
	'f' => '1111',
	'F' => '1111',
);
	

#hex_digits : /[xXzZ0-9a-fA-F][xXzZ0-9a-fA-F_]*/
sub HexstrToBinstr
{
	my ($obj,$hex) = @_;
	my $ret = '';
	while(length($hex))
		{
		$hex=~/(.)$/;
		my $char = $1;
		$hex =~ s/$char$//;
		next if ($char eq '_');
		$ret = $hex_to_bin_char_converter{$char} . $ret;
		}
	return $ret;
}




my %oct_to_bin_char_converter = (
	'x' => 'xxx',
	'X' => 'xxx',
	'z' => 'zzz',
	'Z' => 'zzz',
	'0' => '000',
	'1' => '001',
	'2' => '010', 
	'3' => '011',
	'4' => '100',
	'5' => '101',
	'6' => '110',
	'7' => '111',
);
	

#octal_digits :  /[xXzZ0-7][xXzZ0-7_]*/
sub OctstrToBinstr
{
	my ($obj, $oct) = @_;
	my $ret = '';
	while(length($oct))
		{
		$oct=~/(.)$/;
		my $char = $1;
		$oct =~ s/$char$//;
		next if ($char eq '_');
		$ret = $oct_to_bin_char_converter{$char} . $ret;
		}
	return $ret;
}




#decimal_digits :  /[0-9][0-9_]*/
sub DecstrToBinstr
{
	my ($obj, $dec) = @_;
	my $ret;
	$dec = lc($dec);
	if($dec =~ /x/)
		{
		$ret = 'x';
		}
	elsif($dec =~ /z/)
		{
		$ret = 'z';
		}
	else
		{
		$ret = sprintf("%lx",$dec);
		$ret = $obj->HexstrToBinstr($ret);
		}
	return $ret;
}





#binary_digits :  /[xXzZ01][xXzZ01_]*/
sub BinstrToBinstr
{
	my ($obj, $bin) = @_;
	my $ret = '';
	$bin =~ s/_//g;
	$ret = lc ($bin);
	return $ret;
}

############################################################



sub Error
{
 my ($obj, $string) = @_;
 print "\n\n\tERROR: $string \n\n";
 return

}


############################################################


sub dump
{
 my ($obj)=@_;
 print "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n";
 my @keys = keys(%$obj);
 @keys = sort(@keys);
 foreach my $key (@keys)
  {
  my $value = $obj->{$key};
  unless(defined($value))
	{$value = 'undefined';}
  print "$key = $value \n";
  }
 print "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
}



my %bin_to_hex_block_converter = (
	'0000' => '0',
	'0001' => '1',
	'0010' => '2',
	'0011' => '3',
	'0100' => '4',
	'0101' => '5',
	'0110' => '6',
	'0111' => '7',
	'1000' => '8',
	'1001' => '9',
	'1010' => 'a',
	'1011' => 'b',
	'1100' => 'c',
	'1101' => 'd',
	'1110' => 'e',
	'1111' => 'f',
);

# return number in hexadecimal format for display
# no width indication, no base specifier
sub hexadecimal
{
 my ($obj) = @_;
 my $bin = $obj->binary;
 # make it a multiple of 4 character long.
 my $rem = length($bin) % 4;
 my $replicate=0;
 if ($rem)
   {$replicate = 4 - $rem;}
 $bin = '0'x$replicate . $bin;
 my $hex = '';
 my $block;
 my $char;
 while($bin)
	{
	$block = substr($bin,-4,4);
	$bin = substr($bin, 0, length($bin) - 4);
	if($block=~/x/)
		{$char = 'x';}
	elsif($block=~/z/)
		{$char = 'z';}
	else
		{
		$char = $bin_to_hex_block_converter{$block};
		}
	$hex = $char . $hex;
	}
 return $hex;
}

my %bin_to_oct_block_converter = (
	'000' => '0',
	'001' => '1',
	'010' => '2',
	'011' => '3',
	'100' => '4',
	'101' => '5',
	'110' => '6',
	'111' => '7',
);

# return number in octal format for display
# no width indication, no base specifier
sub octal
{
 my ($obj) = @_;
 my $bin = $obj->binary;
 # make it a multiple of 3 character long.
 my $rem = length($bin) % 3;
 my $replicate=0;
 if ($rem)
   {$replicate = 3 - $rem;}
 $bin = '0'x$replicate . $bin;
 my $oct = '';
 my $block;
 my $char;
 while($bin)
	{
	$block = substr($bin,-3,3);
	$bin = substr($bin, 0, length($bin) - 3);
	if($block=~/x/)
		{$char = 'x';}
	elsif($block=~/z/)
		{$char = 'z';}
	else
		{
		$char = $bin_to_oct_block_converter{$block};
		}
	$oct = $char . $oct;
	}
 return $oct;
}



# return number in decimal format for display
# no width indication, no base specifier
sub decimal
{
 my ($obj) = @_;
 my $hex = $obj->hexadecimal;
 my $dec_str;
 if ($hex=~/x/)
	{ $dec_str = 'x'; }
 elsif ($hex =~ /z/)
	{ $dec_str = 'z'; }
 else
	{
	my $dec_val = hex($hex);
	$dec_str = sprintf("%d", $dec_val);
	}
 return $dec_str;

}



############################################################



sub basedhexadecimal
{
 my ($obj) = @_;
 return $obj->width . "'h" . $obj->hexadecimal ;
}

sub baseddecimal
{
 my ($obj) = @_;
 return $obj->width . "'d" . $obj->decimal ;
}

sub basedoctal
{
 my ($obj) = @_;
 return $obj->width . "'o" . $obj->octal ;
}


sub basedbinary
{
 my ($obj) = @_;
 return $obj->width . "'b" . $obj->binary ;
}



############################################################
############################################################
############################################################
############################################################
############################################################

# return the numeric value of the object,
# you will need to check to see if all bits are valid first.
sub numeric
{
 my ($obj) = @_;
 my $hex_str = $obj->hexadecimal;
 my $num;
 if ( $hex_str=~ /[zx]/ )
	{ $num = 0; }
 else
	{ $num = hex($hex_str); }
 return $num;
}

############################################################
############################################################
############################################################
############################################################
############################################################

# look at the given width, and fix binary value to match
sub trim
{
 my ($obj)=@_;
 my $width=$obj->width;
 return if($width eq 'u');
 my $binary=$obj->binary;
 my $length=length($binary);
 return if($width == $length);
 if($width > $length)
  {$obj->binary('0'x($width-$length).$binary);}
 else
  {$obj->binary(substr($binary, $length-$width, $width));}

}

############################################################
############################################################
############################################################
############################################################
############################################################

sub unary_reduction_and
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 elsif($bin=~/0/)
  {$ret->binary('0');}
 else
  {$ret->binary('1');}
 return $ret;
}

sub unary_reduction_nand
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 elsif($bin=~/0/)
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret;
}

sub unary_reduction_or
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 elsif($bin=~/1/)
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret;
}

sub unary_reduction_nor
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 elsif($bin=~/1/)
  {$ret->binary('0');}
 else
  {$ret->binary('1');}
 return $ret;
}

sub unary_reduction_xor
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 else
  {
  my $running = substr($bin,0,1);
  my $len = length($bin);
  my $char;
  for(my $i=1;$i < $len; $i++)
   {
   $char = substr($bin,$i,1);
   if($running eq $char)
	{ $running = '0'; }
   else 
	{ $running = '1'; }
   }
  $ret->binary($running);
  }
 return $ret;
}

sub unary_reduction_xnor
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 else
  {
  my $running = substr($bin,0,1);
  my $len = length($bin);
  my $char;
  for(my $i=1;$i < $len; $i++)
   {
   $char = substr($bin,$i,1);
   if($running eq $char)
	{ $running = '1'; }
   else 
	{ $running = '0'; }
   }
  $ret->binary($running);
  }
 return $ret;
}

# evaluate the thing as a boolean
sub unary_logical_boolean
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 elsif($bin=~/1/)
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret;
}

sub unary_logical_negation
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 $ret->width(1);
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 elsif($bin=~/1/)
  {$ret->binary('0');}
 else
  {$ret->binary('1');}
 return $ret;
}

sub unary_bitwise_negation
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 my $bin=$ret->binary;
 $bin =~ tr/z/x/;
 $bin =~ tr/01/10/;
 $ret->binary($bin);
 return $ret;
}

# same as two's complement
sub unary_minus
{
 my ($obj)=@_;
 my $ret = $obj->unary_bitwise_negation;
 $ret = $ret->unary_plus_one;
 return $ret;
}

# add '1' to the input
sub unary_plus_one
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 my $bin=$ret->binary;
 if($bin=~/[xz]/)
  {$ret->binary('x');}
 else
  {
  my $final='';
  my $carry=1;
  my $len = length($bin);
  my $pair;
  for(my $i=$len-1;$i >= 0 ; $i--)
   {
   $pair = substr($bin,$i,1) . $carry;
   if($pair eq '11')
    {
    $final = '0' . $final;
    $carry = '1';
    }

   elsif( ($pair eq '10') or ($pair eq '01') )
    {
    $final = '1' . $final;
    $carry = '0';
    }

   else  # ($pair eq '00')
    {
    $final = '0' . $final;
    $carry = '0';
    }
   }
  $ret->binary($final);
  }
 return $ret;
}


sub unary_plus
{
 my ($obj)=@_;
 my $ret = $obj->copy;
 return $ret;
}


############################################################
############################################################
############################################################
############################################################
############################################################



my %unary_operator_hash_table = (
	 '&' => \&unary_reduction_and,
	'~&' => \&unary_reduction_nand,
	 '|' => \&unary_reduction_or,
	'~|' => \&unary_reduction_nor,
	 '^' => \&unary_reduction_xor,
	'~^' => \&unary_reduction_xnor,
	'^~' => \&unary_reduction_xnor,
	'+'  => \&unary_plus,
	'-'  => \&unary_minus,
	'!'  => \&unary_logical_negation, 
	'~'  => \&unary_bitwise_negation,
	);

############################################################
############################################################
############################################################
############################################################
############################################################


sub unary_operator
{
#print "CALLING unary_operator\n";
 my ($obj, $unary_operator) = @_ ;
 my $call = $unary_operator_hash_table{$unary_operator};
 my $ret = &$call($obj);
 $ret->trim;
 return $ret;
}


############################################################
############################################################
############################################################
############################################################
############################################################


sub binary_arithmetic_multiply
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 if( ($obj_left->width eq 'u') or ($obj_right->width eq 'u') )
  { $ret->width('u'); }
 else
  { $ret->width( $obj_left->width + $obj_right->width ) };

 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  my $num = ( $obj_left->numeric * $obj_right->numeric );
  my $str = sprintf("%x", $num);
  $ret->binary($ret->HexstrToBinstr($str)); 
  }
 return $ret;
}

sub binary_arithmetic_divide
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 if( ($obj_left->width eq 'u') or ($obj_right->width eq 'u') )
  { $ret->width('u'); }
 else
  {
  $ret->width( $obj_left->width - $obj_right->width );
  if($ret->width < 0)
   {$ret->width(0);}
  }

 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  my $num = ( $obj_left->numeric / $obj_right->numeric );
  my $int = int ($num);
  my $str = sprintf("%x", $int);
  $ret->binary($ret->HexstrToBinstr($str)); 
  }
 return $ret;
}

sub binary_arithmetic_add
{
#print "CALLING binary_arithmetic_add\n";
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 my $left_width  = $obj_left->width;
 my $right_width = $obj_right->width;
 if( ($left_width eq 'u') or ($right_width eq 'u') )
  { $ret->width('u'); }
 else
  {
  if ($left_width > $right_width)
   {$ret->width($left_width);}
  else
   {$ret->width($right_width);}
  }

 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  my $num = ( $obj_left->numeric + $obj_right->numeric );
  my $str = sprintf("%x", $num);
  my $bin = $ret->HexstrToBinstr($str);
  $ret->binary($bin); 
  $ret->trim;
  }
 return $ret;
}

sub binary_arithmetic_subtract
{
#print "CALLING binary_arithmetic_subtract\n";
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);

 my $neg_right = $prep_right->unary_minus;
 $ret = $prep_left->binary_arithmetic_add($neg_right);
 return $ret;
}

sub binary_arithmetic_modulus
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 if( ($obj_left->width eq 'u') or ($obj_right->width eq 'u') )
  { $ret->width('u'); }
 else
  {
  $ret->width( $obj_right->width );
  }

 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  my $num = ( $obj_left->numeric % $obj_right->numeric );
  my $str = sprintf("%x", $num);
  $ret->binary($ret->HexstrToBinstr($str)); 
  }
 return $ret;
}

sub binary_relational_greater_than
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 $ret->width(1);
 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  if( $obj_left->numeric > $obj_right->numeric )
   { $ret->binary('1'); }
  else
   { $ret->binary('0'); }
  }
}

sub binary_relational_less_than
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 $ret->width(1);
 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  if( $obj_left->numeric < $obj_right->numeric )
   { $ret->binary('1'); }
  else
   { $ret->binary('0'); }
  }
}

sub binary_relational_greater_than_or_equal_to
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 $ret->width(1);
 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  if( $obj_left->numeric >= $obj_right->numeric )
   { $ret->binary('1'); }
  else
   { $ret->binary('0'); }
  }
}

sub binary_relational_less_than_or_equal_to
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 $ret->width(1);
 if ( ($obj_left->binary =~ /[zx]/) or ($obj_right->binary =~ /[zx]/) )
  { $ret->binary('x'); }
 else
  {
  if( $obj_left->numeric <= $obj_right->numeric )
   { $ret->binary('1'); }
  else
   { $ret->binary('0'); }
  }
}

sub binary_logical_and
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 $ret->width(1);
 my $bool_left  = $obj_left->unary_logical_boolean;
 my $bool_right = $obj_right->unary_logical_boolean;
 my $pair = $bool_left->binary . $bool_right->binary;
 if ($pair =~ /[xz]/)
  {$ret->binary('x');}
 elsif ($pair eq '11')
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret;
}

sub binary_logical_or
{
 my ($obj_left, $obj_right)=@_;
 my $ret = ref($obj_left)->new;
 $ret->width(1);
 my $bool_left  = $obj_left->unary_logical_boolean;
 my $bool_right = $obj_right->unary_logical_boolean;
 my $pair = $bool_left->binary . $bool_right->binary;
 if ($pair =~ /[xz]/)
  {$ret->binary('x');}
 elsif ($pair eq '11')
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret;
}

sub binary_equality
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 $ret->width(1);
 my $bin_left  = $prep_left->binary;
 my $bin_right = $prep_right->binary;
 if ( ($bin_left=~/[xz]/) or ($bin_right=~/[xz]/) )
  {$ret->binary('x');}
 elsif ($bin_left eq $bin_right)
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret
}

sub binary_inequality
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 $ret->width(1);
 my $bin_left  = $prep_left->binary;
 my $bin_right = $prep_right->binary;
 if ( ($bin_left=~/[xz]/) or ($bin_right=~/[xz]/) )
  {$ret->binary('x');}
 elsif ($bin_left eq $bin_right)
  {$ret->binary('0');}
 else
  {$ret->binary('1');}
 return $ret
}

sub binary_case_equality
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 $ret->width(1);
 if ($prep_left->binary eq $prep_right->binary)
  {$ret->binary('1');}
 else
  {$ret->binary('0');}
 return $ret
}

sub binary_case_inequality
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 $ret->width(1);
 if ($prep_left->binary eq $prep_right->binary)
  {$ret->binary('0');}
 else
  {$ret->binary('1');}
 return $ret
}

sub binary_bitwise_and
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 my $bin_left =$prep_left->binary;
 my $bin_right=$prep_right->binary;
 my $pair;
 my $final='';
 my $len = length($bin_left);
 for(my $i=0; $i<$len ; $i++)
  {
  $pair  = substr($bin_left ,$i,1) . substr($bin_right,$i,1);
  if($pair =~ /[xz]/)
   {
   $final .= 'x';
   }
  elsif( $pair eq '11' )
   {
   $final .= '1';
   }
  else  
   {
   $final .= '0';
   }
  }
 $ret->binary($final);
 return $ret;
}

sub binary_bitwise_or
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 my $bin_left =$prep_left->binary;
 my $bin_right=$prep_right->binary;
 my $pair;
 my $final='';
 my $len = length($bin_left);
 for(my $i=0; $i<$len ; $i++)
  {
  $pair  = substr($bin_left ,$i,1) . substr($bin_right,$i,1);
  if($pair =~ /[xz]/)
   {
   $final .= 'x';
   }
  elsif( $pair =~ '1' )
   {
   $final .= '1';
   }
  else  
   {
   $final .= '0';
   }
  }
 $ret->binary($final);
 return $ret;
}

sub binary_bitwise_xor
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 my $bin_left =$prep_left->binary;
 my $bin_right=$prep_right->binary;
 my $pair;
 my $final='';
 my $len = length($bin_left);
 for(my $i=0; $i<$len ; $i++)
  {
  $pair  = substr($bin_left ,$i,1) . substr($bin_right,$i,1);
  if($pair =~ /[xz]/)
   {
   $final .= 'x';
   }
  elsif( ($pair eq '01') or ($pair eq '10') )
   {
   $final .= '1';
   }
  else  
   {
   $final .= '0';
   }
  }
 $ret->binary($final);
 return $ret;
}

sub binary_bitwise_xnor
{
 my ($obj_left, $obj_right)=@_;
 my ($ret,$prep_left,$prep_right) = $obj_left->binary_prep($obj_right);
 my $bin_left =$prep_left->binary;
 my $bin_right=$prep_right->binary;
 my $pair;
 my $final='';
 my $len = length($bin_left);
 for(my $i=0; $i<$len ; $i++)
  {
  $pair  = substr($bin_left ,$i,1) . substr($bin_right,$i,1);
  if($pair =~ /[xz]/)
   {
   $final .= 'x';
   }
  elsif( ($pair eq '11') or ($pair eq '00') )
   {
   $final .= '1';
   }
  else  
   {
   $final .= '0';
   }
  }
 $ret->binary($final);
 return $ret;
}

sub binary_right_shift
{
 my ($obj_left, $obj_right)=@_;
 my $ret=$obj_left->copy;
 if($obj_right->binary =~ /[zx]/)
  {
  $ret->binary('x');
  }
 else
  {
  unless($obj_left->width eq 'u')
   {
   $ret->width($obj_left->width - $obj_right->numeric); 
   $ret->width(0) if($ret->width < 0);
   }
  $ret->binary
   (substr
    ($obj_left->binary,
    0,
    length($obj_left->binary)-$obj_right->numeric
    )
   );
  }
 return $ret;
}

sub binary_left_shift
{
 my ($obj_left, $obj_right)=@_;
 my $ret=$obj_left->copy;
 if($obj_right->binary =~ /[zx]/)
  {
  $ret->binary('x');
  }
 else
  {
  unless($obj_left->width eq 'u')
   { $ret->width($obj_left->width + $obj_right->numeric); }
  $ret->binary($obj_left->binary . '0'x($obj_right->numeric));
  }
 return $ret;
}

############################################################
############################################################
############################################################
############################################################
############################################################


###################################################
# most all binary operations will call this sub
# it will take two objects, and return copies
# of those objects, except that it will trim up
# the widths of the data so that they match.
# i.e. the calling subs shouldn't have to worry
# if the widths dont match, or if the width
# is undefined. this sub will handle it.
###################################################
sub binary_prep
{
 my ($obj_left,$obj_right) = @_;
 my $left  = $obj_left->copy;
 my $right = $obj_right->copy;
 my $leftbin=$left->binary;
 my $leftwidth=$left->width;
 my $leftlength=length($leftbin);
 my $rightbin=$right->binary;
 my $rightwidth=$right->width;
 my $rightlength=length($rightbin);

 my $new_obj = $obj_left->copy;

 #########################################################
 # if both undefined widths
 #########################################################
 if ( ($leftwidth eq 'u') and ($rightwidth eq 'u') )
	{
	# make lengths match the longest binary string
	if($leftlength > $rightlength)
		{
		$right->binary('0'x($leftlength-$rightlength) . $rightbin);
		$new_obj->width($leftlength);
		}
	else
		{
		$left->binary('0'x($rightlength-$leftlength) . $leftbin);
		$new_obj->width($rightlength);
		}
	}

 #########################################################
 # if left has undefined width (and right is defined width)
 #########################################################
 elsif ($leftwidth eq 'u')
	{
	# expand the undefined width (left) to match it.
	$left->binary('0'x($rightlength-$leftlength) . $leftbin);
	$left->width($rightwidth);
	$new_obj->width($rightwidth);
	}

 #########################################################
 # if right has undefined width (and left is defined width)
 #########################################################
 elsif ($rightwidth eq 'u')
	{
	# expand the undefined width (right) to match it.
	$right->binary('0'x($leftlength-$rightlength) . $rightbin);
	$right->width($leftwidth);
	$new_obj->width($leftwidth);
	}

 #########################################################
 # if both widths defined, and both equal to each other
 #########################################################
 elsif ($rightwidth eq $leftwidth)
	{
	$new_obj->width($leftwidth);
	}

 #########################################################
 # otherwise, widths are defined, but not equal
 # check for left > right
 #########################################################
 elsif ( $leftlength > $rightlength )
	{
	$right->binary('0'x($leftlength-$rightlength) . $rightbin);
	$right->width($leftwidth);
	$new_obj->width($leftwidth);
	}

 #########################################################
 # widths are defined, and right > left
 #########################################################
 else
	{
	$left->binary('0'x($rightlength-$leftlength) . $leftbin);
	$left->width($rightwidth);
	$new_obj->width($rightwidth);
	}

 my @ret = ( $new_obj, $left, $right );
 return @ret;
}

############################################################
############################################################
############################################################
############################################################
############################################################


my %binary_operator_hash_table = (
	'*'   => \&binary_arithmetic_multiply,
	'/'   => \&binary_arithmetic_divide,
	'+'   => \&binary_arithmetic_add,
	'-'   => \&binary_arithmetic_subtract,
	'%'   => \&binary_arithmetic_modulus,
	'&&'  => \&binary_logical_and,
	'||'  => \&binary_logical_or,
	'>'   => \&binary_relational_greater_than,
	'<'   => \&binary_relational_less_than,
	'>='  => \&binary_relational_greater_than_or_equal_to,
	'<='  => \&binary_relational_less_than_or_equal_to,
	'=='  => \&binary_equality,
	'!='  => \&binary_inequality,
	'===' => \&binary_case_equality,
	'!==' => \&binary_case_inequality,
	'&'   => \&binary_bitwise_and,
	'|'   => \&binary_bitwise_or,
	'^'   => \&binary_bitwise_xor,
	'~^'  => \&binary_bitwise_xnor,
	'^~'  => \&binary_bitwise_xnor,
	'>>'  => \&binary_right_shift,
	'<<'  => \&binary_left_shift,
	);

############################################################
############################################################
############################################################
############################################################
############################################################


sub binary_operator
{
#print "CALLING binary_operator \n";
 my ($left, $binary_operator, $right) = @_ ;
 my $call = $binary_operator_hash_table{$binary_operator};
 my $ret = &$call($left, $right);
 $ret->trim;
 return $ret;
}


############################################################
############################################################
############################################################
############################################################
############################################################

# the conditional operator in verilog is:
#      expr1 ? cond1 : expr2
# note, that in verilog, expr2 could be another
# conditional operator, which can result in 
# daisy chained conditionals, such as this:
#   output = 
#	8'd0 ? reset :
#	8'd1 ? start :
#	8'd2 ? state1 :
#	8'd3 ? state2 :
#	8'd4;
		


sub conditional_operator
{
 my ($expr1, $cond1, $expr2) = @_;
 my $ret;
 my $bool = $cond1->unary_logical_boolean;
 if ($bool->binary eq '1')
  { $ret = $expr1->copy; }
 else
  { $ret = $expr2->copy; }
 return $ret;
}



############################################################
############################################################
############################################################
############################################################
############################################################

# highest priority					priority
# unary 				+ - ~ !		xxx
# multiply divide modulus		* / %		100
# add subtract				+ -		90
# shift					<< >>		80
# relation				< <= > >=	70
# equality				== != === !==	60
# reduction and				& ~&		50
# reduction xor				^ ~^		40
# reduction or				| ~|		30
# logical and				&&		20
# logical or				||		10
# conditional				?:		xxx
# lowest priority

# note that unary operators and
# conditional (trinary ?:) operators
# are handled separate from this level of priority,
# therefore they are not included in the hash shown below.

my %binary_priority_hash = (
	'||' => 10,
	'&&' => 20,
	'|'  => 30,	'~|' => 30,
	'^'  => 40, 	'~^' => 40,
	'&'  => 50,	'~&' => 50,
	'==' => 60, 	'!=' => 60,   '===' => 60, '!==' => 60,
	'<'  => 70, 	'<=' => 70,   '>'   => 70, '>='  => 70,
	'<<' => 80, 	'>>' => 80,
	'+'  => 90,	'-'  => 90,
	'*'  => 100,	'/'  => 100,  '%' =>100, 
	);

############################################################
############################################################
############################################################
############################################################
############################################################

# given a chain of constant expressions, 
# separated by binary operators,
# evaluate the result using the correct precedence.


# 9 + 49 / -23 * 33 << 3

sub BinaryOperatorChain
{

# print "\n\n CALLING BinaryOperatorChain \n\n\n";

 my ( $obj, @chain_list ) = @_;

 ############################################################
 if(0)
  {
  print "\n\n\n DUMPING LIST \n\n\n";
  foreach my $item (@chain_list)
	 {
	 if (ref($item))
		 {
		 $item->dump;
		 }
	 else
		 { print "operator is  $item \n"; }
	 }
  }
 ############################################################

 ############################################################
 # go through the chain_list and reduce it one operator at a time,
 # taking into account operator precedence and left to right
 # occurence of operators.
 ############################################################
 my $i;
 my $binary_operator;
 my $current_priority;
 my $highest_operator_index;
 my $highest_priority_so_far;

 my $left;
 my $right;
 my $result;
 while( @chain_list > 1 )
	{
	####################################################
	# look at all the operators and find the one
	# with the highest priority.
	# go left to right so that left has higher priority
	####################################################
 	$highest_operator_index = 0;
 	$highest_priority_so_far = 0;
	for($i=1; $i<@chain_list; $i=$i+2)
		{
		$binary_operator = $chain_list[$i];
		$current_priority = $binary_priority_hash{$binary_operator};
		if ($current_priority > $highest_priority_so_far)
			{
			$highest_operator_index = $i;
			}
		}

	####################################################
	# $highest_operator_index points to the operator in
	# @chain_list with the highest priority.
	# take the operator and the two items that surround it,
	# and reduce it to a single value.
	# (i.e. three items in chain_list: '4' '+' '2'
	#  are replaced with one item in chain_list: '6' )
	####################################################
	$left            = $chain_list[$highest_operator_index - 1];
	$binary_operator = $chain_list[$highest_operator_index    ];
	$right           = $chain_list[$highest_operator_index + 1];

	$result = $left->binary_operator($binary_operator, $right);

	splice(@chain_list, $highest_operator_index-1, 3, ($result));
	}


 return $chain_list[0];
}

############################################################
############################################################
############################################################
############################################################
############################################################

