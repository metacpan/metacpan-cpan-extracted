package HTML::Widgets::NavMenu::ExpandVal;

use strict;
use warnings;

use base 'HTML::Widgets::NavMenu::Object';

__PACKAGE__->mk_acc_ref([
    qw(_capture)],
    );

sub _init
{
    my ($self, $args) = @_;

    $self->_capture($args->{'capture'});

    return 0;
}

sub is_capturing
{
    my $self = shift;

    return $self->_capture();
}

=head1 NAME

HTML::Widgets::NavMenu::ExpandVal - an expand value that differentiates among
different expands

For internal use only.

=head1 SYNOPSIS

    my $expand_val = HTML::Widgets::NavMenu::ExpandVal->new('capture' => $bool);

=head1 FUNCTIONS

=head2 my $expand_val = HTML::Widgets::NavMenu::ExpandVal->new('capture' => $bool);

Creates a new object.

=head2 $expand_val->is_capturing()

Returns whether or not it is a capturing expansion.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

