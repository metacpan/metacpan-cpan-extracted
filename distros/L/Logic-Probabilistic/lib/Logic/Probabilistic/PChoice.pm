package Logic::Probabilistic::PChoice;

use v5.38;
use experimental 'signatures';
use Carp qw(croak);
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

sub new ( $class, %args ) {
    my $pred      = $args{predicate} // croak "predicate is required";
    my $raw_outs  = $args{outcomes}  // croak "outcomes is required";
    my $base_args = $args{args}      // [];
    croak "outcomes must be an arrayref" unless ref($raw_outs) eq 'ARRAY';
    croak "args must be an arrayref"     unless ref($base_args) eq 'ARRAY';

    require Logic::Relational::Term;
    require Logic::Relational::Clause;

    if ( @$raw_outs && !ref( $raw_outs->[0] ) ) {
        my @paired;
        for ( my $i = 0 ; $i < scalar(@$raw_outs) ; $i += 2 ) {
            push @paired, [ $raw_outs->[$i], $raw_outs->[ $i + 1 ] ];
        }
        $raw_outs = \@paired;
    }

    my @outcomes;
    my $sum = 0.0;
    my $idx = 0;

    for my $item (@$raw_outs) {
        my ( $prob, $val );
        if ( ref($item) eq 'ARRAY' ) {
            ( $prob, $val ) = @$item;
        }
        elsif ( ref($item) eq 'HASH' ) {
            $prob = $item->{probability} // $item->{prob};
            $val  = $item->{value}       // $item->{val};
        }
        else {
            croak "Invalid outcome specification in pchoice";
        }

        croak "Outcome probability must be >= 0.0" if $prob < 0.0;
        $sum += $prob;

        my @full_args =
          ( @$base_args, ( ref($val) eq 'ARRAY' ? @$val : ($val) ) );

        my $head = Logic::Relational::Term->new(
            functor => $pred,
            args    => \@full_args,
        );

        my $clause = Logic::Relational::Clause->new(
            head => $head,
            id   => "pchoice-$pred-$idx",
        );

        push @outcomes,
          {
            index       => $idx,
            probability => 0.0 + $prob,
            value       => $val,
            args        => \@full_args,
            clause      => $clause,
            key         => $pred . '/' . scalar(@full_args),
          };
        $idx++;
    }

    croak "Total probability in pchoice cannot exceed 1.0 (got $sum)"
      if $sum > 1.0 + 1e-7;

    my $id = $args{id};
    if ( !defined $id ) {
        my $args_str = join(
            ',',
            map {
                ( blessed($_) && $_->can('to_string') )
                  ? $_->to_string
                  : "$_"
            } @$base_args
        );
        $id = $args_str eq '' ? $pred : "$pred($args_str)";
    }

    my $self = {
        id        => $id,
        predicate => $pred,
        base_args => $base_args,
        outcomes  => \@outcomes,
        sum_prob  => $sum,
        null_prob => ( $sum < 1.0 - 1e-7 ) ? ( 1.0 - $sum ) : 0.0,
    };

    return bless $self, $class;
}

sub id        ($self) { return $self->{id}; }
sub predicate ($self) { return $self->{predicate}; }
sub base_args ($self) { return $self->{base_args}; }
sub args      ($self) { return $self->{base_args}; }
sub outcomes  ($self) { return @{ $self->{outcomes} }; }
sub sum_prob  ($self) { return $self->{sum_prob}; }
sub null_prob ($self) { return $self->{null_prob}; }

1;

__END__

=head1 NAME

Logic::Probabilistic::PChoice - Represents an annotated disjunction or categorical random choice.

=head1 SYNOPSIS

    use Logic::Probabilistic::PChoice;

    my $choice = Logic::Probabilistic::PChoice->new(
        predicate => 'weather',
        outcomes  => [
            [ 0.7, 'sunny' ],
            [ 0.2, 'cloudy' ],
            [ 0.1, 'rainy' ],
        ],
    );

=head1 DESCRIPTION

C<Logic::Probabilistic::PChoice> models a discrete random variable with mutually
exclusive categorical outcomes. In any possible world, at most one outcome is
selected and asserted into the knowledgebase.

=cut
