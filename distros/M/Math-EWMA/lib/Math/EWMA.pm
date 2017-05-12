package Math::EWMA;
use Moo;
use namespace::autoclean;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.03';
$VERSION = eval $VERSION;


has alpha => (
	is =>'ro',
	isa => sub { die "$_[0] is not a number!" unless looks_like_number $_[0]},
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


sub ewma
{
	my ($self, $current) = @_;
	my $last = $self->last_avg();
	my $alpha = $self->alpha();
	my $prec = $self->precision();

	return sprintf("%.${prec}f",$last) unless defined $current;
	die "ewma() works on numbers only!" unless looks_like_number $current;

	$last = $current if not defined $last;
	my $ewma = (1 - $alpha) * $last + $alpha * $current;
	$self->_set_last_avg($ewma);
	return sprintf("%.${prec}f",$ewma);
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Math::EWMA - EWMA in object form

=head1 SYNOPSIS

	use Math::EWMA;
	my $ewma = Math::EWMA->new(alpha => $n);
	$ewma->ewma($value);

=head1 DESCRIPTION

Implements an exponential moving average with a weight of C<$alpha> in object form.
L<http://en.wikipedia.org/wiki/Moving_average>

=head2 new

Create a new EWMA object with alpha C<$n>.

	my $ewma = Math::EWMA->new(alpha => $n);

An alpha value of 2/(N+1) is roughly equivalent to a simple moving average of N periods

=head2 ewma

Add value to series and return the current exponential moving average

    $ewma->ewma($current);

C<$current> is the current live value

Returns C<last_avg> if called with no arguments.

=head2 precision

The precision level for decimal places. Defaults to 2.

=head2 last_avg

The current value of the EWMA series. If you want to continue a series from a previous time,
then pass that value in during object construction:

	my $ewma = Math::EWMA->new(alpha => .125, last_avg => 45.754);


=head1 AUTHORS

Samuel Smith E<lt>esaym@cpan.orgE<gt>

=head1 BUGS

See L<http://rt.cpan.org> to report and view bugs.

=head1 SOURCE

The source code repository for Math::EWMA can be found at
L<https://github.com/smith153/Math-EWMA>.

=head1 COPYRIGHT

Copyright 2015 by Samuel Smith E<lt>esaym@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

 
