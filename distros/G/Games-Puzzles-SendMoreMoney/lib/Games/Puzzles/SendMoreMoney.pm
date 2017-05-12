###########################################
# Games::Puzzles::SendMoreMoney 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package Games::Puzzles::SendMoreMoney;
###########################################

use strict;
use warnings;
use Algorithm::FastPermute;
use Log::Log4perl qw(:easy);

our $VERSION     = "0.03";
our $STOP_SOLVER = 0;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        puzzle       => undef,
        permutator   => undef,
        search_space => undef,
        validator    => undef,
        reporter     => undef,
        values       => undef,
        %options,
    };

    LOGDIE "Mandatory parameter puzzle missing" 
        unless defined $self->{puzzle};

    ($self->{left}, $self->{right}) = split /\s*=\s*/, $self->{puzzle};

    LOGDIE "Puzzle not an equation: '$self->{puzzle}'"
        unless defined $self->{right};

    bless $self, $class;

    $self->{chars} = [$self->chars_extract($self->{puzzle})];
    
    return $self;
}

###########################################
sub tryout {
###########################################
    my($self, $try) = @_;

    unless($self->{seen}->{join "", values %$try}++) {
        if($self->is_valid($try)) {
            if($self->evaluate($try)) {
                $self->{reporter}->($try) if defined $self->{reporter};
                push @{$self->{results}}, $try;
                return 1;
            }
        }
    }

    return 0;
}

###########################################
sub solve {
###########################################
    my($self) = @_;

    my %try;
    $self->{results} = ();

    $self->{seen}    = {};
    $self->{results} = [];

    if($self->{permutator}) {
        while(my $perm = $self->{permutator}->next()) {
            DEBUG "Permutation: @$perm";
            @try{@{$self->{chars}}} = @$perm;
            $self->tryout(\%try);
            last if $STOP_SOLVER;
        }
    } else {
        my @array = @{$self->{values}};
        eval {
            permute {
                DEBUG "Permutation: @array";
                @try{@{$self->{chars}}} = @array;
                $self->tryout(\%try);
                die "STOP_SOLVER_SET" if $STOP_SOLVER;
            } @array;
        };
        if($@ and $@ !~ /STOP_SOLVER_SET/) {
            die "Error is '$@'";
        }
    }

    return $self->{results};
}

###########################################
sub is_valid {
###########################################
    my($self, $try) = @_;

    if(defined $self->{validator}) {
        return $self->{validator}->($try);
    }

    return 1;
}

###########################################
sub evaluate {
###########################################
    my($self, $try) = @_;

    (my $left_tmp  = $self->{left})  =~ s/([a-zA-Z])/$try->{$1}/g;
    (my $right_tmp = $self->{right}) =~ s/([a-zA-Z])/$try->{$1}/g;
    
        # Remove pseudo-octal values
    $left_tmp  =~ s/\b0+([1-9])/$1/g;
    $right_tmp =~ s/\b0+([1-9])/$1/g;

    if(eval $left_tmp == eval $right_tmp) {
        INFO "$left_tmp == $right_tmp";
        return 1;
    }

    DEBUG "$left_tmp != $right_tmp";
    return 0;
}

###########################################
sub chars_extract {
###########################################
    my($self, $string) = @_;

    my %chars = ();

    while($string =~ /([a-zA-Z])/g) {
        $chars{$1}++;
    }

    return keys %chars;
}

1;

__END__

=head1 NAME

Games::Puzzles::SendMoreMoney - Solve SEND+MORE=MONEY problems

=head1 SYNOPSIS

    use Games::Puzzles::SendMoreMoney;
    use Data::Dumper;

    my $solver = Games::Puzzles::SendMoreMoney->new(
        values    => [0..9],
        puzzle    => "SEND + MORE = MONEY",
        reporter  => sub { print Dumper($_[0]) },
        validator => sub { return 0 if $_[0]->{S} == 0;
                           return 0 if $_[0]->{M} == 0;
                           return 1; },
    );

    $solver->solve();

=head1 DESCRIPTION

Games::Puzzles::SendMoreMoney solves numerical puzzles like to following:
Assume that each of the letters in the following expression represents
a distinct numerical digit:

    SEND + MORE = MONEY

Games::Puzzles::SendMoreMoney will crack this puzzle by brute-forcing
the entire search space.
In its simplest form, a call to its constructor specifies the puzzle
and a range of digit values for each letter in the puzzle:

        # Either ...
    my $solver = Games::Puzzles::SendMoreMoney->new(
        values => [0..9],
        puzzle => "SEND + MORE = MONEY",
    };

Calling the solver will then run through all possible permutations and
return a reference to an array of results:

    my $result = $solver->solve();

A single result (hence, an element of the array which C<$result> is
pointing to) consists of a reference to a hash containing the mapping
between the puzzle letters and their values:

    $VAR1 = {
              'S' => 9,
              'O' => 0,
              'M' => 1,
              'D' => 7,
              'N' => 6,
              'R' => 8,
              'E' => 5,
              'Y' => 2
            };

Often times, however, going through the entire search space can be 
extremely time consuming. Instead, it is desirable to report a result
as soon as it is found: 

    my $solver = Games::Puzzles::SendMoreMoney->new(
        values    => [0..9],
        puzzle    => "SEND + MORE = MONEY",
        reporter  => sub { print Dumper($_[0]) },
    );

The C<reporter> parameter specifies a reference to a function, which will
be called by Games::Puzzles::SendMoreMoney on every result that matches
the puzzle expression. The C<reporter> function will get a reference
to a result hash as its first parameter.
On top of that, the reporter can set the variable 
C<$Games::Puzzles::SendMoreMoney::STOP_SOLVER> to a true value to
indicate that the solver should terminate immediately. (However,
this doesn't work for the default permutator yet).

Sometimes, not all possible permutations are valid. For example, 
the original form of the SEND+MORE=MONEY puzzle requires that
neither of the numbers in the puzzle has a leading zero.
These types of constraints can be specified by using a validator
function, which will be called before evaluating a combination:

    my $solver = Games::Puzzles::SendMoreMoney->new(
        values    => [0..9],
        puzzle    => "SEND + MORE = MONEY",
        reporter  => sub { print Dumper($_[0]) },
        validator => sub { return 0 if $_[0]->{S} == 0;
                           return 0 if $_[0]->{M} == 0;
                           return 1; },
    );

If the validator returns 0, Games::Puzzles::SendMoreMoney won't even
evaluate the permutation but instead move on to the next one immediately.

Games::Puzzles::SendMoreMoney also supports custom permutators, which
need to return arrays of numbers which will be mapped to the puzzle letters
somewhat unpredictably:

        # ... or ...
    my $solver = Games::Puzzles::SendMoreMoney->new(
        permutator => \&get_next_permutation,
        puzzle     => "SEND + MORE = MONEY",
    };

At some point, Games::Puzzles::SendMoreMoney will even support 
a narrowly defined search space (however, currently, this isn't
implemented):

        # ... or ...
    my $solver = Games::Puzzles::SendMoreMoney->new(
        search_space => {
            S => [1..5],
            E => [1..5],
            N => [1..5],
            D => [1..5],
            # ...
        puzzle     => "SEND + MORE = MONEY",
    };

=head2 Debugging

Games::Puzzles::SendMoreMoney is Log::Log4perl-enabled, to turn on
debugging in this component, just initialize Log::Log4perl appropriately,
e.g. by calling

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

at the beginning of the script.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
