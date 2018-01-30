package Directory::Scanner::Stream::Concat;
# ABSTRACT: Connect streaming directory iterators

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
use Directory::Scanner::API::Stream;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_CONCAT_DEBUG} // 0;

## ...

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Directory::Scanner::API::Stream') }
our %HAS; BEGIN {
	%HAS = (
		streams    => sub { [] },
		# internal state ...
		_index     => sub { 0 },
		_is_done   => sub { 0 },
		_is_closed => sub { 0 },
	)
}

## ...

sub BUILD {
	my $self    = $_[0];
	my $streams = $self->{streams};

	(Scalar::Util::blessed($_) && $_->DOES('Directory::Scanner::API::Stream'))
		|| Carp::confess 'You must supply all directory stream objects'
			foreach @$streams;
}

sub clone {
	# TODO - this might be possible ...
	Carp::confess 'Cloning a concat stream is not a good idea, just dont do it';
}

## delegate

sub head {
	my $self = $_[0];
	return if $self->{_index} > $#{$self->{streams}};
	return $self->{streams}->[ $self->{_index} ]->head;
}

sub is_done   { $_[0]->{_is_done}   }
sub is_closed { $_[0]->{_is_closed} }

sub close {
	my $self = $_[0];
	foreach my $stream ( @{ $self->{streams} } ) {
		$stream->close;
	}
	$_[0]->{_is_closed} = 1;
	return
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

		if ( $self->{_index} > $#{$self->{streams}} ) {
			# end of the streams now ...
			$self->{_is_done} = 1;
			last;
		}

		my $current = $self->{streams}->[ $self->{_index} ];

		if ( $current->is_done ) {
			# if we are done, advance the
			# index and restart the loop
			$self->{_index}++;
			next;
		}
		else {
			$next = $current->next;

			# if next returns nothing,
			# then we now done, so
			# restart the loop which
			# will trigger the ->is_done
			# block above and DWIM
			next unless defined $next;

			$self->_log('Exiting loop ... ') if DEBUG;

			# if we have gotten to this
			# point, we have a value and
			# want to return it
			last;
		}
	}

	return $next;
}

1;

__END__

=pod

=head1 NAME

Directory::Scanner::Stream::Concat - Connect streaming directory iterators

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Given multiple streams, this will concat them together one
after another.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
