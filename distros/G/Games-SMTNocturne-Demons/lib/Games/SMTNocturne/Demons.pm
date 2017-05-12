package Games::SMTNocturne::Demons;
BEGIN {
  $Games::SMTNocturne::Demons::AUTHORITY = 'cpan:DOY';
}
$Games::SMTNocturne::Demons::VERSION = '0.02';
use strict;
use warnings;
# ABSTRACT: look up information about demon fusion in Shin Megami Tensei: Nocturne

use Exporter 5.58 'import';
our @EXPORT_OK = qw(demon demons_of_type all_demons fuse fusions_for);

use Games::SMTNocturne::Demons::Demon;
use Games::SMTNocturne::Demons::Fusion;
use Games::SMTNocturne::Demons::FusionChart;



sub demon {
    my ($demon) = @_;

    return Games::SMTNocturne::Demons::Demon->from_name($demon);
}


sub demons_of_type {
    my ($type) = @_;

    return Games::SMTNocturne::Demons::Demon->from_type($type);
}


sub all_demons {
    return Games::SMTNocturne::Demons::Demon->all_demons;
}


sub fuse {
    my ($demon1, $demon2, $options) = @_;
    $options = { %{ $options || {} } };

    $demon1 = demon($demon1) unless ref($demon1);
    $demon2 = demon($demon2) unless ref($demon2);
    if ($options->{sacrifice}) {
        $options->{sacrifice} = demon($options->{sacrifice})
            unless ref($options->{sacrifice});
    }

    if (!$options->{basic}) {
        if (my $demon = _try_special_fusion($demon1, $demon2, $options)) {
            # XXX this is the wrong place for this, but not sure how to do
            # it better
            return if $demon->type eq 'Fiend'
                   && ($demon1->type eq 'Fiend' || $demon2->type eq 'Fiend');
            return $demon;
        }
        else {
            $options->{fusion_type} = 'normal';
        }
    }

    if ($demon1->type eq 'Element' && $demon2->type eq 'Element') {
        return _fuse_mitama($demon1, $demon2, $options);
    }
    elsif ($demon1->type eq 'Element' || $demon2->type eq 'Element') {
        return _element_fusion(
            ($demon1->type eq 'Element'
                ? ($demon1, $demon2) : ($demon2, $demon1)),
            $options
        );
    }
    elsif ($demon1->type eq 'Mitama' && $demon2->type eq 'Mitama') {
        return;
    }
    elsif ($demon1->type eq 'Mitama' || $demon2->type eq 'Mitama') {
        return _mitama_fusion(
            ($demon1->type eq 'Mitama'
                ? ($demon1, $demon2) : ($demon2, $demon1)),
            $options
        );
    }
    elsif ($demon1->type eq $demon2->type) {
        return _fuse_element($demon1, $demon2, $options);
    }
    else {
        return _normal_fusion($demon1, $demon2, $options);
    }
}


