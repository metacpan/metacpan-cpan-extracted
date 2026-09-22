package IO::K8s::Cilium::V2::AWSGroup;
# ABSTRACT: AWSGroup is an structure that can be used to whitelisting information from AWS integration
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s labels              => { Str => 1 };
k8s region              => Str;
k8s securityGroupsIds   => [Str];
k8s securityGroupsNames => [Str];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AWSGroup - AWSGroup is an structure that can be used to whitelisting information from AWS integration

=head1 VERSION

version 1.108

=head2 labels

Labels selects AWS ENIs by labels.
Multiple labels are AND-ed together.

=head2 region

Deprecated: Region is unused.

=head2 securityGroupsIds

SecurityGroupsIds selects VPC SecurityGroups by IDs.
If multiple IDs are specified, they are OR-ed together.

Note that this may be AND-ed with any Names specified. Specifying both
IDs and Names is not recommended.

=head2 securityGroupsNames

SecurityGroupsNames selects VPC SecurityGroups by name.
If multiple names are specified, they are OR-ed together.

Note that this may be AND-ed with any IDs specified. Specifying both
IDs and Names is not recommended.

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
