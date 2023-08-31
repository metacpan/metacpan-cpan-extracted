package Finance::Random::Price;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Currency;
use Error::Pure qw(err);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Price currencies.
	$self->{'currencies'} = ['CZK'];

	# Decimal numbers.
	$self->{'decimal_num'} = undef;

	# Min/max value..
	$self->{'min'} = 0;
	$self->{'max'} = 10000;

	# Process params.
	set_params($self, @params);

	if (! defined $self->{'min'}) {
		err "Parameter 'min' is required.";
	}
	if ($self->{'min'} !~ m/^\-?\d+\.?\d*$/ms) {
		err "Parameter 'min' must be a number.";
	}
	if (! defined $self->{'max'}) {
		err "Parameter 'max' is required.";
	}
	if ($self->{'max'} !~ m/^\-?\d+\.?\d*$/ms) {
		err "Parameter 'max' must be a number.";
	}
	if ($self->{'max'} < $self->{'min'}) {
		err "Parameter 'max' must be greater than parameter 'min'.";
	}
	if (defined $self->{'decimal_num'}) {
		if ($self->{'decimal_num'} !~ m/^\-?\d+$/ms) {
			err "Parameter 'decimal_num' must be a number.";
		}
		if ($self->{'decimal_num'} < 0) {
			err "Parameter 'decimal_num' must be greater than 0.";
		}
		if ($self->{'decimal_num'} > 2) {
			err "Parameter 'decimal_num' must be lesser than 3.";
		}
	}

	# Object.
	return $self;
}

sub random {
	my $self = shift;

	my $dec_mul = $self->{'decimal_num'} ? $self->{'decimal_num'} * 10 : 1;

	my $rand_currency = int(rand(scalar @{$self->{'currencies'}}));
	my $rand_value = int(rand(($self->{'max'} - $self->{'min'} + 1) * $dec_mul))
		/ $dec_mul + $self->{'min'};

	my $price = Data::Currency->new($rand_value, $self->{'currencies'}->[$rand_currency]);

	return $price; 
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Finance::Random::Price - Perl class for creating random image.

=head1 SYNOPSIS

 use Finance::Random::Price;

 my $obj = Finance::Random::Price->new(%parameters);
 my $price = $obj->random;

=head1 METHODS

=head2 C<new>

 my $obj = Finance::Random::Price->new(%parameters);

Constructor.

=over 8

=item * C<currencies>

Reference to array with possible currencies.

Default value is ['CZK'].

=item * C<decimal_num>

Number of decimal characters in number. Possible values are undef, 1 or 2.

Default value is undef.

=item * C<min>

Minimal value for random price.

Default value is 0.

=item * C<max>

Maximal value for random price.

Default value is 100.

=back

Returns instance of object.

=head2 C<random>

 my $price = $obj->random;

Get random price.

Returns Data::Currency object.

=head1 ERRORS

 new():
         Parameter 'decimal_num' must be a number.
         Parameter 'decimal_num' must be greater than 0.
         Parameter 'decimal_num' must be lesser than 3.
         Parameter 'min' is required.
         Parameter 'min' must be a number.
         Parameter 'max' is required.
         Parameter 'max' must be a number.
         Parameter 'max' must be greater than parameter 'min'.
         From Class::Utils:
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=random_usd_or_eur.pl

 use strict;
 use warnings;

 use Finance::Random::Price;

 # Object.
 my $obj = Finance::Random::Price->new(
         'currencies' => ['USD', 'EUR'],
         'min' => 99,
         'max' => 101,
 );

 # Print random price.
 print $obj->random."\n";

 # Output like:
 # EUR100,00
 
 # Output like:
 # $99.00
 
 # Output like:
 # $101.00

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::Currency>,
L<Error::Pure>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Finance-Random-Price>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
