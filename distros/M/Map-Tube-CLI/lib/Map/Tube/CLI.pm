package Map::Tube::CLI;

$Map::Tube::CLI::VERSION   = '0.39';
$Map::Tube::CLI::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::CLI - Command Line Interface for Map::Tube::* map.

=head1 VERSION

Version 0.39

=cut

use 5.006;
use Data::Dumper;
use MIME::Base64;
use Map::Tube::Exception::MissingStationName;
use Map::Tube::Exception::InvalidStationName;
use Map::Tube::Exception::InvalidLineName;
use Map::Tube::Exception::MissingSupportedMap;
use Map::Tube::Exception::FoundUnsupportedMap;
use Map::Tube::CLI::Option;
use Module::Pluggable
    search_path => [ 'Map::Tube' ],
    require     => 1,
    inner       => 0,
    max_depth   => 3;

use Moo;
use namespace::autoclean;
use MooX::Options;
with 'Map::Tube::CLI::Option';

=head1 DESCRIPTION

It provides simple command line interface  to the package consuming L<Map::Tube>.
The distribution contains a script C<map-tube>, using package L<Map::Tube::CLI>.

=head1 SYNOPSIS

You can list all command line options by giving C<-h> flag.

    $ map-tube -h
    USAGE: map-tube [-h] [long options...]

        --map=String    Map name
        --start=String  Start station name
        --end=String    End station name
        --preferred     Show preferred route
        --generate_map  Generate map as image
        --line=String   Line name for map

        --usage         show a short help message
        -h              show a compact help message
        --help          show a long help message
        --man           show the manual

