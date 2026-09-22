package IO::K8s::Traefik::V1alpha1::SourceCriterion;
# ABSTRACT: SourceCriterion defines what criterion is used to group requests as originating from a common source.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ipStrategy        => '+IO::K8s::Traefik::V1alpha1::IPStrategy';
k8s requestHeaderName => Str;
k8s requestHost       => Bool;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::SourceCriterion - SourceCriterion defines what criterion is used to group requests as originating from a common source.

=head1 VERSION

version 1.108

=head2 ipStrategy

IPStrategy holds the IP strategy configuration used by Traefik to determine the client IP.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/ipallowlist/#ipstrategy

=head2 requestHeaderName

RequestHeaderName defines the name of the header used to group incoming requests.

=head2 requestHost

RequestHost defines whether to consider the request Host as the source.

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
