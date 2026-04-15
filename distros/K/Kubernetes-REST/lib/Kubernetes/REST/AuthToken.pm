package Kubernetes::REST::AuthToken;
our $VERSION = '1.104';
# ABSTRACT: Kubernetes API authentication token
use Moo;
use Types::Standard qw/Str/;


has token => (is => 'ro', isa => Str, required => 1);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::AuthToken - Kubernetes API authentication token

=head1 VERSION

version 1.104

=head1 SYNOPSIS

    use Kubernetes::REST::AuthToken;

    my $auth = Kubernetes::REST::AuthToken->new(
        token => $bearer_token,
    );

=head1 DESCRIPTION

Authentication credentials for Kubernetes API requests using bearer token authentication.

=head2 token

Required. The bearer token for API authentication.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Kubeconfig> - Load token from kubeconfig

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
