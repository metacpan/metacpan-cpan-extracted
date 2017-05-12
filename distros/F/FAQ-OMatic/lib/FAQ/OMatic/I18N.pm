##############################################################################
# The Faq-O-Matic is Copyright 1997 by Jon Howell, all rights reserved.      #
#                                                                            #
# This program is free software; you can redistribute it and/or              #
# modify it under the terms of the GNU General Public License                #
# as published by the Free Software Foundation; either version 2             #
# of the License, or (at your option) any later version.                     #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.#
#                                                                            #
# Jon Howell can be contacted at:                                            #
# 6211 Sudikoff Lab, Dartmouth College                                       #
# Hanover, NH  03755-3510                                                    #
# jonh@cs.dartmouth.edu                                                      #
#                                                                            #
# An electronic copy of the GPL is available at:                             #
# http://www.gnu.org/copyleft/gpl.html                                       #
#                                                                            #
##############################################################################

use strict;

###
### I18N.pm
###
### Internationalization support routines
###
# huge THANKS: to Dirk Hansen and Okke Timm, who did the first translation
# (to German), which involved weaving gettext() calls all over the code.

package FAQ::OMatic::I18N;
#use Locale::PGetText;

use FAQ::OMatic;

BEGIN {
    use Exporter   ();
    use vars       qw(@ISA @EXPORT);
    @ISA         = qw(Exporter);

    @EXPORT      = qw(&gettext &gettexta &gettext_noop);
}

sub new {
	my $class = shift;
	my $force = shift;

	my $tx = FAQ::OMatic::getLocal('i18n');
	if ($force or not defined $tx) {
		$tx = {};
		bless $tx;
		$tx->load();
		FAQ::OMatic::setLocal('i18n', $tx);
	}
	return $tx;
}

sub reload {
	# force next gettext() to reload
	my $tx = new FAQ::OMatic::I18N('force');
}

sub language {
	return $FAQ::OMatic::Config::language || 'en';
}

sub load {
	my $self = shift;
	if ($self->language() ne 'en') {
		my $kit = "FAQ/OMatic/Language_".$self->language().".pm";
		eval {
			require $kit;
		};
		translations($self);
	}
}

sub gettext {
	my $text = shift;
	my $tx = new FAQ::OMatic::I18N();
	my $translated = $tx->{$text} || $text;
	if (language() ne 'en'
		and not exists $tx->{$text}) {
		FAQ::OMatic::gripe('debug', "No \""
			.$tx->language()."\" translation for \"$text\"");
	}
	return $translated;
}

sub gettexta {
	# a slower version that plugs in arguments.
	# (if perl were partially evaluated, we'd only have this
	# sub, and gettext would be the curried version. :v)

	my $text = shift;
	if (not defined($text)) {$text = ''};
	my $translated = gettext($text);
	if (not defined($translated)) {$translated = ''};

	my $arg;
	my $i=0;
	$translated =~ s/\%(\d+)/defined($_[$1])?$_[$1]:('%'.$1)/sge;
	return $translated;
}

sub gettext_noop
{
	return $_[0];
}

1;
