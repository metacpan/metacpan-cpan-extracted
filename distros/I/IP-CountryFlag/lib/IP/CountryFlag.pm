package IP::CountryFlag;

$IP::CountryFlag::VERSION   = '0.12';
$IP::CountryFlag::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

IP::CountryFlag - Interface to fetch country flag of an IP.

=head1 VERSION

Version 0.12

=cut

use 5.006;
use autodie;
use Data::Dumper;
use IP::CountryFlag::UserAgent;
use File::Spec::Functions qw(catfile);
use IP::CountryFlag::Params qw(validate);

use Moo;
use namespace::clean;
extends 'IP::CountryFlag::UserAgent';

has 'base_url' => (is => 'ro', default => sub { return 'http://api.hostip.info/flag.php' });

=head1 DESCRIPTION

A very thin wrapper for the hostip.info API to get the country flag of an IP address.

=head1 METHOD

=head2 save()

Saves the country flag in the given location for the given IP address. It returns the location
of the country flag where it has been saved.

    use strict; use warnings;
    use IP::CountryFlag;

    my $countryFlag = IP::CountryFlag->new;
    print $countryFlag->save({ ip => '12.215.42.19', path => './' });

=cut

sub save {
    my ($self, $params) = @_;

    my $fields   = { 'ip' => 1, 'path' => 1 };
    my $url      = $self->_url($fields, $params);
    my $response = $self->get($url);

    return _save($params, $response->{content});
}

#
#
# PRIVATE METHODS

sub _save {
    my ($params, $data) = @_;

    my $flag = catfile($params->{path}, $params->{ip} . ".gif");
    eval {
        open(my $FLAG, ">$flag");
        binmode($FLAG);
        print $FLAG $data;
        close $FLAG;

        return $flag;
    };

    die("ERROR: Couldn't save flag [$flag][$@].\n") if $@;
}

sub _url {
    my ($self, $fields, $params) = @_;

    validate($fields, $params);

    return sprintf("%s?ip=%s", $self->base_url, $params->{ip});
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

    perldoc IP::CountryFlag

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

Copyright (C) 2011 - 2017 Mohammad S Anwar.

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

1; # End of IP::CountryFlag
