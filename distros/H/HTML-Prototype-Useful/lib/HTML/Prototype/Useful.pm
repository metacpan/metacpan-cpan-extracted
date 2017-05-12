package HTML::Prototype::Useful;

use strict;

use base 'HTML::Prototype';
use HTML::Prototype::Useful::Js;

our $VERSION = '0.05';
our $prototype_useful = do { package HTML::Prototype::Useful::Js; local $/; <DATA> };

=head1 NAME

HTML::Prototype::Useful - Some useful additions for the Prototype library.

=head1 SYNOPSIS

  use HTML::Prototype::Useful;
  $protype=HTML::Prototype::Useful->new();
  print $prototype->call_remote( ... )
  print $prototype->lazy_observe_field( .. )

=head1 DESCRIPTION

 this adds some more useful features for AJAX development based on the 
 Prototype library, as L<HTML::Prototype> is a straight port of the ruby
 implementation.

=head2 METHODS

=over 4

=item define_javascript_functions

Returns the javascript required for L<HTML::Prototype> as well as this module.

=cut

sub define_javascript_functions {
    return <<"";
<script type="text/javascript">
<!--
$HTML::Prototype::prototype
$prototype_useful
//-->
</script>

}

=item remote_function

Generate a remote function that you can stuff into your js somewhere.

=cut

sub remote_function {
    my ($self,@args) = @_;
    return HTML::Prototype::_remote_function(@args);
}

=item lazy_observe_field

like L<HTML::Prototype>'s observe_field method, but only detect 
changes after a user has stopped typing for C<frequency>. 

=cut

sub lazy_observe_field {
    my ( $self, $id, $options ) = @_;
    HTML::Prototype->_build_observer( 'Form.Element.SmartObserver', 
        $id, $options );
}

=item $p->observe_hover( $id \%options );

Observes the  element with the DOM ID specified by $id and makes an 
Ajax when you hover the mouse over it for at least <frequency> seconds.

Takes the same arguments as observe_field.

=cut

sub observe_hover {
    my ( $self, $id, $options ) = @_;
    HTML::Prototype->_build_observer( 'Element.HoverObserver', $id, $options );
}

=back

=head1 SEE ALSO

L<HTML::Prototype>, L<Catalyst::Plugin::Prototype>, L<Catalyst>.
L<http://prototype.conio.net/>

=head1 AUTHOR
Marcus Ramberg, C<mramberg@cpan.org>

=head1 THANK YOU

Sebastian Riedel for L<HTML::Prototype>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
