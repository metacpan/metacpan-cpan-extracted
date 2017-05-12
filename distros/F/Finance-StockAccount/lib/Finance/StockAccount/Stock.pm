package Finance::StockAccount::Stock;

our $VERSION = '0.01';

use strict;
use warnings;

sub new {
    my ($class, $init) = @_;
    my $self = {
        symbol              => undef,
        exchange            => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub set {
    my ($self, $init) = @_;
    for my $key (keys %$init) {
        if (exists($self->{$key})) {
            $self->{$key} = $init->{$key};
            return 1;
        }
        else {
            warn "Tried to set $key in Finance::StockAccount::Stock object, but that's not a known key.\n";
            return 0;
        }
    }
}

sub symbol {
    my ($self, $symbol) = @_;
    if ($symbol) {
        $self->{symbol} = $symbol;
        return 1;
    }
    else {
        return $self->{symbol};
    }
}

sub exchange {
    my ($self, $exchange) = @_;
    if ($exchange) {
        $self->{exchange} = $exchange;
        return 1;
    }
    else {
        return $self->{exchange};
    }
}

sub same {
    my ($self, $stock) = @_;
    my $symbol = $self->symbol();
    if ($symbol and $symbol eq $stock->symbol()) {
        my $exchange = $self->exchange();
        if ($exchange or $stock->exchange()) {
            if ($exchange eq $stock->exchange()) {
                return 1;
            }
            else {
                return 0;
            }
        }
        return 1;
    }
    else {
        return 0;
    }
}

sub hashKey {
    my $self = shift;
    my $symbol = $self->{symbol};
    my $exchange = $self->{exchange};
    if ($symbol and $exchange) {
        return "$symbol:$exchange";
    }
    elsif ($symbol) {
        return $symbol;
    }
    else {
        warn "Cannot generate hash key when stock symbol not set.\n";
        return undef;
    }
}



1;

__END__



    symbol              # Vernacular stock symbol string, e.g. 'AAPL', 'QQQ', or 'VZ'.
    exchange            # Optional specification of stock exchange to be associate with symbol, e.g. 'NASDAQ'.
