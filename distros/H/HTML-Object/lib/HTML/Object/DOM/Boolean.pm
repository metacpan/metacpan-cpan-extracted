##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Boolean.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2021/12/13
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Boolean;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $bool = shift( @_ );
    $self->{value} = $bool;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{value} = $self->{value} ? 1 : 0;
    return( $self );
}

sub toString { return( shift->{value} ? 'true' : 'false' ); }

sub valueOf { return( shift->{value} ? 1 : 0 ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Boolean - HTML Object DOM Boolean

=head1 SYNOPSIS

    use HTML::Object::DOM::Boolean;
    my $bool = HTML::Object::DOM::Boolean->new(1) || 
        die( HTML::Object::DOM::Boolean->error, "\n" );
    say $bool->toString;
    say $bool->valueOf;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements an object wrapper for a boolean value.

The value passed as the first parameter is converted to a boolean value, if necessary. If the value is omitted or is C<0>, C<-0>, C<undef>, or the empty string (""), the object has an initial value of false (i.e. C<0> in perl). All other values, including any object, an empty array ([]), or the string "false", create an object with an initial value of true (i.e. C<1> in perl).

=head1 METHODS

=head2 toString

Returns a string of either C<true> or C<false> depending upon the value of the object.

=head2 valueOf

Returns the primitive value of the Boolean object, i.e. C<0> for false, or C<1> for true.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
