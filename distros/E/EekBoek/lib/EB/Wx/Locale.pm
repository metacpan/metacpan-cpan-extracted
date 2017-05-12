#! perl

# Locale.pm -- EB Locale setup (GUI version)
# Author          : Johan Vromans
# Created On      : Fri Sep 16 20:27:25 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Mar  8 14:07:23 2011
# Update Count    : 161
# Status          : Unknown, Use with caution!

package EB::Locale;

# IMPORTANT:
#
# This module is used (require-d) by module EB only.
# No other modules should try to play localisation tricks.
#
# Note: Only _T must be defined. The rest is defined in EB::Utils.

use strict;

use constant GUIPACKAGE  => "ebwxshell";
use constant COREPACKAGE => "ebcore";

use base qw(Exporter);

our @EXPORT_OK = qw(_T);
our @EXPORT = @EXPORT_OK;

use Wx qw(wxLANGUAGE_DEFAULT wxLOCALE_LOAD_DEFAULT);
use Wx::Locale gettext => '_T';

my $gui_localiser;
our $LOCALISER = "Wx::Locale";

unless ( $gui_localiser ) {
    $gui_localiser = Wx::Locale->new( wxLOCALE_LOAD_DEFAULT, wxLOCALE_LOAD_DEFAULT );
    __PACKAGE__->_set_language( wxLANGUAGE_DEFAULT );
}

sub get_language {
    $gui_localiser->GetCanonicalName;
}

sub _set_language {
    # Set/change language.
    my ($self, $lang) = @_;

    $gui_localiser->Init( $lang, wxLOCALE_LOAD_DEFAULT );

    # Since EB is use-ing Locale, we cannot use the EB exported libfile yet.
    $gui_localiser->AddCatalogLookupPathPrefix(EB::libfile("locale"));

    $gui_localiser->AddCatalog(GUIPACKAGE);
    $gui_localiser->AddCatalog(COREPACKAGE);
}

sub set_language {
    # Set/change language.
    my ($self, $lang) = @_;
    $lang =~ s/\..*//;		# strip .utf8

    my $info = Wx::Locale::FindLanguageInfo($lang);
    unless ( $info ) {
	# Universal error message.
	warn("%Ne povos sxangi la lingvon -- Neniu dateno por $lang\n");
	return;
    }

    $self->_set_language( $info->GetLanguage );
}

1;
