package Geo::UK::Postcode::Regex::Hash;

our $VERSION = '0.015';

require Tie::Hash;

our @ISA = qw/ Tie::StdHash /;

sub TIEHASH {
    my $class = shift;
    return bless {@_}, $class;
}

sub FETCH {
    my ( $this, $key ) = @_;
    $this->{$key} //= $this->{_fetch}->($key);
    return $this->{$key};
}

1;

