package Error::Tiny::Exception;

use strict;
use warnings;

require Carp;

use overload '""' => \&to_string, fallback => 1;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{message} = $params{message};
    $self->{file}    = $params{file};
    $self->{line}    = $params{line};

    return $self;
}

sub message { $_[0]->{message} }
sub line    { $_[0]->{line} }
sub file    { $_[0]->{file} }

sub throw {
    my $class = shift;
    my ($message) = @_;

    my (undef, $file, $line) = caller(0);
    my $self = $class->new(message => $message, file => $file, line => $line);

    Carp::croak($self);
}

sub rethrow {
    my $self = shift;

    Carp::croak($self);
}

sub catch {
    my $self = shift;
    my ($then, @tail) = @_;

    my $class = ref($self) ? ref($self) : $self;
    (Error::Tiny::Catch->new(handler => $then->handler, class => $class),
        @tail);
}

sub to_string {
    my $self = shift;

    my $message = $self->{message};
    $message =~ s{$}{ at $self->{file} line $self->{line}.}m;

    $message;
}

1;
__END__

=head1 NAME

Error::Tiny::Exception - Base exception

=head1 SYNOPSIS

    use Error::Tiny::Exception;

    Error::Tiny::Exception->throw('my error');

=head1 DESCRIPTION

L<Error::Tiny::Exception> is a base exception for L<Error::Tiny>.

=head1 METHODS

=head2 C<throw>

Throw exception.

=head2 C<rethrow>

Rethrow exception.

=head2 C<message>

Exception message.

=head2 C<file>

Exception file.

=head2 C<line>

Exception line.

=cut
