#! perl

package main;

package EB::Wx::Shell::HtmlViewer;

use base qw(Wx::Dialog);
use base qw(EB::Wx::Shell::Window);
use strict;

# begin wxGlade: ::dependencies
use Wx::Locale gettext => '_T';
# end wxGlade

use Wx::Html;

use Wx qw[
          wxADJUST_MINSIZE
          wxALL
          wxDEFAULT_DIALOG_STYLE
          wxDefaultPosition
          wxDefaultSize
          wxEXPAND
          wxHORIZONTAL
          wxID_CLOSE
          wxID_OK
          wxID_PRINT
          wxID_SAVE
          wxLEFT
          wxMAXIMIZE_BOX
          wxMINIMIZE_BOX
          wxFD_OVERWRITE_PROMPT
          wxRESIZE_BORDER
          wxFD_SAVE
          wxTHICK_FRAME
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

# begin wxGlade: EB::Wx::Shell::HtmlViewer::new

	$style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER|wxMAXIMIZE_BOX|wxMINIMIZE_BOX|wxTHICK_FRAME 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{b_print} = Wx::Button->new($self, wxID_PRINT, "");
	$self->{b_save} = Wx::Button->new($self, wxID_SAVE, "");
	$self->{p_close} = Wx::Button->new($self, wxID_CLOSE, "");
	$self->{p_htmlview} = Wx::HtmlWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, );

	$self->__set_properties();
	$self->__do_layout();

	Wx::Event::EVT_BUTTON($self, $self->{b_print}->GetId, \&OnPrint);
	Wx::Event::EVT_BUTTON($self, $self->{b_save}->GetId, \&OnSave);
	Wx::Event::EVT_BUTTON($self, $self->{p_close}->GetId, \&OnClose);

# end wxGlade

	Wx::Event::EVT_HTML_LINK_CLICKED($self->{p_htmlview}, $self->{p_htmlview}->GetId, \&OnLinkClicked);

	$self->{_PRINTER} =  Wx::HtmlEasyPrinting->new('Print');

	$self->sizepos_restore(lc($title));

	return $self;

}

sub info_only {
    my ( $self ) = @_;
    $self->{b_print}->Hide;
    $self->{b_save}->Hide;
}

sub html     { $_[0]->{p_htmlview}  }
sub htmltext :lvalue { $_[0]->{_HTMLTEXT} }
sub printer  { $_[0]->{_PRINTER}  }

sub __set_properties {
	my $self = shift;

# begin wxGlade: EB::Wx::Shell::HtmlViewer::__set_properties

	$self->SetTitle(_T("HTML Uitvoer"));
	$self->SetSize(Wx::Size->new(618, 522));
	$self->{p_close}->SetFocus();
	$self->{p_close}->SetDefault();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: EB::Wx::Shell::HtmlViewer::__do_layout

	$self->{sz_htmlview} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_htmlviewbuttons} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sz_htmlviewbuttons}->Add($self->{b_print}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_htmlviewbuttons}->Add($self->{b_save}, 0, wxLEFT|wxADJUST_MINSIZE, 5);
	$self->{sz_htmlviewbuttons}->Add(5, 1, 1, wxADJUST_MINSIZE, 0);
	$self->{sz_htmlviewbuttons}->Add($self->{p_close}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_htmlview}->Add($self->{sz_htmlviewbuttons}, 0, wxALL|wxEXPAND, 5);
	$self->{sz_htmlview}->Add($self->{p_htmlview}, 1, wxEXPAND, 0);
	$self->SetSizer($self->{sz_htmlview});
	$self->Layout();

# end wxGlade
}

sub OnPrint {
    my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::HtmlViewer::OnPrint <event_handler>
    $self->printer->SetFooter(' - @PAGENUM@ - ');
    $self->printer->PrintText($self->htmltext);
# end wxGlade
}


sub OnSave {
    my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::HtmlViewer::OnSave <event_handler>
    my $d = Wx::FileDialog->new($self, _T("Opslaan als..."),
				"", _T("raport.html"),
				_T("HTML bestanden (*.html)|*.html"),
				wxFD_SAVE | wxFD_OVERWRITE_PROMPT);
    my $result = $d->ShowModal;
    if ( $result == wxID_OK ) {
	my $file = $d->GetPath;
	open(my $fd, ">", $file);
	print { $fd } $self->htmltext;
	close($fd);
    }
# end wxGlade
}


sub OnClose {
    my ($self, $event) = @_;
# wxGlade: EB::Wx::Shell::HtmlViewer::OnClose <event_handler>
    $self->sizepos_save;
    $self->Show(0);
# end wxGlade
}

sub OnLinkClicked {
    my ($self, $event) = @_;

    my $link = $event->GetLinkInfo->GetHref;

    if ( $link =~ m;^([^:]+)://(.+)$;
	 && (my $rep = EB::Wx::Shell::MainFrame->can("ShowR" . ucfirst(lc($1)))) ) {
	my @a = split(/[?&]/, $2);
	my $args = { select => shift(@a) };
	foreach ( @a ) {
	    if ( /^([^=]+)=(.*)/ ) {
		$args->{$1} = $2;
	    }
	    else {
		$args->{$_} = 1;
	    }
	}
	$rep->($self->GetParent->GetParent, $args);
    }
    elsif ( $link =~ m;^(https?|mailto):; ) {
	Wx::LaunchDefaultBrowser($link);
    }
    else {
	Wx::LogMessage('Link: "%s"', $1);
    }
}

# end of class EB::Wx::Shell::HtmlViewer

1;

