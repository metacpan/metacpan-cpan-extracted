package Finance::Bitcoin::Role::HasAPI;

BEGIN {
	$Finance::Bitcoin::Role::HasAPI::AUTHORITY = 'cpan:TOBYINK';
	$Finance::Bitcoin::Role::HasAPI::VERSION   = '0.902';
}

use Moo::Role;
use Finance::Bitcoin::API;
use Scalar::Util qw( blessed );

has api => (
	is      => 'rw',
	default => sub { "Finance::Bitcoin::API"->new },
);

around BUILDARGS => sub
{
	my $orig  = shift;
	my $class = shift;
	
	if (scalar @_ == 1 and blessed $_[0])
	{
		return $class->$orig(api => @_);
	}
	elsif (scalar @_ == 1 and $_[0] =~ /^http/)
	{
		my $api = "Finance::Bitcoin::API"->new(endpoint => "$_[0]");
		return $class->$orig(api => $api);
	}
	
	return $class->$orig(@_);
};

1;

__END__

=head1 NAME

Finance::Bitcoin::Role::HasAPI - role for objects with an "api" attribute

=head1 DESCRIPTION

=over

=item C<< api >>

Returns an instance of L<Finance::Bitcoin::API>.

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2011, 2013, 2014 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
