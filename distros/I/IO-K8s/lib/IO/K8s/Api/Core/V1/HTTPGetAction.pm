package IO::K8s::Api::Core::V1::HTTPGetAction;
# ABSTRACT: HTTPGetAction describes an action based on HTTP Get requests.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s host => Str;


k8s httpHeaders => ['Core::V1::HTTPHeader'];


k8s path => Str;


k8s port => IntOrStr, 'required';


k8s scheme => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::HTTPGetAction - HTTPGetAction describes an action based on HTTP Get requests.

=head1 VERSION

version 1.008

=head2 host

Host name to connect to, defaults to the pod IP. You probably want to set "Host" in httpHeaders instead.

=head2 httpHeaders

Custom headers to set in the request. HTTP allows repeated headers.

=head2 path

Path to access on the HTTP server.

=head2 port

Name or number of the port to access on the container. Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.

=head2 scheme

Scheme to use for connecting to the host. Defaults to HTTP.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
