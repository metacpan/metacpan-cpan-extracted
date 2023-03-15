package LibUI::Tab 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiTabAppend', 'append' ],
        [ InstanceOf ['LibUI::Tab'], Str, InstanceOf ['LibUI::Control'] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiTabInsertAt', 'insertAt' ],
        [ InstanceOf ['LibUI::Tab'], Str, Int, InstanceOf ['LibUI::Control'] ] => Void
    );
    affix( LibUI::lib(), [ 'uiTabNumPages', 'numPages' ], [ InstanceOf ['LibUI::Tab'] ] => Int );
    affix(
        LibUI::lib(),
        [ 'uiTabMargined',           'margined' ],
        [ InstanceOf ['LibUI::Tab'], Int ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiTabSetMargined', 'setMargined' ],
        [ InstanceOf ['LibUI::Tab'], Int, Int ] => Void
    );
    affix( LibUI::lib(), [ 'uiNewTab', 'new' ], [Void] => InstanceOf ['LibUI::Tab'] );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Tab - Multi-Page Control Interface that Displays One Page at a Time

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Tab;
    use LibUI::Window;
    use LibUI::Label;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $tabs   = LibUI::Tab->new;
    $tabs->append( $_, LibUI::Label->new($_) ) for qw[First Second Third Fourth];
    $tabs->setMargined( $_ - 1, 1 ) for 1 .. $tabs->numPages;
    $window->setChild($tabs);
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

A LibUI::Tab object represents a control interface that displays one page at a
time.

Each page/tab has an associated label that can be selected to switch between
pages/tabs.

=head1 Functions

Not a lot here but... well, it's just a tab box.

=head2 C<new( ... )>

    my $tab = LibUI::Tab->new( );

Creates a new LibUI::Tab.

=head2 C<append( ... )>

    $tab->append( 'Welcome', $box );

Appends a control in form of a page/tab with label.

Expected parameters include:

=over

=item C<$text> - label text

=item C<$child> - LibUI::Control instance to append

=back

=head2 C<delete( ... )>

    $tab->delete( $index );

Removes the control at C<$index>.

Note: The control is neither destroyed nor freed.

=head2 C<insertAt( ... )>

    $tab->insertAt( 'Settings', 5, $box );

Inserts a control in form of a page/tab with label at C<$index>.

Expected parameters include:

=over

=item C<$text> - label text

=item C<$index> - index at which to insert the control

=item C<$child> - LibUI::Control instance to append

=back

=head2 C<numPages( )>

    my $tally = $tab->numPages( );

Returns the number of pages contained.

=head2 C<margined( )>

    if( $tab->margined( 1 ) ) {
        ...;
    }

Returns whether or not the page/tab at C<$index> has a margin.

=head2 C<setMargined( ... )>

    $tab->setMargined( 1, 1 );

Sets whether or not the page/tab at index has a margin.

The margin size is determined by the OS defaults.

Expected parameters include:

=over

=item C<$index> - index at which to query the control

=item C<$margin> - boolean value

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

