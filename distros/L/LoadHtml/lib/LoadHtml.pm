package LoadHtml;

#use lib '/home1/people/turnerj';

use strict;
#no strict 'refs';
use vars (qw(@ISA @EXPORT $useLWP $err $rtnTime $VERSION));

require Exporter;
#use LWP::Simple;
eval 'use  LWP::Simple; $useLWP = 1;';
#use Socket;

@ISA = qw(Exporter);
@EXPORT = qw(loadhtml_package loadhtml buildhtml dohtml modhtml AllowEvals cnvt set_poc 
		SetListSeperator SetRegices SetHtmlHome);

our $VERSION = '7.08';

local ($_);

local $| = 1;
my $calling_package = 'main';    #ADDED 20000920 TO ALLOW EVALS IN ASP!

my $poc = 'your website administrator';
my $listsep = ', ';
my $evalsok = 0;
my %cfgOps = (
	hashes => 0,
	CGIScript => 0,
	includes => 1,
	loops => 1,
	numbers => 1,
	pocs => 0,
	perls => 0,
	embeds => 0,
);   #ADDED 20010720.
my ($htmlhome, $roothtmlhome, $hrefhtmlhome, $hrefcase);

sub SetListSeperator
{
	$listsep = shift;
}

sub cnvt
{
	my $val = shift;
	return ($val eq '26') ? ('%' . $val) : (pack("c",hex($val)));
}

sub set_poc
{
	$poc = shift || 'your website administrator';
	$cfgOps{pocs} = 1;
}

sub SetRegices
{
	my (%setregices) = @_;
	my ($i, $j);

	foreach $j (qw(hashes CGIScript includes embeds loops numbers pocs perls))
	{
		if ($setregices{"-$j"})
		{
			$cfgOps{$j} = 1;
		}
		elsif (defined($setregices{"-$j"}))
		{
			$cfgOps{$j} = 0;
		}
	}
}

sub loadhtml
{
	my %parms = ();
	my $html = '';

	local ($/) = '\x1A';

	if (&fetchparms(\$html, \%parms, 1, @_))
	{
		print &modhtml(\$html, \%parms);
		return 1;
	}
	else
	{
		print $html;
		return undef;
	}
}

sub buildhtml
{
	my %parms = ();
	my $html = '';

	local ($/) = '\x1A';
	return &fetchparms(\$html, \%parms, 1, @_) ? &modhtml(\$html, \%parms) : $html;
}

sub dohtml
{
	my %parms = ();
	my $html = '';

	return &fetchparms(\$html, \%parms, 0, @_) ? &modhtml(\$html, \%parms) : $html;
}

sub fetchparms
{
	my $html = shift;
	my $parms = shift;
	my $fromFile = shift;
	my ($parm0) = shift;
	
	my ($v, $i, $t);
	
#	%loopparms = ();

	%{$parms} = ();
	$$html = '';

	$i = 1;
	$parms->{'0'} = $parm0;
	while (@_)
	{
		$v = shift;
		$parms->{$i++} = (ref($v)) ? $v : "$v";
		last  unless (@_);
		if ($v =~ s/^\-([a-zA-Z]+)/$1/)
		{
			$t = shift;
			if (defined $t)   #ADDED 20000523 PREVENT -W WARNING!
			{
				$parms->{$i} = (ref($t)) ? $t : "$t";
			}
			else
			{
				$parms->{$i} = '';
			}
			$parms->{$v} = $parms->{$i++};
		}
	}

	unless ($fromFile)
	{
		$$html = $parm0;
		return ($$html) ? 1 : 0;
	}

	if (open(HTMLIN,$parm0))
	{
		$$html = (<HTMLIN>);
		close HTMLIN;
	}
	else
	{
		$$html = LWP::Simple::get($parm0)  if ($useLWP);
		unless(defined($$html) && $$html =~ /\S/o)
		{
			$$html = &html_error("Could not load html page: \"$parm0\"!");
			return undef;
		}
	}
	return 1;
}

sub AllowEvals
{
	$evalsok = shift;
}

