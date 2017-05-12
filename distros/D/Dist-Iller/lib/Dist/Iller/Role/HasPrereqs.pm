use 5.10.0;
use strict;
use warnings;

package Dist::Iller::Role::HasPrereqs;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1408';

use Moose::Role;
use namespace::autoclean;
use version;
use Types::Standard qw/ArrayRef HashRef InstanceOf/;
use Dist::Iller::Prereq;

has prereqs => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['Dist::Iller::Prereq']],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        add_prereq => 'push',
        filter_prereqs => 'grep',
        find_prereq => 'first',
        get_prereq => 'get',
        all_prereqs => 'elements',
        has_prereqs => 'count',
    },
);
has default_prereq_versions => (
    is => 'ro',
    isa => HashRef,
    traits => ['Hash'],
    default => sub { +{ } },
    handles => {
        set_default_prereq_version => 'set',
        get_default_prereq_version => 'get',
        all_default_prereq_versions => 'kv',
    },
);



# Ensure that we require the highest wanted version
around add_prereq => sub {
    my $next = shift;
    my $self = shift;
    my $prereq = shift;


    my $default_version = $self->get_default_prereq_version($prereq->module);
    if($default_version && !$prereq->version) {
        my $parsed_default_version = version->parse($default_version);

        if($parsed_default_version > version->parse($prereq->version)) {
            $prereq->version($default_version);
        }
    }

    my $already_existing = $self->find_prereq(sub {$_->module eq $prereq->module && $_->phase eq $prereq->phase });
    if($already_existing) {
        my $old_version = version->parse($already_existing->version);
        my $new_version = version->parse($prereq->version);

        if($new_version > $old_version) {
            $already_existing->version($prereq->version);
        }
    }
    else {
        $self->$next($prereq);
    }
};

sub merge_prereqs {
    my $self = shift;
    my @prereqs = @_;

    for my $prereq (@prereqs) {
        my $already_existing = $self->find_prereq(sub {$_->module eq $prereq->module && $_->phase eq $prereq->phase });

        if($already_existing) {
            my $old_version = version->parse($already_existing->version);
            my $new_version = version->parse($prereq->version);

            if($new_version > $old_version) {
                $already_existing->version($prereq->version);
            }
        }
        else {
            $self->add_prereq($prereq);
        }
    }
}

sub prereqs_to_array {
    my $self = shift;

    my $array = [];
    for my $prereq ($self->all_prereqs) {
        my $phase_relation = sprintf '%s_%s', $prereq->phase, $prereq->relation;
        push @{ $array } => { $phase_relation => sprintf '%s %s', $prereq->module, $prereq->version };
    }

    return $array;
}

sub prereqs_to_hash {
    my $self = shift;

    my $hash = {};
    for my $prereq ($self->all_prereqs) {
        if(!exists $hash->{ $prereq->phase }{ $prereq->relation }) {
            $hash->{ $prereq->phase }{ $prereq->relation } = [];
        }
        push @{ $hash->{ $prereq->phase }{ $prereq->relation } } => { $prereq->module => $prereq->version };
    }
    return $hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Role::HasPrereqs

=head1 VERSION

Version 0.1408, released 2016-03-12.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
