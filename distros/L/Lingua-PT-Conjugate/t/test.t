#!/usr/bin/perl -w 

use Encode;

# use Ref ; Won't do
use Data::Dumper;
$Data::Dumper::Useqq=1;
$Data::Dumper::Terse=1;
use Lingua::PT::Conjugate ;
$verbose = 1 ;$|=1 ;

BEGIN {print "1..12\n";}

# Check wether the output of conjug matches the reference conjugation
# data. 
$incstr = join(" ", map("-I$_", "../..", @INC));
print "$^X $incstr ./ckconj all\n" ;
@a = `$^X $incstr ./ckconj all`;

$ok=1;
foreach (@a){
	unless( /^(THESE VERBS ARE OK|NOT IN REFERENCE FILE)/){
		print "ERROR $_\n";
		$ok=0;
	}
}
unless(@a){$ok=0}
print "not " unless $ok;
print "ok 1\n";

# Other tests.
$cnt = 1 ;

# Minimal comparison of hashes
sub cmpany
{
    my ($a,$b) = @_ ;
    return 0 unless defined($a) || defined($b) ;
    return 1 if defined($a) xor defined($b) ;
    return 1 if ref($a) ne ref($b) ;
    if( ! ref($a) )
    {
	# print "$a, $b\n" ;
	return "$a" eq "$b" ? 0 : 1 ;
	
    }  elsif( ref($a) eq "SCALAR" || ref($a) eq "REF" )
    {
	return "$$a" eq "$$b" ? 0 : 1 ;

    } elsif( ref($a) eq "HASH" )
    { 
	return 0 if $a == $b ;
	foreach ( keys(%$a) )
	{
	    return 1 unless exists( $b->{$_} ) && 
		! cmpany( $b->{$_} , $a->{$_} ) ;
	}
	foreach ( keys(%$b) )
	{
	    return 1 unless exists( $b->{$_} ) && 
		! cmpany( $b->{$_} , $a->{$_} ) ;
	}
	return 0 ;
    } elsif(  ref($a) eq "ARRAY" )
    {	
	return 0 if $a == $b ;
	return 1 unless @$a == @$b ;
	foreach $i ( 0..$#a )
	{
	    return 1 unless 
		defined( $b->[$i] ) == defined( $a->[$i] ) ;
	    return 1 if defined( $b->[$i] ) && 
		cmpany( $b->[$i] , $a->[$i] ) ;
	}
	return 0 ;
    }
    print STDERR "Can't compare!!\n"; 
    return 0 ;
}

sub cmp_str_ans
{
    my ($a,$b) = @_ ;
    chomp($a,$b) ;
    if( $a ne $b )
    {
        my ($aa,$bb) =  (Dumper($a),Dumper($b)) ;
        chomp ( $aa, $bb ) ;
        print 
            "Whoa! :             >>",$aa,"<<\n",
            "    does not match  >>",$bb,"<<\n"
            if $verbose ;
        return 1 ;
    }
    return 0 ;
}


# Check persons and tenses
$a = conjug("dormir","pres",1,4,5) ;
$b = "dormir :  irreg                 \npres      durmo dormimos dormis \n" ;
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";

$a = conjug("cegar","pp","pres",1,4) ;
$b = "cegar :  irreg         \npp       cego          \npres     cego  cegamos \n" ;
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";


$a = conjug("pagar","pp") ;
$b = "pagar :  irreg      \npp       pago       \n";
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";


$a = conjug("ter","Futuro","Mais-Que-Perfeito");
$b = "ter :  irreg                                            \nfut    terei  ter\341s   ter\341   teremos   tereis   ter\343o   \nmdp    tivera tiveras tivera tiv\351ramos tiv\351reis tiveram \n";
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";

# Check various options
# Check persons and tenses
$a = conjug("sx","cegar","pp","pres") ;
$b = "ceg(|ad)o cego cegas cega cegamos cegais cegam" ;
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";

$a = conjug("s","cegar","pp","pres",1,4);
$b = "cego cego cegamos" ;
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";


# "q" should be overriden by subsequent "v"
$a = conjug("q","s","v","l","cegar","pp","pres",1,4);
$b = "cegar :  irreg  partic\355pio passado cego presente cego cegamos" ;
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";

# "q" should be overriden by subsequent "v". IDEM, joined options
$a = conjug("qsvlsv","cegar","pp","pres",1,4);
$b = "cegar :  irreg  partic\355pio passado cego presente cego cegamos" ;
print "not " if cmp_str_ans($a,$b) ;
print "ok ",++$cnt,"\n";

# Hash
$a = conjug("h","desafiar","mais-que-perfeito","pres",1,4,5,6);
$b0 = $b = {
          "mdp" => [
                     undef,
                     "desafiara",
                     undef,
                     undef,
                     "desafiáramos",
                     "desafiáreis",
                     "desafiaram"
                   ],
          "pres" => [
                      undef,
                      "desafio",
                      undef,
                      undef,
                      "desafiamos",
                      "desafiais",
                      "desafiam"
                    ]
        };
# print Dumper($a) ;
# print Dumper($b) ;
print "not " if cmpany($a,$b) ;
print "ok ",++$cnt,"\n";

# Check cmpref, by the way ...
$a = conjug("hl","desafiar","mais-que-perfeito","pres",1,4,5,6);
$b = $b0 ; 
$b->{mdp}->[0] = 1 ;

print "not " unless cmpany($a,$b) ;
print "ok ",++$cnt,"\n";

# Check cmpref, by the way ...
$a = conjug("hl","desafiar","mais-que-perfeito","pres",1,4,5,6);
$b = $b0 ; 
$b->{ERROR} = 2 ;
print "not " unless cmpany($a,$b) ;
print "ok ",++$cnt,"\n";


