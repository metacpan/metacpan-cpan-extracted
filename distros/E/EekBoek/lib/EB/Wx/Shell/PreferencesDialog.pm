#! perl 

package main;

use strict;

package EB::Wx::Shell::PreferencesDialog;

use base qw(Wx::Dialog);
use strict;

# begin wxGlade: ::dependencies
use Wx::Locale gettext => '_T';
# end wxGlade

use Wx qw[
	  wxADJUST_MINSIZE
	  wxALIGN_CENTER_VERTICAL
	  wxALL
	  wxDEFAULT_DIALOG_STYLE
	  wxDefaultPosition
	  wxDefaultSize
	  wxEXPAND
	  wxHORIZONTAL
	  wxID_CANCEL
	  wxID_OK
	  wxLEFT
	  wxRIGHT
	  wxSP_ARROW_KEYS
	  wxTOP
	  wxVERTICAL
       ];

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: EB::Wx::Shell::PreferencesDialog::new

	$style = wxDEFAULT_DIALOG_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{sz_prefs_inner_staticbox} = Wx::StaticBox->new($self, -1, _T("Voorkeuren") );
	$self->{cx_repwin} = Wx::CheckBox->new($self, -1, _T("Rapporten in hetzelfde venster"), wxDefaultPosition, wxDefaultSize, );
	$self->{cx_errorpopup} = Wx::CheckBox->new($self, -1, _T("Popup window voor foutboodschappen"), wxDefaultPosition, wxDefaultSize, );
	$self->{cx_warnpopup} = Wx::CheckBox->new($self, -1, _T("Popup window voor waarschuwingen"), wxDefaultPosition, wxDefaultSize, );
	$self->{cx_infopopup} = Wx::CheckBox->new($self, -1, _T("Popup window voor mededelingen"), wxDefaultPosition, wxDefaultSize, );
	$self->{l_histlines} = Wx::StaticText->new($self, -1, _T("Aantal te bewaren regels invoer historie:"), wxDefaultPosition, wxDefaultSize, );
	$self->{spin_histlines} = Wx::SpinCtrl->new($self, -1, "200", wxDefaultPosition, wxDefaultSize, wxSP_ARROW_KEYS, 0, 99999, 200);
	$self->{b_prefs_cancel} = Wx::Button->new($self, wxID_CANCEL, "");
	$self->{b_prefs_ok} = Wx::Button->new($self, wxID_OK, "");

	$self->__set_properties();
	$self->__do_layout();

	Wx::Event::EVT_BUTTON($self, $self->{b_prefs_cancel}->GetId, \&OnCancel);
	Wx::Event::EVT_BUTTON($self, $self->{b_prefs_ok}->GetId, \&OnAccept);

# end wxGlade
	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: EB::Wx::Shell::PreferencesDialog::__set_properties

	$self->SetTitle(_T("Voorkeursinstellingen"));
	$self->{cx_errorpopup}->SetValue(1);
	$self->{cx_warnpopup}->SetValue(1);
	$self->{cx_infopopup}->SetValue(1);
	$self->{b_prefs_ok}->SetDefault();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: EB::Wx::Shell::PreferencesDialog::__do_layout

	$self->{sz_prefs_outer} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_prefs_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sz_prefs_inner}= Wx::StaticBoxSizer->new($self->{sz_prefs_inner_staticbox}, wxVERTICAL);
	$self->{sz_prefs} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_histlines} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sz_prefs}->Add($self->{cx_repwin}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_prefs}->Add($self->{cx_errorpopup}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_prefs}->Add($self->{cx_warnpopup}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_prefs}->Add($self->{cx_infopopup}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_histlines}->Add($self->{l_histlines}, 0, wxRIGHT|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 5);
	$self->{sz_histlines}->Add($self->{spin_histlines}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
	$self->{sz_histlines}->Add(0, 0, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
	$self->{sz_prefs}->Add($self->{sz_histlines}, 1, wxEXPAND, 0);
	$self->{sz_prefs}->Add(1, 5, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_prefs_inner}->Add($self->{sz_prefs}, 1, wxLEFT|wxRIGHT|wxTOP|wxEXPAND, 5);
	$self->{sz_prefs_outer}->Add($self->{sz_prefs_inner}, 1, wxLEFT|wxRIGHT|wxTOP|wxEXPAND, 5);
	$self->{sz_prefs_buttons}->Add(5, 1, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
	$self->{sz_prefs_buttons}->Add($self->{b_prefs_cancel}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_prefs_buttons}->Add($self->{b_prefs_ok}, 0, wxLEFT|wxADJUST_MINSIZE, 5);
	$self->{sz_prefs_outer}->Add($self->{sz_prefs_buttons}, 0, wxALL|wxEXPAND, 5);
	$self->SetSizer($self->{sz_prefs_outer});
	$self->{sz_prefs_outer}->Fit($self);
	$self->Layout();

# end wxGlade
}

sub OnCancel {
	my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::PreferencesDialog::OnCancel <event_handler>
	$event->Skip;

# end wxGlade
}


sub OnAccept {
	my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::PreferencesDialog::OnAccept <event_handler>
	$event->Skip;

# end wxGlade
}


# end of class EB::Wx::Shell::PreferencesDialog

1;

