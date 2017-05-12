package Finance::StockAccount::Acquisition;

our $VERSION = '0.01';

use strict;
use warnings;

use Carp;

use Finance::StockAccount::AccountTransaction;


sub new {
    my ($class, $at, $shares) = @_;
    my $self = {
        at                  => undef,
        shares              => 0,
        cashEffect          => 0,
        commission          => 0,
        regulatoryFees      => 0,
        otherFees           => 0,
    };
    bless($self, $class);
    $self->init($at, $shares);
    return $self;
}

sub at {
    my ($self, $at) = @_;
    if ($at) {
        if (ref($at) and ($at->buy() or $at->short())) {
            $self->{at} = $at;
            return 1;
        }
        else {
            confess "Acquisition requires a valid AccountTransaction object of type buy or short.";
            return 0;
        }
    }
    else {
        return $self->{at};
    }
}

sub cashEffect         { return shift->{cashEffect};         }
sub commission         { return shift->{commission};         }
sub regulatoryFees     { return shift->{regulatoryFees};     }
sub otherFees          { return shift->{otherFees};          }
sub shares             { return shift->{shares};             }

sub tm {
    my $self = shift;
    my $at = $self->{at};
    return $at->tm();
}

sub proportion {
    my $self = shift;
    my $shares = $self->{shares};
    my $at = $self->{at};
    my $quantity = $at->quantity();
    return $shares / $quantity;
}

sub compute {
    my $self = shift;
    my $proportion = $self->proportion();
    my $at = $self->at();
    $self->{cashEffect}     = $at->cashEffect() * $proportion;
    $self->{commission}     = $at->commission() * $proportion;
    $self->{regulatoryFees} = $at->regulatoryFees() * $proportion;
    $self->{otherFees}      = $at->otherFees() * $proportion;
    return 1;
}

sub init {
    my ($self, $at, $shares) = @_;
    if (!($at and $shares)) {
        confess "Acquisition->new constructor requires \$at (AccountTransaction) and shares count parameters.\n";
    }
    if ($shares =~ /^[0-9]+$/ and $shares > 0) {
        $self->at($at);
        $self->{shares} = $shares;
        $self->compute();
        return 1;
    }
    else {
        confess "Acquisition::Init requires numeric positive shares value, got $shares.\n";
        return 0;
    }
}

sub lineFormatValues {
    my $self = shift;
    my $at = $self->{at};
    my $lineFormatValues = $at->lineFormatValues();
    $lineFormatValues->[3] = $self->{shares};
    $lineFormatValues->[5] = $self->{commission};
    $lineFormatValues->[6] = $self->{regulatoryFees} + $self->{otherFees};
    $lineFormatValues->[7] = $self->{cashEffect};
    return $lineFormatValues;
}

sub lineFormatString {
    my $self = shift;
    return sprintf(Finance::StockAccount::Transaction->lineFormatPattern(), @{$self->lineFormatValues()});
}




1;
