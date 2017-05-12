package Finance::StockAccount::Realization;

our $VERSION = '0.01';

use strict;
use warnings;

use Time::Moment;
use Carp;

use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Acquisition;

# qw(Symbol ROI Outlays Revenues Profit)
my $summaryPattern = "%-6s %7.4f %12.2f %12.2f %53.2f\n";

sub new {
    my ($class, $init) = @_;
    my $self = {
        stock               => undef,
        divestment          => undef,
        acquisitions        => [],
        costBasis           => 0,
        revenue             => 0,
        realized            => 0,
        commissions         => 0,
        regulatoryFees      => 0,
        otherFees           => 0,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub addAcquisition {
    my ($self, $acquisition, $dateLimitPortion) = @_;
    if (!defined($dateLimitPortion)) {
        $dateLimitPortion = 1; # Assume no date limit restriction if none specified, i.e., none by default
    }
    my $shares = $acquisition->shares();
    my $divestment = $self->{divestment};
    my $divQuantity = $divestment->quantity();
    my $divestedPortion;
    if ($divQuantity) {
        $divestedPortion = $shares / $divQuantity;
    }
    else {
        croak "No shares divested in transaction, cannot proceed with realization.";
    }

    my $divCommission     += $divestedPortion * $divestment->commission();
    my $divRegulatoryFees += $divestedPortion * $divestment->regulatoryFees();
    my $divOtherFees      += $divestedPortion * $divestment->otherFees();

    my $costBasis = 0 - $dateLimitPortion * $acquisition->cashEffect();
    my $revenue   = $dateLimitPortion * $divestedPortion * $divestment->cashEffect();
    $self->{costBasis}      += $costBasis;
    $self->{revenue}        += $revenue;
    $self->{realized}       += $revenue - $costBasis;
    $self->{commissions}    += $dateLimitPortion * ($acquisition->commission()     + $divCommission    );
    $self->{regulatoryFees} += $dateLimitPortion * ($acquisition->regulatoryFees() + $divRegulatoryFees);
    $self->{otherFees}      += $dateLimitPortion * ($acquisition->otherFees()      + $divOtherFees     );

    push(@{$self->{acquisitions}}, $acquisition);
    return 1;
}

sub set {
    my ($self, $init) = @_;
    my $status = 1;
    foreach my $key (keys %{$init}) {
        if (exists($self->{$key})) {
            if ($key eq 'divestment') {
                my $divestment = $init->{$key};
                if ($divestment and ref($divestment)) {
                    $self->{divestment} = $divestment;
                }
                else {
                    $status = 0;
                    warn "Invalid divestment value in Realization intialization hash.\n";
                }
            }
            elsif ($key eq 'stock') {
                $self->{$key} = $init->{$key};
            }
            else {
                $status = 0;
                warn "Unable to initialize Realization object with $key parameter.\n";
            }
        }
        else {
            $status = 0;
            warn "Tried to set $key in Realization object, but that's not a known key.\n";
        }
    }
    return $status;
}

sub ROI {
    my $self = shift;
    my $costBasis = $self->{costBasis};
    if ($costBasis) {
        return $self->{realized} / $costBasis;
    }
    else {
        warn "Realize method finds no cost basis upon which to compute ROI.\n";
        return undef;
    }
}

sub acquisitionCount {
    my $self = shift;
    return scalar(@{$self->{acquisitions}});
}

sub startDate {
    my $self = shift;
    my $startDate;
    foreach my $acquisition (@{$self->{acquisitions}}) {
        if (!$startDate) {
            $startDate = $acquisition->tm();
        }
        else {
            my $tm = $acquisition->tm();
            if ($tm < $startDate) {
                $startDate = $tm;
            }
        }
    }
    return $startDate;
}

sub endDate {
    my $self = shift;
    my $divestment = $self->{divestment};
    return $divestment->tm();
}


sub divestment          { return shift->{divestment};           }
sub acquisitions        { return shift->{acquisitions};         }
sub costBasis           { return shift->{costBasis};            }
sub revenue             { return shift->{revenue};              }
sub realized            { return shift->{realized};             }
sub commissions         { return shift->{commissions};          }
sub regulatoryFees      { return shift->{regulatoryFees};       }
sub otherFees           { return shift->{otherFees};            }

sub headerString {
    return Finance::StockAccount::Transaction->lineFormatHeader() . '-'x94 . "\n" .
        sprintf("%-6s %7s %12s %12s %53s\n", qw(Symbol ROI Outlays Revenues Profit));
}

sub divestmentLineFormatString {
    my $self = shift;
    my $divestment = $self->{divestment};
    my $proportion = $divestment->accounted() / $divestment->quantity();
    my $lineFormatValues = $divestment->lineFormatValues();
    $lineFormatValues->[5] *= $proportion;
    $lineFormatValues->[6] *= $proportion;
    $lineFormatValues->[7] *= $proportion;
    return sprintf(Finance::StockAccount::Transaction->lineFormatPattern(), @$lineFormatValues);
}

sub string {
    my $self = shift;
    my $divestment = $self->{divestment};
    my $string;
    foreach my $acquisition (@{$self->{acquisitions}}) {
        $string .= $acquisition->lineFormatString();
    }
    $string .= $self->divestmentLineFormatString . '-'x94 . "\n" .
        sprintf($summaryPattern, $divestment->symbol(), $self->ROI() || 0, (0 - $self->{costBasis}) || 0, $self->{revenue} || 0, $self->{realized} || 0);
    return $string;
}





1;
