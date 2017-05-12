#! perl

package main;

use strict;

package EB::Wx::Shell::EditDialog;

use base qw(Wx::Dialog);
use base qw(EB::Wx::Shell::Window);
use strict;

use Wx qw[
	  wxADJUST_MINSIZE
	  wxALL
	  wxBOTTOM
	  wxDEFAULT_DIALOG_STYLE
	  wxDefaultPosition
	  wxDefaultSize
	  wxEXPAND
	  wxHORIZONTAL
	  wxID_APPLY
	  wxID_CANCEL
	  wxRESIZE_BORDER
	  wxRIGHT
	  wxTE_MULTILINE
	  wxTHICK_FRAME
	  wxVERTICAL
       ];

use Wx::Locale gettext => '_T';
sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: EB::Wx::Shell::EditDialog::new

	$style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER|wxTHICK_FRAME 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{t_input} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE);
	$self->{b_cancel} = Wx::Button->new($self, wxID_CANCEL, "");
	$self->{b_apply} = Wx::Button->new($self, wxID_APPLY, "");

	$self->__set_properties();
	$self->__do_layout();

	Wx::Event::EVT_BUTTON($self, $self->{b_cancel}->GetId, \&OnCancel);
	Wx::Event::EVT_BUTTON($self, $self->{b_apply}->GetId, \&OnApply);

# end wxGlade

	$self->sizepos_restore(lc($title));

	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: EB::Wx::Shell::EditDialog::__set_properties

	$self->SetTitle(_T("Wijzigen invoerregel"));
	$self->SetSize(Wx::Size->new(582, 318));
	$self->{t_input}->SetFocus();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: EB::Wx::Shell::EditDialog::__do_layout

	$self->{sz_main} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sz_main}->Add($self->{t_input}, 1, wxALL|wxEXPAND|wxADJUST_MINSIZE, 5);
	$self->{sz_buttons}->Add(5, 0, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
	$self->{sz_buttons}->Add($self->{b_cancel}, 0, wxRIGHT|wxBOTTOM|wxADJUST_MINSIZE, 5);
	$self->{sz_buttons}->Add($self->{b_apply}, 0, wxRIGHT|wxBOTTOM|wxADJUST_MINSIZE, 5);
	$self->{sz_main}->Add($self->{sz_buttons}, 0, wxEXPAND, 0);
	$self->SetSizer($self->{sz_main});
	$self->Layout();

# end wxGlade
}

sub OnCancel {
    my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::EditDialog::OnCancel <event_handler>

    $self->sizepos_save;
    $event->Skip;

# end wxGlade
}


sub OnApply {
    my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::EditDialog::OnApply <event_handler>

    $self->sizepos_save;
    $self->EndModal( wxID_APPLY );

# end wxGlade
}


# end of class EB::Wx::Shell::EditDialog

1;
