package Gapp;
{
  $Gapp::VERSION = '0.60';
}

use Gtk2 '-init';

use Gapp::Action;
use Gapp::ActionGroup;
use Gapp::Assistant;
use Gapp::AssistantPage;
use Gapp::Button;
use Gapp::ButtonBox;
use Gapp::CellRenderer;
use Gapp::CheckButton;
use Gapp::ComboBox;
use Gapp::DateEntry;
use Gapp::Dialog;
use Gapp::Entry;
use Gapp::Expander;
use Gapp::EventBox;
use Gapp::FileChooserButton;
use Gapp::FileChooserDialog;
use Gapp::FileFilter;
use Gapp::Form::Context;
use Gapp::Form::Stash;
use Gapp::Frame;
use Gapp::HBox;
use Gapp::HPaned;
use Gapp::HButtonBox;
use Gapp::Image;
use Gapp::ImageMenuItem;
use Gapp::Label;
use Gapp::ListStore;
use Gapp::Menu;
use Gapp::MenuBar;
use Gapp::MenuItem;
use Gapp::MenuToolButton;
use Gapp::Model::List;
use Gapp::Model::SimpleList;
use Gapp::ProgressBar;
use Gapp::RadioButton;
use Gapp::ScrolledWindow;
use Gapp::SeparatorMenuItem;
use Gapp::SeparatorToolItem;
use Gapp::SpinButton;
use Gapp::Model::SimpleList;
use Gapp::Notebook;
use Gapp::Statusbar;
use Gapp::StatusIcon;
use Gapp::Table;
use Gapp::TextBuffer;
use Gapp::TextTag;
use Gapp::TextTagTable;
use Gapp::TextView;
use Gapp::TimeEntry;
use Gapp::ToggleButton;
use Gapp::Toolbar;
use Gapp::ToolButton;
use Gapp::ToolItemGroup;
use Gapp::ToolPalette;
use Gapp::TreeView;
use Gapp::TreeViewColumn;
use Gapp::UIManager;
use Gapp::VBox;
use Gapp::Viewport;
use Gapp::VPaned;
use Gapp::VButtonBox;
use Gapp::Widget;
use Gapp::Window;


use Gapp::Layout::Default;
our $Layout = Gapp::Layout::Default->Layout;
use Gapp::Meta::Widget::Native::Role::FormField;

use Gapp::Meta::Widget::Native::Trait::AssistantPage;
use Gapp::Meta::Widget::Native::Trait::Form;
use Gapp::Meta::Widget::Native::Trait::FromUIManager;
use Gapp::Meta::Widget::Native::Trait::NotebookPage;
use Gapp::Meta::Widget::Native::Trait::ListFormField;
use Gapp::Meta::Widget::Native::Trait::Sensitivity;
use Gapp::Meta::Widget::Native::Trait::ToggleListFormField;

sub main { Gtk2->main };
sub quit { Gtk2->main_quit };


1;

__END__

=pod

=head1 NAME

Gapp - Post-modern Gtk+ applications

=head1 SYNOPSIS

    use Gapp;
    use Gapp::Actions::Basic qw( Quit );

    my $w = Gapp::Window->new(
        title => 'Gapp Application',
        signal_connect => [
            [ 'delete-event' => Quit ],
        ],
        content => [
            Gapp::HBox->new(
                content => [
                  Gapp::Label->new( text => 'hello world!' ),
                  Gapp::Button->new( action => Quit ),
                ]
            )
        ]
    );
    
    $w->show_all;

    Gapp->main;
  
=head1 NEW VERSION WARNING

*THIS IS NEW SOFTWARE. IT IS STILL IN DEVELOPMENT. THE API MAY CHANGE IN FUTURE
VERSIONS WITH NO NOTICE. THE DOCUMENTATION MAY COVER FEATURES THAT ARE NOT
COMPLETE IN THEIR IMPLEMENTATION. THE DOCUMENTATION MAY ALSO BE LACKING.*
    
=head1 DESCRIPTION

Gapp brings the I<post-modern> feel of L<Moose> to Gtk2-Perl.

The primary goal of Gapp is to make Perl 5 GUI programming easier and less
tedious. With Gapp you can to think more about what you want to do and less
about choreographing widgets or keeping them (and your data) up to date.

Gapp effectively separates user interface design from business logic and
data structures. By defining the appearance and layout of widgets at a
single point in your program, your entire application maintains a consistent
look and feel.

Combining the features of Moose with Gtk2 yields a powerful framework for
building GUI applications. Declarative syntax results in code that is
clearer and easier to maintain. Roles and traits can by applied to widgets
like any other Moose object.

=head2 New to Gapp?

The best place to start is the L<Gapp::Manual>.

=head1 PROVIDED METHODS

=over 4

=item B<main>

Delegates to C<Gtk2::main>.

=item B<quit>

Delegates to C<Gtk2::main_quit>.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to everyone at Gtk2-Perl and Moose and all those who came before me for
making this module possible. Thanks to Jörn Reder and the authors and contributors
of MooseX::Types.

Gapp::TableMap uses code from Jörn Reder's L<Gtk2::Ex::FormFactory::Table>
(see L<Gapp::TableMap> for more details.)

Gapp::Actions is based off of L<MooseX::Types> (see L<Gapp::Actions> for more details.)

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
Individual files in this package may have have multiple copyrights and/or
licenses. Please refer to the documentation of indivdual packages for more
information. (see L<Gapp::Actions>, L<Gapp::TableMap>)

=cut









