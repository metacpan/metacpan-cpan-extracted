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


my $script = <<'END_OF_SCRIPT';
~startperl~
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

use HTML::EP ();
use HTML::EP::Config ();


$SIG{'__WARN__'} = \&HTML::EP::WarnHandler;
my $self = HTML::EP->new();
$ENV{'PATH_TRANSLATED'} = shift @ARGV if @ARGV; # For IIS
my $path = $ENV{'PATH_TRANSLATED'};
if ($path =~ /(.*)[\/\\]/) {
    chdir $1;
}
$self->CgiRun($path);

exit 0;
END_OF_SCRIPT

require Config;
$script =~ s/\~startperl\~/$Config::Config{startperl}/e;
if (!open(FILE, ">ep.cgi")  ||  !print FILE ($script)  ||  !close(FILE)) {
    die "Error while creating 'ep.cgi': $!";
}
