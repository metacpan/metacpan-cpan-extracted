package LibUI::Area::MouseEvent 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    typedef 'LibUI::Area::MouseEvent' => Struct [
        x => Double,
        y => Double,
        #
        width  => Double,
        height => Double,
        #
        down => Int,
        up   => Int,
        #
        count => Int,
        #
        modifiers => LibUI::Area::Modifiers(),
        #
        held1To64 => ULongLong
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Area::MouseEvent - LibUI::Area Mouse Event

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

A L<LibUI::Area::Handler> passes this when the C<mouseEvent> callback is
triggered.

=head1 Fields

Being a struct, a mouse event contains the following data:

=over

=item C<x> - horizontal position of the event

=item C<y> - vertical position of the event

=item C<width> - full width of the area

=item C<height> - full height of the area

=item C<down> - a value indicating which button has been released, if applicable

=item C<up> - a value indicating which button has been released, if applicable

=item C<count> - a value indicating how many buttons are currently pressed

=item C<modifiers> - see L<LibUI::Area::Modifiers>

=item C<Held1To64> - a value indicating which buttons are currently being pressed

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords struct

=cut

