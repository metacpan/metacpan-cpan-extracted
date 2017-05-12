package Game::Life::NDim::Life;

# Created on: 2010-01-04 18:54:13
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use List::Util qw/sum max min/;

use overload '""' => \&to_string;

our $VERSION     = version->new('0.0.4');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

has type => (
    is      => 'rw',
    isa     => 'Str',
    default => 0,
);

has next_type => (
    is      => 'rw',
    isa     => 'Str',
);

has board => (
    is       => 'rw',
    isa      => 'Game::Life::NDim::Board',
    required => 1,
    weak_ref => 1,
);

has position => (
    is  => 'rw',
    isa => 'Game::Life::NDim::Dim',
    required => 1,
);

sub seed {
    my ($self, $types) = @_;
    my $new_type;

    TYPE:
    while (!defined $new_type) {
        for my $type (keys %{$types}) {
            if ( rand() < $types->{$type} ) {
                $new_type = $type;
                last TYPE;
            }
        }
    }

    $self->type($new_type);

    return $self;
}

# process
sub process {
    my ($self, $rules) = @_;

    $self->next_type($self->type);

    # process the rules in order until a rule is found that returns a type to
    # change too, rules that maintain status quoe return undef
    RULE:
    for my $rule (@{ $rules } ) {
        my $change = $rule->($self);

        # next if status quoe
        next RULE if !defined $change;

        # stage the changed type
        $self->next_type($change);
        last RULE;
    }

    return $self;
}

sub set {
    my ($self) = @_;

    $self->type($self->next_type);

    return $self;
}

sub surround {
    my ($self, $level) = @_;
    my $max   = $self->board->dims;
    my @lives;
    my $cursor = $self->position->clone;

    $level ||= 1;
    my $itter = $self->transformer;

    while (my $transform = $itter->()) {
        my $life = eval{ $self->board->get_life($self->position + $transform) };
        if (!$EVAL_ERROR) {
            push @lives, $life;
        }
        else { warn "Error: $EVAL_ERROR\n"; }
    }

    return \@lives;
}

sub transformer {
    my ($self) = @_;
    my @max    = @{ $self->board->dims };
    my $max    = @max - 1;
    my @transform;
    my @alter;
    for (0 .. $max) {
        push @transform, -1;
    }
    my $point;

    my $itter;
    $itter = sub {
        if (!defined $point) {
            $point = 0;
            return [@transform];
        }

        my $done = 0;
        while (!$done) {
            if ($transform[$point] + 1 <= 1) {
                $transform[$point]++;
                $done = 1;
                $point = 0;
                last;
            }
            $transform[$point] = -1;
            $point++;
            my $undef;
            return $undef if !exists $transform[$point];
        }

        return $itter->() if ($max + 1 == (grep {$_ == 0} @transform));

        return [@transform];
    };

    return $itter;
}

sub clone {
    my ($self) = @_;

    return __PACKAGE__->new(type => $self->type, board => $self->board, position => $self->position);
}

sub to_string {
    my ($self) = @_;

    return $self->type;
}

1;

__END__

=head1 NAME

Game::Life::NDim::Life - Object representing a life

=head1 VERSION

This documentation refers to Game::Life::NDim::Life version 0.0.4.


=head1 SYNOPSIS

   use Game::Life::NDim::Life;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<seed (  )>

=head2 C<process (  )>

=head2 C<set (  )>

=head2 C<surround (  )>

=head2 C<transformer (  )>

=head2 C<clone (  )>

=head2 C<to_string (  )>


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
