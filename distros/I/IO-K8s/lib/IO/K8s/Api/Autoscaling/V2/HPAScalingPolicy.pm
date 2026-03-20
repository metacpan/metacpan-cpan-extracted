package IO::K8s::Api::Autoscaling::V2::HPAScalingPolicy;
# ABSTRACT: HPAScalingPolicy is a single policy which must hold true for a specified past interval.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s periodSeconds => Int, 'required';


k8s type => Str, 'required';


k8s value => Int, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::HPAScalingPolicy - HPAScalingPolicy is a single policy which must hold true for a specified past interval.

=head1 VERSION

version 1.009

=head2 periodSeconds

periodSeconds specifies the window of time for which the policy should hold true. PeriodSeconds must be greater than zero and less than or equal to 1800 (30 min).

=head2 type

type is used to specify the scaling policy.

=head2 value

value contains the amount of change which is permitted by the policy. It must be greater than zero

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
