# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;


use Apache ();
use DBI ();
use HTML::EP ();
use Symbol ();

# Pull in HTML::EP and the helper packages
use HTML::EP ();
use HTML::EP::Locale ();
use HTML::EP::Session ();


package Apache::EP;

$Apache::EP::VERSION = '0.1003';

my $Is_Win32 = $^O eq "MSWin32";


sub handler ($$) {
    my($class, $r) = @_;
    if(ref $r) {
	$r->request($r);
    } else {
	$r = Apache->request;
    }
    my $filename = $r->filename;
    local $^W;

    if (($r->allow_options() & Apache::Constants::OPT_EXECCGI())  ==  0) {
	$r->log_reason("Options ExecCGI is off in this directory",
		       $filename);
	return Apache::Constants::FORBIDDEN();
    }
    if (!-r $filename  ||  !-s _) {
	$r->log_reason("File not found", $filename);
	return Apache::Constants::NOT_FOUND();
    }
    if (-d _) {
	$r->log_reason("attempt to invoke directory as script", $filename);
	return Apache::Constants::FORBIDDEN();
    }

    $r->chdir_file($filename);
    $r->cgi_env('PATH_TRANSLATED' => $filename);
    local $SIG{'__WARN__'} = \&HTML::EP::WarnHandler;
    my $self = HTML::EP->new();
    $self->{'_ep_r'} = $r;
    $r->no_cache(1);
    $self->CgiRun($filename, $r);
    return Apache::Constants::OK();
}


1;
