package HTTP::Status::Const;

use v5.10.1;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.3.0');

use Const::Exporter;
use HTTP::Status qw/ :is status_message /;
use Package::Stash;

# RECOMMEND PREREQ: Package::Stash::XS 0

=head1 NAME

HTTP::Status::Const - interpolable HTTP status constants

=for readme plugin version

=head1 SYNOPSIS

  use HTTP::Status::Const;

  ...

  $response->status( $HTTP_NOT_FOUND );

  ...

  my %handlers = (
    $HTTP_OK      => sub { ... },
    $HTTP_CREATED => sub { ... },
    ...
  );

=head1 DESCRIPTION

This module is basically a wrapper around L<HTTP::Status> that allows
you to use the constants as read-only scalar variables instead of
function names.

This means the constants can be used in contexts where you need
interpolated variables, such as hash keys or in strings.

=head2 Do I really need this?

No. You can get interpolated constants already, with some ugly syntax:

  my %handlers = (
    HTTP_OK() => sub { ... },
  );

or

  "Status code ${ \HTTP_OK }"

So all this module gives you is some stylistic convenience, at the
expense of additional dependencies (although ones that may be used
by other modules).

=begin :readme

=head1 INSTALLATION

See
L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>.

=for readme plugin requires heading-level=2 title="Required Modules"

=for readme plugin changes

=end :readme

=head1 EXPORTS

By default, only the HTTP constants are exported.

For convenience, the tags from L<HTTP::Status> are supported so that
the C<:is> and C<status_message> functions are exported.

=head1 SEE ALSO

L<HTTP::Status>

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head2 Acknowledgements

Several people who pointed out that this module is unnecessary.
(Yes, it's written to scratch an itch.)

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2015 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut

BEGIN {
    my $stash = Package::Stash->new('HTTP::Status');
    my $syms  = $stash->get_all_symbols('CODE');

    my %defaults;

    foreach my $sym ( keys %{$syms} ) {
        next unless $sym =~ /^HTTP_/;
        my $val = &{ $syms->{$sym} };
        $defaults{ '$' . $sym } = $val;
    }

    Const::Exporter->import(
        constants => [%defaults],
        default   => [ keys %defaults ],
    );

    $EXPORT_TAGS{is} = $HTTP::Status::EXPORT_TAGS{is};

    push @EXPORT_OK, 'status_message', @{ $EXPORT_TAGS{is} };
    push @{ $EXPORT_TAGS{all} }, 'status_message', @{ $EXPORT_TAGS{is} };
}

1;
