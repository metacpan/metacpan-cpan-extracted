package Test::Facile;
use base qw(Exporter);

use strict;
use warnings;
require Test::More;

our $VERSION = 1.00;

our @EXPORT_OK = qw(nearly_ok nearly each_ok deep_ok);

sub nearly_ok {
  my ($got, $expected, $epsilon, $message) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::ok( nearly($got, $expected, $epsilon), $message ) or warn "wanted epsilon $epsilon, got " . abs($expected - $got) . "\n";
}

sub nearly {
	my ($got, $expected, $epsilon) = @_;
  my $close = abs($expected - $got) <= $epsilon;
	return !!$close;
}

sub each_ok (&@) {
	my $code = shift;

	local $_;

	my $index = 0;

	my @bad;
	foreach (@_) {
		my $orig = $_;
		my (@got) = $code->();

		my $ok = 1;
		my $expected;

		if (@got == 1) {
			$ok = !! $got[0];
			$expected = 'something true';
		} elsif ($got[0] ne $got[1]) {
			$ok = 0;
			$expected = $got[1];
		}

		push @bad, {
			raw => $_,
			index => $index,
			got => $got[0],
			expected => $expected,
		} if ! $ok;

		$index++;
	}

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return Test::More::is_deeply( \@bad, [] );
}

sub deep_ok ($$;$) {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	Test::More::is_deeply( @_ )
		? return 1
		: do { require Data::Dumper; Test::More::diag(Data::Dumper::Dumper(@_[0,1])); return 0 };
}

1;

__END__

=head1 NAME

Test::Facile - facilitates easy testing patterns

=head1 SYNOPSIS

    use Test::Facile qw(nearly_ok nearly each_ok);

    # prove that $got is within $epsilon of $expected
    nearly_ok( 1, 1.25, .7, '1 is within .7 of 1.25' );

    # build your own close-approximation tests:
    ok( nearly(1, 1.25, .7), '1 is within .7 of 1.25' );

Simplify tests-in-a-loop:

    # Rather than having a test in a loop like this:
    my @values = (1, 1.1, .9);
    foreach (@values) {
      nearly_ok( $_, 1.25, .7, "$_ is within .7 of 1.25" );
    }

    # You can write it as a single test of the entire set, like this:
    my @values = (1, 1.1, .9);
    my @bad;
    foreach (@values) {
      push @bad, $_ unless nearly($_, 1.25, .7);
    }
    is_deeply( \@bad, [], 'all @values are within .7 of 1.25' );

    # You can write the above test more simply still by simply expressing the
    # test you wish to conduct within the foreach loop:
    each_ok { nearly($_, 1.25, .7, "$_ is within .7 of 1.25") } (1, 1.1, .9);

=head1 AUTHOR AND COPYRIGHT

(c) 2012 Belden Lyman <belden@cpan.org>

=head1 LICENSE

You may use this under the same terms as Perl itself.
