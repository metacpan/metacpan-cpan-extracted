package LibUI::Window 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix( LibUI::lib(), [ 'uiWindowTitle', 'title' ], [ InstanceOf ['LibUI::Window'] ] => Str );
    affix(
        LibUI::lib(),
        [ 'uiWindowSetTitle',           'setTitle' ],
        [ InstanceOf ['LibUI::Window'], Str ] => Void
    );

    sub contentSize($) {
        my $w = shift;
        CORE::state $affix //= wrap( LibUI::lib(), 'uiWindowContentSize',
            [ InstanceOf ['LibUI::Window'], Pointer [Int], Pointer [Int] ] => Void );
        my ( $width, $height );
        $affix->( $w, $width, $height );
        return ( $width, $height );
    }
    affix(
        LibUI::lib(),
        [ 'uiWindowSetContentSize',     'setContentSize' ],
        [ InstanceOf ['LibUI::Window'], Int, Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowFullscreen', 'fullscreen' ],
        [ InstanceOf ['LibUI::Window'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowSetFullscreen',      'setFullscreen' ],
        [ InstanceOf ['LibUI::Window'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowOnContentSizeChanged', 'onContentSizeChanged' ],
        [   InstanceOf ['LibUI::Window'],
            CodeRef [ [ InstanceOf ['LibUI::Window'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowOnClosing', 'onClosing' ],
        [   InstanceOf ['LibUI::Window'],
            CodeRef [ [ InstanceOf ['LibUI::Window'], Any ] => Int ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowOnFocusChanged', 'onFocusChanged' ],
        [   InstanceOf ['LibUI::Window'],
            CodeRef [ [ InstanceOf ['LibUI::Window'], Any ] => Int ], Any
        ] => Void
    );
    affix( LibUI::lib(), [ 'uiWindowFocused', 'focused' ],
        [ InstanceOf ['LibUI::Window'] ] => Int );
    affix(
        LibUI::lib(),
        [ 'uiWindowBorderless', 'borderless' ],
        [ InstanceOf ['LibUI::Window'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowSetBorderless',      'setBorderless' ],
        [ InstanceOf ['LibUI::Window'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowSetChild',           'setChild' ],
        [ InstanceOf ['LibUI::Window'], InstanceOf ['LibUI::Control'] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowMargined', 'margined' ],
        [ InstanceOf ['LibUI::Window'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowSetMargined',        'setMargined' ],
        [ InstanceOf ['LibUI::Window'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowResizeable', 'resizable' ],
        [ InstanceOf ['LibUI::Window'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiWindowSetResizeable',      'setResizable' ],
        [ InstanceOf ['LibUI::Window'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiNewWindow', 'new' ],
        [ Void, Str, Int, Int, Int ] => InstanceOf ['LibUI::Window']
    );

    # Dialogs
    affix(
        LibUI::lib(),
        [ 'uiMsgBox', 'msgBox' ],
        [ InstanceOf ['LibUI::Window'], Str, Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMsgBoxError', 'msgBoxError' ],
        [ InstanceOf ['LibUI::Window'], Str, Str ] => Void
    );
    affix( LibUI::lib(), [ 'uiOpenFile', 'openFile' ], [ InstanceOf ['LibUI::Window'] ] => Str );
    affix( LibUI::lib(), [ 'uiOpenFolder', 'openFolder' ],
        [ InstanceOf ['LibUI::Window'] ] => Str );
    affix( LibUI::lib(), [ 'uiSaveFile', 'saveFile' ], [ InstanceOf ['LibUI::Window'] ] => Str );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Window - Top-Level Window

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Window;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
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

A LibUI::Window object represents a top-level window.

A window contains exactly one child control that occupies the entire window. A
LibUI::Window is a subclass of LibUI::Control and can NOT be a child of another
LibUI::Control.

=head1 Functions

Many of the LibUI::Window methods should be regarded as mere hints. The
underlying system may override these or even choose to ignore them completely.
This is especially true for many Unix systems.

=head2 C<new( ... )>

    my $w = LibUI::Window->new( $title, $width, $height, $hasMenubar );

Creates a new LibUI::Window.

Expected parameters include:

=over

=item C<$title>

Window title text

=item C<$width>

Window width

=item C<$height>

Window height

=item C<$hasMenubar>

Boolean value indicating whether or no the window should display a menu bar

=back

=head2 C<title( ... )>

    my $title = $w->title( );

Returns the window title.

=head2 C<setTitle( ... )>

    $w->setTitle( '.../lib/Readonly.pm - SciTE' );

Sets the window title.

This method is merely a hint and may be ignored on unix platforms.

=head2 C<contentSize( ... )>

    my ( $w_, $h_ ) = $w->contentSize( );
    warn sprintf 'Window size: %d * %d', $w_, $h_;

Gets the window content size.

The content size does NOT include window decorations like menus or title bars.

=head2 C<setContentSize( ... )>

    $w->setContentSize( 1024, 720 );

Sets the window content size.

The content size does NOT include window decorations like menus or title bars.
This method is merely a hint and may be ignored by the system.

=head2 C<fullscreen( ... )>

    my $fs = $w->fullscreen( $w );

Returns whether or not the window is full screen.

Returns a true value if full screen; an untrue value otherwise.

=head2 C<setFullscreen( ... )>

    $w->setFullscreen( 1 );

Sets whether or not the window is full screen.

A true value to make the window full screen, an untrue value otherwise.

This method is merely a hint and may be ignored by the system.

=head2 C<onContentSizeChanged( ... )>

    $w->onContentSizeChanged(
        sub {
            my ($wnd, $data) = @_;
            my ( $w, $h );
            uiWindowContentSize( $wnd, $w, $h );
            warn sprintf 'Window size: %d * %d', $w_, $h_;
        },
        undef
    );

Registers a callback for when the window content size is changed.

Only one callback can be registered at a time.

=head2 C<onClosing( ... )>

    $w->onClosing(
        sub {
            my ($wnd, $data) = @_;
            my ( $w_, $h_ );
            warn 'Goodbye...';
            return 1;
        },
        undef
    );

Registers a callback for when the window is to be closed.

Your callback should return a boolean value:

=over

=item true to destroy the window

=item false to abort closing and keep the window alive and visible

=back

Only one callback can be registered at a time.

=head2 C<onFocusChanged( ... )>

    $w->onFocusChanged(
        sub {
            my ($wnd, $data) = @_;
            warn uiWindowFocused($wnd) ? 'Focus' : 'Lost focus';
        },
        undef
    );

Registers a callback for when the window focus changes.

Only one callback can be registered at a time.

=head2 C<focused( ... )>

    my $focused = $w->focused( );

Returns whether or not the window is focused. True if the window is focused,
otherwise false.

=head2 C<borderless( ... )>

    my $borderless = $w->borderless( );

Returns whether or not the window is borderless. True if the window is
borderless, otherwise false.

=head2 C<setBorderless( ... )>

    $w->setBorderless( 1 );

Sets whether or not the window is borderless. A true value to make the window
borderless, otherwise false.

This method is merely a hint and may be ignored by the system.

=head2 C<setChild( ... )>

    $w->setChild( $box );

Sets the window's child. The child must be a subclass of LibUI::Context.

=head2 C<margined( ... )>

    my $margin = $w->margined( );

Returns whether or not the window has a margin. True if the window has a
margin, otherwise false.

=head2 C<setMargined( ... )>

    $w->setMargined( 1 );

Sets whether or not the window has a margin. True to set a window margin,
otherwise false.

The margin size is determined by the OS defaults.

=head2 C<resizeable( ... )>

    my $can_resize = $w->resizeable( );

Returns whether or not the window is user resizable. True if the window can be
resized, otherwise false.

=head2 C<setResizeable( ... )>

    $w->setResizeable( 0 );

Sets whether or not the window is user resizable. True to make the window
resizable, otherwise false.

This method is merely a hint and may be ignored by the system.

=head1 Dialog Functions

These methods launch platform-dependant dialogs.

=head2 C<openFile( )>

    my $path = $w->openFile();

File chooser dialog window to select a single file.

File paths are separated by the underlying OS's file path separator.

=head2 C<openFolder( )>

    my $directory = $w->openFolder();

Folder chooser dialog window to select a single folder.

File paths are separated by the underlying OS's file path separator.

=head2 C<saveFile( )>

    my $path = $w->saveFile();

Save file dialog window.

The user is asked to confirm overwriting existing files, should the chosen file
path already exist on the system.

File paths are separated by the underlying OS's file path separator.

=head2 C<msgBox( ... )>

    $w->msgBox( 'MsgBox Demonstration', 'This works!' );

Message box dialog window.

A message box displayed in a new window indicating a common message.

Expected parameters include:

=over

=item C<$title>

Dialog window title text.

=item C<$description>

Dialog message text.

=back

=head2 C<msgBoxError( ... )>

    $w->msgBoxError( 'Oh, no!', 'This is broken!' );

Error message box dialog window.

A message box displayed in a new window indicating an error. On some systems
this may invoke an accompanying sound.

Expected parameters include:

=over

=item C<$title>

Dialog window title text.

=item C<$description>

Dialog message text.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords unix borderless resizable

=cut
