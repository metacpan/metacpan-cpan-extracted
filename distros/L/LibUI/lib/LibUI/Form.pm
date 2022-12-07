package LibUI::Form 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(), 'uiFormAppend',
        [ InstanceOf ['LibUI::Form'], Str, InstanceOf ['LibUI::Control'], Int ] => Void,
        'append'
    );
    affix( LibUI::lib(), 'uiFormDelete', [ InstanceOf ['LibUI::Form'], Int ] => Void, 'delete' );
    affix(
        LibUI::lib(), 'uiFormNumChildren', [ InstanceOf ['LibUI::Form'] ] => Int,
        'numChildren'
    );
    affix( LibUI::lib(), 'uiFormPadded', [ InstanceOf ['LibUI::Form'] ] => Int, 'padded' );
    affix(
        LibUI::lib(), 'uiFormSetPadded', [ InstanceOf ['LibUI::Form'], Int ] => Void,
        'setPadded'
    );
    affix( LibUI::lib(), 'uiNewForm', [Void] => InstanceOf ['LibUI::Form'], 'new' );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Form - Control Container to Organize Ccontained Controls as Labeled
Fields

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Form;
    use LibUI::Window;
    use LibUI::ColorButton;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    my $form   = LibUI::Form->new();
    my $cbtn_l = LibUI::ColorButton->new();
    my $cbtn_r = LibUI::ColorButton->new();

    sub colorChanged {
        warn sprintf '%5s #%02X%02X%02X%02X', pop, map { $_ * 255 } shift->color();
    }
    $cbtn_l->onChanged( \&colorChanged, 'Left' );
    $cbtn_r->onChanged( \&colorChanged, 'Right' );
    $form->append( 'Left',  $cbtn_l, 0 );
    $form->append( 'Right', $cbtn_r, 0 );
    $form->setPadded(1);
    $window->setChild($form);
    $window->onClosing(
        sub {
            Quit();
            return 1;
        },
        undef
    );
    $window->show;
    Main();

=head1 DESCRIPTION

A LibUI::Form object represents a container control to organize contained
controls as labeled fields.

As the name suggests this container is perfect to create ascetically pleasing
input forms.

Each control is preceded by it's corresponding label.

Labels and containers are organized into two panes, making both labels and
containers align with each other.

=head1 Functions

Not a lot here but... well, it's just a tab box.

=head2 C<new( ... )>

    my $frm = LibUI::Form->new( );

Creates a new form.

=head2 C<append( ... )>

    $frm->append( 'Color', $kid, 0 );

Appends a control with a label to the form.

Expected parameters include:

=over

=item C<$text> - label text

=item C<$child> - LibUI::Control instance to append

=item C<$stretchy> - true to stretch control, otherwise false

=back

Stretchy items expand to use the remaining space within the container. In the
case of multiple stretchy items the space is shared equally.

=head2 C<delete( ... )>

    $frm->delete( 1 );

Removes the control at C<$index> from the form.

Note: The control is neither destroyed nor freed.

=head2 C<numChildren( )>

    my $tally = $frm->numChildren( );

Returns the number of controls contained within the form.

=head2 C<padded( )>

    if( $frm->padded ) {
        ...;
    }

Returns whether or not controls within the form are padded.

Padding is defined as space between individual controls.

=head2 C<setPadded( ... )>

    $box->setPadded( 1 );

Sets whether or not controls within the box are padded.

Padding is defined as space between individual controls. The padding size is
determined by the OS defaults.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

