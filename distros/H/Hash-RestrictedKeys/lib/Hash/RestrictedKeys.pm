package Hash::RestrictedKeys;

use 5.006;
use strict;
use warnings;
use Hash::RestrictedKeys::Tie;

our $VERSION = '0.03';

use overload '%{}' => sub { ${$_[0]}->{hash}; }, fallback => 1;

sub new {
        my ($class, @keys) = @_;

        my $self = \{
                hash => {},
        };

        tie %{${$self}->{hash}}, 'Hash::RestrictedKeys::Tie', @keys;

        bless $self, $class;
}

1;

__END__

=head1 NAME

Hash::RestrictedKeys - restricted hash keys

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Hash::RestrictedKeys;

	my $foo = Hash::RestrictedKeys->new(qw/one two three/);

	$foo->{one} = 1;
	$foo->{two} = 2;
	$foo->{three} = 3;
	$foo->{four} = 'kaput'; # Invalid key four. Allowed keys: one, two, three
	
	...

	use Hash::RestrictedKeys::Tie;

	tie my %foo, 'Hash::RestrictedKeys::Tie', qw/one two three/;

	$foo{one} = 1;
	$foo{two} = 2;
	$foo{three} = 3;
	$foo->{four} = 'kaput'; # Invalid key four. Allowed keys: one, two, three

=head1 METHODS

=cut

=head2 new

Instantiate a new Hash::RestrictedKeys Object which is a wrapper around Hash::RestrictedKeys::Tie.

	Hash::RestrictedKeys->new();	

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-restrictedkeys at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-RestrictedKeys>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::RestrictedKeys

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-RestrictedKeys>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hash-RestrictedKeys>

=item * Search CPAN

L<https://metacpan.org/release/Hash-RestrictedKeys>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut
