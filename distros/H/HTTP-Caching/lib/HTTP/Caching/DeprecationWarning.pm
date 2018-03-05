package HTTP::Caching::DeprecationWarning;

use strict;
use warnings;

use feature 'state';

use Carp;

my $hide_deprecation_warning;

sub import {
    $hide_deprecation_warning = 1 if $_[1] and $_[1] eq ':hide';
    __PACKAGE__->show_once();
}

sub show_once {
    my $class = shift;
    state $did_show_deprecation_warning;
    
    $did_show_deprecation_warning =
        $class->show()
        unless $did_show_deprecation_warning;
}

sub show {
    my $class = shift;
    
    return if
        $hide_deprecation_warning
        or
        $ENV{HTTP_CACHING_DEPRECATION_WARNING_HIDE};

    my $deprecation_warning = q{
        
        ########################################################################
        ####                                                                ####
        #### DEPRECATION WARNING !!!                                        ####
        ####                                                                ####
        #### This module is going to be completely redesigned!!!            ####
        ####                                                                ####
        #### As it was planned, these are the brains, but unfortunately, it ####
        #### has become an implementation.                                  ####
        ####                                                                ####
        #### The future version will answer two questions:                  ####
        #### - may_store                                                    ####
        #### - may_reuse                                                    ####
        ####                                                                ####
        #### Those are currently implemented as private methods.            ####
        ####                                                                ####
        #### Please contact the author if you rely on this module directly  ####
        #### to prevent breakage                                            ####
        ####                                                                ####
        #### Sorry for any inconvenience                                    ####
        ####                                                                ####
        #### ADVICE:                                                        ####
        ####                                                                ####
        #### Please use the latest version of:                              ####
        #### - LPW::UserAgent::Caching                                      ####
        #### - LWP::UserAgent::Caching::Simple                              ####
        ####                                                                ####
        ########################################################################
        
};
    
    return carp $deprecation_warning

}

1;
