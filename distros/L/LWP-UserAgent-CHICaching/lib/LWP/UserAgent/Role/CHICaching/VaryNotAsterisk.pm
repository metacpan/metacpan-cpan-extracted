package LWP::UserAgent::Role::CHICaching::VaryNotAsterisk;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Str);

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.04';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::Role::CHICaching::VaryNotAsterisk - A role for when Vary is not * when caching LWP::UserAgent

=head1 SYNOPSIS

See L<LWP::UserAgent::Role::CHICaching>.


=head1 DESCRIPTION

See L<LWP::UserAgent::Role::CHICaching::SimpleKeyGen> for a
background. Basically, this module does the second dumbest thing, but
in doing so, the User Agent ceases to be compliant with the HTTP
standard. You basically have to implement your own C<key> attribute to
make it compliant.

=head2 Attributes and Methods

=over

=item C<< cache_vary >>

Allow a response with a C<Vary> header to be cached if it doesn't
contain an asterisk (*).

=back

=cut

sub cache_vary {
	my ($self, $res) = @_;
	foreach my $vary ($res->header('Vary')) {
		return 0 if ($vary =~ m/\*/);
	}
	return 1;
}

1;

__END__


=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