You can also ask for shortest route in London Tube Map as below:

    $ map-tube --map 'London' --start 'Baker Street' --end 'Euston Square'

    Baker Street (Bakerloo, Circle, Hammersmith & City, Jubilee, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

Now request for preferred route as below:

    $ map-tube --map 'London' --start 'Baker Street' --end 'Euston Square' --preferred

    Baker Street (Circle, Hammersmith & City, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

If encountered  invalid  map  or  missing map i.e not installed, you get an error
message like below:

    $ map-tube --map 'xYz' --start 'Baker Street' --end 'Euston Square'
    ERROR: Unsupported Map [xYz].

    $ map-tube --map 'Kazan' --start 'Baker Street' --end 'Euston Square'
    ERROR: Missing Map [Kazan].

To generate entire map, follow the command below:

    $ map-tube --map 'Delhi' --generate_map

To generate just a particular line map, follow the command below:

    $ map-tube --map 'London' --line 'Bakerloo' --generate_map

=head1 SUPPORTED MAPS

The command line parameter C<map> can take one of the following map names.  It is
case insensitive i.e. 'London' and 'lOndOn' are the same.

You could use L<Task::Map::Tube::Metro> to install the supported maps.Please make
sure you have the latest maps when you install.

=over 4

=item * L<Athens|Map::Tube::Athens>

=item * L<Barcelona|Map::Tube::Barcelona>

=item * L<Beijing|Map::Tube::Beijing>

=item * L<Berlin|Map::Tube::Berlin>

=item * L<Bucharest|Map::Tube::Bucharest>

=item * L<Budapest|Map::Tube::Budapest>

=item * L<Copenhagen|Map::Tube::Copenhagen>

=item * L<Delhi|Map::Tube::Delhi>

=item * L<Dnipropetrovsk|Map::Tube::Dnipropetrovsk>

=item * L<Glasgow|Map::Tube::Glasgow>

=item * L<Kazan|Map::Tube::Kazan>

=item * L<Kharkiv|Map::Tube::Kharkiv>

=item * L<Kiev|Map::Tube::Kiev>

=item * L<KoelnBonn|Map::Tube::KoelnBonn>

=item * L<Kolkatta|Map::Tube::Kolkatta>

=item * L<KualaLumpur|Map::Tube::KualaLumpur>

=item * L<London|Map::Tube::London>

=item * L<Lyon|Map::Tube::Lyon>

=item * L<Malaga|Map::Tube::Malaga>

=item * L<Milan|Map::Tube::Milan>

=item * L<Minsk|Map::Tube::Minsk>

=item * L<Moscow|Map::Tube::Moscow>

=item * L<NYC|Map::Tube::NYC>

=item * L<Nanjing|Map::Tube::Nanjing>

=item * L<NizhnyNovgorod|Map::Tube::NizhnyNovgorod>

=item * L<Novosibirsk|Map::Tube::Novosibirsk>

=item * L<Prague|Map::Tube::Prague>

=item * L<SaintPetersburg|Map::Tube::SaintPetersburg>

=item * L<Samara|Map::Tube::Samara>

=item * L<Singapore|Map::Tube::Singapore>

=item * L<Sofia|Map::Tube::Sofia>

=item * L<Tbilisi|Map::Tube::Tbilisi>

=item * L<Tokyo|Map::Tube::Tokyo>

=item * L<Vienna|Map::Tube::Vienna>

=item * L<Warsaw|Map::Tube::Warsaw>

=item * L<Yekaterinburg|Map::Tube::Yekaterinburg>

=back

=cut

sub BUILD {
    my ($self) = @_;

    my $plugins = [ plugins ];
    foreach my $plugin (@$plugins) {
        my $key = _map_key($plugin);
        if (defined $key) {
            $self->{maps}->{uc($key)} = $plugin->new;
        }
    }

    $self->_validate_param;
}

=head1 METHODS

=head2 run()

This is the only method provided by the package L<Map::Tube::CLI>. It does not
expect any parameter. Here is the code from the supplied C<map-tube> script.

    use strict; use warnings;
    use Map::Tube::CLI;

    Map::Tube::CLI->new_with_options->run;

=cut

sub run {
    my ($self) = @_;

    my $start = $self->start;
    my $end   = $self->end;
    my $map   = $self->map;
    my $line  = $self->line;

    if ($self->preferred) {
        print $self->{maps}->{uc($map)}->get_shortest_route($start, $end)->preferred, "\n";
    }
    elsif ($self->generate_map) {
        my ($image_file, $image_data);
        if (defined $line) {
            $image_file = sprintf(">%s.png", $line);
            $image_data = $self->{maps}->{uc($map)}->as_image($line);
        }
        else {
            $image_file = sprintf(">%s.png", $map);
            $image_data = $self->{maps}->{uc($map)}->as_image;
        }

        open(my $IMAGE, $image_file);
        binmode($IMAGE);
        print $IMAGE decode_base64($image_data);
        close($IMAGE);
    }
    else {
        print $self->{maps}->{uc($map)}->get_shortest_route($start, $end), "\n";
    }
}

#
#
# PRIVATE METHODS

sub _map_key {
    my ($name) = @_;
    return unless defined $name;

    my $maps = _supported_maps();
    foreach my $map (keys %$maps) {
        return $map if ($maps->{$map} eq $name);
    }

    return;
}

sub _validate_param {
    my ($self) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    my $start = $self->start;
    my $end   = $self->end;
    my $map   = $self->map;
    my $line  = $self->line;

    my $supported_maps = _supported_maps();
    Map::Tube::Exception::FoundUnsupportedMap->throw({
        method      => __PACKAGE__."::_validate_param",
        message     => "ERROR: Unsupported Map [$map].",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (exists $supported_maps->{uc($map)});

    Map::Tube::Exception::MissingSupportedMap->throw({
        method      => __PACKAGE__."::_validate_param",
        message     => "ERROR: Missing Map [$map].",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (exists $self->{maps}->{uc($map)});

    if ($self->generate_map) {
        if (defined $line) {
            Map::Tube::Exception::InvalidLineName->throw({
                method      => __PACKAGE__."::_validate_param",
                message     => "ERROR: Invalid Line Name [$line].",
                filename    => $caller[1],
                line_number => $caller[2] })
                unless defined $self->{maps}->{uc($map)}->get_line_by_name($line);
        }
    }

    unless ($self->generate_map) {
        Map::Tube::Exception::MissingStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Missing Station Name [start].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $start;

        Map::Tube::Exception::MissingStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Missing Station Name [end].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $end;

        Map::Tube::Exception::InvalidStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Invalid Station Name [$start].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $self->{maps}->{uc($map)}->get_node_by_name($start);

        Map::Tube::Exception::InvalidStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Invalid Station Name [$end].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $self->{maps}->{uc($map)}->get_node_by_name($end);
    }
}

sub _supported_maps {

    return {
        'ATHENS'          => 'Map::Tube::Athens',
        'BARCELONA'       => 'Map::Tube::Barcelona',
        'BEIJING'         => 'Map::Tube::Beijing',
        'BERLIN'          => 'Map::Tube::Berlin',
        'BUCHAREST'       => 'Map::Tube::Bucharest',
        'BUDAPEST'        => 'Map::Tube::Budapest',
        'COPENHAGEN'      => 'Map::Tube::Copenhagen',
        'DELHI'           => 'Map::Tube::Delhi',
        'DNIPROPETROVSK'  => 'Map::Tube::Dnipropetrovsk',
        'GLASGOW'         => 'Map::Tube::Glasgow',
        'KAZAN'           => 'Map::Tube::Kazan',
        'KHARKIV'         => 'Map::Tube::Kharkiv',
        'KIEV'            => 'Map::Tube::Kiev',
        'KOELNBONN'       => 'Map::Tube::KoelnBonn',
        'KOLKATTA'        => 'Map::Tube::Kolkatta',
        'KUALALUMPUR'     => 'Map::Tube::KualaLumpur',
        'LONDON'          => 'Map::Tube::London',
        'LYON'            => 'Map::Tube::Lyon',
        'MALAGA'          => 'Map::Tube::Malaga',
        'MILAN'           => 'Map::Tube::Milan',
        'MINSK'           => 'Map::Tube::Minsk',
        'MOSCOW'          => 'Map::Tube::Moscow',
        'NYC'             => 'Map::Tube::NYC',
        'NANJING'         => 'Map::Tube::Nanjing',
        'NIZHNYNOVGOROD'  => 'Map::Tube::NizhnyNovgorod',
        'NOVOSIBIRSK'     => 'Map::Tube::Novosibirsk',
        'PRAGUE'          => 'Map::Tube::Prague',
        'SAINTPETERSBURG' => 'Map::Tube::SaintPetersburg',
        'SAMARA'          => 'Map::Tube::Samara',
        'SINGAPORE'       => 'Map::Tube::Singapore',
        'SOFIA'           => 'Map::Tube::Sofia',
        'TBILISI'         => 'Map::Tube::Tbilisi',
        'TOKYO'           => 'Map::Tube::Tokyo',
        'VIENNA'          => 'Map::Tube::Vienna',
        'WARSAW'          => 'Map::Tube::Warsaw',
        'YEKATERINBURG'   => 'Map::Tube::Yekaterinburg',
    };
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-CLI>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube-cli at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-CLI>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::CLI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-CLI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-CLI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-CLI>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-CLI/>

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

1; # End of Map::Tube::CLI
