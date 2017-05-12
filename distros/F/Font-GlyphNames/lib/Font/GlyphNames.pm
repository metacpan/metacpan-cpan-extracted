package Font::GlyphNames;

require 5.008;
use strict;
use warnings;

use File::Spec::Functions 'catfile';
use Encode 'decode';

require Exporter;

our($VERSION)   = '1.00000';
our(@ISA)       = 'Exporter';
our(@EXPORT_OK) = qw[
	name2str
	name2ord
	str2name
	ord2name
	ord2ligname
];
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $_obj;  # object used by the function-oriented interface
our @LISTS = qw[ zapfdingbats.txt
                 glyphlist.txt   ];
our @PATH  = split /::/, __PACKAGE__;

use subs qw[
	_read_glyphlist
];


=encoding utf-8

=head1 NAME

Font::GlyphNames - Convert between glyph names and characters

=head1 VERSION

Version 1.00000

=head1 SYNOPSIS

  use Font::GlyphNames qw[
                           name2str
                           name2ord
                           str2name
                           ord2name
                           ord2ligname
                         ];
  # or:
  use Font::GlyphNames ':all';
  
  name2str     qw[one two three s_t Psi uni00D4];
  name2ord     qw[one two three s_t Psi uni00D4];
  str2name     qw[1 2 3 st Ψ Ô];
  ord2name     qw[49 50 51 115 116 936 212];
  ord2ligname  qw[49 50 51 115 116 936 212];

  # Or you can use the OO interface:
  
  use Font::GlyphNames;
  
  $gn = new Font::GlyphNames; # use default glyph list
  $gn = new Font::GlyphNames 'my-glyphs.txt'; # custom list

  $gn->name2ord(qw[ a slong_slong_i s_t.alt ]);
  # etc.
  
=head1 DESCRIPTION

This module uses the Adobe Glyph Naming convention (see L<SEE ALSO>) for converting
between glyph names and characters (or character codes).

=head1 METHODS/FUNCTIONS

Except for C<new> (which is only a method), each item listed 
here is
both a function and a method.

=over 4

=item new ( LIST )

This class method constructs and returns a new Font::GlyphNames object.
If an error occurs, it returns undef (check C<$@> for the error; note
also that C<new()> clobbers any existing value of C<$@>, whether there
is an error or not). LIST is a
list of files to use as a glyph list. If LIST is
omitted, the Zapf Dingbats Glyph List and the Adobe
Glyph List (see L<SEE ALSO>) will be used instead.

=item new \%options

C<new> can also take a hashref of options, which are as follows:

=over 4

=item lists

=item list

(You can specify it with or without the 's'.) Either the name of the file
containing the glyph list, or a reference to an array of file names. In
fact, if you want an object with no glyph list (not that you would), you
can use S<C<< lists => [] >>>.

=item search_inc

If this is set to true, 'Font/GlyphNames/' will be added to the beginning
of each file name, and the files will then be searched for in the folders
listed in C<@INC>.

=item substitute

Set this to a string that you want C<name2str> to output for each invalid
glyph name. The default is C<undef>. (Actually, it doesn't have to be a 
string; it could be anything, but it will be stringified if C<name2str> is
called in scalar context with more than one argument.)

=back

=cut

