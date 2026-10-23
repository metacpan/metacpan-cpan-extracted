package Logic::Probabilistic::Inference::Base;

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp qw(croak);

use Scalar::Util qw(blessed);

our $VERSION = '0.01';

sub new ( $class, %args ) {
    my $prog = $args{program} // croak "program is required";
    my $self = {
        program => $prog,
        %args,
    };
    return bless $self, $class;
}

sub program ($self) { return $self->{program}; }

sub _normalize_dist_query ( $self, $raw_query, $var ) {
    if ( !ref($raw_query) && defined $var ) {
        if ( blessed($var) && $var->isa('Logic::Relational::Variable') ) {
            require Logic::Relational::Goal::Call;
            return Logic::Relational::Goal::Call->new( $raw_query, [$var] );
        }
    }
    return $raw_query;
}

sub _is_truth_value ( $self, $val ) {
    return 0 if !defined $val || ref($val);
    return 1 if $val =~ /\A(?:0|1|true|false)\z/ix;
    return 0;
}

sub _is_evidence_pair ( $self, $pair ) {
    return 0 unless ref($pair) eq 'ARRAY' && @$pair == 2;
    return $self->_is_truth_value( $pair->[1] );
}

sub _normalize_pair ( $self, $target, $bool ) {
    require Logic::Relational::Goal::Not;
    my $goal =
      ( blessed($target) && $target->isa('Logic::Relational::Goal') )
      ? $target
      : $self->program->normalize_goal($target);
    if ( !$bool || ( !ref($bool) && ( $bool eq 'false' || $bool eq '0' ) ) ) {
        return Logic::Relational::Goal::Not->new($goal);
    }
    return $goal;
}

sub _normalize_item_evidence ( $self, $item ) {
    if ( ref($item) eq 'ARRAY' ) {
        if ( @$item == 2 && $self->_is_evidence_pair($item) ) {
            return $self->_normalize_pair( $item->[0], $item->[1] );
        }
    }
    return $self->program->normalize_goal($item);
}

sub _normalize_goals ( $self, $raw_evidence ) {
    if ( ref($raw_evidence) eq 'HASH' ) {
        return $self->_normalize_hash_evidence($raw_evidence);
    }
    if ( ref($raw_evidence) eq 'ARRAY' ) {
        return $self->_normalize_array_evidence($raw_evidence);
    }
    return [ $self->program->normalize_goal($raw_evidence) ];
}

sub _normalize_hash_evidence ( $self, $hash_ref ) {
    require Logic::Relational::Goal::Not;
    my @evidence_goals;
    for my $k ( sort keys %$hash_ref ) {
        my $val  = $hash_ref->{$k};
        my $goal = $self->program->normalize_goal($k);
        if ( !$val
            || ( !ref($val) && ( $val eq 'false' || $val eq '0' ) ) )
        {
            push @evidence_goals, Logic::Relational::Goal::Not->new($goal);
        }
        else {
            push @evidence_goals, $goal;
        }
    }
    return \@evidence_goals;
}

sub _normalize_array_evidence ( $self, $raw_evidence ) {

    # If the array itself is a flattened list of pairs: [ G1 => 1, G2 => 1 ]
    if ( @$raw_evidence >= 2 && @$raw_evidence % 2 == 0 ) {
        my $all_pairs = 1;
        for ( my $i = 0 ; $i < @$raw_evidence ; $i += 2 ) {
            if ( !$self->_is_truth_value( $raw_evidence->[ $i + 1 ] ) ) {
                $all_pairs = 0;
                last;
            }
        }
        if ($all_pairs) {
            my @goals;
            for ( my $i = 0 ; $i < @$raw_evidence ; $i += 2 ) {
                push @goals,
                  $self->_normalize_pair( $raw_evidence->[$i],
                    $raw_evidence->[ $i + 1 ] );
            }
            return \@goals;
        }
    }

    my @goals;
    for my $item (@$raw_evidence) {
        if ( ref($item) eq 'ARRAY' ) {
            if ( @$item == 2 && $self->_is_evidence_pair($item) ) {
                push @goals, $self->_normalize_pair( $item->[0], $item->[1] );
            }
            elsif ( @$item >= 2 && @$item % 2 == 0 ) {
                my $all_inner = 1;
                for ( my $i = 0 ; $i < @$item ; $i += 2 ) {
                    if ( !$self->_is_truth_value( $item->[ $i + 1 ] ) ) {
                        $all_inner = 0;
                        last;
                    }
                }
                if ($all_inner) {
                    for ( my $i = 0 ; $i < @$item ; $i += 2 ) {
                        push @goals,
                          $self->_normalize_pair( $item->[$i],
                            $item->[ $i + 1 ] );
                    }
                }
                else {
                    push @goals, $self->program->normalize_goal($item);
                }
            }
            else {
                push @goals, $self->program->normalize_goal($item);
            }
        }
        else {
            push @goals, $self->program->normalize_goal($item);
        }
    }
    return \@goals;
}

