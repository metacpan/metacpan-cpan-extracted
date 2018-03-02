package Directory::Scanner::Stream::Ignoring;
# ABSTRACT: Ignoring files in the streaming directory iterator

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_IGNORING_DEBUG} // 0;

## ...

use parent 'UNIVERSAL::Object';
use roles 'Directory::Scanner::API::Stream';
use slots (
    stream => sub {},
    filter => sub {},
);

## ...

sub BUILD {
    my $self   = $_[0];
    my $stream = $self->{stream};
    my $filter = $self->{filter};

    (Scalar::Util::blessed($stream) && $stream->roles::DOES('Directory::Scanner::API::Stream'))
        || Carp::confess 'You must supply a directory stream';

    (defined $filter)
        || Carp::confess 'You must supply a filter';

    (ref $filter eq 'CODE')
        || Carp::confess 'The filter supplied must be a CODE reference';
}

sub clone {
    my ($self, $dir) = @_;
    return $self->new(
        stream => $self->{stream}->clone( $dir ),
        filter => $self->{filter}
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

        # now try to filter the value
        # and redo the loop if it does
        # not pass
        local $_ = $next;
        next if $self->{filter}->( $next );

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

Directory::Scanner::Stream::Ignoring - Ignoring files in the streaming directory iterator

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is provides a stream that will ignore any item for which the
given a C<filter> CODE ref returns true.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
