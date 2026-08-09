package Kubernetes::REST::RemoteError;
our $VERSION = '1.106';
# ABSTRACT: DEPRECATED - v0 remote error class
  use Moo;
  use Types::Standard qw/Int/;
  use Kubernetes::REST::Error;
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

Kubernetes::REST::RemoteError - DEPRECATED - v0 remote error class

=head1 VERSION

version 1.106

=head1 DESCRIPTION

B<This error class is DEPRECATED>. The new v1 API uses C<croak> for errors instead of throwing structured exceptions.

Thrown for errors reported by the cluster itself, carrying the HTTP status alongside the message of L<Kubernetes::REST::Error>.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=head2 status

HTTP status code.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST::Error> - The base error class

=back

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