sub _check_evidence ( $self, $rel_prog, $evidence_goals, $world_predicates,
    $generators )
{
    require Logic::Relational::Query;
    for my $ev_goal (@$evidence_goals) {
        my $q = Logic::Relational::Query->new(
            program    => $rel_prog,
            goals      => [$ev_goal],
            predicates => $world_predicates,
            generators => $generators,
        );
        return 0 unless $q->is_true;
    }
    return 1;
}

sub _check_query ( $self, $rel_prog, $query_goal, $world_predicates,
    $generators )
{
    require Logic::Relational::Query;
    my $q = Logic::Relational::Query->new(
        program    => $rel_prog,
        goals      => [$query_goal],
        predicates => $world_predicates,
        generators => $generators,
    );
    return $q->is_true ? 1 : 0;
}

sub _resolve_target_var ( $self, $query_goal, $var_arg = undef ) {
    if ( defined $var_arg ) {
        if ( blessed($var_arg) && $var_arg->isa('Logic::Relational::Variable') )
        {
            return $var_arg;
        }
        if ( !ref($var_arg) ) {
            my @vars = $self->_extract_variables($query_goal);
            for my $v (@vars) {
                return $v if $v->name eq $var_arg;
            }
            croak "Target variable '$var_arg' not found in query goal";
        }
        croak "Invalid target variable specification: $var_arg";
    }

    my @vars = $self->_extract_variables($query_goal);
    if ( @vars == 0 ) {
        croak
"No target variable found in query goal. Pass var => \$var or include an unbound variable in the query goal.";
    }
    if ( @vars > 1 ) {
        my $names = join( ', ', map { $_->name } @vars );
        croak
"Multiple variables found in query goal ($names). Specify which variable to target using var => \$var.";
    }
    return $vars[0];
}

sub _extract_variables ( $self, $goal ) {
    my %seen;
    my @result;

    my $walker;
    $walker = sub ($item) {
        return unless defined $item;
        if ( blessed($item) ) {
            if ( $item->isa('Logic::Relational::Variable') ) {
                if ( !$seen{ $item->id }++ ) {
                    push @result, $item;
                }
            }
            elsif ( $item->can('args') ) {
                for my $sub ( @{ $item->args // [] } ) {
                    $walker->($sub);
                }
            }
        }
        elsif ( ref($item) eq 'ARRAY' ) {
            for my $sub (@$item) {
                $walker->($sub);
            }
        }
    };

    if ( blessed($goal) && $goal->can('args') ) {
        for my $arg ( @{ $goal->args // [] } ) {
            $walker->($arg);
        }
    }
    return @result;
}

sub _val_to_key ( $self, $val ) {
    return 'undef' unless defined $val;
    if ( blessed($val) ) {
        return $val->to_string if $val->can('to_string');
        return $val->as_string if $val->can('as_string');
        return "$val";
    }
    if ( ref($val) eq 'ARRAY' ) {
        return '[' . join( ', ', map { $self->_val_to_key($_) } @$val ) . ']';
    }
    return "$val";
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Inference::Base - Abstract base class for probabilistic inference engines.

=head1 DESCRIPTION

Provides shared routines for goal normalization, evidence validation, and query checking
against possible world state predicates.

=cut
