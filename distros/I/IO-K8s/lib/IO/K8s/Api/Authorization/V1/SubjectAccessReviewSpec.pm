package IO::K8s::Api::Authorization::V1::SubjectAccessReviewSpec;
# ABSTRACT: SubjectAccessReviewSpec is a description of the access request.  Exactly one of ResourceAuthorizationAttributes and NonResourceAuthorizationAttributes must be set
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s extra => { Str => 1 };


k8s groups => [Str];


k8s nonResourceAttributes => 'Authorization::V1::NonResourceAttributes';


k8s resourceAttributes => 'Authorization::V1::ResourceAttributes';


k8s uid => Str;


k8s user => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authorization::V1::SubjectAccessReviewSpec - SubjectAccessReviewSpec is a description of the access request.  Exactly one of ResourceAuthorizationAttributes and NonResourceAuthorizationAttributes must be set

=head1 VERSION

version 1.006

=head2 extra

Extra corresponds to the user.Info.GetExtra() method from the authenticator.  Since that is input to the authorizer it needs a reflection here.

=head2 groups

Groups is the groups you're testing for.

=head2 nonResourceAttributes

NonResourceAttributes describes information for a non-resource access request

=head2 resourceAttributes

ResourceAuthorizationAttributes describes information for a resource access request

=head2 uid

UID information about the requesting user.

=head2 user

User is the user you're testing for. If you specify "User" but not "Groups", then is it interpreted as "What if User were not a member of any groups

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
