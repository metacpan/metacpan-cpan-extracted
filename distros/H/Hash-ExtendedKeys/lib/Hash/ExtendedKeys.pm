package Hash::ExtendedKeys;

use 5.006;
use strict;
use warnings;
use Hash::ExtendedKeys::Tie;

our $VERSION = '1.00';

use overload '%{}' => sub { ${$_[0]}->{hash}; }, fallback => 1;

sub new {
	my ($class) = @_;

	my $self = \{
		hash => {},
	};

	tie %{${$self}->{hash}}, 'Hash::ExtendedKeys::Tie';

	bless $self, $class;	
}

=head1 NAME

Hash::ExtendedKeys - Hash Keys

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Hash::ExtendedKeys;

	my $hash = Hash::ExtendedKeys->new();

	my $ref = { a => 1, b => 2, c => 3 };
	
	$hash->{$ref} = 1;
	$hash->{{ a => 1, b => 2, c => 3}}++;

	...

	use Hash::ExtendedKeys::Tie;

	tie my %hash, 'Hash::ExtendedKeys::Tie';

	my $ref = [qw/a b c/];

	$hash{$ref} = 1;
	$hash{[qw/a b c/]}++;

=head1 METHODS

=cut

=head2 new

Instantiate a new Hash::ExtendedKeys object.

	Hash::ExtendedKeys->new();

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-extendedkeys at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-ExtendedKeys>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::ExtendedKeys


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-ExtendedKeys>

=item * Search CPAN

L<https://metacpan.org/release/Hash-ExtendedKeys>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021->2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Hash::ExtendedKeys
