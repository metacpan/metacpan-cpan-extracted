package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::WebhookConversion;
# ABSTRACT: WebhookConversion describes how to call a conversion webhook
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s clientConfig => 'Apiextensions::V1::WebhookClientConfig';


k8s conversionReviewVersions => [Str], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::WebhookConversion - WebhookConversion describes how to call a conversion webhook

=head1 VERSION

version 1.006

=head2 clientConfig

clientConfig is the instructions for how to call the webhook if strategy is `Webhook`.

=head2 conversionReviewVersions

conversionReviewVersions is an ordered list of preferred `ConversionReview` versions the Webhook expects. The API server will use the first version in the list which it supports. If none of the versions specified in this list are supported by API server, conversion will fail for the custom resource. If a persisted Webhook configuration specifies allowed versions and does not include any versions known to the API Server, calls to the webhook will fail.

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
