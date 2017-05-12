use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph::Station;

# ABSTRACT: Information about a station
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Types::Standard qw/Int Str Maybe ArrayRef Bool/;
use Map::Metro::Types qw/Line Station/;
use Text::Undiacritic 'undiacritic';

has id => (
    is => 'ro',
    isa => Int,
    required => 1,
    documentation => 'Internal identification',
);

has name => (
    is => 'rw',
    isa => Str,
    required => 1,
    documentation => q{The station's name, with any diacritics removed.},
);
has original_name => (
    is => 'ro',
    isa => Maybe[Str],
    documentation => q{The station's name as given in the map file.},
);
has search_names => (
    is => 'rw',
    isa => ArrayRef[Str],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        add_search_name => 'push',
        all_search_names => 'elements',
    },
    documentation => q{All search names for the station given in the map file.},
);
has alternative_names => (
    is => 'rw',
    isa => ArrayRef[Str],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        add_alternative_name => 'push',
        all_alternative_names => 'elements',
    },
    documentation => q{All alternative names for the station given in the map file.},
);

has lines => (
    is => 'rw',
    isa => ArrayRef[ Line ],
    traits => ['Array'],
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_line => 'push',
        all_lines => 'elements',
        find_line => 'first',
        filter_lines => 'grep',
    },
    documentation => q{All lines passing through this station.},
);
has connecting_stations => (
    is => 'ro',
    isa => ArrayRef[ Station ],
    traits => ['Array'],
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_connecting_station => 'push',
        all_connecting_stations => 'elements',
        find_connecting_station => 'first',
    },
    documentation => q{All stations one can travel to from this station without passing another station.},
);
has do_undiacritic => (
    is => 'rw',
    isa => Bool,
    default => 1,
    traits => ['Documented'],
    documentation_alts => {
        0 => q{Do not remove diacritics from station name.},
        1 => q{Do remove diacritics from station name.},
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    return $class->$orig(%args) if exists $args{'do_undiacritic'} && !$args{'do_undiacritic'};

    my $no_diacritic = undiacriticise($args{'name'});
    if(defined $no_diacritic) {
        if(exists $args{'search_names'}) {
            push @{ $args{'search_names'} } => $no_diacritic;
        }
        else {
            $args{'search_names'} = [$no_diacritic];
        }
    }
    return $class->$orig(%args);
};

sub set_name {
    my $self = shift;
    my $name = shift;

    if($self->do_undiacritic) {
        my $no_diacritic = undiacriticise($name);
        if(defined $no_diacritic) {
            $self->add_search_name($no_diacritic);
        }
    }
    $self->name($name);
}
sub set_original_name {
    my $self = shift;
    my $name = shift;

    if($self->do_undiacritic) {
        my $no_diacritic = undiacriticise($name);

        if(defined $no_diacritic) {
            $self->add_search_name($no_diacritic);
        }
    }
    $self->original_name($name);
}
around add_search_name => sub {
    my $next = shift;
    my $self = shift;
    my @names = @_;

    if($self->do_undiacritic) {
        foreach my $name (@names) {
            my $no_diacritic = undiacriticise($name);
            push @names => $no_diacritic if defined $no_diacritic;
        }
    }
    $self->$next(@names);
};

around add_alternative_name => sub {
    my $next = shift;
    my $self = shift;
    my @names = @_;

    if($self->do_undiacritic) {
        foreach my $name (@names) {
            my $no_diacritic = undiacriticise($name);
            push @names => $no_diacritic if defined $no_diacritic;
        }
    }
    $self->$next(@names);
};

around add_line => sub {
    my $next = shift;
    my $self = shift;
    my $line = shift; # Line

    $self->$next($line) if !$self->find_line(sub { $line->id eq $_->id });
};

around add_connecting_station => sub {
    my $next = shift;
    my $self = shift;
    my $station = shift; # Station

    $self->$next($station) if !$self->find_connecting_station(sub { $station->id eq $_->id });
};

sub name_with_alternative {
    my $self = shift;

    return ($self->name, $self->all_alternative_names);
}

sub undiacriticise {
    my $text = shift;
    my $undia = undiacritic($text);
    return $undia if $undia ne $text;
    return;
}

sub to_hash {
    my $self = shift;

    return {
        id => $self->id,
        name => $self->name,
        original_name => $self->original_name,
        search_names => [ $self->all_search_names ],
        alternative_names => [ $self->all_alternative_names ],
        lines => [
            map { $_->to_hash } $self->all_lines
        ],
       # connecting_stations => [
       #     map { $_->to_hash } $self->all_connecting_stations
       # ],

    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph::Station - Information about a station

=head1 VERSION

Version 0.2405, released 2016-07-23.



=head1 DESCRIPTION

Stations represents actual stations, and are used both during the graph building phase and the navigational phase.

=head1 ATTRIBUTES


=head2 id

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 name

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end markdown

=head2 do_undiacritic

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>0</code>:</td>
    <td style="padding-left: 12px;">Do not remove diacritics from station name.</td>
</tr>
<tr>
    <td>&#160;</td>
    <td>&#160;</td>
    <td>&#160;</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Do remove diacritics from station name.</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Do remove diacritics from station name.</td>
</tr>
</table>

<p></p>

=end markdown

=head2 alternative_names

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end markdown

=head2 original_name

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Maybe">Maybe</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Maybe">Maybe</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 search_names

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end markdown

=head2 connecting_stations

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Map::Metro::Types#Station">Station</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Map::Metro::Types#Station">Station</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 lines

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Line">Line</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Line">Line</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end markdown

=head1 METHODS

=head2 id()

Returns the internal station id. Do not depend on this between executions.

=head2 name()

Returns the station name given in the parsed map file.

=head2 lines()

Returns an array of all L<Lines|Map::Metro::Graph::Line> passing through the station.

=head2 connecting_stations()

Returns an array of all L<Stations|Map::Metro::Graph::Station> directly (on at least one line) connected to this station.

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
