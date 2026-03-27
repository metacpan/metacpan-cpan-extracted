package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::GroupVersionForDiscovery;
# ABSTRACT: GroupVersion contains the "group/version" and "version" string of a version. It is made a struct to keep extensibility.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s groupVersion => Str, 'required';


k8s version => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::GroupVersionForDiscovery - GroupVersion contains the "group/version" and "version" string of a version. It is made a struct to keep extensibility.

=head1 VERSION

version 1.100

=head2 groupVersion

groupVersion specifies the API group and version in the form "group/version"

=head2 version

version specifies the version in the form of "version". This is to save the clients the trouble of splitting the GroupVersion.

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
