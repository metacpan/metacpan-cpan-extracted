# Copyright (C) 2008 Stephen Vance
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
# 
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
# 
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package Error::Exception::Class;

use strict;
use warnings;

use base qw( Exception::Class );

our $VERSION = '1.0';

sub import {
    my ($pkg, @exceptions) = @_;

    local $Exception::Class::BASE_EXC_CLASS = 'Error::Exception';

    local *CORE::GLOBAL::caller = sub {
        my ($n) = @_ ? @_ : 0;
        return CORE::caller( $n + 1 );
    };

    $pkg->SUPER::import( @exceptions );

    return;
}

1;
__END__

=head1 NAME

Error::Exception::Class - A wrapper around L<Exception::Class> that uses
L<Error::Exception> as the default base class instead of
L<Exception::Class::Base>.

=head1 SYNOPSIS

Error::Exception::Class is a drop-in replacement for L<Exception::Class> that
ensure that classes without an "isa" attribute inherit from
L<Error::Exception> instead of the default L<Exception::Class::Base>.

Use it the same as you would L<Exception::Class>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-error-exception-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Error-Exception-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Error::Exception::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Error-Exception-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Error-Exception-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Error-Exception-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Error-Exception-Class>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions. Also, thank you to Damian
Conway for wonderful training and helpful advice.

=head1 COPYRIGHT

Copyright 2008 Stephen Vance, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
