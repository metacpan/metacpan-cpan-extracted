package LibUI::Area::KeyEvent 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Area::ExtKey' => Enum [
        [ ExtKeyEscape => 1 ], qw[ExtKeyInsert
            ExtKeyDelete
            ExtKeyHome
            ExtKeyEnd
            ExtKeytPageUp
            ExtKeyPageDown
            ExtKeyUp
            ExtKeyDown
            ExtKeyLeft
            ExtKeyRight],

        # F1..F12 are guaranteed to be consecutive
        qw[ExtKeyF1 ExtKeyF2 ExtKeyF3 ExtKeyF4 ExtKeyF5 ExtKeyF6 ExtKeyF7 ExtKeyF8 ExtKeyF9 ExtKeyF10 ExtKeyF11 ExtKeyF12],

        # numpad keys; independent of Num Lock state
        # N0..N9 are guaranteed to be consecutive
        qw[ExtKeyN0 ExtKeyN1 ExtKeyN2 ExtKeyN3 ExtKeyN4 ExtKeyN5 ExtKeyN6 ExtKeyN7 ExtKeyN8 ExtKeyN9],
        #
        qw[ExtKeyNDot
            ExtKeyNEnter
            ExtKeyNAdd
            ExtKeyNSubtract
            ExtKeyNMultiply
            ExtKeyNDivide]
    ];
    #
    typedef 'LibUI::Area::KeyEvent' => Struct [
        key       => Char,
        extKey    => LibUI::Area::ExtKey(),
        modifier  => LibUI::Area::Modifiers(),
        modifiers => LibUI::Area::Modifiers(),
        up        => Int
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Area::KeyEvent - LibUI::Area Keyboard Event

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

A L<LibUI::Area::Handler> passes this when the C<keyEvent> callback is
triggered.

=head1 Fields

Being a struct, a mouse event contains the following data:

=over

=item C<key> - key code

=item C<extKey> - extended key code

=item C<modifier> - see L<LibUI::Area::Modifiers>

=item C<modifiers> - see L<LibUI::Area::Modifiers>

=item C<up> - a value indicating which key has been released, if applicable

=back

=head1 Extended Key Codes

Here's the current list of values:

=over

=item C<ExtKeyEscape1>

=item C<ExtKeyInsert> - equivalent to "Help" on Apple keyboards

=item C<ExtKeyDelete>

=item C<ExtKeyHome>

=item C<ExtKeyEnd>

=item C<ExtKeyPageUp>

=item C<ExtKeyPageDown>

=item C<ExtKeyUp>

=item C<ExtKeyDown>

=item C<ExtKeyLeft>

=item C<ExtKeyRight>

=item C<ExtKeyF1> - F1..F12 are guaranteed to be consecutive

=item C<ExtKeyF2>

=item C<ExtKeyF3>

=item C<ExtKeyF4>

=item C<ExtKeyF5>

=item C<ExtKeyF6>

=item C<ExtKeyF7>

=item C<ExtKeyF8>

=item C<ExtKeyF9>

=item C<ExtKeyF10>

=item C<ExtKeyF11>

=item C<ExtKeyF12>

=item C<ExtKeyN0> - numpad keys; independent of Num Lock state

=item C<ExtKeyN1> - N0..N9 are guaranteed to be consecutive

=item C<ExtKeyN2>

=item C<ExtKeyN3>

=item C<ExtKeyN4>

=item C<ExtKeyN5>

=item C<ExtKeyN6>

=item C<ExtKeyN7>

=item C<ExtKeyN8>

=item C<ExtKeyN9>

=item C<ExtKeyNDot>

=item C<ExtKeyNEnter>

=item C<ExtKeyNAdd>

=item C<ExtKeyNSubtract>

=item C<ExtKeyNMultiply>

=item C<ExtKeyNDivide>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords struct numpad

=cut

