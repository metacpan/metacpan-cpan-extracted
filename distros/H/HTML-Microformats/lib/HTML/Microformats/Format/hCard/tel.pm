=head1 NAME

HTML::Microformats::Format::hCard::tel - helper for hCards; handles the tel property

=head1 DESCRIPTION

Technically, this inherits from HTML::Microformats::Format::hCard::TypedField, so can be used in the
same way as any of the other microformat module, though I don't know why you'd
want to.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Format::hCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

package HTML::Microformats::Format::hCard::tel;

use base qw(HTML::Microformats::Format::hCard::TypedField);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hCard::tel::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hCard::tel::VERSION   = '0.105';
}

sub _fix_value_uri
{
	my $self  = shift;
	my $uri;

	return if $self->{'DATA'}->{'value'} =~ /^(tel|modem|fax):\S+$/i;
	
	my $number = $self->{'DATA'}->{'value'};
	$number =~ s/[^\+\*\#x0-9]//gi;
	($number, my $extension) = split /x/i, $number, 2;
	
	if ($number =~ /^\+/ and $number !~ /[\*\#]/) # global number
	{
		if (length $extension)
		{
			$uri = sprintf('tel:%s;ext=%s', $number, $extension);
		}
		else
		{
			$uri = sprintf('tel:%s', $number);
		}
	}
	else #local number
	{
		if (length $extension)
		{
			$uri = sprintf('tel:%s;ext=%s;phone-context=localhost.localdomain', $number, $extension);
		}
		else
		{
			$uri = sprintf('tel:%s;phone-context=localhost.localdomain', $number);
		}
	}
	
	$self->{'DATA'}->{'value'} = $uri;
}

1;
