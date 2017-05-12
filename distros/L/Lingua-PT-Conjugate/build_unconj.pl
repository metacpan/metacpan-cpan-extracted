#!/usr/bin/perl -w

use Lingua::PT::Conjugate ;

# Expand regexes
sub expand0
{
    my @res = ();
    while (@_)
    {
	my $w = shift ;
	my ($a,$b,$c) ;
	
	my $s = "" ;		# Separator
	if( (($a,$b,$c) = $w=~ /^(.*?)\[([^\]]*)\](.*)$/) ||
	    (($a,$b,$c) = $w=~ /^(.*?)\(([^\)]*)\)(.*)$/) && ($s='\|') )
	{
	    foreach (split /$s/, $b) # List of possibilities
	    {
		push @_ , $a . $_ . $c ;
	    }
	} else {
	    push @res, $w ;
	    # print "expand0 : Adding $w\n" ;
	}
    }
    return @res ;
}


# Expands a hash to a list of [$v,$t,$p]
sub expand
{
    my $h = shift ;
    my ($p,$t,$k,$v) ;
    my @res = () ;
    while( ($t,$v) = each %$h )
    {
	foreach $p (1..6)
	{
	    next unless $w = $v->[$p] ;
	    push @res, map {[$_,$t,$p]} expand0($w) ;
	}
    }
    # print "expand : returning ",
    # map {" $_->[0] $_->[1] $_->[2]\n"} @res ;
    return @res ;
}

# build_entries \%verbdb, $verb ... 
sub build_entries
{
    my ($v,$x,$w,$t,$p) ;
    my @res ;
    my $vdb = shift ;
    my $vcnt = 0 ;
    print "build_entries\n";
    printf ("%-6d ",0);
    while( @_ )
    {
	print "." if ($vcnt % 20) == 19 ;
	print "\n".sprintf("%-6d ",$vcnt) 
	    if ($vcnt % 800) == 799 ;
	$v = shift ;
	$vcnt++ ;
	chomp($v) ;
	# print "$v\n" ;
	foreach $x (expand conjug("hx",$v)){
	    
	    ($w,$t,$p) = @$x ;
				# Find common part to inf and conjug
	    my $i=0;
	    while( $i<length($w) &&
		   substr($w,$i,1) eq substr($v,$i,1) ){ $i++ }
	    $w = substr($w,$i) ;
	    if( $w )
	    {			# Add the ending
		$vdb->{$w}->{$t}->[$p]->{substr($v,$i)} = 1 ; 
##              $vdb->{$w}->{$t}->[$p]->{$v} = 1 ; 
	    }
	}
    }
}

				# \%hash -> @strings 
sub dump_entries
{
    my $vdb = shift ;
    my ($w,$x,$y,$z);
    my @res = ();

    my $vcnt = 0 ;
    # print "dump_entries\n     0 ";

    while( ($w,$x) = each %$vdb ) {
	next if $w eq " " ;
	next unless $w ;
	while( ($t,$y) = each %$x ) {
	    foreach $p (1..6)
	    {
		# print "." if $vcnt % 50 == 49 ;
		# print "\n".sprintf("%-6d ",$vcnt) 
		# if $vcnt %1000 == 999 ;
		next unless defined( $z = $y->[$p] );
		
		# push @res, "$w $t,$p,".join(",",keys(%$z)) ;
		push @res, "$w $t,$p,".join(",",sort keys(%$z)) ;
	    }
	}
    }
    return sort @res ;
}

$| = 1 ;

$vf = "all_infinitives" ;	# Verb file containing infinitives
# $vf = "limited_list" ;
$outfile = "all_output" ;	# Output file


while (@ARGV) {
  $opt = shift ;
  if      ($opt eq "-i") {

    $vf = shift;
    print "Will use list '$vf'\n";

  } elsif ($opt eq "-o") {

    $outfile = shift;
    print "Will output to '$outfile'\n";

  } else {
    print <<EOF ;
Usage : 

    $0 [-i infinitive_file] [-o output_file]

EOF
  }
}



open AA,"<$vf" or die "Can't open list of infinitives >$vf<\n" ;
@allv = <AA> ;
close AA ;
# @allv = ("submeter");
$vdb = {};
print "There are ",0+@allv," verbs\n";

build_entries $vdb,@allv ;
@r = dump_entries($vdb) ;
open AA,">", $outfile or
    die "Can't open result file $outfile\n" ;
print AA join "\n", @r,"\n" ;
close AA;

print "\nDone\n";


