package Kubernetes::REST::Error;
our $VERSION = '1.100';
# ABSTRACT: DEPRECATED - v0 error classes
  use Moo;
  use Types::Standard qw/Str/;
  extends 'Throwable::Error';

  has type => (is => 'ro', isa => Str, required => 1);


  has detail => (is => 'ro');


  sub header {
    my $self = shift;
    return sprintf "Exception with type: %s: %s", $self->type, $self->message;
  }


  sub as_string {
    my $self = shift;
    if (defined $self->detail) {
      return sprintf "%s\nDetail: %s", $self->header, $self->detail;
    } else {
      return $self->header;
    }
  }


package Kubernetes::REST::RemoteError;
our $VERSION = '1.003';
# ABSTRACT: DEPRECATED - v0 remote error class
  use Moo;
  use Types::Standard qw/Int/;
  extends 'Kubernetes::REST::Error';

  has '+type' => (default => sub { 'Remote' });
  has status => (is => 'ro', isa => Int, required => 1);


  around header => sub {
    my ($orig, $self) = @_;
    my $orig_message = $self->$orig;
    sprintf "%s with HTTP status %d", $orig_message, $self->status;
  };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Error - DEPRECATED - v0 error classes

=head1 VERSION

version 1.100

=head1 DESCRIPTION

B<These error classes are DEPRECATED>. The new v1 API uses C<croak> for errors instead of throwing structured exceptions.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=head2 type

Error type string.

=head2 detail

Optional detailed error message.

=head2 header

Returns the error header string.

=head2 as_string

Returns the full error message as a string, including detail if available.

=head2 status

HTTP status code.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org> (JLMARTIN, original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
