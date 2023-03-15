package LibUI::Area::Handler 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use LibUI::Area::Modifiers;
    use LibUI::Area::KeyEvent;
    use LibUI::Area::MouseEvent;
    use LibUI::Area::DrawParams;
    #
    typedef 'LibUI::Area::Handler' => Struct [
        draw => CodeRef [
            [   Pointer [ InstanceOf ['LibUI::Area::Handler'] ],
                Pointer [ InstanceOf ['LibUI::Area'] ],
                Pointer [ InstanceOf ['LibUI::Area::DrawParams'] ]
            ] => Void
        ],
        mouseEvent => CodeRef [
            [   Pointer [ InstanceOf ['LibUI::Area::Handler'] ],
                Pointer [ InstanceOf ['LibUI::Area'] ],
                Pointer [ InstanceOf ['LibUI::Area::MouseEvent'] ]
            ] => Void
        ],
        mouseCrossed => CodeRef [
            [   Pointer [ InstanceOf ['LibUI::Area::Handler'] ],
                Pointer [ InstanceOf ['LibUI::Area'] ],
                Int
            ] => Void
        ],
        dragBroken => CodeRef [
            [   Pointer [ InstanceOf ['LibUI::Area::Handler'] ],
                Pointer [ InstanceOf ['LibUI::Area'] ]
            ] => Void
        ],
        keyEvent => CodeRef [
            [   Pointer [ InstanceOf ['LibUI::Area::Handler'] ],
                Pointer [ InstanceOf ['LibUI::Area'] ],
                Pointer [ InstanceOf ['LibUI::Area::KeyEvent'] ]
            ] => Int
        ]
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Area::Handler - Event Handler for the LibUI::Area Control

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

A LibUI::Area::Handler is an object with several methods that L<LibUI::Area>
calls to do certain tasks.

To create an area handler, simply create a structure which contains the
following keys:

=over

=item C<draw>

Provide a code reference which should expect...

=over

=item C<$handler> - pointer to the LibUI::Area::Handler object

=item C<$area> - pointer to the LibUI::Area object

=item C<$drawParams> - pointer to the LibUI::Area::DrawParams structure

=back

...and return void.


=item C<mouseEvent>

Provide a code reference which should expect...

=over

=item C<$handler> - pointer to the LibUI::Area::Handler object

=item C<$area> - pointer to the LibUI::Area object

=item C<$event> - pointer to the LibUI::Area::MouseEvent structure

=back

...and return void.

=item C<mouseCrossed>

Provide a code reference which should expect...

=over

=item C<$handler> - pointer to the LibUI::Area::Handler object

=item C<$area> - pointer to the LibUI::Area object

=back

...and return void.

=item C<dragBroken>

Provide a code reference which should expect...

=over

=item C<$handler> - pointer to the LibUI::Area::Handler object

=item C<$area> - pointer to the LibUI::Area object

=back

...and return void.

Note that there is no support for this event on GTK+ or MacOS.

=item C<keyEvent>

Provide a code reference which should expect...

=over

=item C<$handler> - pointer to the LibUI::Area::Handler object

=item C<$area> - pointer to the LibUI::Area object

=item C<$event> - pointer to the LibUI::Area::KeyEvent structure

=back

...and return an integer.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords MacOS

=cut

