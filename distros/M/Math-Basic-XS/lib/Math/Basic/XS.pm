package Math::Basic::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

use base qw/Import::Export/;

our %EX = (
        sum => [qw/all/],
	min => [qw/all/],
	max => [qw/all/],
	mean => [qw/all/],
	median => [qw/all/],
	mode => [qw/all/]
);

require XSLoader;
XSLoader::load('Math::Basic::XS', $VERSION);

1;

__END__

=head1 NAME

Math::Basic::XS - basic math faster

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

        use Math::Basic::XS qw/all/;

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

=head1 BENCHMARK

	use Benchmark qw(:all);
	use lib '.';
	use Math::Basic;
	use Math::Basic::XS;

	my @data = (
		{ value => 1 },
		{ value => 2 },
		{ value => 3 },
		{ value => 4 },
		{ value => 5 },
	);

	timethese(1000000, {
		'Math::Basic' => sub {
			my $min = Math::Basic::min { $_->{value} } @data;
			my $max = Math::Basic::max { $_->{value} } @data;
			my $sum = Math::Basic::sum { $_->{value} } @data;
			my $mean = Math::Basic::mean { $_->{value} } @data;
			my $median = Math::Basic::median { $_->{value} } @data;
			my $mode = Math::Basic::mode { $_->{value} } @data;
		},
		'XS' => sub {
			my $min = Math::Basic::XS::min { $_->{value} } @data;
			my $max = Math::Basic::XS::max { $_->{value} } @data;
			my $sum = Math::Basic::XS::sum { $_->{value} } @data;
			my $mean = Math::Basic::XS::mean { $_->{value} } @data;
			my $median = Math::Basic::XS::median { $_->{value} } @data;
			my $mode = Math::Basic::XS::mode { $_->{value} } @data;
		}
	});

...

	Benchmark: timing 1000000 iterations of Math::Basic, XS...
	Math::Basic:  5 wallclock secs ( 5.00 usr +  0.00 sys =  5.00 CPU) @ 200000.00/s (n=1000000)
		XS:  2 wallclock secs ( 2.21 usr +  0.05 sys =  2.26 CPU) @ 442477.88/s (n=1000000)


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-basic-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Basic-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Basic::XS


You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Basic-XS>

=item * Search CPAN

L<https://metacpan.org/release/Math-Basic-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Math::Basic::XS
