package LibUI::Button 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix( LibUI::lib(), [ 'uiNewButton', 'new' ], [ Void, Str ] => InstanceOf ['LibUI::Button'] );
    affix(
        LibUI::lib(),
        [ 'uiButtonOnClicked', 'onClicked' ],
        [   InstanceOf ['LibUI::Button'],
            CodeRef [ [ InstanceOf ['LibUI::Button'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiButtonSetText',            'setText' ],
        [ InstanceOf ['LibUI::Button'], Str ] => Void
    );
    affix( LibUI::lib(), [ 'uiButtonSetText', 'text' ], [ InstanceOf ['LibUI::Button'] ] => Str );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Button - Button to be Clicked by the User to Trigger an Action

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Window;
    use LibUI::Button;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $btn    = LibUI::Button->new('Click me!');
    $btn->onClicked(
        sub {
            $_[0]->setText( sprintf 'Clicked %d times', ++$_[1] );
        },
        my $i = 0
    );
    $window->setChild($btn);
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

A LibUI::Button object represents a control that visually represents a button
to be clicked by the user to trigger an action.

=head1 Functions

Not a lot here but... well, it's just a button.

=head2 C<new( ... )>

    my $btn = LibUI::Button->new( 'Click me!' );

Creates a new button.

=head2 C<onClicked( ... )>

    $btn->onClicked(
    sub {
        my ($ctrl, $data) = @_;
        ...;
    }, undef);

Registers a callback for when the button is clicked.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$btn> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

=head2 C<setText( ... )>

    $btn->setText( 'Scan' );

Sets the button label text.

=head2 C<text( )>

    my $txt = $btn->text;

Sets the button label text.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference

=cut

