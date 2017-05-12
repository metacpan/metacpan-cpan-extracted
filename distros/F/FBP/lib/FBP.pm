package FBP;

=pod

=head1 NAME

FBP - Parser and Object Model for wxFormBuilder Project Files (.fpb files)

=head1 SYNOPSIS

  my $object = FBP->new;
  
  $object->parse_file( 'MyProject.fbp' );

=head1 DESCRIPTION

B<NOTE: Documentation is limited as this module is in active development>

wxFormBuilder is currently the best and most sophisticated program for
designing wxWidgets dialogs, and generating the code for these designs.

However, wxFormBuilder does not currently support the generation of Perl code.
If we are to produce Perl code for the designs it creates, the code generation
must be done independantly, outside of wxFormBuilder itself.

B<FBP> is a SAX-based parser and object model for the XML project files that
are created by wxFormBuilder. While it does B<NOT> do the creation of Perl code
itself, it should serve as a solid base for anyone who wishes to produce a code
generator for these saved files.

=head1 METHODS

=head2 new

  my $fbp = PBP->new;

The C<new> constructor takes no arguments and creates a new parser/model object.

=cut

use 5.008005;
use Mouse                0.90;
use Params::Util         1.00 ();
use FBP::Project              ();
use FBP::Dialog               ();
use FBP::AnimationCtrl        ();
use FBP::BitmapButton         ();
use FBP::BoxSizer             ();
use FBP::Button               ();
use FBP::CalendarCtrl         ();
use FBP::CheckBox             ();
use FBP::Choice               ();
use FBP::Choicebook           ();
use FBP::ChoicebookPage       ();
use FBP::ComboBox             ();
use FBP::ColourPickerCtrl     ();
use FBP::CustomControl        ();
use FBP::DatePickerCtrl       ();
use FBP::DirPickerCtrl        ();
use FBP::FilePickerCtrl       ();
use FBP::FlexGridSizer        ();
use FBP::FontPickerCtrl       ();
use FBP::FormPanel            ();
use FBP::Frame                ();
use FBP::Gauge                ();
use FBP::GenericDirCtrl       ();
use FBP::Grid                 ();
use FBP::GridBagSizer         ();
use FBP::GridBagSizerItem     ();
use FBP::GridSizer            ();
use FBP::HtmlWindow           ();
use FBP::HyperlinkCtrl        ();
use FBP::Listbook             ();
use FBP::ListbookPage         ();
use FBP::ListBox              ();
use FBP::ListCtrl             ();
use FBP::Menu                 ();
use FBP::MenuBar              ();
use FBP::MenuItem             ();
use FBP::MenuSeparator        ();
use FBP::Notebook             ();
use FBP::NotebookPage         ();
use FBP::Panel                ();
use FBP::RadioBox             ();
use FBP::RadioButton          ();
use FBP::RichTextCtrl         ();
use FBP::ScrollBar            ();
use FBP::ScrolledWindow       ();
use FBP::SearchCtrl           ();
use FBP::SizerItem            ();
use FBP::Slider               ();
use FBP::Spacer               ();
use FBP::SpinButton           ();
use FBP::SpinCtrl             ();
use FBP::SplitterItem         ();
use FBP::SplitterWindow       ();
use FBP::StaticBitmap         ();
use FBP::StaticBoxSizer       ();
use FBP::StaticText           ();
use FBP::StaticLine           ();
use FBP::StatusBar            ();
use FBP::StdDialogButtonSizer ();
use FBP::TextCtrl             ();
use FBP::ToggleButton         ();
use FBP::Tool                 ();
use FBP::ToolBar              ();
use FBP::ToolSeparator        ();
use FBP::TreeCtrl             ();

our $VERSION = '0.41';

extends 'FBP::Object';
with    'FBP::Children';





######################################################################
# Search Methods

=pod

=head2 project

  my $project = $FBP->project;

Finds and returns the L<FBP::Project> object for the FBP file, of which there
should only be one. Throws an exception if the file does not contains a project.

=cut

sub project {
	my $self = shift;
	my $project = $self->children->[0];
	unless ( Params::Util::_INSTANCE($project, 'FBP::Project') ) {
		die("FBP file does not contain a project");
	}
	return $project;
}

=pod

=head2 form

  my $form = $FBP->form('MyDialog1');

Convenience method which finds and returns the root L<FBP::Form> object for
a specific named dialog, frame, panel, menu or toolbar in the object model.

=cut

sub form {
	my $self = shift;
	my $name = shift;

	# Scan downwards under the project to find it
	foreach my $form ( $self->project->forms ) {
		if ( $form->name and $form->name eq $name ) {
			return $form;
		}
	}

	return undef;
}

=pod

=head2 dialog

  my $dialog = $fbp->dialog('MyDialog1');

Convenience method which finds and returns the root L<FBP::Dialog> object
for a specific named dialog box in the object model.

=cut

sub dialog {
	my $self = shift;
	my $name = shift;

	# Scan downwards under the project to find it
	foreach my $dialog ( $self->project->dialogs ) {
		if ( $dialog->name and $dialog->name eq $name ) {
			return $dialog;
		}
	}

	return undef;
}





######################################################################
# Parsing Code

=pod

=head2 parse_file

  my $ok = $fbp->parse_file('foo/bar.fbp');

The C<parse_file> method takes a named fbp project file, and parses it to
produce an object model.

Returns true if the parsing run succeeds, or throws an exception on error.

=cut

sub parse_file {
	my $self = shift;
	my $file = shift;
	unless ( -f $file and -r $file ) {
		die("Missing or unreadable file '$file'");
	}

	# Open the file
	require IO::File;
	my $fh = IO::File->new( $file );
	unless ( $fh ) {
		die("Failed to open file '$file'");
	}

	# Create the parser and parse the file
	require FBP::Parser;
	require XML::SAX;
	eval {
		my $handler = FBP::Parser->new($self);
		my $parser  = XML::SAX::ParserFactory->parser(
			Handler => $handler,
		);
		$parser->parse_file($fh);
	};
	if ( $@ ) {
		die("Error while parsing '$file': $@");
	}

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
