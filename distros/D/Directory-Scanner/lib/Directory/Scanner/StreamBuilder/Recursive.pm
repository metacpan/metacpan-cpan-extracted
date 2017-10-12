package Directory::Scanner::StreamBuilder::Recursive;
# ABSTRACT: Recrusive streaming directory iterator

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
use Directory::Scanner::API::Stream;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_RECURSIVE_DEBUG} // 0;

## ...

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Directory::Scanner::API::Stream') }
our %HAS; BEGIN {
	%HAS = (
		stream     => sub {},
		# internal state ...
		_head      => sub {},
		_stack     => sub { [] },
		_is_done   => sub { 0 },
		_is_closed => sub { 0 },
	)
}

## ...

sub BUILD {
	my ($self, $params) = @_;

	my $stream = $self->{stream};

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Scanner::API::Stream'))
		|| Carp::confess 'You must supply a directory stream';

	push @{$self->{_stack}} => $stream;
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new( stream => $self->{stream}->clone( $dir ) );
}

## accessor

sub head { $_[0]->{_head} }

sub is_done   { $_[0]->{_is_done}   }
sub is_closed { $_[0]->{_is_closed} }

sub close {
	my $self = $_[0];
	while ( my $stream = pop @{ $self->{_stack} } ) {
		$stream->close;
	}
	$self->{_is_closed} = 1;
	return;
}

sub next {
	my $self = $_[0];

	return if $self->{_is_done};

	Carp::confess 'Cannot call `next` on a closed stream'
		if $self->{_is_closed};

	my $next;
	while (1) {
		undef $next; # clear any previous values, just cause ...
		$self->_log('Entering loop ... ') if DEBUG;

		if ( my $current = $self->{_stack}->[-1] ) {
			$self->_log('Stream available in stack') if DEBUG;
			if ( my $candidate = $current->next ) {
				# if we have a directory, prepare
				# to recurse into it the next time
				# we are called, then ....
				if ( $candidate->is_dir ) {
					push @{$self->{_stack}} => $current->clone( $candidate );
				}

				# return our successful candidate
				$next = $candidate;
				last;
			}
			else {
				$self->_log('Current stream has been exhausted, moving to next') if DEBUG;

				# something, something, ... check is_done on $current here ...

				my $old = pop @{$self->{_stack}};
				$old->close unless $old->is_closed;
				next;
			}
		}
		else {
			$self->_log('No more streams available in stack') if DEBUG;
			$self->_log('Exiting loop ... DONE') if DEBUG;

			$self->{_head}    = undef;
			$self->{_is_done} = 1;
			last;
		}
	}

	return $self->{_head} = $next;
}

1;

__END__

=pod

=head1 NAME

Directory::Scanner::StreamBuilder::Recursive - Recrusive streaming directory iterator

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This is provides a stream that will traverse all encountered
sub-directories.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
