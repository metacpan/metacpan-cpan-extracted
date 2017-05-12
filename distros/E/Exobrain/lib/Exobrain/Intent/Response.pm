package Exobrain::Intent::Response;

use 5.010;
use Moose;
use Method::Signatures;

our $VERSION = '1.08'; # VERSION
# ABSTRACT: A generic class for responses to social media messages


# TODO: Find a good way of doing platform verification

method summary() { return $self->to.'@'.$self->platform.': '.$self->text; }

BEGIN { with 'Exobrain::Intent'; }

payload text           => ( isa => 'Str' );
payload to             => ( isa => 'Str' ); # User to receive message
payload in_response_to => ( isa => 'Str' ); # Status/event we're responding to
payload platform       => ( isa => 'Str' ); # Platform to respond on.

1;

__END__

=pod

=head1 NAME

Exobrain::Intent::Response - A generic class for responses to social media messages

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    $exobrain->intent('Response',
        to             => 'pjf',
        text           => 'Thanks!',
        platform       => 'Twitter',
        in_response_to => $twitter_status_id,
    );

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
