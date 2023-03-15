package LibUI::Draw::Brush 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Draw::BrushType' => Enum [qw[Solid LinearGradient RadialGradient Image]];
    typedef 'LibUI::Draw::Brush::GradientStop' =>
        Struct [ pos => Double, r => Double, g => Double, b => Double, a => Double ];
    #
    typedef 'LibUI::Draw::Brush' => Struct [
        type => LibUI::Draw::BrushType(),

        # solid brushes
        R => Double,
        G => Double,
        B => Double,
        A => Double,

        # gradient brushes
        X0          => Double,
        Y0          => Double,
        X1          => Double,
        Y1          => Double,
        outerRadius => Double,
        stops       => Pointer [ LibUI::Draw::Brush::GradientStop() ],
        numStops    => Size_t
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Draw::Brush - TODO

=head1 SYNOPSIS

    TODO

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

=head1 Enumerations

=head2 Brush Type

This enum is defined as C<LibUI::Draw::BrushType>.

Values include:

=over

=item C<Solid>

=item C<LinerGradient>

=item C<RadialGradient>

=item C<Image>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference enum

=cut