sub fusions_for {
    my ($demon, $options) = @_;

    $demon = demon($demon) unless ref($demon);

    my @fusions;
    my %seen;
    for my $types (Games::SMTNocturne::Demons::FusionChart::unfuse($demon->type)) {
        my ($type1, $type2) = @$types;
        for my $demon1 (Games::SMTNocturne::Demons::Demon->from_type($type1)) {
            next if defined $options->{max_level}
                 && $options->{max_level} < $demon1->level;
            for my $demon2 (Games::SMTNocturne::Demons::Demon->from_type($type2)) {
                next if defined $options->{max_level}
                     && $options->{max_level} < $demon2->level;
                push @fusions, [ $options, $demon1, $demon2 ]
                    if (fuse($demon1, $demon2, $options) || '') eq $demon;
            }
        }
    }

    my $special = Games::SMTNocturne::Demons::FusionChart::special_fusion_for(
        $demon->name
    );
    my @special_fusions;
    if ($special) {
        for my $key (qw(demon1 demon2 demon3 target sacrifice)) {
            next unless $special->{$key};
            if (my $name = $special->{$key}{name}) {
                $special->{$key} = [ demon($name) ];
            }
            elsif (my $type = $special->{$key}{type}) {
                my @types = ref($type) ? (@$type) : ($type);
                $special->{$key} = [
                    map {
                        Games::SMTNocturne::Demons::Demon->from_type($_)
                    } @types
                ];
            }
            $special->{$key} = [
                grep { $_->level <= $options->{max_level} }
                     @{ $special->{$key} }
            ] if $key ne 'target' && defined $options->{max_level};
        }

        if ($special->{demon3}) {
            for my $demon1 (@{ $special->{demon1} }) {
                for my $demon2 (@{ $special->{demon2} }) {
                    for my $demon3 (@{ $special->{demon3} }) {
                        push @special_fusions, [
                            $options, $demon1, $demon2, $demon3
                        ];
                        push @special_fusions, [
                            $options, $demon1, $demon3, $demon2
                        ];
                        push @special_fusions, [
                            $options, $demon2, $demon3, $demon1
                        ];
                    }
                }
            }
        }
        elsif ($special->{demon2}) {
            for my $demon1 (@{ $special->{demon1} }) {
                for my $demon2 (@{ $special->{demon2} }) {
                    push @special_fusions, [ $options, $demon1, $demon2 ];
                }
            }
        }
        elsif ($special->{demon1}) {
            if ($special->{target}) {
                my @target_fusions = map {
                    $_->raw
                } map {
                    fusions_for($_, $options)
                } @{ $special->{target} };
                push @special_fusions, grep {
                    my $fusion = $_;
                    grep { $_ eq $fusion->[0] || $_ eq $fusion->[1] }
                         @{ $special->{demon1} }
                } @target_fusions;
            }
            else {
                die "???";
            }
        }
        else {
            if ($special->{target}) {
                my @new_special = map {
                    $_->raw
                } map {
                    fusions_for($_, $options)
                } @{ $special->{target} };
                if ($demon->type eq 'Fiend') {
                    @new_special = grep {
                        $_->[1]->type ne 'Fiend' && $_->[2]->type ne 'Fiend'
                    } @new_special;
                }
                push @special_fusions, @new_special;
            }
            else {
                die "???";
            }
        }

        if ($special->{sacrifice}) {
            @special_fusions = map {
                my $sac = $_;
                map { [ @$_, $sac ] } @special_fusions
            } @{ $special->{sacrifice} };
        }

        if ($special->{deathstone}) {
            push @$_, '<deathstone>' for @special_fusions;
        }

        if ($special->{kagutsuchi}) {
            push @$_, $special->{kagutsuchi} for @special_fusions;
        }
    }

    return map { Games::SMTNocturne::Demons::Fusion->new(@$_) }
               @fusions, @special_fusions;
}

sub _try_special_fusion {
    my ($demon1, $demon2, $options) = @_;

    my $fused = Games::SMTNocturne::Demons::FusionChart::special_fusion(
        $demon1, $demon2, $options
    );
    return unless $fused;

    my $demon = demon($fused);

    my %bosses = map { $_ => 1 } @{ $options->{bosses} || [] };
    return if $demon->boss && !$bosses{$demon->name};

    return $demon;
}

sub _fuse_mitama {
    my ($element1, $element2) = @_;

    my $mitama = Games::SMTNocturne::Demons::FusionChart::fuse_mitama(
        $element1->name, $element2->name
    );
    return unless $mitama;
    return demon($mitama);
}

sub _element_fusion {
    my ($element, $demon, $options) = @_;

    my $direction = Games::SMTNocturne::Demons::FusionChart::element_fusion(
        $demon->type, $element->name
    );
    return unless $direction;

    return Games::SMTNocturne::Demons::Demon->from_fusion_stats({
        type   => $demon->type,
        level  => $demon->level,
        offset => $direction,
        %{ $options || {} },
    });
}

sub _mitama_fusion {
    my ($mitama, $demon) = @_;

    return $demon;
}

sub _fuse_element {
    my ($demon1, $demon2) = @_;

    my $element = Games::SMTNocturne::Demons::FusionChart::fuse_element(
        $demon1->type
    );
    return unless $element;
    return demon($element);
}