sub new {
	my($class, $self, $search_inc) = (@_ ? shift : __PACKAGE__, {});
	my(@lists,$found_list);
	if(@_ and ref $_[0] eq 'HASH') {
		for (qw 'lists list') {
			next unless exists $_[0]{$_};
			++$found_list;
			push @lists, ref $_[0]{$_} eq 'ARRAY'
				? @{$_[0]{$_}}
				: $_[0]{$_};
		}
		$search_inc = delete $_[0]{search_inc} if $found_list;
		$$self{subst} = delete $_[0]{substitute};
	}
	elsif(@_) {
		$found_list++;
		@lists = @_;
	}
	unless($found_list) {
		@lists = @{$search_inc = 1, \@LISTS};
	}

	# read the glyph list(s) into $self;
	$$self{name2ord} = {};
	$$self{str2name} = {};
	for my $file (@lists) {
		my(@h,$fh);
	
		if($search_inc) {
			my $f;
			# I pilfered this code from  Unicode::Collate  (and
			# modified it slightly).
			for (@INC) { 
				$f = catfile $_, @PATH, $file;
				last if open $fh, $f;
				$f = undef;
			}
			defined $f or
				$@ = __PACKAGE__ . ": Can't locate " .
				    catfile(@PATH, $file) .
				    " in \@INC (\@INC contains @INC).\n",
				return
		}
		else {
			open $fh, $file
			    or $@= "$file could not be opened: $!",
			       return
		}
	
		local *_;
		my $line; for ($line) {
		while (<$fh>) {
			next if /^\s*(?:#|\z)/;
			s/^\cj//; # for Mac Classic compatibility
			/^([^;]+);\s*([0-9a-f][0-9a-f\s]+)\z/i
			  or $@ = "Invalid glyph list line in $file: $_",
			     return;
			my($name,$codes) = ($1,[map hex, split ' ', $2]);
			exists $$self{name2ord}{$name} or
				$$self{name2ord}{$name} = $codes;
			if(@$codes == 1) {
				my $key = chr $$codes[0];
				exists $$self{str2name}{$key} or 
				    $$self{str2name}{$key} = $name;
			} else {
				my $key = join '', map chr, @$codes;
				exists $$self{str2name}{$key}
					or $$self{str2name}{$key} = $name
			}
		}}
	}
	$ @= '';
	
	bless $self, $class;
}

=item name2str ( LIST )

LIST is a list of glyph names. This function returns a list of the
string equivalents of the glyphs in list context. In scalar context the
individual elements of the list are concatenated. Invalid glyph
names and names beginning with a dot (chr 0x2E) produce undef. Some 
examples:

  name2str   's_t'             # returns 'st'
  name2str qw/Psi uni00D4/     # returns ("\x{3a8}", "\xd4")
  name2str   '.notdef'         # returns undef
  name2str   'uni12345678'     # returns "\x{1234}\x{5678}"
  name2str qw/one uni32 three/ # returns ('1', undef, '3')

If, for invalid glyph names, you would like something other than undef 
(the null char, for instance), you can either use the OO interface and the
C<substitute> option to L</new>, or replace it afterwards like this:

  map +("\0",$_)[defined], name2str ...

=cut

sub name2str {
	my $self = &_get_self;
	my(@names,@ret,$str) = @_;
	for(@names) {
		s/\..*//s;
		$str = undef;
		for (split /_/) {
			# Here we check each type of glyph name
			if (exists $$self{name2ord}{$_}) {
				$str .= join '', map chr, 
					@{$$self{name2ord}{$_}};
			}
			elsif (/^uni( 
				  (?: #non-surrogate codepoints:
				    [0-9A-CEF][0-9A-F]{3}
				      |
				    D[0-7][0-9A-F]{2}
				  )+
				)\z/x) {
				$str .= decode 'UTF-16BE', pack 'H*', $1;
			}
			elsif (/^u(
				  0{0,2}[0-9A-CEF][0-9A-F]{3}
				    |	
				  0{0,2}D[0-7][0-9A-F]{2}
				    |
				  (?:0?(?!0)|1(?=0))[0-9A-F]{5}
				)\z/x) {
				$str .= chr hex $1;
			}
			else {
				no warnings 'uninitialized';
				defined $str ? $str .= $$self{subst} :
				              ($str  = $$self{subst});
			}
		}
		push @ret, defined $str ? $str : $$self{subst};
	}
	no warnings 'uninitialized';
	wantarray ? @ret : @ret > 1 ? join '', @ret : $ret[-1];
}


=item name2ord ( LIST )

LIST is a list of glyph names. This function returns a list of the
character codes that the glyphs represent. If called in scalar context
with more than one argument, the behaviour is undefined (and subject to
change in future releases). Invalid glyph
names and names beginning with a dot (chr 0x2E) produce -1. Some 
examples:

  name2ord   's_t'             # returns 115, 116
  name2ord qw/Psi uni00D4/     # returns 0x3a8, 0xd4
  name2ord   '.notdef'         # returns -1
  name2ord   'uni12345678'     # returns 0x1234, 0x5678
  name2ord qw/one uni32 three/ # returns 49, -1, 51

=cut

sub name2ord {
	my $self = &_get_self;
	my(@names,@ret) = @_;
	for(@names) {
		s/\..*//s;
		$_ = ' ' unless $_; # make sure split returns something
		for (split /_/) {
			# Here we check each type of glyph name
			# It would be nice to avoid duplicating this logic,
			# but I think it runs faster this way.
			if (exists $$self{name2ord}{$_}) {
				push @ret, @{$$self{name2ord}{$_}};
			}
			elsif (/^uni( 
				  (?: #non-surrogate codepoints:
				    [0-9A-CEF][0-9A-F]{3}
				      |
				    D[0-7][0-9A-F]{2}
				  )+
				)\z/x) {
				push @ret, unpack 'n*', pack 'H*', $1;
			}
			elsif (/^u(
				  0{0,2}[0-9A-CEF][0-9A-F]{3}
				    |	
				  0{0,2}D[0-7][0-9A-F]{2}
				    |
				  (?:0?(?!0)|1(?=0))[0-9A-F]{5}
				)\z/x) {
				push @ret, hex $1;
			}
			else {
				push @ret, -1;
			}
		}
	}
	@ret == 1 ? $ret[-1] : @ret ;
}


=item str2name ( LIST )

LIST is a list of strings. This function returns a list of glyph names that
correspond to all the arguments passed to it. If a string is more than one
character long, the resulting glyph name will be a ligature name. An empty
string will return '.notdef'. If called
in scalar context
with more than one argument, the behaviour is undefined (and subject to
change in future releases).

  str2name 'st'               # returns   's_t'
  str2name "\x{3a8}", "\xd4"  # returns qw/Psi Ocircumflex/
  str2name "\x{3a8}\xd4"      # returns   'Psi_Ocircumflex'
  str2name "\x{1234}\x{5678}" # returns   'uni12345678'
  str2name "\x{05D3}\x{05B9}" # returns   'daletholam'

=cut

sub str2name {
	my $self = &_get_self;
	my(@strs,@ret) = @_;
	my $map = $$self{str2name};
	for(@strs) {
		if(length > 1) {
			if (exists $$map{$_}) {
				push @ret, $$map{$_};
			}else{
				my @components;
				my $uni_component; # whether the previous
				for(split //) {    # component was a ‘uni-’
					if (exists $$map{$_}){
						push @components,
							$$map{$_} ;
						$uni_component =0;
					} elsif((my $ord = ord) > 0xffff) {
						push @components,
							sprintf "u%X",$ord;
						$uni_component =0;
					} elsif($uni_component) {
						$components[-1] .=
							sprintf"%04X",ord;
					} else {
						push @components,
							sprintf"uni%04X",
								ord;
						++$uni_component;
					}
				}
				push @ret, join '_', @components;
			}
		}
		elsif(length) {
			my $ord = ord;
			push @ret, exists $$map{$_}
				? $$map{$_}
				:  sprintf $ord > 0xffff ?"u%X":"uni%04X",
					$ord;
		}else { push @ret, '.notdef' }
	}
	@ret == 1 ? $ret[-1] : @ret ;
}


=item ord2name ( LIST )

LIST is a list of character codes. This function returns a list of glyph
names that
correspond to all the arguments passed to it. If called
in scalar context
with more than one argument, the behaviour is undefined (and subject to
change in future releases).

  ord2name 115            # returns 's'
  ord2name 0x3a8, 0xd4    # returns 'Psi', 'Ocircumflex'
  ord2name 0x1234, 0x5678 # returns 'uni1234', 'uni5678'

=cut

sub ord2name {
	my $self = &_get_self;
	my(@codes,@ret) = @_;
	my $map = $$self{str2name};
	for(@codes) {
		my $char = chr;
		push @ret, exists $$map{$char}
			? $$map{$char}
			:  sprintf $_ > 0xffff ?"u%X":"uni%04X",
				$_;
	}
	@ret == 1 ? $ret[-1] : @ret ;
}


=item ord2ligname ( LIST )

LIST is a list of character codes. This function returns a glyph
name for a ligature that
corresponds to the arguments passed to it, or '.notdef' if there are none.

  ord2ligname 115, 116       # returns 's_t'
  ord2ligname 0x3a8, 0xd4    # returns 'Psi_Ocircumflex'
  ord2ligname 0x1234, 0x5678 # returns 'uni12345678'
  ord2ligname 0x05D3, 0x05B9 # returns 'daletholam'

=cut

sub ord2ligname {
	my $self = &_get_self;
	my(@codes) = @_;
	my $map = $$self{str2name};
	my $str = join '', map chr, @codes;
	exists $$map{$str} and return $$map{$str};
	my @components;
	my $uni_component; # whether the previous
	for(@codes) {      # component was a ‘uni-’
		my $char = chr;
		if (exists $$map{$char}){
			push @components,
				$$map{$char} ;
			$uni_component =0;
		} elsif( $_ > 0xffff ) {
			push @components,
				sprintf "u%X",$_;
			$uni_component =0;
		} elsif($uni_component) {
			$components[-1] .=
				sprintf"%04X",$_;
		} else {
			push @components,
				sprintf"uni%04X",
					$_;
			++$uni_component;
		}
	}
	return @components ? join '_', @components : '.notdef';
}


=back

=cut
   



#----------- A PRIVATE SUBROUTINE ---------------#

# _get_self helps the methods act as functions as well.
# Each function should call it thusly:
#	my $self = &_get_self;
# The object (if any) will be shifted off @_.
# If there was no object in @_, $self will refer to $_obj (a
# package var.)

sub _get_self {
	UNIVERSAL::isa($_[0], __PACKAGE__)
	?	shift
	:	($_obj ||= new);
}


#----------- THE REST OF THE DOCUMENTATION ---------------#

=pod

=head1 THE GLYPH LIST FILE FORMAT

B<Note:> This section is not intended to be normative. It simply
describes how this module parses glyph list files--which works with
those provided by Adobe.

All lines that consist solely of
whitespace or that have a sharp sign (#) preceded only by whitespace
(if any) are ignored. All others lines must consist of the glyph name
followed by a semicolon, and the character numbers in hex, separated
and optionally
surrounded by whitespace. If there are multiple character numbers, the
glyph is understood to represent a sequence of characters. The line
breaks must be either CRLF sequences 
(as in
Adobe's
lists) or native line breaks.
If a glyph name occurs more than once, the first instance
will be
used.


=head1 COMPATIBILITY

This module requires perl 5.8.0 or later.

=head1 BUGS

Please e-mail me if you find any.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2006-8, Father Chrysostomos <name2str qw[s p r o u t at c p a n
period o r g]>

=head1 SEE ALSO

=over 4

=item B<Unicode and Glyph Names> 

L<http://partners.adobe.com/public/developer/opentype/index_glyph.html>

=item B<Glyph Names and Current Implementations>

L<http://partners.adobe.com/public/developer/opentype/index_glyph2.html>

=item B<Adobe Glyph List>

L<http://partners.adobe.com/public/developer/en/opentype/glyphlist.txt>

=item B<ITC Zapf Dingbats Glyph List>

L<http://partners.adobe.com/public/developer/en/opentype/zapfdingbats.txt>

=cut




