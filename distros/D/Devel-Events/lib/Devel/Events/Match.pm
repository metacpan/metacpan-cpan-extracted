#!/usr/bin/perl

package Devel::Events::Match;
use Moose;

use Carp qw/croak/;
use Scalar::Util qw/reftype/;

sub match {
	my ( $self, $cond, @event ) = @_;
	$self->compile_cond($cond)->(@event);
}

sub grep {
	my ( $self, %args ) = @_;

	my $events = $args{events} or croak "'events' is a required parameter";;
	my $match = $args{match} or croak "'match' is a required parameter";;

	my $compiled_cond = $self->compile_cond($match);

	grep { $compiled_cond->(@$_) } @$events;
}

sub first {
	my ( $self, %args ) = @_;

	my $events = $args{events} or croak "'events' is a required parameter";;
	my $match = $args{match} or croak "'match' is a required parameter";;

	my $compiled_cond = $self->compile_cond($match);

	foreach my $event ( @$events ) {
		return wantarray ? @$event : $event if $compiled_cond->(@$event);
	}

	return;
}

sub take_while {
	my ( $self, %args ) = @_;

	my $match = $args{match} or croak "'match' is a required parameter";;

	my $compiled_cond = $self->compile_cond($match);

	$self->limit( %args, to => sub { not $compiled_cond->(@_) }, to_inclusive => 0 );
}

sub take_until {
	my ( $self, %args ) = @_;

	my $match = delete $args{match} or croak "'match' is a required parameter";

	$self->limit( %args, to => $match, to_inclusive => 0 );
}


sub drop_while {
	my ( $self, %args ) = @_;

	my $match = $args{match} or croak "'match' is a required parameter";;

	my $compiled_cond = $self->compile_cond($match);

	$self->limit( %args, from => sub { not $compiled_cond->(@_) });
}

sub drop_until {
	my ( $self, %args ) = @_;

	my $match = delete $args{match} or croak "'match' is a required parameter";;

	$self->limit( %args, from => $match );
}

sub limit {
	my ( $self, %args ) = @_;

	my ( $events, $from, $to ) = @args{qw/events from to/};

	croak "'events' is a required parameter" unless $events;

	$_ = $self->compile_cond($_) for $from, $to;

	my $to_inclusive = exists $args{to_inclusive} ? $args{to_inclusive} : 1;
	my $from_inclusive = exists $args{from_inclusive} ? $args{from_inclusive} : 1;

	my @matches;
	my @events = @$events;

	if ( $from ) {
		before: while ( my $event = shift @events ) {
			if ( $from->(@$event) ) {
				push @matches, $event if $from_inclusive;
				last before;
			}
		}
	}

	if ( $to ) {
		match: while ( my $event = shift @events ) {
			if ( $to->(@$event) ) {
				push @matches, $event if $to_inclusive;
				last match;
			} else {
				push @matches, $event;
			}
		}

		return @matches;
	} else {
		return ( @matches, @events );
	}
}

sub chunk {
	my ( $self, %args ) = @_;

	my $events = $args{events} or croak "'events' is a required parameter";;
	my $marker = $args{marker} || $args{match} or croak "'marker' is a required parameter";;
	
	my $compiled_cond = $self->compile_cond($marker);

	my @chunks = ( [ ] );

	foreach my $event ( @$events ) {
		push @chunks, [ ] if $compiled_cond->( @$event );
		push @{ $chunks[-1] }, $event;
	}

	shift @chunks if exists $args{first} and not $args{first};
	pop @chunks   if exists $args{last}  and not $args{last};

	return @chunks;
}

sub compile_cond {
	my ( $self, $cond ) = @_;

	if ( ref $cond ) {
		if ( reftype $cond eq 'CODE' ) {
			return $cond;
		} elsif ( reftype $cond eq 'HASH' ) {

			my %cond = %$cond;

			foreach my $subcond ( values %cond ) {
				$subcond = $self->compile_cond($subcond);
			}

			return sub {
				my ( @data ) = @_;

				if ( @data == 1 and ref $data[0]) {
					if ( reftype($data[0]) eq 'ARRAY' ) {
						@data = @{ $data[0] };
					} elsif ( reftype($data[0]) eq 'HASH' ) {
						@data = %{ $data[0] };
					}
				}

				my $type = shift @data if @data % 2 == 1;

				my %data = @data;

				$data{type} = $type if defined $type;

				foreach my $key ( keys %cond ) {
					my $subcond = $cond{$key};
					return unless $subcond->($data{$key});
				}

				return 1;
			}
		}
	} elsif ( defined $cond ) {
		return sub {
			my ( $type ) = @_;
			defined $type and $type eq $cond;
		}
	}
	
	croak "unknown condition format: $cond";
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Match - Event matching, splicing and dicing.

=head1 SYNOPSIS

	use Devel::Events::Match;

	my $matcher = Devel::Events::Match->new;

	my @matching = $matcher->grep( match => $cond, events => \@events );

=head1 DESCRIPTION

This class provides event list filtering, chunking etc based on a simple match
format.

This class is used by L<Devel::Events::Handler::Log::Memory> in order to ease
access into the event log.

=head1 METHODS

=item compile_cond

Used to compile condition values into code references.

Scalars become equality tests on the first element (event type/name matches this).

Hashes become recursive conditions, where each key is matched on the field. The
'type' pseudofield is the first element of the event. Every value in the hash
gets C<compile_cond> called on it recursively.

Code references are returned verbatim.

The output is a code reference that can be used to match events.

=item first %args

Return the first event that matches a certain condition.

Requires the C<match> and C<events> parameters.

=item grep %args

Return the list of events that match a certain condition.

Requires the C<match> and C<events> parameters.

=item limit from => $cond, to => $cond, %args

Return events between two events. If C<from> or C<to> is omitted then it
returns all the events up to or from the other filter (C<from> defaults to
C<sub { 1 }> and C<to> defaults to C<sub { 0 }>).

If either the C<from_inclusive> and C<to_inclusive> parameters are provided and
set to false then the range will only begin on the event after the C<from>
match and end on the event before the C<to> match respectively.

Requires the C<events> parameter.

=item chunk %args

Cuts the event log into chunks. When C<$marker> matches a new chunk is opened.

Requires the C<marker> and C<events> parameters.

The C<first> and C<last> parameters, when provided and false will cause the
first and last chunks to be dropped, respectively.

The first chunk contains all the events up to the first matching one.

=item take_while %args

=item take_until %args

=item drop_while %args

=item drop_until %args

Require the C<match> and C<events> parameters.

=cut

