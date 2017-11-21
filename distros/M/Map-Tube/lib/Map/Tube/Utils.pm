package Map::Tube::Utils;

$Map::Tube::Utils::VERSION   = '3.41';
$Map::Tube::Utils::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Utils - Helper package for Map::Tube.

=head1 VERSION

Version 3.41

=cut

use 5.006;
use strict; use warnings;
use JSON;
use File::Share ':all';

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(to_perl is_same trim common_lines filter get_method_map is_valid_color);

our @COLOR_NAMES = _color_names();

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>.

=cut

sub to_perl {
    my ($file) = @_;

    my $json_text = do {
        open(my $json_fh, $file) or die("ERROR: Can't open \$file\": $!\n");
        local $/;
        my $text = <$json_fh>;
        close($json_fh);
        $text;
    };

    return JSON->new->allow_nonref->utf8(1)->decode($json_text);
}

sub trim {
    my ($data) = @_;

    return unless defined $data;

    $data =~ s/\s+/ /g;
    $data =~ s/^\s+|\s+$//g;

    return $data;
}

sub is_same {
    my ($this, $that) = @_;

    return 0 unless (defined($this) && defined($that));

    (_is_number($this) && _is_number($that))
    ?
    (return ($this == $that))
    :
    (uc($this) eq uc($that));
}

sub common_lines {
    my ($a, $b) = @_;

    my %element = map { $_ => undef } @{$a};
    return grep { exists($element{$_}) } @{$b};
}

sub filter {
    my ($data) = @_;

    my %c;
    for my $i (0 .. $#$data) {
        for my $m (@{ $data->[$i] }) {
            undef $c{$m}{$i};
        }
    }

    my @common = sort { $a cmp $b }
    grep @$data == keys %{ $c{$_} },
    keys %c;

    return [ map [@common], @$data ] if @common;

    my %r;
    for my $i (0 .. $#$data - 1) {
        for my $m (@{ $data->[$i] }) {
            if (exists $c{$m}{ $i + 1 }) {
                undef $r{$_}{$m} for $i, $i + 1;
            }
        }
    }

    return [
        map [ sort { $a cmp $b }
              keys %{ $r{$_} } ],
        sort { $a cmp $b } keys %r
    ];
}

sub get_method_map {

    return {
        fuzzy_find => {
            module    => 'Map::Tube::Plugin::FuzzyFind',
            exception => 'Map::Tube::Exception::MissingPluginFuzzyFind',
        },
        as_image   => {
            module    => 'Map::Tube::Plugin::Graph',
            exception => 'Map::Tube::Exception::MissingPluginGraph',
        },
        to_xml     => {
            module    => 'Map::Tube::Plugin::Formatter',
            exception => 'Map::Tube::Exception::MissingPluginFormatter',
        },
        to_json    => {
            module    => 'Map::Tube::Plugin::Formatter',
            exception => 'Map::Tube::Exception::MissingPluginFormatter',
        },
        to_yaml    => {
            module    => 'Map::Tube::Plugin::Formatter',
            exception => 'Map::Tube::Exception::MissingPluginFormatter',
        },
        to_string  => {
            module    => 'Map::Tube::Plugin::Formatter',
            exception => 'Map::Tube::Exception::MissingPluginFormatter',
        },
    };
}

sub is_valid_color {
    my ($color) = @_;

    return 0 unless defined $color;

    if (($color =~ /^#[a-f0-9]{6}$/i)
        ||
        (grep { lc($color) eq $_ } @COLOR_NAMES)) {
        return 1;
    }
    else {
        return 0;
    }
}

#
#
# PRIVATE METHODS

sub _is_number {
    my ($this) = @_;

    return (defined($this)
            && ($this =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/));
}

sub _color_names {

    my $source = dist_file('Map-Tube', 'color-names.txt');
    open (FILE, $source);
    my @color_names = <FILE>;
    chomp @color_names;
    close (FILE);

    return @color_names;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube at rt.cpan.org>,  or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License  (2.0). You may obtain a copy of the full
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

1; # End of Map::Tube::Utils
