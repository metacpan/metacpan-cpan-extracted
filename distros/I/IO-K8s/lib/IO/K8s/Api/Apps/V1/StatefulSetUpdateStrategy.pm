package IO::K8s::Api::Apps::V1::StatefulSetUpdateStrategy;
# ABSTRACT: StatefulSetUpdateStrategy indicates the strategy that the StatefulSet controller will use to perform updates.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s rollingUpdate => 'Apps::V1::RollingUpdateStatefulSetStrategy';


k8s type => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::StatefulSetUpdateStrategy - StatefulSetUpdateStrategy indicates the strategy that the StatefulSet controller will use to perform updates.

=head1 VERSION

version 1.100

=head2 rollingUpdate

RollingUpdate is used to communicate parameters when Type is RollingUpdateStatefulSetStrategyType.

=head2 type

Type indicates the type of the StatefulSetUpdateStrategy. Default is RollingUpdate.

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
