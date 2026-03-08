package IO::K8s::Api::Core::V1::HTTPHeader;
# ABSTRACT: HTTPHeader describes a custom header to be used in HTTP probes
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s value => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::HTTPHeader - HTTPHeader describes a custom header to be used in HTTP probes

=head1 VERSION

version 1.006

=head2 name

The header field name. This will be canonicalized upon output, so case-variant names will be understood as the same header.

=head2 value

The header field value

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
