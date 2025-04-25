package Manipulator;
use 5.006; use strict; use warnings;
our $VERSION = '0.02';
use overload '&{}' => 'engage';
use Tie::IxHash;
use base 'Import::Export';

our %EX = (
	manipulate => [qw/all/],
);

sub manipulate {
	my (%args) = (scalar @_ > 1 
		? @_
		: ref $_[0] eq 'CODE'
			? (code => $_[0])
			: ref $_[0] eq 'HASH' 
				? %{ $_[0] } 
				: @{ $_[0] }
	);
	bless \%args, __PACKAGE__;
}

sub engage {
	my ($self) = shift;
	return sub {
		my (@params) = @_;

		if (scalar @params == 1) {
			my $hash = shift @params;
			@params = map {($_, $hash->{$_})} sort { $a <=> $b } keys %{$hash};
		}

		if (scalar keys %{$self} > 1) {
			for (my $i = 0; $i < scalar @params; $i += 2) {
				my ($key, $value) = ($params[$i], $params[$i + 1]);
				$params[$i + 1] = $self->{$key}->($value); 	
			}
		} else {
			for (my $i = 0; $i < scalar @params; $i++) {
				$params[$i] = $self->{code}->($params[$i]);
			}
		}

		return wantarray ? @params : {@params};
	};
}

sub ordered {
	my ($self, @params) = @_;
	my @data = $self->(@params);
	my %out; tie %out, 'Tie::IxHash', @data;
	return wantarray ? %out : \%out;
}

1;

__END__

=head1 NAME

Manipulator - manipulate data structs via codeblocks

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Manipulator;

	my $manipulate = manipulate(
		zues => sub { time; },
		eris => sub { Num->($_[0]) * 100000000000000 },
		asclepius => sub { my $val = Str->(shift); $val =~ s/apollo/aeolus/g; $val; },
		...
	);

	$manipulate->(
		zues => 1,
		eris => 211,
		asclepius => '... apollo ...'
	);

	...

	my $manipulate = manipulate(sub { Num->($_[0]) % 2 ? 'odd' : 'even' });
	
	$manipulate->(1..211);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-manipulator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Manipulator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Manipulator

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Manipulator>

=item * Search CPAN

L<https://metacpan.org/release/Manipulator>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Manipulator
