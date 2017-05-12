package Math::SMA;
use Scalar::Util qw(looks_like_number);
use Moo;
use namespace::autoclean;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

has size => (
	is =>'ro',
	isa => sub { die "$_[0] is not an integer!" unless(looks_like_number($_[0]) && $_[0] >= 1)},
	required => '1',
);

has last_avg => (
	is =>'ro',
	isa => sub { die "$_[0] is not a number!" unless looks_like_number $_[0]},
	writer => '_set_last_avg',
);

has precision => (
	is => 'rw',
	isa => sub { die "$_[0] is not a number!" unless looks_like_number $_[0]},
	default => 2,
);

has values => (
	is => 'ro',
	isa => sub { die "$_[0] is not an array ref!" unless ref($_[0]) eq 'ARRAY'},
	default => sub { [] },
);


sub BUILD
{
	my $self = shift();
	my $values = $self->values();
	my $size = $self->size();

	return unless defined $values;

	#perfectly valid to pass in values to constructor
	#however, not valid to have more values than size()
	if(@{$values} > $size){
		@{$values} = splice(@{$values}, -1 * $size);
	}
	
	$self->_set_last_avg($self->_raw_average());

}

sub sma
{
	my ($self, $current) = @_;
	my $last = $self->last_avg();
	my $values = $self->values();
	my $size = $self->size();
	my $prec = $self->precision();
	my $obsolete;
	my $avg;

	return sprintf("%.${prec}f",$last) unless defined $current;
	die "sma() works on numbers only!" unless looks_like_number $current;

	push(@{$values}, $current);

	#return simple avg if not enough periods
	if(@{$values} <= $size){
		$self->_set_last_avg($self->_raw_average());
		return sprintf("%.${prec}f", $self->last_avg());
	}

	$obsolete = shift(@{$values});

	$avg = $last - ($obsolete/$size) + ($current/$size);
	$self->_set_last_avg($avg);

	return sprintf("%.${prec}f", $avg);
}


sub _raw_average
{
	my $self = shift();
	my $size = @{$self->values()} || 1;
	my $total = 0;
	foreach (@{$self->values}){
		$total += $_;
	}
	return $total / $size;
}



1;

__END__

=encoding utf8

=head1 NAME

Math::SMA - SMA in object form

=head1 SYNOPSIS

    use Math::SMA;
	my $sma = Math::SMA->new(size => $n);
	$sma->sma($value);

=head1 DESCRIPTION

Implements a simple moving average of N periods with an amortized runtime complexity of < O(n²).

L<http://en.wikipedia.org/wiki/Moving_average>

=head2 new

Create a new SMA object of C<$n> periods.

	my $sma = Math::SMA->new(size => $n);

=head2 sma

Add a value to series and return the current simple moving average

    $sma->sma($current);

C<$current> is the current live value

Returns C<last_avg> if called with no arguments.

=head2 precision

The precision level for decimal places. Defaults to 2.

=head2 last_avg

The current value of the SMA series. 

=head2 values

The current values of the SMA period. If you want to continue a series from a previous time,
then pass an arrayref in during object construction:

	$sma = Math::SMA->new(size => 5, values => [3,2,7,4,9] );

=head1 AUTHORS

Samuel Smith E<lt>esaym@cpan.orgE<gt>

=head1 BUGS

See L<http://rt.cpan.org> to report and view bugs.

=head1 SOURCE

The source code repository for Math::EWMA can be found at
L<https://github.com/smith153/Math-SMA>.

=head1 COPYRIGHT

Copyright 2015 by Samuel Smith E<lt>esaym@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

