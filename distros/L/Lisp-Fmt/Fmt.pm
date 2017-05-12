# -*- perl -*-

# Copyright (c) 1998 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Function: Lisp format
#
# $Id: Fmt.pm,v 1.1 1998/08/31 23:50:12 jaw Exp jaw $
# 
# LICENSE: at end
# DOCUMENTATION: at end
#

package Lisp::Fmt;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(fmt pfmt);
$VERSION = "0.01";

use vars qw($accum $argno @arglist $VERSION);
use strict;

### config options

# lisp's notion of false differs from that of perl
# you may or may not want 0 be considered false...
# this effects ~:[ and ~@[
my($config_zero_is_false) = 0;

# X3J13 is ambiguous on how to align the middle columns of <>
# set this to 'r', 'l', or 'c'
my($config_align_middle)  = 'l';

# turn on verbose debugging output, most run 0 through 2
my($verbose_tok)    = 0;
my($verbose_parse)  = 0;
my($verbose_reduce) = 0;
my($verbose_run)    = 0;
my($verbose_fmt)    = 0;

### end of config options

################################################################
### No user servicable parts below this point
################################################################

### tokenize the format spec
sub tok {
    my( $s ) = @_;
    my( $fulls ) = $s;
    my( @s );
    my( @t );
    my( $len ) = length($s);
    my( $soff, $eoff );

    while( $s ){
	print STDERR "T: $s\n" if $verbose_tok;
	
	if( $s =~ /^([^~]+)/ && $1 ){
	    print STDERR "T-> $1 <$'>\n" if $verbose_tok > 1;
	    $soff = $len - length($s) - 1;
	    $s = $';
	    $eoff = $len - length($s) - 1;
	    
	    # add literal
	    push @t, {
		directive => 'literal',
		text      => $1,
		fullfmt   => $fulls,
		fmtoffset => $eoff,
		fmtstart  => $soff,
	    };
	}

	elsif( $s =~ /^~(<{2,}|>{2,}|\|{2,})/ && $1 ){
	    # perl-esque format spec ~<<<<<< ~>>>>>>> ~||||||
	    # NB: must be at least 3 long (eg ~<<) to avoid confusion with ~|, ~< and ~>
	    my( $p ) = $1;
	    print STDERR "T-> $1 {$'}\n" if $verbose_tok > 1;
	    $soff = $len - length($s) - 1;
	    $s = $';
	    $eoff = $len - length($s) - 1;

	    push @t, {
		directive => 'A',
		numbers   => [ length($1)+1 ],
		gravity   => ( $p =~ /</ ) ? 'l' : (( $p =~ />/ ) ? 'r' : 'c'),
		fullfmt   => $fulls,
		fmtoffset => $eoff,
		fmtstart  => $soff,
	    };
	}

        elsif( $s =~ /^~(((-?\d*|v|\#|\'.)(,(-?\d*|v|\#|\'.))*)?	# comma sep. list of params
			([\@:!]*)					# optional @ ! and :
			([^=\@:!\'v\#]|\n\s*|=.))/x			# directive
	      && $1 ){
	    my($ns, $sp, $f)   = ($2, $6, $7);
	    print STDERR "T-> $f; <$ns>; $sp <$'>\n" if $verbose_tok > 1;
	    $soff = $len - length($s) - 1;
	    $s = $';
	    $eoff = $len - length($s) - 1;
	    my(@n) = split ',', $ns;
	    foreach (@n){
		if( /^\'(.*)$/ ){
		    $_ = $1;
		}
	    }

	    # add it
	    push @t, {
		numbers   => [@n],
		directive => uc($f),
		atsign    => ($sp =~ /@|!/) ? 1 : 0,	# because we have to \@, we allow ! as a synonym
		colon     => ($sp =~ /:/)   ? 1 : 0,
		fullfmt   => $fulls,
		fmtoffset => $eoff,
		fmtstart  => $soff,
	    };
	}
    }

    @t;
}


### parse the tokenized format string
sub parse {
    my( @t ) = @_;
    my( $t );
    my( $i ) = 0;
    my( $tnext );
    
    $tnext = sub {
	return undef if( $i >= @t );
	return $t[ $i ++ ];
    };

    parser('', 1, $tnext);
}

sub parser {
    my( $term, $n, $tnext ) = @_;
    my( $t, @tt );
    
    while( 1 ){
	$t = &$tnext();
	
	if( $term && ! $t ){
	    # error ESARAHCONNOR - no terminator
	    $t = $tt[0];
	    formaterror("I see no matching $term here", $t);
	    return ;
	}
	
	return \@tt unless $t;

	print STDERR "PP", "<"x$n,  ": $t->{directive}\n" if $verbose_parse;
	
	return \@tt if( $t->{'directive'} eq $term );
	
	if( $t->{'directive'} eq '[' ){
	    print STDERR "PP->[\n" if $verbose_parse > 1;
	    my( $l ) = parser(']', $n+1, $tnext);
	    my( @l ) = @{$l};
	    my( @nn, @ll );
	    my( $n ) = 0;

	    while( @l ){
		$l = shift @l;
		if( $l->{'directive'} eq ";" ){
		    push @nn, [@ll];
		    $t->{'default_item'} = ($n+1) if $l->{'colon'};
		    @ll = ();
		    $n++;
		}else{
		    push @ll, $l;
		}
	    }
	    push @nn, [@ll];
	    
	    $t->{'subparts'} = \@nn;
	    print STDERR "PP->]\n" if $verbose_parse > 1;
	}
	
	if( $t->{'directive'} eq '<' ){
	    print STDERR "PP-><\n" if $verbose_parse > 1;
	    my( $l ) = parser('>', $n+1, $tnext);
	    my( @l ) = @{$l};
	    my( @nn, @ll );
	    my( $n ) = 0;

	    while( @l ){
		$l = shift @l;
		if( $l->{'directive'} eq ";" ){
		    push @nn, [@ll];
		    @ll = ();
		    $n++;
		}else{
		    push @ll, $l;
		}
	    }
	    push @nn, [@ll];
	    
	    $t->{'subparts'} = \@nn;
	    print STDERR "PP->>\n" if $verbose_parse > 1;
	}

	if( $t->{'directive'} eq '{' ){
	    print STDERR "PP->{\n" if $verbose_parse > 1;
	    my( $b ) = parser('}', $n+1, $tnext);

	    if( @{$b} != 0 ){
		$t->{'body'} = $b;
	    }
	    print STDERR "PP->}\n" if $verbose_parse > 1;
	}

	if( $t->{'directive'} eq '(' ){
	    print STDERR "PP->(\n" if $verbose_parse > 1;
	    $t->{'body'} = parser(')', $n+1, $tnext);
	    print STDERR "PP->)\n" if $verbose_parse > 1;
	}
	
	if( $t->{'directive'} eq '/' ){
	    my( $tt );
	    $tt = &$tnext();
	    $tt->{'directive'} eq 'literal' || return formaterror("I was expecting a function name. Pity.", $tt);
	    $t->{'funcname'} = $tt->{'text'};
	    $tt = &$tnext();
	    $tt->{'directive'} eq '/' || return formaterror("I see no matching / here", $tt);
	}

	if( $t->{'directive'} eq '=(' ){
	    print STDERR "PP->=(\n" if $verbose_parse > 1;
	    $t->{'body'} = parser('=)', $n+1, $tnext);
	    print STDERR "PP->=)\n" if $verbose_parse > 1;
	}
	
	push @tt, reduce($t);
	
    }
}

### the optimizer - simplify parse tree
sub reduce {
    my( $t ) = @_;
    my( @n );
    my( $d );

    $d = $t->{'directive'};
    print STDERR "R: $d\n" if $verbose_reduce;
    
    # collapse all numbers together
    if( $d =~ /^[DOXBR]$/ ){
	$t->{'directive'} = 'number';
	$t->{'radix'} = 10  if $d eq "D";
	$t->{'radix'} =  8  if $d eq "O";
	$t->{'radix'} = 16  if $d eq "X";
	$t->{'radix'} =  2  if $d eq "B";
	
	# NB: radix could end up 'v' or '#'
	
	if( $d eq "R" ){
	    @n = @{$t->{'numbers'}};
	    $t->{'radix'} = shift @n;
	    $t->{'numbers'} = [ @n ];
	    if( ! $t->{'radix'} ){
		if( $t->{'atsign'} ){
		    $t->{'directive'} = 'roman';
		}else{
		    $t->{'directive'} = 'english';
		}
	    }
	}
	print STDERR "R-> number, $t->{'radix'}\n" if $verbose_reduce > 1;
    }

    if( $d =~ /^[ASW]$/ ){
	$t->{'directive'} = 'A';
	$t->{'how'} = $d eq 'A' ? 0 : 1;
    }
    
    # convert to literal or repeated text
    if( $d =~ /^[%_|~]$/ ){
	my( $c, $n );
	
	@n = @{$t->{'numbers'}};
	$n = shift @n || "";
	$n = 1 if $n eq "";

	$c = "";
	$c = " "  if $d eq "_";
	$c = "~"  if $d eq "~";
	$c = "\n" if $d eq "%";
	$c = "\f" if $d eq "|";
	
	if( $n !~ /\d/ ){
	    $t->{'directive'} = "repeat";
	    $t->{'text'} = $c;
	}else{
	    $t->{'text'} = $c x $n;
	    $t->{'directive'} = "literal";
	}
	print STDERR "R-> $d rewrite $t->{'directive'}\n" if $verbose_reduce > 1;
    }
    
    # convert to literal text
    if( $d =~ /^\n/ ){
	my( $sp ) = $d;
	
	$sp =~ s/\n//;
	$t->{'text'} = ($t->{'atsign'} ? "\n" : "") . ($t->{'colon'} ? $sp : "");
	$t->{'directive'} = "literal";
	
	print STDERR "R-> whitespace literal\n" if $verbose_reduce > 1;
    }
    
    $t;
}

sub formaterror {
    my( $msg, $t ) = @_;
    my( $fmt );

    $fmt = $t->{'fullfmt'};
    $fmt =~ s/\n/\$/g;
    print STDERR "\n## FORMAT ERROR: $msg\n";
    print STDERR "## \t\"", $fmt, "\"\n";
    print STDERR "## \t ", " " x $t->{'fmtoffset'}, "^\n";
    
    "error";
}

my($_fmtobja, $_fmtobjs) = ("","");
sub objecttostring {
    my( $how, $obj ) = @_;

    if( ref($obj) ){
	if( ref($obj) eq "SCALAR"){
	    if( $how ){
		fmt( "\\~s", $$obj );
	    }else{
		fmt( "\\~a", $$obj );
	    }
	}elsif( ref($obj) eq "CODE"){
	    # is it possible to do anything more useful?
	    "CODE";
	}elsif( ref($obj) eq "GLOB"){
	    "GLOB";
	}else{
	    my( $fmta, $fmtb );
	    # recursively call fmt, to nicely render lists (refs)
	    
	    if( $how ){
		$_fmtobjs = compile( "~#[~;~s~:;~!{~#[~;~s~:;~s, ~]~}~]" ) unless $_fmtobjs;
		$fmtb = $_fmtobjs;
	    }else{
		$_fmtobja = compile( "~#[~;~a~:;~!{~#[~;~a~:;~a, ~]~}~]" ) unless $_fmtobja;
		$fmtb = $_fmtobja;
	    }

	    # should I do anything with the package name?
	    $fmta = "<~?>";
	    $fmta = "[~?]" if ref($obj) eq "ARRAY";
	    $fmta = "{~?}" if ref($obj) eq "HASH";
	    fmt($fmta, $fmtb, $obj);
	}
    }elsif( $obj =~ /^[+-]?\d+$/ ){
	"$obj";
    }elsif( $obj =~ /^[+-]\d*\.\d*$/ ){
	"$obj";
    }else{
	if( $how ){
	    qq("$obj");
	}else{
	    "$obj";
	}
    }
}

sub formatstring {
    my( $how, $mincol, $colinc, $minpad, $padchar, $ovchar, $gravity, $obj ) = @_;
    my( $str ) = objecttostring($how, $obj);
    my( $l, $w, $padamt, $maxcolp );

    $padchar = chr($padchar) if( $padchar =~ /^\d+$/ );
    $ovchar  = chr($ovchar)  if( $ovchar  =~ /^\d+$/ );
    
    print STDERR "F: $how, MC:$mincol, C:$colinc, MP:$minpad, P:$padchar, OV:$ovchar, G:$gravity, O:$obj\n"
	if $verbose_fmt;

    $l = length($str) + $minpad;
    $w = abs($mincol?$mincol:0);
    $padamt  = $colinc * int((($w - $l) + $colinc - 1) / $colinc);
    $maxcolp = ($mincol ne "") && ($mincol < 0);

    print STDERR "F: $l, $w, $padamt, $maxcolp, $str\n" if $verbose_fmt;

    # and minimum padding
    if( $gravity eq "r" ){
	$str = $padchar x $minpad . $str;
    }elsif( $gravity eq "l" ){
	$str .= $padchar x $minpad;
    }
    
    if( $l == $w ){
	# Happy Happy, Joy Joy!
    }elsif( $l > $w ){
	# You can't fit this five-foot clam through that little passage!
	if( $maxcolp ){
	    my( $fl ) = $w - 1;
	    if( $gravity eq "r" ){
		$str =~ s/^(.{$fl}).*$/$1$ovchar/;
	    }else{
		$str =~ s/^(.{$fl}).*$/$ovchar$1/;
	    }
	}
    }else{
	# too short - pad
	if( $gravity eq "r" ){
	    $str = $padchar x $padamt . $str;
	}elsif( $gravity eq "l" ){
	    $str .= $padchar x $padamt;
	}else{
	    my($rp, $lp);
	    $rp = int(  ($w - $l) / 2 );
	    $lp = $w - $l - $rp;
	    $str = $padchar x $lp . $str . $padchar x $rp;
	}
    }
    $str;
}

sub formatnumber {
    my( $radix, $mincol, $padchar, $commachar,
       $commawidth, $ovchar, $withsign, $withcommas, $val ) = @_;
    my( $str, $sign, @cs );

    $str = "";
    $val = int($val);
    if( $val < 0 ){
	$val = - $val;
	$sign = "-";
    }elsif( $withsign ){
	$sign = "+";
    }else{
	$sign = "";
    }

    # convert to desired radix
    if( $radix == 1 ){
	# special case
	$str = "1" x $val;
    }else{
	@cs = split //,"0123456789abcdefghijklmnopqrstuvwxyz";
	while( $val ){
	    $str = $cs[ $val % $radix ] . $str;
	    $val = int( $val / $radix );
	}
    }

    # add commas
    if( $withcommas ){
	1 while $str =~ s/^(-?\d+)(\d{$commawidth})/$1$commachar$2/;
    }

    formatstring(0, $mincol, 1, 0, $padchar, $ovchar, "r", "$sign$str");
}

sub roman {
    my( $oldway, $val ) = @_;
    my( $rc, $rv, $i, $str );
    my( @rc, @rv );
    
    @rc = qw(/M /D /C /L /X /V M D C L X V I);
    @rv = qw(1000000 500000 100000 50000 10000 5000 1000 500 100 50 10 5 1 0 0);
    $i = 0;
    $str = '';
    
    while($val){
	
	if( $val >= $rv[$i] ){
	    $str .= $rc[$i];
	    $val -= $rv[$i];

	}elsif( $val <= $rv[$i+1] ){
	    $i++;

	}elsif( !$oldway && ($i&1)==0 && ($val >= ($rv[$i] - $rv[$i+2])) ){
	    $str .= $rc[$i+2];
	    $str .= $rc[$i];
	    $val -= $rv[$i] - $rv[$i+2];

	}elsif( !$oldway && ($i&1)!=0 && ($val >= ($rv[$i] - $rv[$i+1])) ){
	    $str .= $rc[$i+1];
	    $str .= $rc[$i];
	    $val -= $rv[$i] - $rv[$i+1];

	}else{
	    $i ++;
	}
    }
    $str;
}

sub englishsmall {
    my($ordinal, $val) = @_;
    my($n, $str);
    my(@units, @ounits, @tens, @otens);

    @units  = qw(zero one two three four five six seven eight nine
	      ten eleven twelve thirteen fourteen fifteen sixteen
	      seventeen eighteen nineteen);
    @ounits = qw(zeroth first second third fourth fifth sixth seventh
		 eighth ninth tenth eleventh twelfth);
    @tens  = qw(twenty thirty forty fifty sixty seventy eighty ninety);
    @otens = qw(twentieth thirtieth fortieth fiftieth sixtieth seventieth eightieth ninetieth);
    unshift @tens, "";  unshift @tens, ""; 
    unshift @otens, ""; unshift @otens, ""; 

    $str = "";
    if( $val >= 100 ){
	$str .= " " . $units[ $val / 100 ] . " hundred";
	$val %= 100;
	$str .= "th" if $ordinal && !$val;
    }

    if( $val >= 20 ){
	$n = $val % 10;
	if( $ordinal && !$n ){
	    $str .= " " . $otens[ $val / 10 ];
	}else{
	    $str .= " " . $tens[ $val / 10 ];
	}
	$val = $n;
    }

    if( $val ){
	if( $ordinal ){
	    if( $val < @ounits ){
		$str .= " " . $ounits[$val];
	    }else{
		$str .= " " . $units[$val] . "th";
	    }
	}else{
	    $str .= " " . $units[$val];
	}
    }

    $str =~ s/^ //;
    $str;
}

sub english {
    my($ordinal, $val) = @_;
    my(@illions);
    my($ordd, $f);
    
    @illions = qw(thousand million billion trillion quadrillion quintillion
		  sextillion septillion octillion nonillion decillion undecillion
		  duodecillion tredecillion quattuordecillion quindecillion
		  sexdecillion septdecillion octodecillion novemdecillion vigintillion);
    unshift @illions, "";
    
    $f = sub {
    	my($val, $k) = @_;
    	my($n, $r, $str);

	$str = "";
    	$n = $val % 1000;
    	$r = int($val / 1000);

    	if( $r ){
    	    $str .= &$f($r, $k + 1);
    	    if( $n ){
    		if( !$k && ($n < 100) ){
    		    $str .= " and ";
    		}else{
    		    $str .= ", ";
    		}
    	    }
    	}
    
    	if( $n ){
    	    my($o);
    	    $o = $ordinal && ($k==0);
    	    $ordd = 1 if($o);
    	    $str .= englishsmall($o , $n);
    	}
    
    	if( $k && $n ){
    	    $str .= " ";
    	    if( $k > @illions ){
    		$str .= "times ten to the " . english(1, $k * 3);
    	    }else{
    		$str .= $illions[ $k ];
    	    }
    	}
	$str;
    };

    if( ! $val ){
	if( $ordinal ){
	    return "zeroth";
	}else{
	    return "zero";
	}
    }elsif( $val < 0 ){
	return "minus " . english($ordinal, - $val);
    }else{
	&$f($val, 0) . (($ordinal && !$ordd) ? "th" : "");
    }
}
    
sub falsep {
    my($val) = @_;

    if( $config_zero_is_false ){
	$val ? 0 : 1;
    }else{
	$val eq "";
    }
}

sub mkarray {
    my( $a )  = @_;
    my( @a );

    if( $a =~ /ARRAY/ ){
	@a = @{$a};
    }elsif( $a =~ /HASH/ ){
	@a = %{$a};
    }else{
	@a = ( $a );
    }
    @a;
}

sub capitalize {
    my( $s ) = @_;

    $s = ucfirst(lc($s));
    $s =~ s/\b(\w)/\U$1/g;
    $s;
}
	
sub nextarg {
    return "" if( $argno >= @arglist );
    return $arglist[ $argno ++ ];
}

sub pound {
    return 0 if( $argno >= @arglist );
    return @arglist - $argno;
}

sub param {
    my( $t, $nth, $dfl ) = @_;
    my( $n, @n );

    @n = @{$t->{'numbers'}};
    return $dfl if( $nth >= @n );
    $n = $n[ $nth ];

    return nextarg() if( $n eq "v" );
    return pound()   if( $n eq "#" );

    return $dfl if $n eq "";		# no n, dfl

    $n;
}

### run the compiled format
sub run {
    my( $t ) = @_;
    my( $d, @t );

    @t = @{$t};
    
    while( @t ){
	$t = shift @t;
	$d = $t->{'directive'};

	print STDERR "U: $d\n" if $verbose_run;

	if( $d eq 'literal' ){
	    $accum .= $t->{'text'};
	    
	}elsif( $d eq 'repeat' ){
	    $accum .= $t->{'text'} x param($t, 0, 1);

	}elsif( $d eq "&" ){
	    my($n) = param($t, 0, 1);

	    next unless $n;
	    $accum .= "\n" unless( $accum =~ /\n$/ );
	    if( $n > 1 ){
		$accum .= "\n" x ($n - 1);
	    }
	    
	}elsif( $d eq "T" ){
	    my($colnum, $colinc, $tabchar);
	    my($l) = $accum;
	    my($cp, $mp);

	    $colnum = param($t,0,1);
	    $colinc = param($t,1,1);
	    $tabchar = param($t,2," ");
	    
	    $l =~ s/.*\n$//;
	    $cp = length $l;
	    $mp = 0;
	    
	    if( $t->{'atsign'} ){
		if( $colinc ){
		    $mp = $colnum + $colinc - (($cp + $colnum) % $colinc);
		}
	    }else{
		$mp = $colnum - $cp;
		if( $mp < 0 ){
		    if( $colinc ){
			$mp = $colnum + $colinc - ($cp % $colinc);
			$mp = $mp - $colinc  if $mp >= $colinc;
		    }
		}
	    }

	    $accum .= $tabchar x $mp;
	    
	}elsif( $d eq 'A' ){
	    # mincol, colinc, minpad, padchr, ovchr, gravity
	    $accum .= 
		formatstring( $t->{'how'}, param($t,0,""), param($t,1,1),
			     param($t,2,0), param($t,3," "),
			     param($t,4,"*"),
			     $t->{'gravity'} || ($t->{'atsign'} ? "r" : "l"),
			     nextarg() );

	}elsif( $d eq '*' ){
	    my( $n ) = param($t, 0, $t->{'atsign'} ? 0 : 1);

	    $n = -$n if( $t->{'colon'} );

	    if( $t->{'atsign'} ){
		$argno = $n;
	    }else{
		$argno += $n;
	    }
	    $argno = 0 if( $argno < 0 );

	}elsif( $d eq '?' ){
	    my( $fmt ) = nextarg();
	    my( $rv );

	    if( $t->{'atsign'} ){
		# use current arglist
		$rv = run( ref($fmt) ? $fmt : compile( $fmt ));
	    }else{
		# nextarg is list of args
		my( $a ) = nextarg();
		local( $argno ) = 0;
		local( @arglist );

		@arglist = mkarray( $a );
		
		$rv = run( ref($fmt) ? $fmt : compile( $fmt ));
	    }
	    return $rv if $rv;
	    
	}elsif( $d eq 'P' ){
	    my( $n );

	    if( $t->{'colon'} ){
		$n = $arglist[ $argno - 1 ];
	    }else{
		$n = nextarg();
	    }

	    if( $n == 1 ){
		$accum .= "y" if $t->{'atsign'};
	    }else{
		if( $t->{'atsign'} ){
		    $accum .= "ies";
		}else{
		    $accum .= "s";
		}
	    }
	    
	}elsif( $d eq 'C' ){
	    my( @cv ) = qw(NUL SOH STX ETX EOT ENQ ACK BEL BS HT NL
			   VT NP CR SO SI DLE DC1 DC2 DC3 DC4 NAK
			   SYN ETB CAN EM SUB ESC FS GS RS US SP);
	    my( $n ) = param($t, 0, "");
	    my( $c, $str );
	    $n = nextarg() if $n eq "";
	    $n = ord($n) unless $n =~ /^\d+$/;
	    $c = chr($n);

	    if( $t->{'colon'} ){
		if( $t->{'atsign'} && $n && $n < 27 ){
		    $str = "Control-" . chr($n+ord('A'));
		}elsif( $n < @cv ){
		    $str = $cv[$n];
		}elsif( $n >= 127 ){
		    if( $t->{'atsign'} ){
			# <shrug>...
			$str = "Meta-" . fmt("~:!C", $n & 127);
		    }else{
			$str = sprintf "\\0%o", $n;
		    }
		}else{
		    $str = $c;
		}
	    }else{
		if( $t->{'atsign'} ){
		    if( ($n >= 127) || ($n < @cv) ){
			$str = sprintf "\"\\0%o\"", $n;
		    }else{
			$str = "\"$c\"";
		    }
		}else{
		    $str = $c;
		}
	    }
	    $accum .= $str;
	    
	}elsif( $d eq '(' ){
	    my( $str, $rv );
	    do {
		local( $accum ) = ("");
		$rv = run( $t->{'body'} );
		$str = $accum;

		if( $t->{'colon'} ){
		    if( $t->{'atsign'} ){
			$str = uc($str);
		    }else{
			$str = capitalize($str);
		    }
		}else{
		    if( $t->{'atsign'} ){
			$str = ucfirst(lc($str));
		    }else{
			$str = lc($str);
		    }
		}
	    };
	    $accum .= $str;
	    return $rv if $rv;

	}elsif( $d eq '/' ){
	    # this is implemented as ~/funcname~/ and not as ~/funcname/
	    # so sue me...
	    my( $func, $str, $p, @p );

	    $func = $t->{'funcname'};
	    foreach $p ( @{$t->{'numbers'}} ){
		$p = pound()   if( $p eq "#" );
		$p = nextarg() if( $p eq "v" );
		push @p, $p;
	    }
	    $str = nextarg();
	    $str = "$func($str, $t->{'colon'}, t->{'atsign'}";
	    $str .= ", " . join(", ", @p) if( @p );
	    $str .= ")";

	    $accum .= eval( $str );
	    
	}elsif( $d eq '<' ){
	    # XXX
	    my( $str, $rv, $n, $s );
	    my( @str );
	    my( $mincol, $colinc, $minpad, $padchar ) =
		(param($t,0,""), param($t,1,1),
		 param($t,2,0), param($t,3," "));
							 
	    
	    do {
		local( $accum );
		# $rv = run( $t->{'subparts'}[0] );
		# $str = $accum;
		
		foreach $s ( @{$t->{'subparts'}} ){
		    $accum = "";
		    $rv = run( $s );
		    last if $rv =~ /hat/;
		    push @str, $accum;
		    $n ++;
		}
	    };

	    if( $n == 1 ){
		$str = formatstring( 0, $mincol, $colinc, $minpad, $padchar, "*",
				    $t->{'atsign'} ? ($t->{'colon'} ? 'c' : 'l') : 'r',
				    $str[0] );

	    }elsif( $n >= 2 ){
		my( $rspace, $lspace, $space, $m );

		$rspace = $mincol;
		$m = 0;
		$str = '';
		foreach $s (@str){
		    $space = $rspace / ( $n - $m );
		    $rspace -= $space;
		
		    $str .= formatstring( 0, $space, $colinc, $m?$minpad:0, $padchar, "*",
					 $m==0 ? ($t->{'colon'} ? 'r' : 'l') :
					  ($m==$n-1 ? ($t->{'atsign'} ? 'l' : 'r') :
					   $config_align_middle),
					 $str[$m]);
		    $m ++;
		}
	    }   
		    
	    
	    $accum .= $str;
	    
	}elsif( $d eq '{' ){
	    my( $maxiter ) = param($t, 0, "");
	    my( $maxiterp ) = $maxiter ne "" ? 1 : 0;
	    my( $retv );
	    my( $body ) = $t->{'body'};

	    if( !$body ){
		$body = nextarg();
		return formaterror("An empty {} may be less filling, but it won't work", $t) unless $body;
		$body = compile($body);
	    }

	    if( $t->{'colon'} && $t->{'atsign'} ){
		# use remaining args, which are sublists

		while( !$maxiterp || $maxiter-- ){
		    my( $a, @a );
		    last if $argno >= @arglist;
		    
		    $a = nextarg();
		    @a = mkarray($a);
		    do {
			local($argno) = 0;
			local(@arglist) = @a;

			$retv = run( $body );
			last if( $retv =~ /colon/ );	# otherwise just this iter
		    };
		}
		
	    }elsif( $t->{'colon'} ){
		# next arg is list of sublists
		my( $a, @a );
		
		$a = nextarg();
		@a = @{$a};

		while( !$maxiterp || $maxiter-- ){
		    last unless @a;
		    do {
			local($argno) = 0;
			local(@arglist) = @{shift @a};

			$retv = run( $body );
			last if( $retv =~ /colon/ );	# otherwise just this iter
		    };
		}

	    }elsif( $t->{'atsign'} ){
		# use remaining args

		while( !$maxiterp || $maxiter-- ){
		    last if $argno >= @arglist;
		    $retv = run( $body );
		    last if( $retv =~ /hat/ );
		}

	    }else{
		# next arg is list of args
		my( $a, @a );

		$a = nextarg();
		@a = mkarray($a);
		do {
		    local($argno) = 0;
		    local(@arglist) = @a;

		    while( !$maxiterp || $maxiter-- ){
			last if $argno >= @arglist;
			$retv = run( $body );
			last if( $retv =~ /hat/ );
		    }
		};
	    }
	    
	}elsif( $d eq '[' ){
	    my( @ch ) = @{$t->{'subparts'}};
	    my( $ni ) = scalar @ch;
	    my( $n ) = param($t, 0, "");
	    my( $rv );
	    $n = nextarg() if $n eq "";

	    if( $t->{'atsign'} ){
		$argno -- if( !falsep($n) );
		$n = !falsep($n) ? 0 : 1;
	    }elsif( $t->{'colon'} ){
		$n = falsep($n) ? 0 : 1;
	    }

	    if( $n >= $ni && (defined $t->{'default_item'} ) ){
		$n = $t->{'default_item'};
	    }

	    if( $n < $ni ){
		my( $str );
		do {
		    local( $accum ) = ("");
		    $rv = run( $t->{'subparts'}[$n] );
		    $str = $accum;
		};
		$accum .= $str;
	    }
	    return $rv if $rv;
	    
	}elsif( $d eq '^' ){
	    my( $np, $out );
	    
	    $np = @{$t->{'numbers'}};

	    if( $np == 1 ){
		$out = 1 if param($t, 0, "") == 0;
	    }elsif( $np == 2 ){
		$out = 1 if param($t, 0, "") == param($t, 1, "");
	    }elsif( $np == 3 ){
		$out = 1 if (param($t, 0, "") <= param($t, 1, ""))
		    && (param($t, 1, "") <= param($t, 2, ""));
	    }else{
		$out = 1 if $argno >= @arglist;
	    }

	    if( $out ){
		return "hat/colon" if( $t->{'colon'} );
		return "hat";
	    }
	    
	}elsif( $d eq 'number' ){
	    my( $r );
	    # $radix, $mincol, $padchar, $commachar, $commawidth, $ovchar, $withsign, $withcommas, $val

	    $r = $t->{'radix'};
	    $r = pound()   if( $r eq "#" );
	    $r = nextarg() if( $r eq "v" );
	    return formaterror("In base $r? I'm game. Would you care to explain how?", $t) if( $r<1 || $r>36 );
	    
	    $accum .=
		formatnumber( $r, param($t,0,""), param($t,1," "),
			     param($t,2,","), param($t,3,3), param($t,4,"*"),
			     ($t->{'atsign'}?1:0), ($t->{'colon'}?1:0),
			     nextarg());
	    
	}elsif( $d eq 'roman' ){
	    $accum .= formatstring(0, param($t,0,""), 1, 0, param($t,1, " "),
				   param($t,4, "*"), "r", 
				   roman($t->{'colon'}, nextarg()));
	    
	}elsif( $d eq 'english' ){
	    $accum .= formatstring(0, param($t,0,""), 1, 0, param($t,1, " "),
				   param($t,4, "*"), "r", 
				   english($t->{'colon'}, nextarg()));

### Non-standard 2 character (=X) directives
	}elsif( $d eq '=V' ){
	    # Version info
	    # ~=:V - long form
	    # ~=:@V - longer form

	    $accum .= "Good morning Dr. Chandra, I am " if $t->{'atsign'};
	    $accum .= "Fmt Version " if $t->{'colon'};
	    $accum .= "$VERSION";
	    
	}elsif( $d eq '=(' ){
	    # "eval" - use results of formatting as a format spec
	    # ~=(...~=)
	    
	    my( $str, $rv, $fmt );
	    do {
		local( $accum ) = ("");
		$rv = run( $t->{'body'} );
		$str = $accum;

		$accum = '';
		$fmt = compile($str);
		$rv = run( $fmt );
		$str = $accum;
		
	    };
	    $accum .= $str;
	    return $rv if $rv;

	}elsif( $d eq '=F' ){
	    # suck in line/lines from a file
	    # ~=F - entire file
	    # ~N=F - just line N
	    # ~N,M=F lines N through M

	    my( $null, $i, $n, $m, $f );

	    $n = param($t,0,'');
	    $m = param($t,1,'');
	    $f = nextarg();
	    $i = 1;
	    open(FMT_FILE, $f) || return formaterror( "'$f' is stubborn and refuses to open: $!", $t);

	    if( $n ne '' ){
		while( $n != $i && !eof(FMT_FILE) ){
		    $null = <FMT_FILE>;
		    $i++;
		}
		if( $m ne '' ){
		    while( $m + 1 != $i++ && !eof(FMT_FILE) ){
			$accum .= <FMT_FILE>;
		    }
		}else{
		    $accum .= <FMT_FILE>;
		}
	    }else{
		$accum .= $_ while( <FMT_FILE> );
	    }
	    close(FMT_FILE);
		

### directives that should not happen (errors)
	}elsif( $d eq ')' ){
	    # error - no start
	    return formaterror( "I see no matching ( here", $t );

	}elsif( $d eq '}' ){
	    # error - no start
	    return formaterror( "I see no matching { here", $t );
	    
	}elsif( $d eq ']' ){
	    # error - no start
	    return formaterror( "I see no matching [ here", $t );

	}elsif( $d eq ';' ){
	    # no enclosing [] or <>
	    return formaterror( "I see no enclosing [] or <> here", $t );
	    
	}else{
	    # error - unknown
	    return formaterror( "I don't know how to apply that word ($d) here.", $t);
	}
    }
    "";
}

### for debugging
sub tree {
    my( $n, $t ) = @_;
    my( $nn, @t, @nn );

    @t = @{$t};
    while( @t ){
	$t = shift @t;
	
	print "  " x $n, "$t->{'directive'}\n";
	tree($n+1, $t->{'body'} ) if( $t->{'body'} );

	if( $t->{'subparts'} ){
	    @nn = @{$t->{'subparts'}};
	    while( @nn ){
		$nn = shift @nn;
		tree($n+1, $nn);
		print "  " x $n, " ;\n";
	    }
	}
    }
}
    
### compile the format spec
sub compile {
    my( $fmt ) = @_;

    parse(tok( $fmt ));
}

### the main entry point
sub fmt {
    my( $fmt ) = shift;
    local( @arglist ) = @_;	# our arglist
    local( $argno ) = 0;	# index into above
    local( $accum ) = "";	# accumulator for output string
    
    run( ref($fmt) ? $fmt : compile($fmt));

    $accum;
}

### format, print to stdout
sub pfmt {
    print fmt(@_);
}

################################################################
################################################################
################################################################

=head1 NAME

Lisp::Fmt - Perl module for Common Lisp like formatting

=head1 SYNOPSIS

    use Lisp::Fmt;
    $str = fmt("~{~a ~5,,,'*a~}", $a,$b,$c,$d);  # store result in $str
    pfmt("~{ ~a~5,,,'*a~}", $a,$b,$c,$d);	 # print to stdout

=head1 DESCRIPTION

The Common Lisp "format" function provides an extremely rich set of formatting
directives. This module brings this to Perl.

The formatting directives all begin with a C<~> and take the form:
    C<~[N]{,N}[@][:]X>

where C<N> is a number, C<X> is a formatting directive, and C<@> and C<:> are
optional modifiers. Recognized directives are: A, S, W, D, O, B, X, R, C, P,
T, ~, %, |, _, ?, *, \n, {, }, (, ), [, ], <, >, ^

examples:
    
    C<~A>		- simplest format spec, prints the arg
    C<~D>		- prints a number in base 10
    C<~X>		- prints a number in base 16
    C<~12R>		- prints a number in base 12
    C<~@R>		- prints a number in roman numerals
    C<~#[ none~; ~a~; ~a and ~a~:;~!{~#[~; and~] ~a~^,~}~].">
 		- prints a list in nice readable english

=head1 FORMAT SPEC

    as a param, a v will read the param from the arglist
    a # will interpolate to the number of remaining args

         the directive can be one of:

    A  print the arg
    S  print the arg in a readable form (strings are quotes,...)
            @ will pad on left
            params are: mincols (maxcols if <0), colinc, minpad, padchar, overflowchar

    ~ print a ~ [N ~s]
    % print a newline [N newlines]
    | print a formfeed [N formfeeds]
    _ print a space [N spaces]
    & print a newline unless already at the beginning of a line
    T tabulate
         @ relative
    	 params are: colnum, colinc
    
    n ignore the newline and any following whitespace
         : newline is ignored, whitespace is left
         @ newline is printed, following whitespce is ignored
    * next arg is ignored, with param, next N args are ignored
         : back up in arg list, with param, backup N args
         @ goto 0th arg, or with a param, Nth arg 
    ? indirect - 2 args are a format string and list of args
         @ - 1 arg - is a format string, use args from current arglist
    
    P pluralize
         @ use y/ies
         : use previous arg
    
    D a number in base 10
    O a number in base 8
    X a number in base 16
    B a number in base 2
    R a number in specified radix (ie. ~7R)
        @ print leading sign
        : print with commas
        params are: mincol, padchar, commachar, commawidth, overflowchar
    
     without a radix specifier:
          in english "four"
       :  in english, ordinal "fourth"
       @  in roman "IV"
       :@ in old roman "IIII"


    C a character
        @ as with write
        : spell out control chars
    
    ( downcase until ~)    - hello world
        @  capitalize the first word  - Hello world
        :  capitalize  - Hello World
        :@ uppercase  - HELLO WORLD
    
    { iteration spec until ~}
        @  use remaining args
        :  arg is list of sublists
        :@ use remaining args, which are sublists
    
    [ conditional spec, separated with ~; ending with ~]
        choose item specified by arg  ~:; is default item
        with a param, chhose with it instead of arg
        @ choose if not false
        : use first item if false, second otherwise
    
    ^ abort ? {} or <> if no args remain,
        or if a param is given, it is 0
        or if 2 params are given, they are equal
        or if 3 params are given, the 1st is <= 2nd <= 3rd
        : terminate an entire :{ or :@{, not just this iteration


For a more complete description of the various formatting directives, parameters, etc.
see your favorite lisp reference, such as
http://www.harlequin.com/education/books/HyperSpec/Body/sec_22-3.html.

=head1 NOTES

! is a synonym for @

Often used format strings can be pre-compiled:
    C<$f = Fmt::compile("~{ ~a ~5,,,'*a~}");>
    C<$str = fmt( $f, ...);>

when lisp says an arg is a "list", we translate that as a reference to a list (or hash)

  lisp: (format () "~{ ~A~}\n" '(a b c d e))
  perl: fmt( "~{ ~A~}\n", ["a", "b", "c", "d"])
        fmt( "~{ key ~A value ~A\n~}", {foo=>1, bar=>2, baz=>3})

=head1 BUGS

Floating-point output is not yet supported.

the <> formatting support is incomplete.

the radix for ~R is restricted to the range 1-36

no test is performed to detect circular data structures

many other bugs not listed here

=head1 CHANGES

none.

=head1 TO DO

see BUGS.

=head1 SEE ALSO

    Common Lisp - The Language 2nd. ed.
    L<http://www.harlequin.com/education/books/HyperSpec/Body/sec_22-3.html>
    Yellowstone National Park.

=head1 AUTHOR

    Jeff Weisberg - http://www.tcp4me.com/code/

=head1 COPYRIGHT

    This software is Copyright (c) 1998 Jeff Weisberg
    Permission is granted to use, copy and distribute this software
    under the following conditions:
    -   This license covers the original software, as well as
 	modified or derived works.
    -   All modified or derived works must contain this notice
        unmodified and in its entirety.
    -   This software is not to be used for any purpose which
 	may be considered illegal, immoral, or unethical.
    -   This software is provided as is and without warranty.

=cut    
    ;

1;
