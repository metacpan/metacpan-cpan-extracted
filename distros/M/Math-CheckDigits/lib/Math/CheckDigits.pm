package Math::CheckDigits;

use 5.006;
use strict;
use warnings;
use integer;
use utf8;
our $VERSION = '0.05';
$VERSION = eval $VERSION; ## no critic

my %DEFAULT = (
    trans_table => {},
    options     => {
        start_at_right  => 1, # multipule
        DSR             => 1, # use DSR or DR
        runes           => 0, # use runes
    },
);

sub new {
    my $cls = shift;
    my $self = {};
    if ( @_ == 2 ){
        ( $self->{modulus}, $self->{weight} ) = @_
    }
    else {
        $self = { %$self, ref $_[0] ? %{$_[0]} : @_ };
    }
    die 'not enough arguments!'
        if !$self->{modulus} || !$self->{weight};

    if (!ref $self->{weight}) {
        $self->{weight} = [$self->{weight}, 1];
    }

    $self->{trans_table} = {
        %{$DEFAULT{trans_table}},
        %{$self->{trans_table} || {}},
    };

    $self->{options} = {
        %{$DEFAULT{options}},
        %{$self->{options} || {}},
    };

    bless $self, $cls;
}

sub checkdigit {
    my $self = shift;
    my @digits = split //, shift;

    @digits = reverse @digits if $self->options('start_at_right');

    my $check_sum = $self->_calc_check_sum( $self->{weight}, @digits );
    my $check_digit = $check_sum % $self->{modulus};

    # DSR or DR ?
    $check_digit = $self->{modulus} - $check_digit if $self->options('DSR');

    # see trans table if exists. ( eg. 16 => 'g' )
    my %trans_table = $self->trans_table;
    $check_digit =
        defined $trans_table{$check_digit} ?
        $trans_table{$check_digit} : $check_digit;
    $check_digit = 0 if length( $check_digit ) >= 2;

    return $check_digit;
}

sub is_valid {
    my ( $self, $digits ) = @_;
    ( $digits, my $check_num )
        = $digits =~ /^(.*)(.)$/;
    return $self->checkdigit( $digits ) == $check_num;
}

sub complete {
    my ( $self, $digits ) = @_;
    return $digits . $self->checkdigit( $digits );
}

sub trans_table {
    my $self = shift;
    if ( @_ ){
        $self->{trans_table} = ref $_[0] ? shift : { @_ };
        return $self;
    }
    return %{$self->{trans_table}};
}

sub options {
    my $self = shift;

    return %{$self->{options}} if @_ == 0;
    return $self->{options}{$_[0]} if (@_ == 1) && (!ref $_[0]);

    $self->{options}
        = { %{$self->{options}}, ref $_[0] ? %{$_[0]} : @_ };

    return $self;
}

sub _calc_check_sum {
    my $self = shift;
    my ( $weight, @digits ) = @_;

    my %trans_table = reverse $self->trans_table;
    for ( keys %trans_table ){
        delete $trans_table{$_} if /\d/;
    }

    my ( $i, $check_sum ) = ( 0, 0 );
    for my $digit ( @digits ){
        my $num = defined $trans_table{$digit} ? $trans_table{$digit} : $digit;
        die "'$num' does not map to number. Use trans_table method." if $num =~ /\D/;

        $num = $weight->[ $i % @$weight ] * $num;
        if ( !$self->options('runes') ){
            $check_sum += $num;
        }
        else{
            my @nums = split //, $num;
            $check_sum += $_ for @nums;
        }
        $i++;
    }

    return $check_sum;
}

1;
__END__

=head1 NAME

Math::CheckDigits - Perl Module to generate and test check digits

=head1 SYNOPSIS

  use Math::CheckDigits;
  my $cd = Math::CheckDigits->new(
    modulus => 11,
    weight  => [2..7],
  );
  print $cd->checkdigit('12345678'); #5
  print $cd->complete('12345678'); #123456785
  print 'ok' if $cd->is_valid('123456785');

set options

  use Math::CheckDigits;
  my $cd = Math::CheckDigits->new(
    modulus => 10,
    weight  => [1, 2],
  )->options(
    runes => 1,
  );

  print $cd->complete('348764') #3487649

advanced

  # modulus 16
  use Math::CheckDigits;
  $cd = Math::CheckDigits->new(
    modulus => 16,
    weight  => [1],
  )->trans_table(
    10  => '-',
    11  => '$',
    12  => ':',
    13  => '.',
    14  => '/',
    15  => '+',
    16  => 'a',
    17  => 'b',
    18  => 'c',
    19  => 'd',
  );
  print $cd->checkdigit('a16329aa') # $;


=head1 DESCRIPTION

Math::CheckDigits is the Module for generating and testing check digits.

This module is similar to L<Algorithm::CheckDigits>. But, in this module, check digits can be computed from not format names (ex. JAN ISBN..), but two arguments, Modulus and Weight. This is the difference between L<Algorithm::CheckDigits> and this module.

This module is effective to any check digits format using Modulus and Weight, and can't support the format that are generated from complicated algorithm.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

L<Algorithm::CheckDigits>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
