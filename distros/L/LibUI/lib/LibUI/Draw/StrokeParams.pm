package LibUI::Draw::StrokeParams 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Draw::LineCap'  => Enum [qw[Flat Round Square]];
    typedef 'LibUI::Draw::LineJoin' => Enum [qw[Miter Round Bevel]];
    #
    typedef 'LibUI::Draw::StrokeParams' => Struct [
        cap        => LibUI::Draw::LineCap(),
        join       => LibUI::Draw::LineJoin(),
        thickness  => Double,
        miterLimit => Double,
        dashes => Pointer [Double],  # TODO: Affix needs a way to stuff data into Arrays as Pointers
        numDashes => Size_t,
        dashPhase => Double
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Draw::StrokeParams - TODO

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

=head2 Line Cap

This enum is defined as C<LibUI::Draw::LineCap>.

Values include:

=over

=item C<Flat>

=item C<Round>

=item C<Square>

=back

=head2 Line Join

This enum is defined as C<LibUI::Draw::LineJoin>.

Values include:

=over

=item C<Miter>

=item C<Round>

=item C<Bevel>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords enum

=cut

