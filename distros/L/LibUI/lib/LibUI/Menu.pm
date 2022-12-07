package LibUI::Menu 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use LibUI::MenuItem;
    #
    affix( LibUI::lib(), 'uiNewMenu', [ Void, Str ] => InstanceOf ['LibUI::Menu'], 'new' );
    affix(
        LibUI::lib(), 'uiMenuAppendAboutItem',
        [ InstanceOf ['LibUI::Menu'] ] => InstanceOf ['LibUI::MenuItem'],
        'appendAboutItem'
    );
    affix(
        LibUI::lib(), 'uiMenuAppendCheckItem',
        [ InstanceOf ['LibUI::Menu'], Str ] => InstanceOf ['LibUI::MenuItem'],
        , 'appendCheckItem'
    );
    affix(
        LibUI::lib(), 'uiMenuAppendItem',
        [ InstanceOf ['LibUI::Menu'], Str ] => InstanceOf ['LibUI::MenuItem'],
        , 'appendItem'
    );
    affix(
        LibUI::lib(), 'uiMenuAppendPreferencesItem',
        [ InstanceOf ['LibUI::Menu'] ] => InstanceOf ['LibUI::MenuItem'],
        , 'appendPreferencesItem'
    );
    affix(
        LibUI::lib(), 'uiMenuAppendQuitItem',
        [ InstanceOf ['LibUI::Menu'] ] => InstanceOf ['LibUI::MenuItem'],
        , 'appendQuitItem'
    );
    affix(
        LibUI::lib(), 'uiMenuAppendSeparator',
        [ InstanceOf ['LibUI::Menu'] ] => InstanceOf ['LibUI::MenuItem'],
        , 'appendSeparator'
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Menu - Application-Level Menu Bar

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Window;
    use LibUI::Menu;
    Init( { Size => 1024 } ) && die;
    my $mnuFile = LibUI::Menu->new('File');
    $mnuFile->appendItem('New')->onClicked( sub { warn 'File>New' }, undef );
    $mnuFile->appendItem('Open');
    $mnuFile->appendItem('Save');
    $mnuFile->appendItem('Save As...');
    $mnuFile->appendSeparator;
    $mnuFile->appendItem(__FILE__);    # reopen
    my $mnuFileQuit = $mnuFile->appendQuitItem;
    LibUI::onShouldQuit(
        sub {
            return 1;
        },
        undef
    );
    my $mnuEdit = LibUI::Menu->new('Edit');
    my $mnuHelp = LibUI::Menu->new('Help');
    my $window  = LibUI::Window->new( 'Hi', 320, 100, 1 );
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

A LibUI::Menu object represents an application level menu bar.

The various operating systems impose different requirements on the creation and
placement of menu bar items, hence the abstraction of the items C<Quit>,
C<Preferences> and C<About>.

An exemplary, cross platform menu bar:

    File
        New
        Open
        Save
        Quit, use appendQuitItem()
    Edit
        Undo
        Redo
        Cut
        Copy
        Paste
        Select All
        Preferences, use appendPreferencesItem()
    Help
        About, use appendAboutItem()

=head1 Functions

Not a lot here but... well, it's just a menu.

=head2 C<new( ... )>

    my $mnu = LibUI::Menu->new("File");

Creates a new menu.

Typical values are C<File>, C<Edit>, C<Help>.

=head2 C<appendAboutItem( )>

    my $mnu_abt = $mnu->appendAboutItem();

Appends a new C<About> menu item.

Only one such menu item may exist per application.

=head2 C<appendCheckItem( ... )>

    my $mnu_chk = $mnu->appendCheckItem( 'Read only' );

Appends a generic menu item with a checkbox.

=head2 C<appendItem( ... )>

    my $mnu_itm = $mnu->appendItem( 'Find...' );

Appends a generic menu item.

=head2 C<appendPreferencesItem( )>

    my $mnu_pref = $mnu->appendPreferencesItem;

Appends a new C<Preferences> menu item.

Only one such menu item may exist per application.

=head2 C<appendQuitItem( )>

    my $mnu_quit = $mnu->appendQuitItem( );

Appends a new C<Quit> menu item.

Only one such menu item may exist per application.

Ranther than calling C<onClicked( ... )> on a C<Quit> item, use
C<LibUI::onShouldQuit( ... )> instead.


=head2 C<appendSeparator( )>

    my $mnu_quit = $mnu->appendSeparator( );

Appends a new separator.

=head1 See Also

L<LibUI::MenuItem>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference

=cut

