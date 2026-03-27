package IO::K8s::Api::Core::V1::LimitRangeItem;
# ABSTRACT: LimitRangeItem defines a min/max usage limit for any resource that matches on kind.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s default => { Str => 1 };


k8s defaultRequest => { Str => 1 };


k8s max => { Str => 1 };


k8s maxLimitRequestRatio => { Str => 1 };


k8s min => { Str => 1 };


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::LimitRangeItem - LimitRangeItem defines a min/max usage limit for any resource that matches on kind.

=head1 VERSION

version 1.100

=head2 default

Default resource requirement limit value by resource name if resource limit is omitted.

=head2 defaultRequest

DefaultRequest is the default resource requirement request value by resource name if resource request is omitted.

=head2 max

Max usage constraints on this kind by resource name.

=head2 maxLimitRequestRatio

MaxLimitRequestRatio if specified, the named resource must have a request and limit that are both non-zero where limit divided by request is less than or equal to the enumerated value; this represents the max burst for the named resource.

=head2 min

Min usage constraints on this kind by resource name.

=head2 type

Type of resource that this limit applies to.

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
