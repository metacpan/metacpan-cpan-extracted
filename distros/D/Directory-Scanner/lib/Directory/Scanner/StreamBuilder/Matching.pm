package Directory::Scanner::StreamBuilder::Matching;
# ABSTRACT: Filtered streaming directory iterator

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
use Directory::Scanner::API::Stream;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_MATCHING_DEBUG} // 0;

## ...

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Directory::Scanner::API::Stream') }
our %HAS; BEGIN {
	%HAS = (
		stream    => sub {},
		predicate => sub {},
	)
}

## ...

sub BUILD {
	my $self      = $_[0];
	my $stream    = $self->{stream};
	my $predicate = $self->{predicate};

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Scanner::API::Stream'))
		|| Carp::confess 'You must supply a directory stream';

	(defined $predicate)
		|| Carp::confess 'You must supply a predicate';

	(ref $predicate eq 'CODE')
		|| Carp::confess 'The predicate supplied must be a CODE reference';
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new(
		stream    => $self->{stream}->clone( $dir ),
		predicate => $self->{predicate}
	);
}

## delegate

sub head      { $_[0]->{stream}->head      }
sub is_done   { $_[0]->{stream}->is_done   }
sub is_closed { $_[0]->{stream}->is_closed }
sub close     { $_[0]->{stream}->close     }

sub next {
	my $self = $_[0];

	my $next;
	while (1) {
		undef $next; # clear any previous values, just cause ...
		$self->_log('Entering loop ... ') if DEBUG;

		$next = $self->{stream}->next;

		# this means the stream is likely
		# exhausted, so jump out of the loop
		last unless defined $next;

		# now try to predicate the value
		# and redo the loop if it does
		# not pass
        local $_ = $next;
		next unless $self->{predicate}->( $next );

		$self->_log('Exiting loop ... ') if DEBUG;

		# if we have gotten to this
		# point, we have a value and
		# want to return it
		last;
	}

	return $next;
}

1;

__END__

=pod

=head1 NAME

Directory::Scanner::StreamBuilder::Matching - Filtered streaming directory iterator

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This is provides a stream that will retain any item for which the
given a C<predicate> CODE ref returns true.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
