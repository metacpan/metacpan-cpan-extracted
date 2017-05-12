package Map::Tube::Plugin::Formatter::Utils;

$Map::Tube::Plugin::Formatter::Utils::VERSION   = '0.12';
$Map::Tube::Plugin::Formatter::Utils::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Plugin::Formatter::Utils - Helper package for Map::Tube::Plugin::Formatter.

=head1 VERSION

Version 0.12

=cut

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(xml get_data validate_object);

use 5.006;
use strict; use warnings;
use Data::Dumper;
use XML::Twig;
use Map::Tube::Exception::MissingSupportedObject;
use Map::Tube::Exception::InvalidSupportedObject;
use Map::Tube::Exception::FoundUnsupportedObject;

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=cut

sub xml {
    my ($data) = @_;

    my $twig = XML::Twig
        ->new()
        ->set_xml_version("1.0")
        ->set_encoding('utf-8');

    my $map = XML::Twig::Elt->new('map');
    $twig->set_root($map);

    foreach my $i (keys %$data) {
        my $e = $map->insert_new_elt($i, $data->{$i}->{attributes});
        foreach my $j (keys %{$data->{$i}->{children}}) {
            my $m = $e->insert_new_elt($j.'s');
            foreach (@{$data->{$i}->{children}->{$j}}) {
                $m->insert_new_elt($j, $_);
            }
        }
    }

    $twig->set_pretty_print('indented');
    return $twig->sprint;
}

sub get_data {
    my ($self, $object) = @_;

    validate_object($object);

    my $data = {};
    if (ref($object) eq 'Map::Tube::Node') {
        $data = {
            id    => $object->id,
            name  => $object->name,
            links => [ map {{ id => $_,     name => $self->get_node_by_id($_)->name }} (split /\,/,$object->link) ],
            lines => [ map {{ id => $_->id, name => $_->name                        }} (@{$object->line})         ],
        };
    }
    elsif (ref($object) eq 'Map::Tube::Line') {
        $data = {
            id       => $object->id,
            name     => $object->name,
            color    => $object->color || 'undef',
            stations => [ map {{ id => $_->id, name => $_->name }} (@{$object->get_stations}) ],
        };
    }
    elsif (ref($object) eq 'Map::Tube::Route') {
        my $children = [];
        my $nodes    = $object->nodes;
        my $size     = $#$nodes;
        foreach my $i (1..($size-1)) {
            push @{$children}, { name => $nodes->[$i]->as_string, order => $i };
        }

        $data = {
            from     => $object->from->as_string,
            to       => $object->to->as_string,
            nodes    => $children,
        };
    }

    return $data;
}

sub validate_object {
    my ($object) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingSupportedObject->throw({
        method      => __PACKAGE__."::validate_object",
        message     => "ERROR: No object received.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless defined $object;

    Map::Tube::Exception::InvalidSupportedObject->throw({
        method      => __PACKAGE__."::validate_object",
        message     => "ERROR: Invalid object received.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ref($object);

    Map::Tube::Exception::FoundUnsupportedObject->throw({
        method      => __PACKAGE__."::validate_object",
        message     => "ERROR: Unsupported object received.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ((ref($object) eq 'Map::Tube::Node')
                || (ref($object) eq 'Map::Tube::Line')
                || (ref($object) eq 'Map::Tube::Route'));
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-Plugin-Formatter>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube-plugin-formatter at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-Plugin-Formatter>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Plugin::Formatter::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-Plugin-Formatter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Plugin-Formatter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Plugin-Formatter>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-Plugin-Formatter/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

=cut

1; # End of Map::Tube::Plugin::Formatter::Utils
