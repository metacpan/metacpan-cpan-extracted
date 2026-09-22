package IO::K8s::PrometheusOperator::V1::GlobalRocketChatConfig;
# ABSTRACT: rocketChat defines the default configuration for Rocket Chat.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiURL  => Str, { pattern => qr/^(http|https):\/\/.+$/ };
k8s token   => 'Core::V1::ConfigMapKeySelector';
k8s tokenID => 'Core::V1::ConfigMapKeySelector';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::GlobalRocketChatConfig - rocketChat defines the default configuration for Rocket Chat.

=head1 VERSION

version 1.108

=head2 apiURL

apiURL defines the default Rocket Chat API URL.

It requires Alertmanager >= v0.28.0.

=head2 token

token defines the default Rocket Chat token.

It requires Alertmanager >= v0.28.0.

=head2 tokenID

tokenID defines the default Rocket Chat Token ID.

It requires Alertmanager >= v0.28.0.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
