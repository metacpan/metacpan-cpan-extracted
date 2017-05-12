package Medical::DukePTP;

use warnings;
use strict;

=head1 NAME

Medical::DukePTP - Calculate the Duke pre-test probability of CAD

=head1 VERSION

Version 0.3

=cut

our $VERSION = '0.3';


=head1 SYNOPSIS

    use Medical::DukePTP;
    
    my $rh_params = { 
        'smoking'      => 1,
        'diabetes'     => 1,
        'age'          => 55,
        'sex'          => 'male',
        'chest_pain'   => 'typical',
    };

    my $ptp = Medical::DukePTP::ptp( $rh_params );

=head1 BACKGROUND


Important diagnostic and prognostic outcomes can be predicted from 
information collected by the physician as a part of the initial 
assessement. Despite the fact that much of the clinical information 
collected by a physician is "soft" or subjective data, predictions
of outcome based on the information from the initial evaluation are accurate
and can be deployed in order to identify "high" and "low" risk patients.

This module implements the Duke pre-test probability of a patient 
having significant Coronary Artery Disease. This is accomplished by
taking into consideration symptom typicality, sex, age and cardiovascular
risk factors such as diabetes or high cholesterol.

The method is based on:

    Pryor D.B. et al., "Value of the history and physical in 
    identifying patients at increased risk of CAD", Ann Int Med 1993, 118:81-90

The PubMed entry for the paper:

L<http://www.ncbi.nlm.nih.gov/pubmed/8416322?ordinalpos=&itool=EntrezSystem2.PEntrez.Pubmed.Pubmed_ResultsPanel.SmartSearch&log$=citationsensor>

=head1 FUNCTIONS

=head2 ptp

Accepts a reference to a hash with parameters and returns a scalar 
which denotes the pre-test probability of coronary artery disease.
Note that the value is rounded upwards.

Required parameters include:

    sex : 'male' or 'female'
    age : numerical age of patient
    
Optional parameters

    chest_pain     : 'typical' or 'atypical'
    previous_MI    : history of previous Myocardial Infarction (1 for yes)
    ECG_Q_wave     : ECG Q waves of previous Myocardial Infarction (1 for yes) 
    ECG_ST-T_wave  : ECG ST changes at rest (1 for yes)
    smoking        : current smoker (1 for yes)
    hyperlipidemia : cholesterol > 6.5 mmol/l (>250 mg/dl) (1 for yes)
    diabetes       : diabetic (1 for yes)
    
This function will return I<undef> on error.

=cut

sub ptp {
    my $rh = shift;
    
    ##
    ## validate input structure

    return unless 
        ( defined $rh && $rh && ref($rh) eq 'HASH');
    
    ##
    ## validate input params
    
    foreach my $k qw(age sex) {
        return unless 
            ( defined( $rh->{$k} ) );
    }
    
    ##
    ## fill in some defaults 
    
    for my $k qw(smoking hyperlipidemia 
                 diabetes previous_MI ECG_Q_wave ECG_ST-T_wave) {
    
        $rh->{$k} ||= 0;
    }
    
    ##
    ## process the 'sex' 
    
    if ( $rh->{'sex'} eq 'male' ) {
        $rh->{'sex'} = 0;
    } elsif ( $rh->{'sex'} eq 'female') {
        $rh->{'sex'} = 1;
    } else {
        die "Unknown sex variable: $rh->{'sex'}";
    }
    
    ##
    ## process the chest pain typicality
    
    # In the event of non-specific chest pain
    # no action is required as there is no coefficient used  
    
    my $typical_angina          = 0;
    my $atypical_angina         = 0;
    
    if ( defined $rh->{'chest_pain'} ) {
       if ( $rh->{'chest_pain'} eq 'typical' ) {
           $typical_angina = 1;
       } elsif ( $rh->{'chest_pain'} eq 'atypical' ) {
           $atypical_angina = 1; 
       }
   }     
    
    my $intercept = -7.376;
    
    my $baseline = 
    
       ( $rh->{'age'}        * 0.1126 ) +
       ( $rh->{'sex'}        * -0.328 ) +
       ( $typical_angina     * 2.581  ) +
       ( $atypical_angina    * 0.976  ) +
       ( $rh->{'ECG_Q_wave'}  * 1.213  ) +
       ( $rh->{'ECG_ST-T_wave'} * 0.637 ) +
       ( $rh->{'previous_MI'} * 1.093  );
     
   my $risk_factors = 
       
       ( $rh->{'smoking'}        * 2.596  ) +
       ( $rh->{'diabetes'}       * 0.694  ) +
       ( $rh->{'hyperlipidemia'} * 1.845  );     
    
    my $interactions = 
        
        ( $rh->{'age'}         * $rh->{'sex'}            * -0.0301 ) +
        ( $rh->{'previous_MI'} * $rh->{'ECG_Q_wave'}     * 0.741   ) +
        ( $rh->{'age'}         * $rh->{'smoking'}        * -0.0404 ) +
        ( $rh->{'age'}         * $rh->{'hyperlipidemia'} * -0.0251 ) + 
        ( $rh->{'sex'}         * $rh->{'smoking'}        * 0.550   );
    
    my $raw_score = 
        $intercept    +
        $baseline     +
        $risk_factors +
        $interactions;       

    my $raw_p = 1 / ( 1 + exp(1) ** ( $raw_score * -1 ) );
    
    my $p = 100 * ( abs( $raw_p ) );
    
    return (int( $p + .5 ));
}

=head1 AUTHOR

Spiros Denaxas, C<< <s.denaxas at gmail.com> >>

=head1 SOURCE CODE

The source code can be found on github L<https://github.com/spiros/Medical-DukePTP>

=head1 BUGS

Please report any bugs or feature requests to C<bug-medical-dukeptp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Medical-DukePTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Medical::DukePTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Medical-DukePTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Medical-DukePTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Medical-DukePTP>

=item * Search CPAN

L<http://search.cpan.org/dist/Medical-DukePTP/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2011 Spiros Denaxas.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Medical::DukePTP
