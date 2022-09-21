##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/WindowProxy.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/31
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::WindowProxy;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Window );
    use vars qw( $VERSION );
    use HTML::Object::DOM;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub AUTOLOAD
{
    my( $name ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    my $win = $HTML::Object::DOM::WINDOW;
    my $code = $win->can( $name );
    die( "No method \"\$name\" in class \"", ref( $win ), "\".\n" ) if( !$code );
    eval( "sub $name" . ( Window->is_property( $name ) ? ' : lvalue' : '' ) . " { return( \$HTML::Object::DOM::WINDOW->$name( \@_ ) ); }\n\n" );
    return( $code->( $win, @_ ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::WindowProxy - HTML Object DOM WindowProxy Class

=head1 SYNOPSIS

    use HTML::Object::DOM::WindowProxy;
    my $proxy = HTML::Object::DOM::WindowProxy->new || 
        die( HTML::Object::DOM::WindowProxy->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface implements a C<WindowProxy>. It is a wrapper around L<HTML::Object::DOM::Window>, but does not inherit from it.

This does not do any specific otherwise, other than existing.

Under JavaScript, a C<WindowProxy> object is a wrapper for a L<Window|HTML::Object::DOM::Window> object. A C<WindowProxy> object exists in every browsing context. All operations performed on a C<WindowProxy> object will also be applied to the underlying L<Window|HTML::Object::DOM::Window> object it currently wraps. Therefore, interacting with a WindowProxy object is almost identical to directly interacting with a Window object. When a browsing context is navigated, the Window object its WindowProxy wraps is changed.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +---------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Window |
    +-----------------------+     +---------------------------+     +---------------------------+

=head1 PROPERTIES

All properties are redirecting to those in L<HTML::Object::DOM::Window>

=head1 METHODS

All methods are redirecting to those in L<HTML::Object::DOM::Window>

=head1 EVENTS & EVENT LISTENERS

All events and event listeners are redirecting to those in L<HTML::Object::DOM::Window>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Glossary/WindowProxy>, L<StackOverlow about WindowProxy|https://stackoverflow.com/questions/16092835/windowproxy-and-window-objects>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
