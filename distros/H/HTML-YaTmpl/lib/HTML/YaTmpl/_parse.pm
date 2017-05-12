package HTML::YaTmpl;
use strict;
use warnings;
no warnings 'uninitialized';
use Config;

our $VERSION='1.0';

sub _parse {
  my $I=shift;
  my $str=shift;
  $str=$I->template unless( defined $str );

  use re 'eval';

  my $regexp;
  my $re_nostr=qr{
		  (?:		# between <: and /> can be written perl code
		   [^\s\w/]>	# but perl knows the -> operator. Originally
		   |		# this (?:...) was written simply as [^"<>]
				# and <:$p->{xxx}/> was matched as $1=':',
				# $2='', $3='$p-' and not as $3='$p->{xxx}'
				# as expected. Now a character other than \s,
				# \w or / acts like an escape character for a
				# subsequent >.
		   /(?!>)
		   |
		   \\.
		   |
		   [^"<>/]	# "]# kein string
		  )*
		 }xs;

  my $re_isstr=qr{
		  "             #"# string start
		  (?:		#
		   \\.		# escaped character
		   |
		   [^"\\]       #"]# other character
		  )*
		  "	        #"# string ende
		 }xs;

  my $re_tparam=qr{
		   $re_nostr
		   (?:
		    $re_isstr
		    $re_nostr
		   )*?
		  }xs;

  $regexp=qr{
#	     (?{
#		my $pos=pos;
#		my $prev=substr($str, $pos>=10?$pos-10:0, $pos>=10?10:$pos);
#		my $post=substr($str, $pos, 10);
#		print "start at position ",pos,": $prev^$post\n";
#	       })
	     <([=:\043])	# [=:#] goes to $1
	     (\w*)		# TAG to $2
	     ($re_tparam)	# tag params go to $3
	     (?:
	      (?> /> )
	      |
	      (?>
	       >
	       (		# the section content goes to $4
		(?:		# we are looking for a character
		 (?> [^<]+ )	# that is not the beginning of a TAG
		 |		# or
		 (?>
		  (??{$regexp})	# we are looking for something that is
		 )		# described by $regexp
		 |		# or
		 <(?!		# is the beginning of a TAG but not followed
		   (?>		# by the rest of an opening or closing TAG
		    \1\2 $re_tparam
		    |
		    /\1\2
		   )> )
		)*?		# and that many times
	       )
	       </\1\2> # the closing TAG
	      ))
#	     (?{
#		my $pos=pos;
#		my $prev=substr($str, $pos-10, 10);
#		my $post=substr($str, $pos, 10);
#		print "emitted at position ",pos,": $prev^$post\n";
#	       })
	    }xs;

  my $sreg=qr{(?:
               \\.
	       |
	       [^"\s]		#"]# kein string oder space
               |
	       (?:$re_isstr)           	# "#
	      )+
	     }xs;

  my $kreg=qr{(?:
	       \\.
	       |
	       [^"\s=]		#"]# kein string oder space
	       |
	       (?:$re_isstr)
	      )+
	     }xs;

  my $vreg=$sreg;

  my $xreg=qr{^($kreg) = ($vreg)$}xs;


  # real start of code

  my ($id, $tag, $tparam, $tbody, $chunk);
  my @res;

  #print "\nparse($str)\n";
  my $start=0;
  while( $str=~/$regexp/g ) {
    ($id, $tag, $tparam, $tbody)=($1,$2,$3,$4);
    $chunk=substr( $str, $-[0], $+[0]-$-[0] );
    if( $start!=$-[0] ) {
      push @res, [undef, 'text', undef, undef,
		  substr( $str, $start, $-[0]-$start )];
    }
    $start=$+[0];
    next if( $id eq '#' );	# skip comments
    my $p=[];

    #print "id='$id'\n";
    #print "tag='$tag'\n";
    #print "tparam='$tparam'\n";
    #print "tbody='$tbody'\n";

    my $pstr=$tparam;
    $pstr=~s/^\s+//;
    $pstr=~s/\s+$//;
    #$pstr=~s/\\(.)/$1/g;
    push @res, [$id, $tag, $p, $tbody, $chunk, $pstr];
    local $_;
    push @{$p}, map {
      #warn "_=$_\n";
      my @l=/$xreg/; @l ? [do {
      local $_;
      map {
	s/\\(.)|"/$1/g;              #";#
	$_;
      } @l;
    }] : do {s/\\(.)|"/$1/g;$_}} $tparam=~/$sreg/g;              #"}};#
  }
  if( $start!=length($str) ) {
    push @res, [undef, 'text', undef, undef, substr( $str, $start )];
  }

  #use Data::Dumper; warn Dumper(\@res);
  return @res;
}

1;
