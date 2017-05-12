package Exobrain::Measurement::Social;

use 5.010;
use Moose::Role;
use Method::Signatures;

# ABSTRACT: Base class for all social media events
our $VERSION = '1.08'; # VERSION

BEGIN { with 'Exobrain::Message'; }

payload from     => ( isa => 'Str' );
payload to       => ( isa => 'ArrayRef[Str]', default => sub { [] } );
payload from_me  => ( isa => 'Bool', default => 0);
payload to_me    => ( isa => 'Bool', default => 0);
payload tags     => ( isa => 'ArrayRef[Str]', default => sub { [] } );
payload text     => ( isa => 'Str' );
payload private  => ( isa => 'Bool', default => 0);

# Platform and ID facilitate the sending of a response message without
# the full stack loaded for that particular message type.
payload platform => ( isa => 'Str' );
payload id       => ( isa => 'Str' );

# This sends a 'response' intent, which presumably will be
# picked up by an agent that will translate such things into
# a more directed intent.

method respond(Str $text) {
    $self->exobrain->intent('Response',
        to             => $self->from,
        platform       => $self->platform,
        in_response_to => $self->id,
        text           => $text,
        private        => $self->private
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Measurement::Social - Base class for all social media events

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
