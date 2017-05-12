package Finance::StockAccount::Transaction;

our $VERSION = '0.01';

use Time::Moment;

use Finance::StockAccount::Stock;

use strict;
use warnings;

use constant BUY        => 0;
use constant SELL       => 1;
use constant SHORT      => 2;
use constant COVER      => 3;

my $lineFormatPattern = "%-35s %-6s %-6s %8s %7.2f %10.2f %5.2f %10.2f\n";
my $headerPattern = "%-35s %-6s %-6s %8s %7s %10s %5s %10s\n";
my @headerNames = qw(Date Symbol Action Quantity Price Commission Fees CashEffect);

sub new {
    my ($class, $init) = @_;
    my $self = {
        tm                  => undef,
        action              => undef,
        stock               => undef,
        quantity            => undef,
        price               => undef,
        commission          => 0,
        regulatoryFees      => 0,
        otherFees           => 0,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub order {
    return qw(date action stock quantity price commission regulatoryFees otherFees);
}

sub tm { # Time::Moment object getter/setter
    my ($self, $tm) = @_;
    if ($tm) {
        if (ref($tm) and ref($tm) eq 'Time::Moment') {
            $self->{tm} = $tm;
            return 1;
        }
        else {
            warn "$tm not a valid Time::Moment object.\n";
            return 0;
        }
    }
    else {
        return $self->{tm};
    }
}


sub dateString {
    my ($self, $dateString) = @_;
    if ($dateString) {
        my $tm = Time::Moment->from_string($dateString);
        if ($tm) {
            $self->{tm} = $tm;
            return 1;
        }
        else {
            warn "Unable to create Time::Moment object from date string $dateString.\n";
            return 0;
        }
    }
    else {
        my $tm = $self->{tm};
        if ($tm) {
            return $tm->to_string();
        }
        else {
            warn "Time::Moment property not set.\n";
            return undef;
        }
    }
}

sub action {
    my ($self, $action) = @_;
    if ($action) {
        if ($action eq 'buy') {
            return $self->buy(1);
        }
        elsif ($action eq 'sell') {
            return $self->sell(1);
        }
        elsif ($action eq 'short') {
            return $self->short(1);
        }
        elsif ($action eq 'cover') {
            return $self->cover(1);
        }
        else {
            die "Action must a string, one of 'buy', 'sell', 'short', 'cover'.\n";
        }
    }
    else {
        return $self->{action};
    }
}

sub stock {
    my ($self, $stock) = @_;
    if ($stock) {
        if (ref($stock) and 'Finance::StockAccount::Stock' eq ref($stock)) {
            $self->{stock} = $stock;
            return 1;
        }
        else {
            warn "$stock is not a recognized Finance::StockAccount::Stock object.\n";
            return 0;
        }
    }
    else {
        $stock = $self->{stock};
        if (!$stock) {
            $stock = Finance::StockAccount::Stock->new();
            $self->{stock} = $stock;
        }
        return $stock;
    }
}

sub sameStock {
    my ($self, $testStock) = @_;
    my $stock = $self->{stock};
    if ($stock) {
        return $stock->same($testStock);
    }
    else {
        warn "Can't test for sameStock, object stock property not yet defined.\n";
        return 0;
    }
}

sub symbol {
    my ($self, $symbol) = @_;
    my $stock = $self->stock();
    return $stock->symbol($symbol);
}

sub exchange {
    my ($self, $exchange) = @_;
    my $stock = $self->stock();
    return $stock->exchange($exchange);
}

sub quantity {
    my ($self, $quantity) = @_;
    if ($quantity) {
        $self->{quantity} = $quantity;
        return 1;
    }
    else {
        return $self->{quantity};
    }
}

sub price {
    my ($self, $price) = @_;
    if ($price) {
        $self->{price} = $price;
        return 1;
    }
    else {
        return $self->{price};
    }
}

sub commission {
    my ($self, $commission) = @_;
    if ($commission) {
        $self->{commission} = $commission;
        return 1;
    }
    else {
        return $self->{commission};
    }
}

sub regulatoryFees {
    my ($self, $regulatoryFees) = @_;
    if ($regulatoryFees) {
        $self->{regulatoryFees} = $regulatoryFees;
        return 1;
    }
    else {
        return $self->{regulatoryFees};
    }
}

sub otherFees {
    my ($self, $otherFees) = @_;
    if ($otherFees) {
        $self->{otherFees} = $otherFees;
        return 1;
    }
    else {
        return $self->{otherFees};
    }
}

sub priceByQuantity {
    my $self = shift;
    return $self->{price} * $self->{quantity};
}

sub feesAndCommissions {
    my $self = shift;
    return $self->{commission} + $self->{regulatoryFees} + $self->{otherFees};
}

sub cashEffect {
    my $self = shift;
    my $cashEffect;
    if ($self->buy() or $self->short()) {
        $cashEffect = 0 - ($self->priceByQuantity() + $self->feesAndCommissions());
    }
    elsif ($self->sell() or $self->cover()) {
        $cashEffect = $self->priceByQuantity() - $self->feesAndCommissions();
    }
    if ($cashEffect) {
        return $cashEffect;
    }
    else {
        warn "Cannot calculate cash effect.\n";
        return 0;
    }
}

sub set {
    my ($self, $init) = @_;
    my $status = 1;
    foreach my $key (keys %{$init}) {
        if (exists($self->{$key})) {
            if ($key eq 'action') {
                $self->action($init->{$key});
            }
            elsif ($key eq 'tm') {
                $self->tm($init->{$key});
            }
            else {
                $self->{$key} = $init->{$key};
            }
        }
        elsif ($key eq 'symbol') {
            $self->symbol($init->{$key}); 
        }
        elsif ($key eq 'exchange') {
            $self->exchange($init->{$key});
        }
        elsif ($key eq 'dateString') {
            $self->dateString($init->{$key});
        }
        else {
            $status = 0;
            warn "Tried to set $key in StockAccount::Transaction object, but that's not a known key.\n";
        }
    }
    return $status;
}

sub get {
    my ($self, $key) = @_;
    if ($key and exists($self->{$key})) {
        return $self->{$key};
    }
    else {
        warn "Tried to get key from StockAccount::Transaction object, but that's not a known key.\n";
        return 0;
    }
}

sub validateAction {
    my $self = shift;
    if (!defined($self->{action})) {
        die "Action has not yet been set.";
        return 0;
    }
    else {
        return 1;
    }
}

sub buy {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = BUY;
        return 1;
    }
    else {
        $self->validateAction();
        return $self->{action} == BUY;
    }
}

sub sell {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = SELL;
        return 1;
    }
    else {
        $self->validateAction();
        return $self->{action} == SELL;
    }
}

