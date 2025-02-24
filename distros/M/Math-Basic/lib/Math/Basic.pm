package Math::Basic;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';

use base qw/Import::Export/;

our %EX = (
	sum => [qw/all/],
	min => [qw/all/],
	max => [qw/all/],
	mean => [qw/all/],
	median => [qw/all/],
	mode => [qw/all/],
);

sub sum (&@) {
	my ($cb, @params) = @_;
	my $sum = 0;
	for (@params) {
		$sum += $cb->($_);
	}
	return $sum;
}

sub min (&@) {
	my ($cb, @params) = @_;
	my $min;
	for (@params) {
		my $val = $cb->($_);
 		$min = $val if (! defined $min || $val < $min);
	}
	return $min;
}

sub max (&@) {
	my ($cb, @params) = @_;
	my $max;
	for (@params) {
		my $val = $cb->($_);
 		$max = $val if (! defined $max || $val > $max);
	}
	return $max;
}

sub mean (&@) {
	my ($cb, @params) = @_;
	my $sum;
	for (@params) {
		$sum += $cb->($_);
	}
	return $sum / scalar @params;
}

sub median (&@) {
	my ($cb, @params) = @_;
	my @median;
	for (@params) {
		push @median, $cb->($_);
	}
	@median = sort @median;
	my $m = int(scalar @median / 2);
	$m++ if ($m % 2 != 0);
	return $median[$m];
}

sub mode (&@) {
	my ($cb, @params) = @_;
	my %map;
	for (@params) {
		$map{$cb->($_)}++;
	}
	my ($mode, $max) = ('', 0);
	for my $k ( keys %map ) {
		if ($map{$k} > $max) {
			$mode = $k;
			$max = $map{$k};
		}
	}
	return $mode;
}

1;

__END__

=head1 NAME

Math::Basic - basic math 

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Math::Basic qw/all/;

	my $sum = sum { $_->value } @objects;

=head1 EXPORT

=head2 min

	my $min = min { $_ } @numbers;

=cut

=head2 max

	my $max = max { $_ } @numbers;

=cut

=head2 sum

	my $sum = sum { $_ } @numbers;

=cut

=head2 mean

	my $mean = mean { $_ } @numbers;

=cut

=head2 median

	my $median = median { $_ } @numbers;

=cut

=head2 mode 

	my $mode = mode { $_ } @numbers;

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-basic at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Basic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Basic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Basic>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Math-Basic>

=item * Search CPAN

L<https://metacpan.org/release/Math-Basic>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Math::Basic
