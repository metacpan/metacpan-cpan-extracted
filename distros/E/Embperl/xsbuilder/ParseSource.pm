package Embperl::ParseSource;

use strict;
use Config ();

use vars qw{@ISA $VERSION $MMARGS} ;

use ExtUtils::XSBuilder::ParseSource  ;
use FindBin ;

@ISA = ('ExtUtils::XSBuilder::ParseSource') ;

$VERSION = '2.0.0';




# ============================================================================

sub include_paths {
    my $self = shift;

    local $MMARGS ;

    if (-f 'WrapXS/mmargs.pl')
        {
        do 'WrapXS/mmargs.pl' ;
        die $@ if ($@) ;
        }

    $MMARGS ||= {} ;

    my @inc = split (/\s+/, $MMARGS -> {INC}) ;
    @inc = map { /-I(.*?)$/; $1 } @inc ;
    push @inc, "$FindBin::Bin/.." ;

    return \@inc ;
}



# ============================================================================
sub find_includes {
    my $self = shift;

    return $self->{includes} if $self->{includes};
    my @includes = ("$FindBin::Bin/../epdat2.h", "$FindBin::Bin/../eppublic.h", "$FindBin::Bin/../eptypes.h", ) ;

    return $self->{includes} = $self -> sort_includes (\@includes) ;
    }




# ============================================================================

sub package { 'Embperl' } 

# ============================================================================

sub targetdir { "$FindBin::Bin/tables" }

# ============================================================================


sub preprocess {
    my $self     = shift ;

    $_[0] =~ s/pTHX_?//g ;

}



1;
__END__