sub short {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = SHORT;
        return 1;
    }
    else {
        $self->validateAction();
        return $self->{action} == SHORT;
    }
}

sub cover {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = COVER;
        return 1;
    }
    else {
        $self->validateAction();
        return $self->{action} == COVER;
    }
}

sub actionString {
    my $self = shift;
    if ($self->buy()) {
        return 'buy';
    }
    elsif ($self->sell()) {
        return 'sell';
    }
    elsif ($self->short()) {
        return 'short';
    }
    elsif ($self->cover()) {
        return 'cover';
    }
    else {
        return '';
    }
}

sub string {
    my $self = shift;
    my $pattern = "%14s %-35s\n";
    my $string;
    foreach my $key ($self->order()) {
        if (defined($self->{$key})) {
            if ($key eq 'stock') {
                my $symbol = $self->symbol();
                my $exchange = $self->exchange();
                if (defined($symbol)) {
                    $string .= sprintf($pattern, 'symbol', $self->symbol());
                }
                if (defined($exchange)) {
                    $string .= sprintf($pattern, 'exchange', $self->exchange());
                }
            }
            else {
                my $value;
                if ($key eq 'action') {
                    $value = $self->actionString();
                }
                else {
                    $value = $self->{$key};
                }
                $string .= sprintf($pattern, $key, $value);
            }
        }
        elsif ($key eq 'date') {
            if ($self->{tm}) {
                $string .= sprintf($pattern, $key, $self->dateString());
            }
        }
    }
    return $string;
}

sub lineFormatHeader {
    return sprintf($headerPattern, @headerNames);
}

sub lineFormatPattern {
    return $lineFormatPattern;
}

sub lineFormatValues {
    my $self = shift;
    return [
        $self->{tm} || '', $self->symbol(), $self->actionString(), $self->{quantity}, $self->{price} || 0,
        $self->{commission} || 0, ($self->{regulatoryFees} + $self->{otherFees}) || 0, $self->cashEffect() || 0
    ];
}

sub lineFormatString {
    my $self = shift;
    return sprintf($lineFormatPattern, @{$self->lineFormatValues()});
}


1;

__END__

=pod

=head1 NAME

Finance::StockAccount::Transaction

=head1 SYNOPSIS

    my $ftr = Finance::StockAccount::Stock->new({
        symbol          => 'FTR',
        exchange        => 'NASDAQ',
    });

    my $st = Finance::StockAccount::Transaction->new({
        date            => $dt,
        action          => Finance::StockAccount::Transaction::SELL,
        stock           => $ftr,
        quantity        => 42,
        price           => 7.11,
        commission      => 8.95,
        regulatoryFees  => 0.01,
    });

    print $st->price(), "\n"; # prints number 7.11

=head1 PROPERTIES

These are the public properties of a StockAccount::Transaction object:

    date                # 'presumed' DateTime object.  See http://datetime.perl.org/wiki/datetime/dashboard and discussion below.
    action              # One of module constants BUY, SELL, SHORT, COVER
    stock               # A Finance::StockAccount::Stock object
    quantity            # How many shares were bought or sold, e.g. 100 or 5.
    price               # Numeric representation of price, e.g. 4.65 instead of the string '$4.65'.
    commission          # Numeric representation of commission in same currency, e.g. 8.95 instead of the string '$8.95'.
    regulatoryFees      # Numeric representation of the regulatory fees, see section on "Regulatory Fees" below.
    otherFees           # Numeric aggregation of any other fees not included in commission and regulatory fees.

Any public property can be instantiated in the C<new> method, set with a method
matching the name of the property, such as C<$st->date($dt)>, or set with the
C<set> method, e.g. C<$st->set({date => $dt})>, as specified further in the
method description below.

Public properties can also be retrieved by the same method matching the name of
the property when no parameter is passed, e.g. C<$st->date()>.  Or by the
C<get> method with a string naming the property, e.g. C<$st->get('price')>.

All properties can also be read or written directly with a hash dereference.
Some people don't consider this good object-oriented practice, but I won't stop
you if that's what you want to do.  E.g. C<$st->{date} = $dt> or
C<$st->{price}>.

=head1 REGULATORY FEES

In the United States the Securities and Exchange Commission imposes regulatory
fees on stock brokers or dealers.  Instead of paying these with their profits,
these for-profit companies often pass these fees onto their customers directly.
The C<regulatoryFees> property could be used for similar purposes in other
jurisdictions.

See http://www.sec.gov/answers/sec31.htm for more information.

=cut
