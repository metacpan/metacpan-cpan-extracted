package IO::K8s::Api::Resource::V1alpha3::DeviceAttribute;
# ABSTRACT: DeviceAttribute must have exactly one field set.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s bool => Bool;


k8s int => Int;


k8s string => Str;


k8s version => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::DeviceAttribute - DeviceAttribute must have exactly one field set.

=head1 VERSION

version 1.006

=head2 bool

BoolValue is a true/false value.

=head2 int

IntValue is a number.

=head2 string

StringValue is a string. Must not be longer than 64 characters.

=head2 version

VersionValue is a semantic version according to semver.org spec 2.0.0. Must not be longer than 64 characters.

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
