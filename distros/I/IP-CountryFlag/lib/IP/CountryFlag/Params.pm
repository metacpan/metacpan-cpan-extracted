package IP::CountryFlag::Params;

$IP::CountryFlag::Params::VERSION   = '0.08';
$IP::CountryFlag::Params::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

IP::CountryFlag::Params - Placeholder for parameters for IP::CountryFlag.

=head1 VERSION

Version 0.08

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(validate);

sub check_ip   { die "ERROR: Received invalid IP [$_[0]]."    unless (is_ipv4($_[0]) || is_ipv6($_[0])) };
sub check_path { die "ERROR: Received invalid Path [$_[0]]."  unless (-d "$_[0]")                       };

our $FIELDS = {
    'ip'   => { check => sub { check_ip(@_)   }, type => 's' },
    'path' => { check => sub { check_path(@_) }, type => 's' },
};

sub validate {
    my ($fields, $values) = @_;

    die "ERROR: Missing params list." unless (defined $values);

    die "ERROR: Parameters have to be hash ref" unless (ref($values) eq 'HASH');

    foreach my $field (sort keys %{$fields}) {
        die "ERROR: Received invalid param: $field"
            unless (exists $FIELDS->{$field});

        die "ERROR: Missing mandatory param: $field"
            if ($fields->{$field} && !exists $values->{$field});

        die "ERROR: Received undefined mandatory param: $field"
            if ($fields->{$field} && !defined $values->{$field});

	$FIELDS->{$field}->{check}->($values->{$field})
            if defined $values->{$field};
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/IP-CountryFlag>

=head1 BUGS

Please report any bugs / feature requests to C<bug-ip-countryflag at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IP-CountryFlag>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IP::CountryFlag::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IP-CountryFlag>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IP-CountryFlag>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IP-CountryFlag>

=item * Search CPAN

L<http://search.cpan.org/dist/IP-CountryFlag/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

DEAFilter API itself is distributed under the terms of the Gnu GPLv3 licence.

=cut

1; # End of IP::CountryFlag::Params
