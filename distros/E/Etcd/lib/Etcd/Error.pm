package Etcd::Error;
$Etcd::Error::VERSION = '0.004';
use namespace::autoclean;

use JSON qw(decode_json);
use Carp qw(longmess);

use Moo;
use Types::Standard qw(Str Int);

has error_code => ( is => 'ro', isa => Str, required => 1, init_arg => 'errorCode' );
has message    => ( is => 'ro', isa => Str, required => 1 );
has cause      => ( is => 'ro', isa => Str, required => 1 );
has index      => ( is => 'ro', isa => Int, required => 1 );
has trace      => ( is => 'ro', isa => Str, required => 1 );

sub new_from_http {
    my ($class, $res) = @_;
    my $data = decode_json($res->{content});
    $class->new(%$data, trace => longmess());
}

use overload
    q{""} => sub {
        my ($self) = @_;
        $self->cause.": ".$self->message." [".$self->error_code."]".$self->trace;
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etcd::Error - API error representation

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Etcd;
    my $etcd = Etcd->new;
    
    use Try::Tiny;
    try {
        $etcd->get("/message");
    }
    catch {
        print $_;
    };

=head1 DESCRIPTION

L<Etcd::Error> objects encapsulate the details of API errors. They are thrown
by API calls when something goes wrong.

The provided methods are simple accessors. A stringification overload is
provided to produce a meaningful error with backtrace.

The API docs have more information about the meaning of each item. See
L<Etcd/SEE ALSO> for further reading.

=head1 METHODS

=over 4

=item *

C<error_code>

=item *

C<message>

=item *

C<cause>

=item *

C<index>

=item *

C<trace>

Stacktrace from the point that the error was generated.

=back

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