sub makaswap
{
	my $parms = shift;
	my $one = shift;

	return ("\:$one")  unless (defined($one) && defined($parms->{$one}));
	if (ref($parms->{$one}) =~ /ARRAY/o)   #JWT, TEST LISTS!
	{
		return defined($listsep) ? (join($listsep,@{$parms->{$one}})) : ($#{$parms->{$one}}+1);
	}
	elsif ($parms->{$one} =~ /(ARRAY|HASH)\(.*\)/o)   #FIX BUG.
	{
		return ('');   #JWT, TEST LISTS!
	}
	else
	{
		return ($parms->{$one});
	}
	#ACTUALLY, I DON'T THINK THIS IS A BUG, BUT RATHER WAS A PROBLEM
	#WHEN $#PARMS > $#LOOPPARMS, PARMS WITH VALUE='' IN A LOOP WOULD
	#NOT GET SUBSTITUTED DUE TO IF-CONDITION 1 ABOVE, BUT WOULD LATER
	#BE SUBSTITUTED AS SCALERS BY THE GENERAL PARAMETER SUBSTITUTION
	#REGEX AND THUS GET SET TO "ARRAY(...)".  CONDITION-2 ABOVE FIXES THIS.
};

sub makamath   #ADDED 20031028 TO SUPPORT IN-PARM EXPRESSIONS.
{
	my ($one) = shift;

	$_ = eval $one;
	return $_;
};

sub makaloop
{
	my ($parms, $parmnos, $loopcontent, $looplabel) = @_;
#print "---makaloop: args=".join('|',@_)."=\n";
	my $rtn = '';
	my ($lc,$i0,$i,$j,%loopparms);
	my (@forlist);   #MOVED UP 20030515. - ORDERED LIST OF ALL HASH KEYS (IFF DRIVING PARAMETER IS A HASHREF).
	$parmnos =~ s/\:(\w+)([\+\-\*]\d+)/eval(&makaswap($parms,$1).$2)/egs;   #ALLOW OFFSETS, ie. ":#+1"		$parmnos =~ s/\:(\w+)/&makaswap($parms,$1)/egs;    #ALLOW ie. <!LOOP 1..:1>
	$parmnos =~ s/\:(\w+)/&makaswap($parms,$1)/egs;   #ALLOW OFFSETS, ie. ":#+1"		$parmnos =~ s/\:(\w+)/&makaswap($parms,$1)/egs;    #ALLOW ie. <!LOOP 1..:1>
	$parmnos =~ s/[\:\(\)]//go;
	$parmnos =~ s/\s+,/,/go;
	$parmnos =~ s/,\s+/,/go;
	my @vectorlist = ();     #THE ORDERED LIST OF INDICES TO ITERATE OVER (ALWAYS NUMBERS):
#	if ($parmnos =~ s/([a-zA-Z]+)\s+([a-zA-Z])/$2/)    #CHANGED TO NEXT LN (20070831) TO ALLOW UNDERSCORES IN ITERATOR PARAMETER NAMES.
	if ($parmnos =~ s/([a-zA-Z][a-zA-Z_]*)\s+([a-zA-Z])/$2/)
	{
#print "<BR>-LOADHTML: 1=$1= param=$$parms{$1}=\n";  #JWT:ADDED EVAL 20120309 TO PREVENT FATAL ERROR IF REFERENCE ARRAY MISSING!:
		eval { @vectorlist = @{$parms->{$1}} };     #WE HAVE AN INDEX LIST PARAMETER (<!LOOP index arg1,arg2...>)
#print "<BR>-???- 1st arg=$1=		VECTOR=".join('|',@vectorlist)."=\n";
	}
	elsif ($parmnos =~ s/(\d+\,\d+)((?:\,\d+)*)\s+([a-zA-Z])/$3/)    #WE HAVE A LITERAL INDEX LIST (<!LOOP 2,3,5,4 arg1,arg2...>)
	{
		eval "\@vectorlist = ($1 $2);";
	}
	$parmnos =~ s/\s+/,/go;

	my (@listparms) = split(/\,/o, $parmnos);
#1ST IF-CHOICE ADDED 20070807 TO SUPPORT AN INDEX ARRAY OF HASH KEYS W/DRIVING PARAMETER OF TYPE HASHREF:
	if (ref($parms->{$listparms[0]}) eq 'HASH' && defined($vectorlist[0]) && defined(${$parms->{$listparms[0]}}{$vectorlist[0]}))
	{
#print "<BR>-???- 1st is HASH:  VECTOR=".join('|',@vectorlist)."=\n";
		#INDEX ARRAY CONTAINS HASH-KEYS AND 1ST (DRIVING) VECTOR IS A HASHREF:
		@forlist = sort keys(%{$parms->{$listparms[0]}});
		my @keys = @vectorlist;
		@vectorlist = ();
		for (my $i=0;$i<=$#keys;$i++)
		{
			for (my $j=0;$j<=$#forlist;$j++)
			{
				if ($keys[$i] eq $forlist[$j])
				{
					push (@vectorlist, $j);
					last;
				}
			}
		}
		$i0 = scalar @vectorlist;   #NUMBER OF LOOP ITERATIONS TO BE DONE.
	}
	elsif (defined($vectorlist[0]) && $vectorlist[0] =~ /^\d+$/o)
	{
#print "<BR>-???2- VL=".join('|',@vectorlist)."=\n";
		#INDEX ARRAY OF JUST NUMBERS:
		if (ref($parms->{$listparms[0]}) eq 'HASH')
		{
			@forlist = sort keys(%{$parms->{$listparms[0]}});
		}
		$i0 = scalar @vectorlist;
	}
	else   #NO INDEX LIST, SEE IF WE HAVE INCREMENT EXPRESSION (ie. "0..10|2"), ELSE DETERMINE FROM 1ST PARAMETER:
	{
#print "<BR>-???3- NO INDEX LIST! vl0=$vectorlist[0]=\n";
		my ($istart) = 0;
		my ($iend) = undef;
		my ($iinc) = 1;
		my $parmnos0 = $parmnos;
		$istart = $1  if ($parmnos =~ s/([+-]?\d+)\.\./\.\./o);
		$iend = $1  if ($parmnos =~ s/\.\.([+-]?\d+)//o);
		$parmnos =~ s/\.\.//o;      #ADDED 19991203 (FIXES "START.. ").
		$iinc = $1  if ($parmnos =~ s/\|([+-]?\d+)//o);
		$parmnos =~ s/^\s*\,//o;    #ADDED 19991203 (FIXES "START.. ").
		shift @listparms  unless ($parmnos eq $parmnos0);   #1ST LISTPARM IS THE INCREMENT EXPRESSION, REMOVE IT NOW.
		if (ref($parms->{$listparms[0]}) eq 'HASH')
		{
			@forlist = sort keys(%{$parms->{$listparms[0]}});
			if ($#vectorlist >= 0) {       #THIS IF ADDED 20070914 TO SUPPORT ALTERNATELY SORTED LIST TO DRIVE HASH-DRIVEN LOOPS:
				my @keys = @vectorlist;   #IE. <!LOOP listparm hashparm, ...>
				@vectorlist = ();
				for (my $i=0;$i<=$#keys;$i++)
				{
					for (my $j=0;$j<=$#forlist;$j++)
					{
						if ($keys[$i] eq $forlist[$j])
						{
							push (@vectorlist, $forlist[$j]);
							last;
						}
					}
				}
				@forlist = @vectorlist;
			}
			$iend = $#forlist  unless (defined $iend);
#print "<BR>-???- 1ST ARG IS HASH:  VL=".join('|',@vectorlist)."= FL=".join('|',@forlist)."=\n";
		}
		else
		{
#no strict 'refs';
#print "<BR>-???- lp=".join('|',@listparms)."= parm0=$parms->{$listparms[0]}=\n";
#print "<BR>-REF=".ref($parms->{$listparms[0]})."=\n";
			unless (defined $iend)
			{
				$iend = (ref($parms->{$listparms[0]}) eq 'ARRAY'
				    ? $#{$parms->{$listparms[0]}} : 0);
			}
#print "<BR>-iend=$iend=\n";
		}
		@vectorlist = ();
		$i = $istart;
		$i0 = 0;
		while (1)
		{
			if ($istart <= $iend)
			{
				last  if ($i > $iend || $iinc <= 0);
			}
			else
			{
				last  if ($i < $iend || $iinc >= 0);
			}
			push (@vectorlist, $i);
			$i += $iinc;
			++$i0;
		}
	}

	my $icnt = 0;
	foreach $i (@vectorlist)
	{
		$lc = $loopcontent;
		foreach $j (keys %{$parms})
		{
			#if (@{$parms->{$j}})  #PARM IS A LIST, TAKE ITH ELEMENT.
			if (" @listparms " =~ /\s$j\s/)
			{
				#@parmlist = @{$parms->{$j}};
				if (ref($parms->{$j}) =~ /HASH/io)   #ADDED 20020613 TO ALLOW HASHES AS LOOP-DRIVERS!
				{
					#WANT_VALUES: $loopparms{$j} = $parms->{$j}->{(keys(%{$parms->{$j}}))[$i]};
					#$loopparms{$j} = (keys(%{$parms->{$j}}))[$i];  #CHGD. TO NEXT 20030515
					$loopparms{$j} = ${$parms->{$j}}{$forlist[$i]};
#						$lc =~ s/\:\%${looplabel}/$forlist[$i]/eg;  #MOVED TO 302l 20070713 ADDED 20031212 TO MAKE :%_loopname HOLD KEY OF 1ST HASH!
				}
				elsif (ref($parms->{$j}) =~ /ARRAY/io)  #TEST ADDED SO FOLLOWING SWITCHES COULD BE ADDED 20070615
				{
					$loopparms{$j} = ${$parms->{$j}}[$i];
				}
				elsif ($parms->{$j} =~ /^\$(\w+)/o)
				{
					#ADDED THIS ELSIF AND NEXT ELSE 20070615 TO 
					#PLAY NICE W/$dbh->selectall_arrayref()
					#SO WE CAN PASS A 2D ROW-BASED MATRIX OF DB DATA 
					#AND ACCCESS EACH COLUMN AS A NAMED PARAMETER BY
					#SPECIFYING: "-fieldname => '$matrix->[*][2]'"
					#WHERE "matrix" IS THE DRIVING LOOP PARAMETER NAME
					#AND "*" IS REPLACED BY NEXT SUBSCRIPT IN LOOP.
					#THIS *AVOIDS* HAVING TO CONVERT ROW-MAJOR ARRAYS 
					#TO COLUMN-MAJOR AND PASSING EACH COLUMN SLICE!
					my $one = $1;
					my $eval = $parms->{$j};
#					$eval =~ s/\*/$i/g;   #CHGD. TO NEXT 20070831 TO ALLOW RECURSION, IE. '$matrix->[*][*][0]', ETC.
					$eval =~ s/\*/$i/;
					my $eval0 = $eval;    #ADDED 20070831 TO SAVE FOR POSSIBLE REGRESSION.
					$eval =~ s/$one/parms\-\>\{$one\}/;
					$loopparms{$j} = eval $eval;
#print "\n---- j=$j= parm=$parms->{$j}= eval=$eval= lp now=$loopparms{$j}= at=$@=\n";
#					$loopparms{$j} = $parms->{$j}  if ($@);   #CHGD. TO NEXT 20070831 TO ALLOW RECURSION, IE. '$matrix->[*][*][0]', ETC.
					if ($@)
					{
						$eval0 =~ s/(?:\-\>)?\[\d+\]//;  #STRIP OFF HIGH-ORDER DIMENSION SO THAT REFERENCE IS CORRECT W/N THE RECURSIVE CALL TO MAKALOOP!
						$loopparms{$j} = $eval0;
#print "-!!!- regressing back to lp=$loopparms{$j}=\n";
					}
				}
				else
				{
					$loopparms{$j} = $parms->{$j};
				}
				$loopparms{$j} = ''  unless(defined($loopparms{$j}));
			}
			else   #PARM IS A SCALER, TAKE IT'S VALUE.
			{
				$loopparms{$j} = $parms->{$j};
			}
		}
#print "<BR>-???- ll=$looplabel= lc=$lc=\n";
# (:# = CURRENT INDEX NUMBER INTO PARAMETER VECTORS; :* = ZERO-BASED ITERATION#; :% = CURRENT HASH KEY, IFF DRIVEN BY A HASHREF; :^ = NO. OF ITERATIONS TO BE DONE)
		$lc =~ s#<\!\:\%(${looplabel})([^>]*?)>#&makanop2($parms,$forlist[$i],$2)#egs;  #MOVED HERE 20070713 FROM 267l TO MAKE :%_loopname HOLD KEY OF 1ST HASH!
		$lc =~ s/\:\%${looplabel}/$forlist[$i]/egs;  #MOVED HERE 20070713 FROM 267l TO MAKE :%_loopname HOLD KEY OF 1ST HASH!
		$lc =~ s#<\!\:\#(${looplabel})([^>]*?)>#&makanop2($parms,$i,$2)#egs;
		$lc =~ s/\:\#${looplabel}([\+\-\*]\d+)/eval("$i$1")/egs;   #ALLOW OFFSETS, ie. ":#+1"
		$lc =~ s/\:\#${looplabel}/$i/egs;
		$lc =~ s#<\!\:\^(${looplabel})([^>]*?)>#&makanop2($parms,$i0,$2)#egs;
		$lc =~ s/\:\^${looplabel}([\+\-\*]\d+)/eval("$i0$1")/egs;   #CHGD. 20020926 FROM :* TO :^.
		$lc =~ s/\:\^${looplabel}/$i0/egs;
		$lc =~ s#<\!\:\*(${looplabel})([^>]*?)>#&makanop2($parms,$icnt,$2)#egs;
		$lc =~ s/\:\*${looplabel}([\+\-\*]\d+)/eval("$icnt$1")/egs;   #ADDED 20020926 TO RETURN INCREMENT NUMBER (1ST = 0);
		$lc =~ s/\:\*${looplabel}/$icnt/egs;
#foreach my $x (sort keys %loopparms) { print "<BR>-loopparm($x)=$loopparms{$x}=\n"; };
#print "<BR>--------------\n";

		#IF-STMT BELOW ADDED 20070830 TO EMULATE Template::Toolkit's ABILITY TO REFERENCE
		#SUBCOMPONENTS OF A REFERENCE BY NAME, IE:

		#-arg => {'id' => 'value', 'name' => 'value'}
		#...
		#<!LOOP arg, id, name>
		if (ref($parms->{$listparms[0]}) eq 'HASH')
		{
			foreach $j (@listparms)
			{
				unless (defined $loopparms{$j})
				{
#print "<BR>-!!!- will convert $j w/1st parm a HASH! i=$i= j=$j= F=$forlist[$i]= lp0=$listparms[0]= parm=$parms->{$listparms[0]}= val=$parms->{$listparms[0]}{$forlist[$i]}=\n";
					$lc =~ s#<\!\:$j([^>]*?)\:>.*?<\!\:\/\1>#&makanop1($parms->{$listparms[0]}{$forlist[$i]},$j,$1)#egs;
					$lc =~ s#<\!\:$j([^>]*?)>#&makanop1($parms->{$listparms[0]}{$forlist[$i]},$j,$1)#egs;
					$lc =~ s/\:\{$j\}/&makaswap($parms->{$listparms[0]}{$forlist[$i]},$j)/egs;   #ALLOW ":{word}"!
				}
			}
		}
		elsif (ref($parms->{$listparms[0]}) eq 'ARRAY')
		{
			foreach $j (@listparms)
			{
				unless (defined $loopparms{$j})
				{
#print "<BR>-!!!- will convert $j w/1st parm an ARRAY! i=$i= j=$j=  parm=$parms->{$listparms[0]}= val=$parms->{$listparms[0]}[$i]=\n";
					$lc =~ s#<\!\:$j([^>]*?)\:>.*?<\!\:\/\1>#&makanop1($parms->{$listparms[0]}[$i],$j,$1)#egs;
					$lc =~ s#<\!\:$j([^>]*?)>#&makanop1($parms->{$listparms[0]}[$i],$j,$1)#egs;
					$lc =~ s/\:\{$j\}/&makaswap($parms->{$listparms[0]}[$i],$j)/egs;   #ALLOW ":{word}"!
				}
			}
		}
		$rtn .= &modhtml(\$lc,\%loopparms);
		++$icnt;
	}

#	$i += $iinc;    #NEXT 2 REMOVED 20070809 - DON'T APPEAR TO BE NEEDED.
#	++$i0;
	return ($rtn);
};

sub makasel           #JWT: REDONE 05/20/1999!
{
	my ($parms, $selpart,$opspart,$endpart) = @_;

	local *makaselop = sub
	{
		my ($selparm,$padding,$valuparm,$valu,$dispvalu) = @_;
		$valu =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;      #ADDED 19991206
		$dispvalu =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;  #ADDED 19991206
		$valu = $dispvalu  unless ($valuparm);  #ADDED 05/17/1999
		my ($res) = "$padding<OPTION";
		if ($valuparm)
		{
			$res .= $valuparm . '"' . $valu . '"';
			$dispvalu = $valu . $dispvalu  unless ($dispvalu =~ /\S/);
		}
		else
		{
			$valu = $dispvalu;
			$valu =~ s/\s+$//o;
		}
		$res .= '>' . $dispvalu;
		if (ref($parms->{$selparm}) =~ /ARRAY/o)   #JWT, IF SELECTED IS A LIST, CHECK ALL ELEMENTS!
		{
			my ($i);
			for ($i=0;$i<=$#{$parms->{$selparm}};$i++)
			{
				if ($valu eq ${$parms->{$selparm}}[$i])
				{
					$res =~ s/\<OPTION/\<OPTION SELECTED/io;
					last;
				}
			}
		}
		else
		{
			$res =~ s/\<OPTION/\<OPTION SELECTED/io  if ($valu eq $parms->{$selparm});
		}
		return $res;
	};

	#my ($rtn) = $selpart;  #CHGD TO NEXT LINE 05/17/1999
	my ($rtn);
	#if ($opspart =~ s/\s*\:(\w+)// || $selpart =~ s/\:(\w+)\s*>$//)  
	#CHANGED 12/18/98 TO PREVENT 1ST OPTION VALUE :# FROM DISAPPEARING!  JWT.

	if ($selpart =~ s/\:(\w+)\s*>$//o)
	{
		$selpart .= '>';
		my $selparm = $1;
		my ($opspart2);
		$opspart =~ s/SELECTED//gio;
		while ($opspart =~ s/(\s*)<OPTION(?:(\s+VALUE\s*\=\s*)([\"\'])([^\3]*?)\3[^>]*)?\s*\>([^<]*)//is)
		{
			$opspart2 .= &makaselop($selparm,$1,$2,$4,$5);
		}
		$opspart = $opspart2;
	}
	$rtn = $selpart . $opspart . $endpart;
	return ($rtn);
};

sub fetchinclude
{
	my $parms = shift;
	my ($fidurl) = shift;
	my ($modhtmlflag) = shift;
	my $tag = shift;
	my %includeparms;    #NEXT 6 ADDED 20030206 TO SUPPORT PARAMETERIZED INCLUDES!
	while (@_)
	{
		$_ = shift;
		$_ =~ s/\-//o;
		$includeparms{$_} = shift;
	}

	my ($html,$rtn);

	#$fidurl =~ s/\:(\w+)/&makaswap($1)/eg;      #JWT 05/19/1999
	$fidurl =~ s/^\"//o;          #JWT 5 NEXT LINES ADDED 1999/08/31.
	$fidurl =~ s/\"\s*$//o;
	$fidurl =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;
	if (defined($roothtmlhome) && $roothtmlhome =~ /\S/o)
	{
		$fidurl =~ s#^(?!(/|\w+\:))#$roothtmlhome/$1#ig;
	}
	#$fidurl =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;  #JWT 20010703: MOVED ABOVE PREV. IF
	if (open(HTMLIN,$fidurl))
	{
		$html = (<HTMLIN>);
		close HTMLIN;
	}
	else
	{
		$html = LWP::Simple::get($fidurl)  if ($useLWP);
		unless(defined($html) && $html =~ /\S/o)
		{
			$rtn = &html_error(">Could not include html page: \"$fidurl\"!");
			return ($rtn);
		}
	}
	if ($tag)  #ADDED 20060117 TO ALLOW PARTIAL FILE INCLUDES BASED ON TAGS.
	{
		$html =~ s/^.*\<\!\-\-\s+BEGIN\s+$tag\s*\-\-\>//is or $html = '';
		$html =~ s#\<\!\-\-\s+END\s+$tag\s*\-\-\>.*$##is;
	}
	#$rtn = &modhtml(\$html, %parms);  #CHGD. 20010720 TO HANDLE EMBEDS.
	#return ($rtn);
	#return $modhtmlflag ? &modhtml(\$html, %parms) : $html;  #CHD 20030206 TO SUPPORT PARAMETERIZED INCLUDES.
	return $modhtmlflag ? &modhtml(\$html, {%{$parms}, %includeparms}) : $html;
};

sub doeval
{
	my ($expn) = shift;
	my ($fid) = shift;
	if ($fid)
	{
		my ($dfltexpn) = $expn;
		$fid =~ s/^\s+//o;
		$fid =~ s/^.*\=\s*//o;
		$fid =~ s/[\"\']//go;
		$fid =~ s/\s+$//o;
		if (open(HTMLIN,$fid))
		{
			my @expns = (<HTMLIN>);
			$expn = join('', @expns);
			close HTMLIN;
		}
		else
		{
			$expn = LWP::Simple::get($fid)  if ($useLWP);
			unless (defined($expn) && $expn =~ /\S/o)
			{
				$expn = $dfltexpn;
				return (&html_error("Could not load embedded perl file: \"$fid\"!"))
				unless ($dfltexpn =~ /\S/o);
			}
		}
	}
	$expn =~ s/^\s*<!--//o;   #STRIP OFF ANY HTML COMMENT TAGS.
	$expn =~ s/-->\s*$//o;
	return ('')  if ($expn =~ /\`/o);   #DON'T ALLOW GRAVS!
#	return ('')  if ($expn =~ /\Wsystem\W/o);   #DON'T ALLOW SYSTEM CALLS - THIS NOT GOOD WAY TO DETECT!

	$expn =~ s/\&gt/>/go;	
	$expn =~ s/\&lt/</go;	

	$expn = 'package htmlpage; ' . $expn;
	my $x = eval "$expn";
	$x = "Invalid Perl Expression - returned $@"  unless (defined $x);
	return ($x);
};

sub dovar
{
	my $var = shift;
	my $two = shift;
	$two =~ s/^=//o;
	#$var = substr($var,0,1) . 'main::' . substr($var,1)  unless ($var =~ /\:\:/);
	#PREV. LINE CHANGED 2 NEXT LINE 20000920 TO ALLOW EVALS IN ASP!
	#$var = substr($var,0,1) . $calling_package . '::' . substr($var,1)  unless ($var =~ /\:\:/);
	#PREV. LINE CHGD. TO NEXT 20031006 TO FIX "${$VAR}...".
	$var =~ s/\$(\w)/\$$calling_package\:\:$1/g;
	my $one = eval $var;
	$one = $two  unless ($one);
	return $one;
};

sub makabutton
{
	my ($parms,$pre,$one,$two,$parmno,$four) = @_;
	my ($rtn) = "$pre$one$two$parmno$four";
	my ($myvalue);

	local *setbtnval = sub
	{
		my ($one,$two,$three) = @_;
		#$two =~ s/\:(\w+)/&makaswap($parms,$1)/eg;   #CHGD 19990527. JWT.
		$two =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;
		$myvalue = "$two";
		return ($one.$two.$three);
	};
	if ($two =~ /VALUE\s*=\"[^\"]*\"/io || $one =~ /CHECKBOX/io)
	{
		$two =~ s/(VALUE\s*=\")([^\"]*)(\")/&setbtnval($1,$2,$3)/ei;
		$rtn = "$pre$one$two$parmno$four";
#		$rtn =~ s/CHECKED//i  if (defined($myvalue)); #JWT:CHGD. TO NEXT: 19990609!
#		$rtn =~ s/CHECKED//io  if (defined($parms->{$parmno})); #JWT:CHGD. TO NEXT: 20100830 (v7.05)!
		$rtn =~ s/\bCHECKED\b//io  if (defined($parms->{$parmno}));
		#if ((defined($myvalue) && $parms->{$parmno} eq $myvalue) || ($one =~ /CHECKBOX/i && $parms->{$parmno} =~ /\S/))
		if (ref($parms->{$parmno}) eq 'ARRAY')  #NEXT 9 LINES ADDED 20000823
		{                                     #TO FIX CHECKBOXES W/SAME NAME 
			foreach my $i (@{$parms->{$parmno}})   #IN LOOPS!
			{
				if ($i eq $myvalue)
				{
					$rtn =~ s/\:$parmno/ CHECKED/;
					last;
				}
			}
			$rtn =~ s/\:$parmno//;
		}
		#elsif ((defined($parms->{$parmno}) && defined($myvalue) && $parms->{$parmno} eq $myvalue) || ($one =~ /CHECKBOX/i && $parms->{$parmno} =~ /\S/)) #JWT: 19990609! - CHGD. 2 NEXT 20041020!
		elsif ((defined($parms->{$parmno}) && defined($myvalue) && $parms->{$parmno} eq $myvalue) || (!defined($myvalue) && $one =~ /CHECKBOX/io && $parms->{$parmno} =~ /\S/o))
		{	#NOTE:  IF NO "VALUE=" IS SPECIFIED, THEN CHECKED UNLESS PARAMETER IS EMPTY/UNDEFINED!!
			$rtn =~ s/\:$parmno/ CHECKED/;
		}
		else
		{
			$rtn =~ s/\:$parmno//;
		}
#print "<BR>-loadhtml: myvalue=$myvalue= parmno=$parmno= parmval=".$parms->{$parmno}."= rtn=$rtn=\n";
	}
	else
	{
		$rtn =~ s/\:$parmno//;
	}
	return ($rtn);
};

sub makatext
{
	my $parms = shift;
	my $one = shift;
	my $parmno = shift;
	my $dflt = shift;

	my $val;
	my $rtn = $one;
	if (defined($parms->{$parmno}))
	{
		$val = $parms->{$parmno};
	}
	elsif ($dflt =~ /\S/o)
	{
		$dflt =~ s/^\=//o;
		$dflt =~ s/\"(.*?)\"/$1/;
		$val = $dflt;
	}
	if (defined($val))
	{
		if ($rtn =~ /\sVALUE\s*=/io)
		{
			$rtn =~ s/(\sVALUE\s*=\s*\").*?\"/$1 . $val . '"'/ei;
		}
		else
		{
			$rtn = $one . ' VALUE="' . $val . '"';
		}
	}
	return ($rtn);
};

sub makanif
{
	my ($parms,$regex,$ifhtml,$nestid) = @_;

	my ($x) = '';
	my ($savesep) = $listsep;

	$regex =~ s/\&lt/</gio;
	$regex =~ s/\&gt/>/gio;
	$regex =~ s/\&le/<=/gio;
	$regex =~ s/\&ge/>=/gio;
	$regex =~ s/\\\%/\%/gio;
	$listsep = undef;

	$regex =~ s/([\'\"])(.*?)\1/
	my ($q, $body) = ($1, $2);
	$body =~ s!\:\{?(\w+)\}?!defined($parms->{$1}) ? &makaswap($parms,$1) : ''!eg;
	$body =~ s!\:!\:\x02!go;    #PROTECT AGAINST MULTIPLE SUBSTITUTION!
	$q.$body.$q;
	/eg;

	#$regex =~ s/\:\{?(\w+)\}?/defined($parms->{$1}) ? '"'.&makaswap($parms,$1).'"' : '""'/eg;

	#PREV. LINE REPLACED BY NEXT REGEX 20000309 TO QUOTE DOUBLE-QUOTES IN PARM. VALUE.
	$regex =~ s/\:\{?(\w+)\}?/
			my ($one) = $1;
	my ($res) = '""';
	if (defined($parms->{$one}))
	{
		$res = &makaswap($parms,$1);
		$res =~ s!\"!\\\"!go;
		$res = '"'.$res.'"';
	}
	$res
	/eg;
	$regex =~ s/\x02//go;    #UNPROTECT!
	$regex =~ s/\:([\$\@\%][\w\:\[\{\]\}\$]+)/&dovar($1)/egs  if ($evalsok);
	#$regex =~ s/\:([\$\@\%][\w\:\[\{\]\}\$\-\>]+)/&dovar($1)/egs  if ($evalsok);

	$regex =~ /^([^`]*)$/o;   #MAKE SURE EXPRESSION CONTAINS NO GRAVS!
	$regex = $1;   #20000626 UNTAINT REGEX FOR EVAL!
	$regex =~ s/([\@\#\$\%])([a-zA-Z_])/\\$1$2/g;   #QUOTE ANY SPECIAL PERL CHARS!
	#$regex =~ s/\"\"\:\w+\"\"/\"\"/g;   #FIX QUOTE BUG -FORCE UNDEFINED PARMS TO RETURN FALSE!
	$regex = '$x = ' . $regex . ';';
	eval $regex;
	$listsep = $savesep;

	my ($ifhtml1,$ifhtml2) = split(/<\!ELSE$nestid>\s*/i,$ifhtml);
	if ($x)
	{
		if (defined $ifhtml1)
		{
			$ifhtml1 =~ s#^(\s*)<\!\-\-(.*?)\-\->(\s*)$#$1$2$3#s;
			return ($ifhtml1);
		}
		else
		{
			return ('');
		}
	}
	else
	{
		if (defined $ifhtml2)
		{
			$ifhtml2 =~ s#^(\s*)<\!\-\-(.*?)\-\->(\s*)$#$1$2$3#s;
			return ($ifhtml2);
		}
		else
		{
			return ('');
		}
	}
};

sub makanop1
{
	#
	#	SUBSTITUTIONS IN COMMENTS TAKE THE ONE OF THE FORMS:
	#	<!:#default[before-stuff:#after-stuff]:>remove ...<!:/#>   OR
	#
	#		where:		"#"=Parameter number to substitute.
	#				"default"=Optional default value to use if parameter
	#				is empty or omitted.
	#				"stuff to remove" is removed.
	#
	#	NOTES:  ONLY 1 SUCH COMMENT MAY APPEAR PER LINE,
	#	THE DEFAULT, BEFORE-STUFF AND AFTER-STUFF MUST FIT ON ONE LINE.
	#	DUE TO HTML LIMITATIONS, ANY ">" BETWEEN THE "[...]" MUST BE
	#	SPECIFIED AS "&gt"!
	#
	#	THIS IS VERY USEFUL FOR SUBSTITUTING WHERE HTML WILL NOT ACCEPT
	#	COMMENTS, EXAMPLE:
	#
	#	<!:1Add[<INPUT NAME="submit" TYPE="submit" VALUE=":1 Record"&gt]:>
	#	<INPUT NAME="submit" TYPE="submit" VALUE="Create Record">
	#	<!/1>
	#
	#	THIS CAUSES A SUBMIT BUTTON WITH THE WORDS "Create Record" TO
	#	BE DISPLAYED IF PAGE IS JUST DISPLAYED, "Add Record" if loaded
	#	by loadhtml() (CGI) but no argument passed.  NOTE the use of
	#	"&gt" instead of ">" since HTML terminates comments with ">"!!!!
	#

	my $parms = shift;
	my $one = shift;
	my $two = shift;
	my ($rtn) = '';
	my ($picture);
	$picture = $1  if ($two =~ s/\%(.*)\%//);
	#$three = shift;
	my $three = '';                ##NEXT 3 LINES REP. PREV. LINE 5/14/98  JWT!
	$two =~ s/^=//o;
	$two =~ s/([^\[]*)(\[.*\])?/$three = $2; $1/e;
	#$two =~ s/^=//;  #MOVED UP 2 LINES 20050523!
#print "-???- 1=$one= 2=$two= parms=$parms=\n";
	return ($two)  unless(defined($one) && ref($parms) eq 'HASH' && defined($parms->{$one}) && "\Q$parms->{$one}\E");
	if (defined($three) ? ($three =~ s/^\[(.*?)\]/$1/) : 0)
	{
		#$three =~ s/\:(\w+)/(${parms{$1}}||$two)/egx;  #JWT 19990611
		$three =~ s/\:(\w+)/(&makaswap($parms,$1)||$two)/egx;
		$three =~ s/\&gt/>/go;
		$rtn = $three;
	}
	elsif ($picture)  #ALLOW "<:1%10.2f%...> (SPRINTF) FORMATTING!
	{
		if ($picture =~ s/^&(.*)/$1/)
		{
			my ($picfn) = $1;
			$picfn =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;  #ADDED 20050517 TO ALLOW "%&:{alt_package}::commatize%"
			$picfn = $calling_package . '::' . $picfn  #ADDED 20050517 TO DEFAULT PACKAGE OF commatize TO MAIN RATHER THAN "LoadHtml"!
			unless ($picfn =~ /\:\:/o);
#				my (@args) = undef;   #CHGD. TO NEXT 20070426 TO PREVENT WARNING.
			my (@args) = ();
			(@args) = split(/\,/o,$1)  if ($picfn =~ s/\((.*)\)//o);
no strict 'refs';
#				if (defined(@args))   #CHGD. TO NEXT 20070426 TO PREVENT WARNING.
			if (@args)
			{
				for my $j (0..$#args)
				{
					$args[$j] =~ s/\:(\w+)/&makaswap($parms,$1)/egs;
				}
				#$rtn = &{$picfn}((${parms{$one}}||$two), @args); #JWT 19990611
				$rtn = &{$picfn}((&makaswap($parms,$one)||$two), @args);
			}
			else
			{
				#$rtn = &{$picfn}(${parms{$one}}||$two); #JWT 19990611
				$rtn = &{$picfn}(&makaswap($parms,$one)||$two);
			}
		}
		else
		{
			#$rtn = sprintf("%$picture",(${parms{$one}}||$two)); #JWT 19990611
			$rtn = sprintf("%$picture",(&makaswap($parms,$one)||$two));
		}
	}
	else
	{
		#$rtn = ${parms{$one}}||$two; #JWT 19990611
		$rtn = &makaswap($parms,$one)||$two;
	}
	return ($rtn);
};

sub makanop2
{
	#
	#	SUBSTITUTIONS IN COMMENTS TAKE THE ONE OF THE FORMS:
	#	<!:[#*^%]_LOOP_NAME:>remove ...<!:/_LOOP_NAME>   OR
	#
	#    ADDED 20070713

	my $parms = shift;
	my $one = shift;
	my $two = shift;

	my ($rtn) = '';
#print "<BR>-!!!- makanop2($one|$two)\n";
	my ($picture);
	$picture = $1  if ($two =~ s/\%(.*)\%//);
	#$three = shift;
	my $three = '';                ##NEXT 3 LINES REP. PREV. LINE 5/14/98  JWT!
	$two =~ s/^=//o;
	if ($picture)  #ALLOW "<:1%10.2f%...> (SPRINTF) FORMATTING!
	{
		if ($picture =~ s/^&(.*)/$1/)
		{
			my ($picfn) = $1;
			$picfn =~ s/\:\{?(\w+)\}?/&makaswap($parms,$1)/eg;  #ADDED 20050517 TO ALLOW "%&:{alt_package}::commatize%"
			$picfn = $calling_package . '::' . $picfn  #ADDED 20050517 TO DEFAULT PACKAGE OF commatize TO MAIN RATHER THAN "LoadHtml"!
			unless ($picfn =~ /\:\:/o);
			my (@args) = ();
			(@args) = split(/\,/o,$1)  if ($picfn =~ s/\((.*)\)//o);
no strict 'refs';
			if (@args)
			{
				for my $j (0..$#args)
				{
					$args[$j] =~ s/\:(\w+)/&makaswap($parms,$1)/egs;
				}
				#$rtn = &{$picfn}((${parms{$one}}||$two), @args); #JWT 19990611
				$rtn = &{$picfn}($one, @args);
			}
			else
			{
				#$rtn = &{$picfn}(${parms{$one}}||$two); #JWT 19990611
				$rtn = &{$picfn}($one);
			}
		}
		else
		{
			#$rtn = sprintf("%$picture",(${parms{$one}}||$two)); #JWT 19990611
			$rtn = sprintf("%$picture",$one);
		}
	}
	else
	{
		$rtn = $one;
	}
	return ($rtn);
};

sub buildahash
{
	my ($one,$two) = @_;

	$two =~ s/^\s*<!--//o;
	$two =~ s/-->\s*$//o;
	$two =~ s/^\s*\(//o;
	$two =~ s/\)\s*$//o;
no strict 'refs';
	#$evalstr = "\%h1_myhash = ($two)";
	my $evalstr = "\%{\"h1_$one\"} = ($two)";
	my $x = eval $evalstr;
	return ('');
};

sub makahash
{
	#
	#	FORMAT:  <!$hashname{index_str}default>

	my ($one,$two,$three) = @_;
no strict 'refs';
	return (${"h1_$one"}{$two})  if (defined(${"h1_$one"}{$two}));
	return $three;
};

sub makaselect
{
	#
	#	FORMAT:  <!SELECTLIST select-options [DEFAULT[SEL]=":scalar|:list"] [VALUE[S]=:list] [(BYKEY)|BYVALUE] [REVERSE[D]]:#>..stuff to remove...
	#	...
	#	...<!/SELECTLIST>
	#
	#   NOTE:  "select-options" MAY CONTAIN "default="value"" AND "value"
	#	MAY ALS0 BE A SCALER PARAMETER.  THE LIST PARAMETER MUST BE AT
	#	THE END JUST BEFORE THE ">" WITH NO SPACE IN BETWEEN!
	#	THESE COMMENTS AND ANYTHING IN BETWEEN GETS REPLACED BY A SELECT-
	#	LISTBOX CONTAINING THE ITEMS CONTAINED IN THE LIST REFERENCED BY
	#	PARAMETER NUMBER "#".  (PASS AS "\@list").
	#	"select_options" MAY ALSO CONTAIN A "value=:#" PARAMETER
	#	SPECIFYING A SECOND LIST PARAMETER TO BE USED FOR THE ACTUAL 
	#	VALUES.  DEFAULTS TO SAME AS DISPLAYED LIST IF OMITTED.
	#	SPECIFYING A SCALAR OR LIST PARAMETER OR VALUE FOR "DEFAULT[SEL]=" 
	#	CAUSES VALUES WHICH MATCH THIS(THESE) VALUES TO BE SET TO SELECTED 
	#	BY DEFAULT WHEN THE LIST IS DISPLAYED.  DEFAULT= MATCHES THE 
	#	DEFAULT LIST AGAINST THE VALUES= LIST, DEFAULTSEL= MATCHES THE 
	#	DEFAULT LIST AGAINST THE *DISPLAYED* VALUES LIST (IF DIFFERENT).
	#	IF USING A HASH, BY DEFAULT IT IS CHARACTER SORTED BY KEY, IF 
	#	"BYVALUE" IS SPECIFIED, IT IS SORTED BY DISPLAYED VALUE.  "REVERSE" 
	#	CAUSES THE HASH OR LIST(S) TO BE DISPLAYED IN REVERSE ORDER.
	#
	my$parms = shift;
	my ($one) = shift;
	my ($two) = shift;
	my ($rtn) = '';
	my ($dflttype) = 'DEFAULT';
	my ($dfltval) = '';
	my (%dfltindex) = ('DEFAULT' => 'value', 'DEFAULTSEL' => 'sel');

	#@value_options = ();
	#@sel_options = ();
	my $options;
	if (ref($parms->{$two}) eq 'HASH')
	{
		#1ST PART OF NEXT IF ADDED 20031124 TO SUPPORT BOTH VALUE ARRAY AND DESCRIPTION HASH.
		if ($one =~ s/value[s]?=(\")?:(\w+)\1?//i)
		{
			@{$options->{value}} = @{$parms->{$2}};
			foreach my $i (@{$options->{value}})
			{
				push (@{$options->{sel}}, ${$parms->{$two}}{$i});
			}
		}
		elsif ($one =~ s/BYVALUE//io)
		{
			foreach my $i (sort {$parms->{$two}->{$a} cmp $parms->{$two}->{$b}} (keys(%{$parms->{$two}})))   #JWT: SORT'EM (ALPHA).
			{
				push (@{$options->{value}}, $i);
				push (@{$options->{sel}}, ${$parms->{$two}}{$i});
			}
		}
		else
		{
			$one =~ s/BYKEY//io;
			foreach my $i (sort(keys(%{$parms->{$two}})))   #JWT: SORT'EM (ALPHA).
			{
				push (@{$options->{value}}, $i);
				push (@{$options->{sel}}, ${$parms->{$two}}{$i});
			}
		}
	}
	else
	{
		@{$options->{sel}} = @{$parms->{$two}};

#NEXT 9 LINES (IF-OPTION) ADDED 20010410 TO ALLOW "VALUE=:#"!
		if ($one =~ s/value[s]?=(\")?:(\#)([\+\-\*]\d+)?\1?//i)
		{
			my ($indx) = $3;
			$indx =~ s/\+//;
			for (my $i=0;$i<=$#{$options->{sel}};$i++)
			{
				push (@{$options->{value}}, $indx++);
			}
		}
		elsif ($one =~ s/value[s]?=(\")?:(\w+)\1?//i)
		{
		@{$options->{value}} = @{$parms->{$2}};
		}
		elsif ($one =~ s/value[s]?\s*=\s*(\")?:\#([\+\-\*]\d+)?\1?//i)
		{
			#JWT(ALLOW "VALUE=:# TO SPECIFY USING NUMERIC ARRAY-INDICES OF 
			#LIST TO BE USED AS ACTUAL VALUES.
			for my $i (0..$#{$options->{sel}})
			{
				push (@{$options->{value}}, eval("$i$2"));
			}
		}
		else
		{
			@{$options->{value}} = @{$options->{sel}};
		}
	}
	if ($one =~ s/REVERSED?//io)
	{
		@{$options->{sel}} = reverse(@{$options->{sel}});
		@{$options->{value}} = reverse(@{$options->{value}});
	}

#$one =~ s/default=\"(.*?)\"//i;
#$one =~ s/default=\"(.*?)\"//i;
#if ($one =~ s/(default|defaultsel)=\"(.*?)\"//i)  #20000505: CHGD 2 NEXT 2 LINES 2 MAKE QUOTES OPTIONAL!
	if (($one =~ s/(default|defaultsel)\s*=\s*\"(.*?)\"//i) 
			|| ($one =~ s/(default|defaultsel)\s*=\s*(\:?\S+)//i))  #20000505: CHGD 2 NEXT LINE 2 MAKE QUOTES OPTIONAL!
	{
		$dflttype = $1;
		$dfltval = $2;
		$dflttype =~ tr/a-z/A-Z/;
		#$dfltval =~ s/\:(\w+)/
		$dfltval =~ s/\:\{?(\w+)\}?/
				if (ref($parms->{$1}) eq 'ARRAY')
				{
					'(?:'.join('|',@{$parms->{$1}}).')'
				}
				else
				{
					quotemeta($parms->{$1})
				}
		/eg;
	}
#$one =~ s/\:(\w+)/$parms->{$1}/g;
	$one =~ s/\:\{?(\w+)\}?/$parms->{$1}/g;      #JWT 05/24/1999
	$rtn = "<SELECT $one>\n";
	$one = $dfltval;
	for (my $i=0;$i<=$#{$options->{sel}};$i++)
	{
		#if (${$options->{value}}[$i] =~ /^\Q${one}\E$/)
#		if (${($dfltindex{$dflttype}.'_options')}[$i] =~ /^${one}$/)
		if (${$options->{$dfltindex{$dflttype}}}[$i] =~ /^${one}$/)
		{
			$rtn .= "<OPTION SELECTED VALUE=\"${$options->{value}}[$i]\">${$options->{sel}}[$i]</OPTION>\n";
		}
		else
		{
			$rtn .= "<OPTION VALUE=\"${$options->{value}}[$i]\">${$options->{sel}}[$i]</OPTION>\n";
		}
	}
	$rtn .= '</SELECT>';
	return ($rtn);
};

sub modhtml
{
	my ($html, $parms) = @_;
	my ($v);

	#NOW FOR THE REAL MAGIC (FROM ANCIENT EGYPTIAN TABLETS)!...

	if ($cfgOps{loops})
	{
		while ($$html =~ s#<\!LOOP(\S*)\s+(.*?)>\s*(.*?)<\!/LOOP\1>\s*#&makaloop($parms, $2,$3,$1)#eis) {};
	}

	$$html =~ s#<\!HASH\s+(\w*?)\s*>(.*?)<\!\/HASH[^>]*>\s*#&buildahash($1,$2)#eigs
			if ($cfgOps{hashes});

	$$html =~ s#</FORM>#<INPUT NAME="CGIScript" TYPE=HIDDEN VALUE="$ENV{'SCRIPT_NAME'}">\n</FORM>#i 
			if ($cfgOps{CGIScript});

	#$$html =~ s#<\!INCLUDE\s+(.*?)>\s*#&fetchinclude($parms, $1)#eigs  #CHGD. TO NEXT 20010720 TO SUPPORT EMBEDS.
	$$html =~ s!<\!INCLUDE\s+(.*?)>\s*!
		my $one = $1;
		$one =~ s/^\"//o;
		$one =~ s/\"\s*$//o;
		my $tag = 0;
		$tag = $1  if ($one =~ s/\:(\w+)//);  #ADDED 20060117 TO ALLOW PARTIAL FILE INCLUDES BASED ON TAGS.
		if ($one =~ s/\((.*)\)\s*$//)
		{
			my $includeparms = $1;
			$includeparms =~ s/\=/\=\>/go;
			eval "&fetchinclude($parms, \"$one\", 1, $tag, $includeparms)";
		}
		else
		{
			&fetchinclude($parms, $one, 1, $tag);
		}
	!eigs  if ($cfgOps{includes});

	if ($cfgOps{pocs})
	{
		$$html =~ s#<\!POC:>(.*?)<\!/POC>#$poc#ig  if ($cfgOps{pocs});  #20000606
		$$html =~ s#<\!POC>#$poc#ig  if ($cfgOps{pocs});
	}

	$$html =~ s#\<\!FILEDATE([^\>]*?)\:\>.*?\<\!\/FILEDATE\>#&filedate($parms,$1,0)#eig;  #20020327
	$$html =~ s#\<\!FILEDATE([^\>]*)\>#&filedate($parms,$1,0)#eig;  #20020327
	$$html =~ s#\<\!TODAY([^\>]*?)\:\>.*?\<\!\/TODAY\>#&filedate($parms,$1,1)#eig;  #20020327
	$$html =~ s#\<\!TODAY([^\>]*)\>#&filedate($parms,$1,1)#eig;  #20020327

	while ($$html =~ s#<\!IF(\S*)\s+(.*?)>\s*(.*?)<\!/IF\1>\s*#&makanif($parms, $2,$3,$1)#eigs) {};

	$$html =~ s#<\!\:(\w+)([^>]*?)\:>.*?<\!\:\/\1>#&makanop1($parms,$1,$2)#egs;
	$$html =~ s#<\!\:(\w+)([^>]*?)>#&makanop1($parms,$1,$2)#egs;
#JWT:CHGD. TO NEXT 20100920 TO ALLOW STYLES IN SELECT TAG!	$$html =~ s#(<SELECT\s+[^\:\>]*?\:\w+\s*>)(.*?)(<\/SELECT>)#&makasel($parms, $1,$2,$3)#eigs;
	$$html =~ s#(<SELECT\s+[^\>]*\>)(.*?)(<\/SELECT>)#&makasel($parms, $1,$2,$3)#eigs;
	$$html =~ s#<\!SELECTLIST\s+(.*?)\:(\w+)\s*>(.*?)<\!\/SELECTLIST>\s*#&makaselect($parms, $1,$2,$3)#eigs;

	$$html =~ s#(<TEXTAREA[^>]*?)\:(\w+)(?:\=([\"\']?)([^\3]*)\3|\>)?\s*>.*?(<\/TEXTAREA>)#$1.'>'.($parms->{$2}||$4).$5#eigs;
	$$html =~ s/(TYPE\s*=\s*\"?)(CHECKBOX|RADIO)([^>]*?\:)(\w+)(\s*>)/&makabutton($parms,$1,$2,$3,$4,$5)/eigs;
	$$html =~ s/(<\s*INPUT[^\<]*?)\:(\w+)(\=.*?)?>/&makatext($parms, $1,$2,$3).'>'/eigs;
	$$html =~ s/\:(\d+)/&makaswap($parms,$1)/egs 
			if ($cfgOps{numbers});   #STILL ALLOW JUST ":number"!
	$$html =~ s/\:\{(\w+)\}/&makaswap($parms,$1)/egs;   #ALLOW ":{word}"!
	$$html =~ s#<\!\%(\w+)\s*\{([^\}]*?)\}([^>]*?)>#&makahash($1,$2,$3)#egs 
			if ($cfgOps{hashes});
#	$$html =~ s/\:\{(\w+)\}/&makaswap($parms,$1)/egs;   #ALLOW ":{word}"!  #MOVED ABOVE PREV. LINE 20070428 SO "<!%hash{:{parameter}}>" WOULD WORK (USED IN "dsm")!

	#NEXT LINE ADDED 20031028 TO ALLOW IN-PARM EXPRESSIONS!
	$$html =~ s/\:\{([^\}]+)\}/&makamath($1)/egs;   #ALLOW STUFF LIKE ":{:{parm1}+:{parm2}+3}"!
	if ($evalsok)
	{
		$$html =~ s#<\!\:([\$\@\%][\w\:]+\{.*?\})([^>]*?)\:>.*?<\!\:\/\1>#&dovar($1,$2)#egs;  #ADDED 20000123 TO HANDLE HASHES W/NON VARIABLE CHARACTERS IN KEYS.
		$$html =~ s#<\!\:(\$[\w\:\[\{\]\}\$]+)([^>]*?)\:>.*?<\!\:\/\1>#&dovar($1,$2)#egs;
		$$html =~ s#<\!\:([\$\@\%][\w\:]+\{.*?\})([^>]*?)>#&dovar($1,$2)#egs;  #ADDED 20000123 TO HANDLE HASHES W/NON VARIABLE CHARACTERS IN KEYS.
		$$html =~ s#<\!\:(\$[\w\:\[\{\]\}\$]+)([^>]*?)>#&dovar($1,$2)#egs;
		$$html =~ s/\:(\$[\w\:\[\{\]\}\$]+)/&dovar($1)/egs;
		$$html =~ s/<\!EVAL\s+(.*?)(?:\/EVAL)?>/&doeval($1)/eigs;
		$$html =~ s#<\!PERL\s*([^>]*)>\s*(.*?)<\!\/PERL>#&doeval($2,$1)#eigs  if ($cfgOps{perls});
	}
	else
	{
		$$html =~ s#<!PERL\s*([^>]*)>(.*?)<!/PERL>##igs;
	};

	#THE FOLLOWING ALLOWS SETTING ' HREF="relative/link.htm" TO 
	#A CGI-WRAPPER, IE. ' HREF="http://my/path/cgi-bin/myscript.pl?relative/link.htm".

	if (defined($hrefhtmlhome))
	{
#		my $hrefhtmlback = $hrefhtmlhome;
#		$hrefhtmlback =~ s#\/[^\/]+$##o;
		if (defined($hrefcase))     #THIS ALLOWS CONTROL OF WHICH "href=" LINKS TO WRAP WITH CGI!
		{
			if ($hrefcase eq 'l')   #ONLY CONVERT LOWER-CASE "href=" LINKS THIS WAY.
			{
				$$html =~ s# (href)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$hrefhtmlhome/$2#g;   #ADDED HREF ON 20010719!
			}
			else                    #ONLY CONVERT UPPER-CASE "HREF=" LINKS THIS WAY.
			{
				$$html =~ s# (HREF)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$hrefhtmlhome/$2#g;   #ADDED HREF ON 20010719!
			}
		}
		else                        #CONVERT ALL "HREF=" LINKS THIS WAY.
		{
			$$html =~ s#( href)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$hrefhtmlhome/$2#gi;   #ADDED HREF ON 20010719!
			#$$html =~ s# (href)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$hrefhtmlhome/\x02$2#gi;   #ADDED HREF ON 20010719!
		}

		#RECURSIVELY CONVERT "my/deep/deeper/../../path" to "my/path".

	}
	if (defined($htmlhome) && $htmlhome =~ /\S/o)      #JWT 6 NEXT LINES ADDED 1999/08/31.
	{
		$$html =~ s#([\'\"])((?:\.\.\/)+)#$1$htmlhome/$2#ig;  #INSERT <htmlhome> between '|" and "../[../]*"
		1 while ($$html =~ s#[^\/]+\/\.\.\/##o);   #RECURSIVELY CONVERT "my/deep/deeper/../../path" to "my/path".
		if (defined($hrefcase))     #ADDED 20020117:  THIS ALLOWS CONTROL OF WHICH LINKS TO WRAP WITH CGI!
		{
			if ($hrefcase eq 'l')   #ONLY CONVERT LOWER-CASE "href=" LINKS THIS WAY.
			{
				$$html =~ s#(src|ground|href)\s*=\s*\"(?!(\#|/|\w+\:))#$1=\"$htmlhome/$2#g;   #CONVERT RELATIVE LINKS TO ABSOLUTE ONES.
				$$html =~ s# (cl|ht)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$htmlhome/$2#g;   #CONVERT RELATIVE SPECIAL JAVASCRIPT LINKS TO ABSOLUTE ONES.
				$$html =~ s#(\s+window\.open\s*\(\s*\')(?!(\#|/|\w+\:))#$1$htmlhome/$2#g;     #ADDED 20050504 TO MAKE CALENDAR.JS WORK!
			}
			else
			{
				$$html =~ s#(SRC|GROUND|HREF)\s*=\s*\"(?!(\#|/|\w+\:))#$1=\"$htmlhome/$2#g;   #CONVERT RELATIVE LINKS TO ABSOLUTE ONES.
				$$html =~ s# (CL|HT)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$htmlhome/$2#g;   #CONVERT RELATIVE SPECIAL JAVASCRIPT LINKS TO ABSOLUTE ONES.
			}
		}
		else
		{
			$$html =~ s#(src|ground|href)\s*=\s*\"(?!(\#|/|\w+\:))#$1=\"$htmlhome/$2#ig;   #CONVERT RELATIVE LINKS TO ABSOLUTE ONES.
			$$html =~ s# (cl|ht)\s*=\s*\"(?!(\#|/|\w+\:))# $1=\"$htmlhome/$2#ig;   #CONVERT RELATIVE SPECIAL JAVASCRIPT LINKS TO ABSOLUTE ONES.
			$$html =~ s#(\s+window\.open\s*\(\s*\')(?!(\#|/|\w+\:))#$1$htmlhome/$2#ig;     #ADDED 20050504 TO MAKE CALENDAR.JS WORK!
		}
		$$html =~ s#\.\.\/##g;   #REMOVE ANY REMAING "../".

		#NOTE:  SOME JAVASCRIPT RELATIVE LINK VALUES MAY STILL NEED HAND-CONVERTING 
		#VIA BUILDHTML, FOLLOWED BY ADDITIONAL APP-SPECIFIC REGICES, ONE EXAMPLE 
		#WAS THE "JSFPR" SITE, FILLED WITH ASSIGNMENTS OF "'image/file.gif'", 
		#WHICH WERE CONVERTED USING:
		#	$html =~ s#([\'\"])images/#$1$main_htmlsubdir/images/#ig;

	}

	#NEXT LINE ADDED 20010720 TO SUPPORT EMBEDS (NON-PARSED INCLUDES).

#	$$html =~ s#<\!EMBED\s+(.*?)>\s*#&fetchinclude($parms, $1, 0)#eigs  
#			if ($cfgOps{embeds});

	#ABOVE CHANGED TO NEXT REGEX 20060117 TO ALLOW PARTIAL FILE INCLUDES BASED ON TAGS.
	$$html =~ s!<\!EMBED\s+(.*?)>\s*!
		my $one = $1;
		$one =~ s/^\"//o;
		$one =~ s/\"\s*$//o;
		my $tag = 0;
		$tag = $1  if ($one =~ s/\:(\w+)//);
		&fetchinclude($parms, $one, 0, $tag);
	!eigs  if ($cfgOps{embeds});

	return ($$html);
}

sub html_error
{
	my ($mymsg) = shift;
	
	return (<<END_HTML);
<html>
<head><title>CGI Program - Unexpected Error!</title></head>
<body>
<h1>$mymsg</h1>
<hr>
Please contact $poc for more information.
</body></html>
END_HTML
}

sub SetHtmlHome
{
	($htmlhome, $roothtmlhome, $hrefhtmlhome, $hrefcase) = @_;

	# hrefcase = undef:  convert all "href=" to $hrefhtmlhome.
	# hrefcase = 'l':    convert only "href=" to $hrefhtmlhome.
	# hrefcase = '~l':    convert only "HREF=" to $hrefhtmlhome.
}

sub loadhtml_package   #ADDED 20000920 TO ALLOW EVALS IN ASP!
{
	$calling_package = shift || 'main';
}

sub filedate    #ADDED 20020327
{
	my $parms = shift;
	my $fmt = shift;
	my $usetoday = shift;   #ADDED 20030501 TO SUPPORT DISPLAYING CURRENT DATE!

	$fmt =~ s/^\=\s*//o;
	$fmt =~ s/[\"\']//go;
	$fmt =~ s/\:$//go;
	$fmt ||= 'mm/dd/yy';    #SUPPLY A REASONABLE DEFAULT.
	my $mtime = time;
	(undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,$mtime) 
			= stat ($parms->{'0'})  unless ($usetoday);
	$mtime ||= time;

#to_char() comes from DBD::Sprite, but is usable as a stand-alone program and is optional.

	my @parmsave = @_;
	@_ = ($mtime, $fmt);

	eval "package $calling_package; require 'to_char.pl'";
	if ($@)
	{
		@_ = @parmsave;
		return scalar(localtime($mtime));
	}
	if (!$rtnTime || $err =~ /^Invalid/o)
	{
		#@_ = (time, 'mm/dd/yy');
		#do 'to_char.pl';
		my $qualified_fn = $calling_package . '::to_char';
no strict 'refs';
		return &{$qualified_fn}($mtime, $fmt);	
	}
	@_ = @parmsave;
	return $rtnTime;
}

1
