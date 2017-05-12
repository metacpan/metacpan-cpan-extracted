package Finance::StockAccount::Import;

our $VERSION = '0.01';

use strict;
use warnings;

use Carp;

use Finance::StockAccount;
use Finance::StockAccount::AccountTransaction;

sub new {
    my ($class, $file, $tzoffset) = @_;
    $file or confess "Please pass a file to import.\n";
    my $self = {
        file                => $file,
        fh                  => undef,
        headers             => undef,
        tzoffset            => $tzoffset || 0,
    };
    return bless($self, $class);
}

sub renameMe {
    my ($self, $key, $value) = @_;
    if ($key eq 'date') {
        $self->extractDate($value) or return 0;
    }
    elsif ($key eq 'price') {
        $self->extractPrice($value) or return 0;
    }
    elsif ($key eq 'commission') {
        $self->extractCommission($value) or return 0;
    }
    elsif ($key eq 'symbol') {
        $self->extractSymbol($value) or return 0;
    }
}

sub extractPrice {
    my ($self, $priceString) = @_;
    my $pricePattern = '';
    if ($priceString =~ /$pricePattern/) {
        my $price = $1;
        $price =~ s/,//g;
        $self->{price} = $price;
    }
    else {
        warn "Failed to recognize price pattern in string $priceString.\n";
        return 0;
    }
}

sub extractCommission {
    my ($self, $commissionString) = @_;
    my $pricePattern = '';
    if ($commissionString =~ /$pricePattern/) {
        my $commission = $1;
        $commission =~ s/,//g;
        $self->{commission} = $commission;
    }
    else {
        warn "Failed to recognize commission pattern in string $commissionString.\n";
        return 0;
    }
}

sub extractSymbol {
    my ($self, $symbolString) = @_;
    my $symbolPattern = '';
    if ($symbolString =~ /$symbolPattern/) {
        $self->{symbol} = $1;
    }
    else {
        warn "Failed to recognize symbol pattern in string $symbolString.\n";
        return 0;
    }
}

sub nextAt {
    # method that returns the next AccountTransaction object,
    # to be overridden by child classes
    return 0;
}

sub stockAccount {
    my $self = shift;
    my $sa = Finance::StockAccount->new();
    while (my $at = $self->nextAt()) {
        $sa->addToSet($at);
    }
    return $sa;
}











1;
