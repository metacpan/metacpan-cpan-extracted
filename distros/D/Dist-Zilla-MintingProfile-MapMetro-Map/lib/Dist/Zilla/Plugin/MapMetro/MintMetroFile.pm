use 5.14.0;

package Dist::Zilla::Plugin::MapMetro::MintMetroFile;

our $VERSION = '0.1500'; # VERSION

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

sub gather_files {
    my $self = shift;

    $self->add_file(Dist::Zilla::File::InMemory->new({
        name => sprintf ('share/map-%s.metro', lc $self->city_name),
        content => $self->map_contents,
    }));
}

sub city_name {
    my $self = shift;
    my $city = $self->zilla->name;
    $city =~ s{^Map-Metro-Plugin-Map-}{};
    return $city;
}

sub map_contents {
return q{--stations

--lines

--transfers

--segments
};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MapMetro::MintMetroFile

=head1 VERSION

Version 0.1500, released 2015-02-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-MintingProfile-MapMetro-Map>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-MintingProfile-MapMetro-Map>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
