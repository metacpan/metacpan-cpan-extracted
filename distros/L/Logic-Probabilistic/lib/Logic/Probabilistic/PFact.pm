package Logic::Probabilistic::PFact;

use v5.38;
use experimental 'signatures';
use Carp         qw(croak);
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

sub new ( $class, %args ) {
    my $prob = $args{probability} // croak "probability is required";
    croak "probability must be between 0.0 and 1.0"
      if $prob < 0.0 || $prob > 1.0;

    my $pred      = $args{predicate} // croak "predicate is required";
    my $args_list = $args{args}      // [];
    croak "args must be an arrayref" unless ref($args_list) eq 'ARRAY';

    my $id = $args{id};
    if ( !defined $id ) {
        my $args_str = join(
            ',',
            map {
                ( blessed($_) && $_->can('to_string') )
                  ? $_->to_string
                  : "$_"
            } @$args_list
        );
        $id = $args_str eq '' ? $pred : "$pred($args_str)";
    }

    my $expires_at = $args{expires_at};
    if ( my $expires_in = $args{expires_in} ) {
        $expires_at = time + $expires_in;
    }

    require Logic::Relational::Term;
    require Logic::Relational::Clause;

    my $head = Logic::Relational::Term->new(
        functor => $pred,
        args    => $args_list,
    );

    my %meta;
    $meta{expires_at} = $expires_at if defined $expires_at;

    my $clause = Logic::Relational::Clause->new(
        head     => $head,
        id       => "pfact-$id",
        metadata => \%meta,
    );

    my $self = {
        probability => 0.0 + $prob,
        predicate   => $pred,
        args        => $args_list,
        id          => $id,
        key         => $pred . '/' . scalar(@$args_list),
        clause      => $clause,
        expires_at  => $expires_at,
    };

    return bless $self, $class;
}

sub probability ($self) { return $self->{probability}; }
sub predicate   ($self) { return $self->{predicate}; }
sub args        ($self) { return $self->{args}; }
sub id          ($self) { return $self->{id}; }
sub key         ($self) { return $self->{key}; }
sub clause      ($self) { return $self->{clause}; }
sub expires_at  ($self) { return $self->{expires_at}; }

sub is_expired ( $self, $now = time ) {
    return ( defined $self->{expires_at} && $now >= $self->{expires_at} )
      ? 1
      : 0;
}

sub remaining_ttl ( $self, $now = time ) {
    return unless defined $self->{expires_at};
    my $rem = $self->{expires_at} - $now;
    return $rem > 0 ? $rem : 0;
}

sub set_probability ( $self, $new_prob ) {
    croak "probability must be between 0.0 and 1.0"
      if $new_prob < 0.0 || $new_prob > 1.0;
    $self->{probability} = 0.0 + $new_prob;
    return $self;
}

1;

__END__

=head1 NAME

Logic::Probabilistic::PFact - Represents an independent probabilistic fact.

=head1 SYNOPSIS

    use Logic::Probabilistic::PFact;

    my $fact = Logic::Probabilistic::PFact->new(
        probability => 0.01,
        predicate   => 'burglary',
        args        => [],
    );

=head1 DESCRIPTION

C<Logic::Probabilistic::PFact> models an independent Bernoulli random variable
under the Distribution Semantics. When true in a possible world, its associated
C<Logic::Relational::Clause> is asserted into the relational program.

=cut
