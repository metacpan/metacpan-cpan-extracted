##################################################################
# Copyright (C) 2000 Greg London   All Rights Reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
##################################################################


##################################################################
package Hardware::Verilog::Parser;
use PrecompiledParser;
use Parse::RecDescent;
use vars qw ( $VERSION  @ISA);
@ISA = ( 'PrecompiledParser' , 'Parse::RecDescent' );
##################################################################
$VERSION = '0.13';
##################################################################

##################################################################
##################################################################
##################################################################
##################################################################

use Benchmark;

##################################################################
sub new
##################################################################
{
 my ($pkg) = @_;

 my $parser = PrecompiledParser->new();

 # bless it as a verilog_parser object
 bless $parser, $pkg;
 return $parser;
} 




#########################################################################
sub decomment_given_text
#########################################################################
{
 my ($obj,$text)=@_;

 my $filtered_text='';

 my $state = 'code';

 my ( $string_prior_to_line_comment, $string_after_line_comment);
 my ( $string_prior_to_block_comment, $string_after_block_comment);
 my ( $string_prior_to_quote, $string_after_quote);
 my ( $comment_string, $string_after_comment);
 my ( $quoted_string, $string_after_quoted_string);

 my $index_to_line_comment=0;
 my $index_to_block_comment=0;
 my $index_to_quote =0;
my $lc_lt_bc;
my $lc_lt_q;
my $bc_lt_q;
my $bc_lt_lc;
my $q_lt_lc;
my $q_lt_bc;

my $could_be_line_comment;
my $could_be_block_comment;
my $could_be_quote;

 while (1)
  {
  #print "#################################################### \n";
  #print "state = $state \n";
  if ($state eq 'code')
	{

	unless ( ($text =~ /\/\*/) or  ($text =~ /\/\//) or ($text =~ /\"/) )
		{ 
		$filtered_text .= $text ;
		last;
		}


	# look for comment or quoted string
	( $string_prior_to_line_comment, $string_after_line_comment)
		= split( '//' , $text, 2 );

	( $string_prior_to_block_comment, $string_after_block_comment)
		= split( /\/\*/ , $text, 2 );

	( $string_prior_to_quote, $string_after_quote)
		= split( /\"/ , $text, 2 );

	$index_to_line_comment = length($string_prior_to_line_comment);
	$index_to_block_comment = length($string_prior_to_block_comment);
	$index_to_quote   = length($string_prior_to_quote  );

	$lc_lt_bc = ($index_to_line_comment  < $index_to_block_comment);
	$lc_lt_q  = ($index_to_line_comment  < $index_to_quote);

	$bc_lt_q  = ($index_to_block_comment < $index_to_quote);
	$bc_lt_lc = ($index_to_block_comment < $index_to_line_comment);

	$q_lt_lc  = ($index_to_quote         < $index_to_line_comment);
	$q_lt_bc  = ($index_to_quote         < $index_to_block_comment);
	
	

	#print "length_remaining_text = $length_of_entire_text \n";
	#print " line_comment index=$index_to_line_comment  ". "text= $string_prior_to_line_comment \n";
	#print "block_comment index=$index_to_block_comment  "."text= $string_prior_to_block_comment \n";
	#print "quote         index=$index_to_quote  ".        "text= $string_prior_to_quote \n";
	#print "\n";

	if($lc_lt_bc and $lc_lt_q)
		{ 
		$state = 'linecomment';
		$filtered_text .= $string_prior_to_line_comment;
		$text = '//' . $string_after_line_comment;
		}

	elsif($bc_lt_q and $bc_lt_lc)
		{ 
		$state = 'blockcomment';
		$filtered_text .= $string_prior_to_block_comment;
		$text = '/*' . $string_after_block_comment;
		}

	elsif($q_lt_lc and $q_lt_bc)
		{
		$state = 'quote'; 
		$filtered_text .= $string_prior_to_quote;
		$text =  $string_after_quote;
		$filtered_text .= '"' ;
		}
	}

  elsif ($state eq 'linecomment')
	{
	# strip out everything from here to the next \n charater
	( $comment_string, $string_after_comment)
		= split( /\n/ , $text, 2  );

	$text = "\n" . $string_after_comment;

	$state = 'code';
	}

  elsif ($state eq 'blockcomment')
	{
	# strip out everything from here to the next */ pattern
	( $comment_string, $string_after_comment)
		= split( /\*\// , $text, 2  );

	$comment_string =~ s/[^\n]//g;

	$text = $comment_string . $string_after_comment;

	$state = 'code';
	}

  elsif ($state eq 'quote')
	{
	# get the text until the next quote mark and keep it as a string
	( $quoted_string, $string_after_quoted_string)
		= split( /"/ , $text, 2  );

	$filtered_text .= $quoted_string . '"' ;
	$text =  $string_after_quoted_string;

	$state = 'code';
	}
  }


 return $filtered_text;

}


#########################################################################
#
# the %define_hash variable keeps track of all `define values.
# it is class level variable because it needs to keep track of
# `defines that may cross file boundaries due to `includes.
# i.e.
# main.v
# `include "defines.inc"
# wire [`width:1] mywire;
#
# defines.inc
# `define width 8
#
# since each included file calls filename_to_text, which in turn
# calls convert_compiler_directives_in_text, the %define_hash cannot
# be declared inside convert_compiler_directives_in_text because it
# will cease to exist once the included file is spliced in.
# for `defines to exists after the included file, the define_hash
# must be class level data.
# it could be stored in $obj->{'define_hash'}, but that seems overkill.
#
#########################################################################
 my %define_hash;

#########################################################################
sub convert_compiler_directives_in_text
#########################################################################
{
 my ($obj,$text)=@_;

 return $text unless ($text=~/`/);

 my $filtered_text='';

 my ( $string_prior_to_tick, $string_after_tick);

my $temp_string;
my ($key, $value);
my $sub_string;

while(1)
	{
	unless ($text =~ /`/) 
		{ 
		$filtered_text .= $text ;
		last;
		}


	( $string_prior_to_tick, $string_after_tick)
		= split( '`' , $text, 2 );

	$filtered_text .= $string_prior_to_tick;

	# if define
	if ($string_after_tick =~ /^define/)
		{
		$string_after_tick =~ /^define\s+(.*)\n/;
		$temp_string = $1;
		($key, $value) = split(/\s+/, $temp_string, 2);
		$define_hash{$key}=$value;

		#print "defining key=$key   value=$value \n";############

		$sub_string = '^define\s+'.$temp_string;

		$string_after_tick =~ s/$sub_string//;
		$text = $string_after_tick;
		}

	# else if `undef
	elsif ($string_after_tick =~ /^undef/)
		{
		$string_after_tick =~ /^undef\s+(\w+)\n/;
		$key = $1;
		$temp_string = '^undef\s+'.$key;
		$string_after_tick =~ s/$temp_string//;

		$define_hash{$key}=undef;
		$text = $string_after_tick;

		#print "undefining key=$key \n";#########
		}

	# else if `include
	elsif ($string_after_tick =~ /^include/)
		{
		$string_after_tick =~ /^include\s+(.*)\n/;
		$temp_string = $1;

		$sub_string = '^include\s+'.$temp_string;
		$string_after_tick =~ s/$sub_string//;

		$temp_string =~ s/"//g;
		# print "including file $temp_string\n";
		$string_after_tick = 
			$obj->filename_to_text($temp_string) .
			$string_after_tick;

		$text = $string_after_tick;
		}

	# else if `timescale
	elsif ($string_after_tick =~ /^timescale/)
		{
		$string_after_tick =~ s/^timescale.*//;

		$text = $string_after_tick;
		}

	# else if `celldefine
	elsif ($string_after_tick =~ /^celldefine/)
		{
		$string_after_tick =~ s/^celldefine.*//;

		$text = $string_after_tick;
		}

	# else if `endcelldefine
	elsif ($string_after_tick =~ /^endcelldefine/)
		{
		$string_after_tick =~ s/^endcelldefine.*//;

		$text = $string_after_tick;
		}

	# else if `suppress_faults
	elsif ($string_after_tick =~ /^suppress_faults/)
		{
		$string_after_tick =~ s/^suppress_faults.*//;

		$text = $string_after_tick;
		}

	# else if `enable_portfaults
	elsif ($string_after_tick =~ /^enable_portfaults/)
		{
		$string_after_tick =~ s/^enable_portfaults.*//;

		$text = $string_after_tick;
		}

	# else if `disable_portfaults
	elsif ($string_after_tick =~ /^disable_portfaults/)
		{
		$string_after_tick =~ s/^disable_portfaults.*//;

		$text = $string_after_tick;
		}

	# else if `suppress_faults
	elsif ($string_after_tick =~ /^suppress_faults/)
		{
		$string_after_tick =~ s/^suppress_faults.*//;

		$text = $string_after_tick;
		}

	# else if `nosuppress_faults
	elsif ($string_after_tick =~ /^nosuppress_faults/)
		{
		$string_after_tick =~ s/^nosuppress_faults.*//;

		$text = $string_after_tick;
		}

	# else if `ifdef
	elsif ($string_after_tick =~ /^ifdef/)
		{
		$string_after_tick =~ /^ifdef\s+(.*)\n/;
		$key = $1;
		$string_after_tick =~ s/^ifdef\s+(.*)\n//;
		$text = $string_after_tick;

		my ($conditional_text,$text_after_conditional)
			= split( '`endif' , $text, 2 );

		my ($true_text, $false_text);

		if( $conditional_text =~ /`else/ )
			{
			($true_text, $false_text) = 
				split('`else', $conditional_text, 2);

			}
		else
			{
			$true_text = $conditional_text;
			$false_text = '';

			}




		if(defined($define_hash{$key}))
			{
			$text = $true_text . $text_after_conditional;
			}
		else
			{
			$text = $false_text . $text_after_conditional;
			}
		}


	# else must be a defined constant, replace `NAME with $value
	else
		{
		$string_after_tick =~ /^(\w+)/;
		my $key = $1;
		unless(	defined($define_hash{$key}) )
			{die "undefined macro `$key\n";}
		$string_after_tick =~ s/$key//;
		$value = $define_hash{$key};
		
		$filtered_text .= $value;

		$text = $string_after_tick;
		#print "replacing key=$key   value=$value\n";#######

		}
	}

 return $filtered_text;
}

#########################################################################
sub Filename
#########################################################################
{
 my $obj = shift;

 while(@_)
	{
	my $filename = shift;
	print "\n\nparsing filename $filename \n\n\n";
	print STDERR "\n\nparsing filename $filename \n\n\n";
 	my $text = $obj->filename_to_text($filename);

	#print "\n\n\ntext to parse is \n$text\n\n\n\n";


	my $tstart = new Benchmark;
 	$obj->design_file($text);
	my $tstop = new Benchmark;

	if(1)
		{
		my $line_count = $obj->count_number_of_lines($text);
		print "line count is $line_count\n";
	
		$t = timediff($tstop,$tstart);
		my $time_string = timestr($t);
		print "timit result is ", $time_string , "\n";

		my $cpu_sec;
		$time_string =~ /(\d+\.\d+) usr/;
		$cpu_sec = $1;
		if(defined($cpu_sec))
			{
			if($cpu_sec<0.99)
				{$cpu_sec = 1;}

			print "using $cpu_sec seconds parse time\n";
			$lines_per_second = $line_count / $cpu_sec ;
			$lines_per_second_two_dec_places = 
				sprintf("%10.2f",  $lines_per_second);
			print "parse_rate is $lines_per_second_two_dec_places lines/sec ";
			print sprintf (" ( %12d / %10.2f ) ", $line_count, $cpu_sec);
			print " $filename ";
			print "\n";
			}
		else
			{
			warn "could not extract cpu time\n";
			$cpu_sec = 10000000;
			}
		}
	}
}

#########################################################################
sub count_number_of_lines
#########################################################################
#
{
 my ($obj,$text)=@_;
 my @list = split(/\n/,$text);
 my $val = @list;
 return $val;
}


#########################################################################
sub SearchPath
#########################################################################
{
 my $obj = shift;
 my @path;
 if(@_)
  {
  while(@_)
   {
   push(@path,shift(@_));
   }
  $obj->{'SearchPath'} = \@path;
  }
 @path = @{$obj->{'SearchPath'}};
 return @path;
}

#########################################################################
sub search_paths_for_filename
#########################################################################
{
 my ($obj,$filename)=@_;

 # if filename contains any '/' or '\' characters,
 # assume it already contains a path. dont bother with search.
 if ( ($filename =~ /\//) or ($filename =~ /\\/) )
	{
	return $filename;
	}

 # if no search path specified, dont bother looking.
 unless(defined($obj->{'SearchPath'}))
	{
	return $filename;
	}

 # get search path, go through each entry, 
 # see if file exists in that area.
 my @paths =  @{$obj->{'SearchPath'}};
 foreach my $path (@paths)
  {
  if(-e $path.$filename)
	{
	print "found $filename in path $path \n";
	return $path.$filename;
	}
  }

 # couldn't find it, report error
 my $string = "Could not find $filename in search path: ";
 foreach my $path (@paths)
  {
  $string .= " $path, ";
  }
 $string .= "\n";
 die $string;
 
}

#########################################################################
sub filename_to_text
#########################################################################
#
{
 my ($obj,$filename)=@_;
 my $full_path_name = $obj->search_paths_for_filename($filename);
 open (FILE, $full_path_name) or 
	die "Cannot open file for reading: $full_path_name\n";
 my $text;
 while(<FILE>)
  {
  $text .= $_;
  }

 $text = $obj->decomment_given_text($text);
 $text = $obj->convert_compiler_directives_in_text($text);

 return $text;
}


##################################################################
##################################################################
##################################################################
##################################################################




##################################################################
##################################################################
##################################################################
##################################################################

1;

##################################################################
##################################################################
##################################################################
##################################################################

__END__

=head1 NAME

Hardware::Verilog::Parser - A complete grammar for parsing Verilog code using perl

=head1 SYNOPSIS

  use Hardware::Verilog::Parser;
  $parser = new Hardware::Verilog::Parser;

  $parser->Filename(@ARGV);

=head1 DESCRIPTION

This module defines the complete grammar needed to parse any Verilog code.
By overloading this grammar, it is possible to easily create perl scripts
which run through Verilog code and perform specific functions.

For example, a Hierarchy.pm uses Hardware::Verilog::Parser to overload the
grammar rule for module instantiations. This single modification
will print out all instance names that occur in the file being parsed.
This might be useful for creating an automatic build script, or a graphical
hierarchical browser of a Verilog design.

This module is currently in alpha release. All code is subject to change.
Bug reports are welcome.


DSLI information:


D - Development Stage

	a - alpha testing

S - Support Level

	d - developer

L - Language used

	p - perl only, no compiler needed, should be platform independent

I - Interface Style

	O - Object oriented using blessed references and / or inheritance




=head1 AUTHOR

Copyright (C) 2000 Greg London   All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

email contact: greg42@bellatlantic.net

=head1 SEE ALSO

Parse::RecDescent, version 1.77

perl(1).

=cut

