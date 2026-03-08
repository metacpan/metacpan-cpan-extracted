package IO::K8s::Api::Batch::V1::UncountedTerminatedPods;
# ABSTRACT: UncountedTerminatedPods holds UIDs of Pods that have terminated but haven't been accounted in Job status counters.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s failed => [Str];


k8s succeeded => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Batch::V1::UncountedTerminatedPods - UncountedTerminatedPods holds UIDs of Pods that have terminated but haven't been accounted in Job status counters.

=head1 VERSION

version 1.006

=head2 failed

failed holds UIDs of failed Pods.

=head2 succeeded

succeeded holds UIDs of succeeded Pods.

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
