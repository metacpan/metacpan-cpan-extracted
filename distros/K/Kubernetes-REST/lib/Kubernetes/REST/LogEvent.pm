package Kubernetes::REST::LogEvent;
our $VERSION = '1.104';
# ABSTRACT: A single log line from the Kubernetes Pod Log API
use Moo;
use Types::Standard qw(Str);


has line => (is => 'ro', isa => Str, required => 1);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::LogEvent - A single log line from the Kubernetes Pod Log API

=head1 VERSION

version 1.104

=head1 SYNOPSIS

    $api->log('Pod', 'my-pod',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {
            my ($event) = @_;
            say $event->line;
        },
    );

=head1 DESCRIPTION

Represents a single log line from the Kubernetes Pod Log API. Wraps the raw text line in a typed object for consistent event handling, analogous to L<Kubernetes::REST::WatchEvent> for the Watch API.

=head2 line

The log line text. Does not include the trailing newline.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST/log> - Pod Log API documentation

=item * L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#read-log-pod-v1-core> - Kubernetes Pod log API reference

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
