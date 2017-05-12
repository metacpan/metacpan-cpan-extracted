package Mecom::Statistics::RatioVariance;

use Statistics::Basic qw(:all);
use Statistics::Zed;


sub calc{
    
    # This variables must be references to arrays.
    my($self, $xvector, $yvector, $xvariance, $yvariance) = @_;   
    
    # Calculates ·
    my $kxvector    = 0;
    my $kyvector    = 0;
    my $kxvariance  = 0;
    my $kyvariance  = 0;
    
    #my $counter = 0;
    #print "X-Vector lenght: ".$#{$xvector}." - ".${$xvector}[0]."\n";
    #print "Y-Vector lenght: ".$#{$yvector}."\n";
    #print "X-Var lenght: ".$#{$xvariance}."\n";
    #print "Y-Var lenght: ".$#{$yvariance}."\n";
    
    for(my $i=0;$i<$#{$xvector};$i++){
        
            $kxvector   = $kxvector + ${$xvector}[$i] if ${$xvector}[$i] ;
            $kyvector   = $kyvector + ${$yvector}[$i] if ${$yvector}[$i] ;
            $kxvariance = $kxvariance + ${$xvariance}[$i] if ${$xvariance}[$i] ;
            $kyvariance = $kyvariance + ${$yvariance}[$i] if ${$yvariance}[$i] ;
            
            #print "$counter:kxvector: $kxvector\n";
            #print "$counter:kyvector: $kyvector\n";
            #print "$counter:kxvariance: $kxvariance\n";
            #print "$counter:kyvariance: $kyvariance\n";
            
            #$counter++;
            
    }
    
    # Calculates ^x and ^y (means)
    my $xmean = $kxvector;
    my $ymean = $kyvector;
    
    # Calculates correlation coefficent
    my $correlation = correlation($xvector, $yvector);
    
    # Calculates the cocient
    my $cocient = 0;
    my $first_term = 0;
    if($ymean != 0){
       # print $ymean."\n";
        $cocient = $xmean/$ymean;
        # Calculates the variance (STEP-BY-STEP)
        $first_term = 1/($ymean*$ymean);
    }
    
    
    my $second_term_first_term = $kxvariance;
    my $second_term_second_term = ($cocient*$cocient)*$kyvariance;
    my $second_term_third_term = 2*$cocient*$correlation*(sqrt($kxvariance))*(sqrt($kyvariance));
    my $second_term = $second_term_first_term + $second_term_second_term - $second_term_third_term;
    
    my $cocient_variance = $first_term*$second_term;
    
    # Wanna debug?
    #print "Correlation: $correlation\n";
    #print "First term: 1/$ymean $first_term\n";
    #print "Second term - First term: $second_term_first_term\n";
    #print "Second term - Second term: $second_term_second_term\n";
    #print "Second term - Third term: $second_term_third_term\n";
    #print "Second term: $second_term\n";
    #print "Cocient variance: $cocient_variance\n";
    
    # ..Fiu!
    
    # It seems a zero-value for variance is not allowed in function $zed->score 
    #$cocient_variance == 0 ? $cocient_variance = 0.000001 : $cocient_variance;
    
    # Creates the ztest obj with default values (see perldoc Statistics::Zed to settings this values)
    my $zed = Statistics::Zed->new();
    my ($z_value, $p_value, $observed_deviation, $standar_deviation) = $zed->score(observed => $cocient, expected => 1, variance => $cocient_variance);

    # Create a hash for the returning value with all the calculated params
    my %hash = ();
    
    $hash{xsum}               = $kxvector;
    $hash{ysum}               = $kyvector;
    $hash{x_var_sum}          = $kxvariance;
    $hash{y_var_sum}          = $kyvariance;
    $hash{cocient}            = $cocient;
    $hash{correlation}        = $correlation;
    $hash{cocient_variance}   = $cocient_variance;
    $hash{z_value}            = $z_value;
    $hash{p_value}            = $p_value;
    $hash{observed_deviation} = $observed_deviation;
    $hash{standar_deviation}  = $standar_deviation;

    
    return %hash;
    
}

1;