package HTML::Microformats::Datatype;

use HTML::Microformats::Datatype::DateTime;
use HTML::Microformats::Datatype::Duration;
use HTML::Microformats::Datatype::Interval;
use HTML::Microformats::Datatype::RecurringDateTime;
use HTML::Microformats::Datatype::String;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Datatype::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Datatype::VERSION   = '0.105';
}

1;

__END__

=head1 NAME

HTML::Microformats::Datatype - representations of literal values

=head1 DESCRIPTION

Many places you'd expect a Perl scalar to appear, e.g.:

  $my_hcard->get_fn;

What you actually get returned is an object from one of the Datatype
modules. Why? Because using a scalar loses information. For example,
most strings have associated language information (from HTML lang and
xml:lang attributes). Using an object allows this information to be kept.

The Datatype modules overload stringification, which means that for
the most part, you can use them as strings (subjecting them to
regular expressions, concatenating them, printing them, etc) and
everything will work just fine. But they're not strings.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>.

L<HTML::Microformats::Datatype::DateTime>,
L<HTML::Microformats::Datatype::Duration>,
L<HTML::Microformats::Datatype::Interval>,
L<HTML::Microformats::Datatype::String>.

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
