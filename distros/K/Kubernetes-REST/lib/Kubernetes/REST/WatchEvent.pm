package Kubernetes::REST::WatchEvent;
our $VERSION = '1.104';
# ABSTRACT: A single event from the Kubernetes Watch API
use Moo;
use Types::Standard qw(Str);


has type => (is => 'ro', isa => Str, required => 1);


has object => (is => 'ro', required => 1);


has raw => (is => 'ro', required => 1);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::WatchEvent - A single event from the Kubernetes Watch API

=head1 VERSION

version 1.104

=head1 SYNOPSIS

    $api->watch('Pod',
        namespace => 'default',
        on_event  => sub {
            my ($event) = @_;
            say $event->type;             # ADDED, MODIFIED, DELETED, ERROR, BOOKMARK
            say $event->object->metadata->name;  # inflated IO::K8s object
            say $event->raw->{metadata}{name};    # original hashref
        },
    );

=head1 DESCRIPTION

Represents a single watch event from the Kubernetes API. Watch events are streamed as newline-delimited JSON objects with a C<type> field and an C<object> field.

=head2 type

The event type string. One of: C<ADDED>, C<MODIFIED>, C<DELETED>, C<ERROR>, or C<BOOKMARK>.

=head2 object

The inflated L<IO::K8s> object for the resource. For C<ERROR> events this is a hashref (the Kubernetes Status object).

=head2 raw

The original hashref from the JSON before inflation. Useful for accessing fields that may not be mapped to the L<IO::K8s> class.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST/watch> - Watch API documentation

=item * L<https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes> - Kubernetes watch documentation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

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

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
