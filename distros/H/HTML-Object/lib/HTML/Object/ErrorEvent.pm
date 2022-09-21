##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/ErrorEvent.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/17
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::ErrorEvent;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Exception );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $sig  = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{signal} = $sig;
    return( $self );
}

sub signal { return( shift->_set_get_scalar( 'signal', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::ErrorEvent - HTML Object Error Event Class

=head1 SYNOPSIS

    use HTML::Object::ErrorEvent;
    my $event = HTML::Object::ErrorEvent->new( 'WARN' ) || 
        die( HTML::Object::ErrorEvent->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The L<HTML::Object::ErrorEvent> object represents an error triggered and captured by a global error in the L<HTML::Object::DOM::Document> object.

It is used by properties like L<HTML::Object::DOM::Document/onabort> or L<HTML::Object::DOM::Document/onerror>

It inherits its methods from L<HTML::Object::Exception> and implements the additional following ones:

=head1 INHERITANCE

    +-------------------------+     +--------------------------+
    | HTML::Object::Exception | --> | HTML::Object::ErrorEvent |
    +-------------------------+     +--------------------------+

=head1 CONSTRUCTOR

=head2 new

This takes a signal, which is case-insensitive and is saved in uppercase, and a list of strings that compose the error message, if any (e.g. for C<WARN> or C<DIE>)

=head1 METHODS

=head2 signal

The signal that triggered this event object. For example: C<DIE>, C<WARN>, C<ABRT>, C<INT>, C<TERM>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::Exception>, L<HTML::Object::DOM::Document>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/ErrorEvent>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