sub _normal_fusion {
    my ($demon1, $demon2, $options) = @_;

    my $new_type = Games::SMTNocturne::Demons::FusionChart::fuse(
        $demon1->type, $demon2->type
    );
    return unless $new_type;

    my $new_level = ($demon1->level + $demon2->level) / 2 + 1;

    return Games::SMTNocturne::Demons::Demon->from_fusion_stats({
        type  => $new_type,
        level => $new_level,
        %{ $options || {} },
    });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::SMTNocturne::Demons - look up information about demon fusion in Shin Megami Tensei: Nocturne

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Games::SMTNocturne::Demons qw(fuse fusions_for);

  say fuse('Rangda', 'Barong');
  # <Fury Shiva (95)>

  say for fusions_for('Shiva');
  # Fuse <Mitama Ara Mitama (25)> with <Fury Shiva (95)> resulting in <Fury Shiva (95)>
  # Fuse <Mitama Nigi Mitama (29)> with <Fury Shiva (95)> resulting in <Fury Shiva (95)>
  # Fuse <Mitama Kusi Mitama (32)> with <Fury Shiva (95)> resulting in <Fury Shiva (95)>
  # Fuse <Mitama Saki Mitama (35)> with <Fury Shiva (95)> resulting in <Fury Shiva (95)>
  # Fuse <Avatar Barong (60)> with <Femme Rangda (72)> resulting in <Fury Shiva (95)>

=head1 DESCRIPTION

This module implements various routines for modeling demon fusion in the
PlayStation 2 game Shin Megami Tensei: Nocturne. Note that it also comes with a
command line script called C<smt> which implements some more useful commands on
top of the basic functionality given here; see its documentation for more
information. All of the functions listed below are exported on request.

=head1 FUNCTIONS

=head2 demon($name)

Returns an instance of L<Games::SMTNocturne::Demons::Demon> for the named
demon. Throws an exception if no such demon exists.

=head2 demons_of_type($name)

Returns a list of all demons of a given type. Throws an exception if no such
type exists.

=head2 all_demons

Returns a list of all demons in the game.

=head2 fuse($demon1, $demon2, $options)

Returns the demon that will be created when fusing C<$demon1> with C<$demon2>.
Possible options (all optional) are:

=over 4

=item sacrifice

A third demon to be sacrificed (at full Kagutsuchi).

=item max_level

The level of your main character (so fusions that would result in a demon of a
higher level than this will be ignored).

=item bosses

An arrayref of boss demons which have been defeated. Any boss demon not listed
here will be unavailable for fusion.

=item deathstone

Whether or not you own any deathstones.

=item kagutsuchi

The current Kagutsuchi phase.

=back

=head2 fusions_for($demon, $options)

Returns a list of all possible demons fusions which can result in the given
demon. Possible options (all optional) are:

=over 4

=item max_level

The level of your main character (so fusions that would result in a demon of a
higher level than this will be ignored).

=item bosses

An arrayref of boss demons which have been defeated. Any boss demon not listed
here will be unavailable for fusion.

=back

=head1 BUGS

Probably a lot, since I just wrote this on the fly as I was playing. It was
reasonably accurate enough to get me through the game, but it probably needs a
lot more cleaning around the edges. Failing tests welcome!

One notable omission (that I would be interested in fixing) is that this module
does not handle cursed fusions (mostly since taking advantage of cursed fusions
is so difficult in the game to begin with).

Please report any bugs to GitHub Issues at
L<https://github.com/doy/games-smtnocturne-demons/issues>.

=head1 SEE ALSO

L<http://megamitensei.wikia.com/wiki/Shin_Megami_Tensei_III:_Nocturne>

L<http://www.gamefaqs.com/ps2/582958-shin-megami-tensei-nocturne/faqs/35110>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Games::SMTNocturne::Demons

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Games-SMTNocturne-Demons>

=item * Github

L<https://github.com/doy/games-smtnocturne-demons>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-SMTNocturne-Demons>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-SMTNocturne-Demons>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
