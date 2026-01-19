package Future::Uring::Exception;
$Future::Uring::Exception::VERSION = '0.001';
use 5.020;
use warnings;
use experimental 'signatures';
use overload '""' => sub($self, $other, $flipped) {
	return $self->to_string;
};

require Future::Uring;

sub new($class, $operation, $res, $filename, $line) {
	my $error = do { local $! = -$res; "$!" };
	bless {
		operation => $operation,
		errno     => -$res,
		error     => $error,
		filename  => $filename,
		line      => $line,
	}, $class;
}

sub operation($self) {
	return $self->{operation};
}

sub errno($self) {
	return $self->{errno};
}

sub error($self) {
	return $self->{error};
}

sub filename($self) {
	return $self->{filename};
}

sub line($self) {
	return $self->{line};
}

sub to_string($self) {
	return "$self->{operation}: $self->{error} at $self->{filename} line $self->{line}\n";
}

sub PROPAGATE($self, $filename, $line) {
	return bless {
		operation => $self->{operation},
		errno     => $self->{errno},
		error     => $self->{error},
		filename  => $filename,
		line      => $line,
	}, ref($self);
}

1;

# ABSTRACT: an exception from Future::Uring

__END__

=pod

=encoding UTF-8

=head1 NAME

Future::Uring::Exception - an exception from Future::Uring

=head1 VERSION

version 0.001

=head1 DESCRIPTION

=head1 METHODS

=head2 operation

This returns the operation that caused the error (e.g. C<'resv'>).

=head2 errno

This returns the error code (e.g. C<EPIPE>) that caused the error.

=head2 error

This returns the error string (e.g. "") for the error.

=head2 filename

The filename where the error originated.

=head2 line

The line number in the file where the error originated.

=head2 to_string

This stringifies the error to something like C<"$operation: $error_message\n">.

=for Pod::Coverage new
PROPAGATE

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
