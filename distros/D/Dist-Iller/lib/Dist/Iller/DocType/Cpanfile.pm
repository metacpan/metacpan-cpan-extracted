use 5.14.0;
use strict;
use warnings;

package Dist::Iller::DocType::Cpanfile;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Turn the Dist::Iller config into a .cpanfile file
our $VERSION = '0.1411';

use Dist::Iller::Elk;
use JSON::MaybeXS qw/decode_json/;
use Path::Tiny;
use Carp qw/croak/;
use Dist::Iller::Prereq;
with qw/
    Dist::Iller::DocType
    Dist::Iller::Role::HasPrereqs
/;

sub comment_start { '#' }

sub filename { 'cpanfile' }

sub phase { 'after' }

sub to_hash {
    my $self = shift;
    return { prereqs => $self->prereqs };
}

sub parse {
    my $self = shift;

    my $metapath = path('META.json');
    if(!$metapath->exists) {
        croak 'META.json does not exist';
    }

    my $meta = decode_json($metapath->slurp)->{'prereqs'};

    for my $phase (keys %{ $meta }) {
        my $phasedata = $meta->{ $phase };

        for my $relation (keys %{ $phasedata }) {
            my $relationdata = $phasedata->{ $relation };

            for my $module (sort keys %{ $relationdata }) {
                my $prereq = $meta->{ $phase }{ $relation };
                $self->add_prereq(Dist::Iller::Prereq->new(
                    module => $module,
                    version => $meta->{ $phase }{ $relation }{ $module },
                    phase => $phase,
                    relation => $relation,
                ));
            }
        }
    }
}

sub to_string {
    my $self = shift;

    my @strings;

    for my $phase (qw/runtime test build configure develop/) {
        RELATION:
        for my $relation (qw/requires recommends suggests conflicts/) {

            my @prereqs = sort { $a->module cmp $b->module } $self->filter_prereqs(sub { $_->phase eq $phase && $_->relation eq $relation });
            next RELATION if !scalar @prereqs;

            push @strings => "on $phase => sub {";
            for my $prereq (@prereqs) {
                push @strings => sprintf q{    %s '%s' => '%s';}, $relation, $prereq->module, $prereq->version;
            }
            push @strings => '};';
        }
    }
    return join "\n" => (@strings, '');

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::DocType::Cpanfile - Turn the Dist::Iller config into a .cpanfile file

=head1 VERSION

Version 0.1411, released 2020-01-01.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
