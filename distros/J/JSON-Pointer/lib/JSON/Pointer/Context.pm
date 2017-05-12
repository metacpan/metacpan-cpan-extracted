package JSON::Pointer::Context;

use 5.008_001;
use strict;
use warnings;
use Class::Accessor::Lite (
    new => 0,
    rw  => [
        qw/
              pointer
              tokens
              processed_tokens
              last_token
              last_error
              result
              target
              parent
          /
      ],
);

our $VERSION = "0.07";

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : +{ @_ };
    %$args = (
        tokens           => [],
        processed_tokens => [],
        last_token       => undef,
        last_error       => undef,
        result           => 0,
        target           => undef,
        parent           => undef,
        %$args,
    );
    bless $args => $class;
}

sub begin {
    my ($self, $token) = @_;
    $self->{last_token} = $token;
    ### assign before target into parent
    $self->{parent} = $self->{target};
}

sub next {
    my ($self, $target) = @_;
    $self->{target} = $target;
    push(@{$self->{processed_tokens}}, $self->{last_token});
}

1;

__END__

=head1 NAME

JSON::Pointer::Context - Internal context object to process JSON Pointer

=head1 VERSION

This document describes JSON::Pointer::Context version 0.07.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is internal only.

=head1 METHODS

=head2 new(%args) :JSON::Pointer::Context

=head2 begin($token)

=head2 next($target)

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

=over

=item L<perl>

=item L<Class::Accessor::Lite>

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Toru Yamaguchi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
