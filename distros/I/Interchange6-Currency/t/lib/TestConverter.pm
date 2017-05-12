package TestConverter;

use Moo;

my %rates = (
    GBP => {
        BHD => 0.559786,
        EUR => 1.3523,
        JPY => 120.957,
        USD => 1.48319,
    },
    EUR => {
        GBP => 0.7388,
        USD => 1.09642,
    },
    USD => {
        GBP => 0.67388,
        EUR => 0.91216,
    }
);

sub convert {
    my ( $self, $value, $from_code, $to_code ) = @_;

    return
      defined $rates{$from_code}->{$to_code}
      ? $rates{$from_code}->{$to_code} * $value
      : undef;
}

1;
