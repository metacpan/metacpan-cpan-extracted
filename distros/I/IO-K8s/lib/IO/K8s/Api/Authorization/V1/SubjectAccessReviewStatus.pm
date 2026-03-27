package IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus;
# ABSTRACT: SubjectAccessReviewStatus
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s allowed => Bool, 'required';


k8s denied => Bool;


k8s evaluationError => Str;


k8s reason => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus - SubjectAccessReviewStatus

=head1 VERSION

version 1.100

=head2 allowed

Allowed is required. True if the action would be allowed, false otherwise.

=head2 denied

Denied is optional. True if the action would be denied, otherwise false. If both allowed is false and denied is false, then the authorizer has no opinion on whether to authorize the action. Denied may not be true if Allowed is true.

=head2 evaluationError

EvaluationError is an indication that some error occurred during the authorization check. It is entirely possible to get an error and be able to continue determine authorization status in spite of it. For instance, RBAC can be missing a role, but enough roles are still present and bound to reason about the request.

=head2 reason

Reason is optional.  It indicates why a request was allowed or denied.

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
