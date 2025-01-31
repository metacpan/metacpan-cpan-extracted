package MIDI::Drummer::Tiny::Syncopate;
$MIDI::Drummer::Tiny::Syncopate::VERSION = '0.5009';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Syncopation logic

use Algorithm::Combinatorics qw(variations_with_repetition);
use MIDI::Util qw(dura_size);

use Moo;
use strictures 2;
use namespace::clean;

extends 'MIDI::Drummer::Tiny';



has duration => (
    is      => 'ro',
    default => sub { 'qn' },
);


has repeat => (
    is      => 'ro',
    default => sub { 4 },
);


sub steady {
    my ( $self, $instrument, $opts ) = @_;

    $instrument ||= $self->closed_hh;

    $opts->{duration} ||= $self->duration;

    # XXX This is not right
    for my $n ( 1 .. $self->counter ) {
        $self->note( $opts->{duration}, $instrument );
    }
}


sub combinatorial {
    my ( $self, $instrument, $opts ) = @_;

    $instrument ||= $self->snare;

    $opts->{negate}   ||= 0;
    $opts->{count}    ||= 0;
    $opts->{beats}    ||= $self->beats;
    $opts->{repeat}   ||= $self->repeat;
    $opts->{duration} ||= $self->duration;
    $opts->{vary}     ||= {
        0 => sub { $self->rest( $opts->{duration} ) },
        1 => sub { $self->note( $opts->{duration}, $instrument ) },
    };

    my $size = dura_size( $opts->{duration} );

    my @items = $opts->{patterns}
        ? @{ $opts->{patterns} }
        : sort map { join '', @$_ }
            variations_with_repetition( [ keys %{ $opts->{vary} } ], $opts->{beats} );

    for my $pattern (@items) {
        next if $pattern =~ /^0+$/;

        $pattern =~ tr/01/10/ if $opts->{negate};

        for ( 1 .. $opts->{repeat} ) {
            for my $bit ( split //, $pattern ) {
                $opts->{vary}{$bit}->($self);
                $self->counter( $self->counter + $size ) if $opts->{count};
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny::Syncopate - Syncopation logic

=head1 VERSION

version 0.5009

=head1 SYNOPSIS

 use MIDI::Drummer::Tiny::Syncopate;

 my $d = MIDI::Drummer::Tiny::Syncopate->new(
    file   => 'syncopate.mid',
    reverb => 15,
 );

 $d->combinatorial( $d->snare, {
    repeat   => 2,
    patterns => [qw(0101 1001)],
 });

 # Play parts simultaneously
 $d->sync( \&snare, \&kick, \&hhat );
 sub snare { $d->combinatorial( $d->snare, { count => 1 } ) }
 sub kick { $d->combinatorial( $d->kick, { negate => 1 } ) }
 sub hhat { $d->steady( $d->closed_hh ) }

 $d->write;

=head1 DESCRIPTION

C<MIDI::Drummer::Tiny::Syncopate> provides methods to use in the
F<eg/syncopation/*> lessons.

=head1 ATTRIBUTES

=head2 duration

  $duration = $d->duration;

Default: C<quarter>

=head2 repeat

  $repeat = $d->repeat;

Default: C<4>

=head1 METHODS

=head2 new

  $d = MIDI::Drummer::Tiny::Syncopate->new(%arguments);

Return a new C<MIDI::Drummer::Tiny::Syncopate> object.

=head2 steady

  $d->steady;
  $d->steady( $d->kick );
  $d->steady( $d->kick, { duration => $d->eighth } );

Play a steady beat with the given B<instrument> and optional
B<duration>, for the number of beats accumulated in the object's
B<counter> attribute.

Defaults:

  instrument: closed_hh
  Options:
    duration: given by constructor

=head2 combinatorial

  $d->combinatorial;
  $d->combinatorial( $d->kick );
  $d->combinatorial( $d->kick, \%options );

Play a beat pattern with the given B<instrument>, given by
L<Algorithm::Combinatorics/variations_with_repetition>.

This method accumulates beats in the object's B<counter> attribute if
the B<count> option is set.

The B<vary> option is a hashref of coderefs, keyed by single character
tokens, like the digits, 0-9.  The coderef durations should add up to
the B<duration> option.

Defaults:

  instrument: snare
  Options:
    duration: given by constructor
    count: 0
    negate: 0
    beats: given by constructor
    repeat: given by constructor
    vary:
        0 => sub { $self->rest( $options->{duration} ) },
        1 => sub { $self->note( $options->{duration}, $instrument ) },
    patterns: undef

=head1 SEE ALSO

The F<eg/syncopation/*> lessons.

L<MIDI::Util>

L<Moo>

L<https://www.amazon.com/dp/0882847953> -
"Progressive Steps to Syncopation for the Modern Drummer"

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
