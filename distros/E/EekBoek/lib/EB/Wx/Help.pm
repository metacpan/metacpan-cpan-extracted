#! perl

package main;

our $cfg;

package EB::Wx::Help;

use strict;
use EB;

use Wx qw(wxHF_FLATTOOLBAR wxHF_TOOLBAR wxHF_CONTENTS wxHF_SEARCH wxHF_BOOKMARKS wxHF_INDEX wxHF_PRINT wxHF_DEFAULTSTYLE);
use Wx qw(wxACCEL_CTRL wxACCEL_NORMAL wxID_CLOSE);
use Wx::Event;
use Wx::Html;
use Wx::Help;
use Wx::FS;

# very important for HTB to work
Wx::FileSystem::AddHandler( new Wx::ZipFSHandler );

sub new {
    my $class = shift;
    my $self = Wx::HtmlHelpController->new
      ( wxHF_FLATTOOLBAR | wxHF_TOOLBAR
#	| wxHF_CONTENTS
#	| wxHF_INDEX
	| wxHF_CONTENTS
#	| wxHF_BOOKMARKS
	| wxHF_SEARCH
	| wxHF_PRINT
      );
    return bless \$self, $class;
}

sub show_html_help {
    my ($self) = @_;

    if ( my $htb_file = findlib( "docs.htb", "help" ) ) {
	$$self->AddBook( $htb_file, 1 );
	$$self->DisplayContents;
	if( my $hframe = Wx::Window::FindWindowByName('wxHtmlHelp')) {
	    $hframe->SetAcceleratorTable
	      (Wx::AcceleratorTable->new
	       ( [wxACCEL_CTRL, ord 'w', wxID_CLOSE],
		 [wxACCEL_NORMAL, 27, wxID_CLOSE],
	       ));
	}
    }
    else {
	::info( _T("No help available for this language"),
	        _T("Sorry") );
    }
}

package Wx::HtmlHelpFrame;

our @ISA = qw( Wx::Frame );

1;
