package HTTP::Throwable::Role::Status::Gone;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::Gone::VERSION = '0.027';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 410 }
sub default_reason      { 'Gone' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::Gone - 410 Gone

=head1 VERSION

version 0.027

=head1 DESCRIPTION

The requested resource is no longer available at the server and
no forwarding address is known. This condition is expected to
be considered permanent. Clients with link editing capabilities
SHOULD delete references to the Request-URI after user approval.
If the server does not know, or has no facility to determine,
whether or not the condition is permanent, the status code 404
(Not Found) SHOULD be used instead. This response is cacheable
unless indicated otherwise.

The 410 response is primarily intended to assist the task of web
maintenance by notifying the recipient that the resource is
intentionally unavailable and that the server owners desire that
remote links to that resource be removed. Such an event is common
for limited-time, promotional services and for resources belonging
to individuals no longer working at the server's site. It is not
necessary to mark all permanently unavailable resources as "gone"
or to keep the mark for any length of time -- that is left to the
discretion of the server owner.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 410 Gone

#pod =head1 DESCRIPTION
#pod
#pod The requested resource is no longer available at the server and
#pod no forwarding address is known. This condition is expected to
#pod be considered permanent. Clients with link editing capabilities
#pod SHOULD delete references to the Request-URI after user approval.
#pod If the server does not know, or has no facility to determine,
#pod whether or not the condition is permanent, the status code 404
#pod (Not Found) SHOULD be used instead. This response is cacheable
#pod unless indicated otherwise.
#pod
#pod The 410 response is primarily intended to assist the task of web
#pod maintenance by notifying the recipient that the resource is
#pod intentionally unavailable and that the server owners desire that
#pod remote links to that resource be removed. Such an event is common
#pod for limited-time, promotional services and for resources belonging
#pod to individuals no longer working at the server's site. It is not
#pod necessary to mark all permanently unavailable resources as "gone"
#pod or to keep the mark for any length of time -- that is left to the
#pod discretion of the server owner.
#pod
