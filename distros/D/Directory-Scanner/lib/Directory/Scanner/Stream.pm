package Directory::Scanner::Stream;
# ABSTRACT: Streaming directory iterator

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();
use Path::Tiny   ();

use UNIVERSAL::Object;
use Directory::Scanner::API::Stream;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_DEBUG} // 0;

## ...

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Directory::Scanner::API::Stream') }
our %HAS; BEGIN {
	%HAS = (
		origin     => sub { die 'You must supply a `origin` directory path' },
		# internal state ...
		_head      => sub {},
		_handle    => sub {},
		_is_done   => sub { 0 },
		_is_closed => sub { 0 },
	)
}

## ...

sub BUILD {
	my ($self, $params) = @_;

	my $dir = $self->{origin};

	# upgrade this to a Path:Tiny
	# object if needed
	$self->{origin} = $dir = Path::Tiny::path( $dir )
		unless Scalar::Util::blessed( $dir )
			&& $dir->isa('Path::Tiny');

	# make sure the directory is
	# fit to be streamed
	(-d $dir)
		|| Carp::confess 'Supplied path value must be a directory ('.$dir.')';
	(-r $dir)
		|| Carp::confess 'Supplied path value must be a readable directory ('.$dir.')';

	my $handle;
	opendir( $handle, $dir )
		|| Carp::confess 'Unable to open handle for directory('.$dir.') because: ' . $!;

	$self->{_handle} = $handle;
}

sub clone {
	my ($self, $dir) = @_;
	$dir ||= $self->{origin};
	return $self->new( origin => $dir );
}

## accessor

sub origin { $_[0]->{_origin} }

## API::Stream ...

sub head      { $_[0]->{_head}      }
sub is_done   { $_[0]->{_is_done}   }
sub is_closed { $_[0]->{_is_closed} }

sub close {
	closedir( $_[0]->{_handle} )
		|| Carp::confess 'Unable to close handle for directory because: ' . $!;
	$_[0]->{_is_closed} = 1;
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

		$self->_log('About to read directory ...') if DEBUG;
		if ( my $name = readdir( $self->{_handle} ) ) {

			$self->_log('Read directory ...') if DEBUG;
			next unless defined $name;

			$self->_log('Got ('.$name.') from directory read ...') if DEBUG;
			next if $name eq '.' || $name eq '..'; # skip these ...

			$next = $self->{origin}->child( $name );

			# directory is not readable or has been removed, so skip it
			if ( ! -r $next ) {
				$self->_log('Directory/File not readable ...') if DEBUG;
				next;
			}
			else {
				$self->_log('Value is good, ready to return it') if DEBUG;
				last;
			}
		}
		else {
			$self->_log('Exiting loop ... DONE') if DEBUG;

			# cleanup ...
			$self->{_head}    = undef;
			$self->{_is_done} = 1;
			last;
		}
		$self->_log('... looping') if DEBUG;
	}

	$self->_log('Got next value('.$next.')') if DEBUG;
	return $self->{_head} = $next;
}

1;

__END__

=pod

=head1 NAME

Directory::Scanner::Stream - Streaming directory iterator

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This is provides a stream of a given C<origin> directory.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
