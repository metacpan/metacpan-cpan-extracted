#! perl

# Globals.pm -- 
# Author          : Johan Vromans
# Created On      : Thu Jul 14 12:54:08 200
# Last Modified By: Johan Vromans
# Last Modified On: Tue May 29 12:40:13 2012
# Update Count    : 104
# Status          : Unknown, Use with caution!

use utf8;

package EB::Globals;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT;

# Define new constant subroutine, and add it to @EXPORT.
sub _newconst($$) {
    my $t = $_[1];
    $t = "'$t'" unless $t =~ /^\d+$/ || $t =~ /^\[.*\]$/;
    #warn("sub $_[0](){$t}\n");
    eval("sub $_[0](){$t}");
    push(@EXPORT, $_[0]);
}

# Define an enumeration of constant subroutines.
sub _enumconst($@) {
    my ($pfx, @list) = @_;
    my $index = 0;
    foreach ( @list ) {
	my $key = $pfx.$_;
	if ( $key =~ /^(.*)=(\d+)$/ ) {
	    $key = $1;
	    $index = $2;
	}
	_newconst( $key, $index++ );
    }
}

# To defeat gettext. Strings here are not for translation.
sub N__($) { $_[0] }

_newconst("SCM_MAJVERSION",  1);
_newconst("SCM_MINVERSION",  0);
_newconst("SCM_REVISION",   16);

_newconst("AMTPRECISION",    2);
_newconst("AMTWIDTH",        9);
_newconst("NUMGROUPS",       3);
_newconst("BTWPRECISION",    4);
_newconst("BTWWIDTH",        5);
_newconst("AMTSCALE",      100);
_newconst("BTWSCALE",    10000);

_newconst("BKY_PREVIOUS", "<<<<");

_enumconst("DBKTYPE_", qw(INKOOP=1 VERKOOP BANK KAS MEMORIAAL) );
_newconst("DBKTYPES",
	  "[qw(".N__("-- Inkoop Verkoop Bank Kas Memoriaal").")]");

_enumconst("BTWTARIEF_", qw(NUL=0 HOOG LAAG PRIV ANDERS) );
_newconst("BTWTARIEVEN", "[qw(".N__("Nul Hoog Laag Privé Anders").")]");
_newconst("BTWPERIODES", "[qw(".N__("Geen Jaar 2 3 Kwartaal 5 6 7 8 9 10 11 Maand").")]");
_newconst("BTWPER_GEEN", 0);
_newconst("BTWPER_JAAR", 1);
_newconst("BTWPER_KWARTAAL", 4);
_newconst("BTWPER_MAAND", 12);
_enumconst("BTWTYPE_", qw(NORMAAL=0 VERLEGD INTRA EXTRA) );
_newconst("BTWTYPES", "[qw(".N__("Normaal Verlegd Intra Extra").")]");
_newconst("BTWKLASSE_BTW_BIT",   0x200);
_newconst("BTWKLASSE_KO_BIT",    0x100);
_newconst("BTWKLASSE_TYPE_BITS", 0x0ff);

# Starting value for automatically defined BTW codes.
_newconst("BTW_CODE_AUTO", 1024);

# Eval, since it uses the (run-time defined) subroutines.
eval( 'sub BTWKLASSE($$$) {'.
      ' ($_[0] ? BTWKLASSE_BTW_BIT : 0)'.
      ' | ($_[1] ? ($_[1] & BTWKLASSE_TYPE_BITS) : 0)'.
      ' | ($_[2] ? BTWKLASSE_KO_BIT : 0);'.
      '}' );
push(@EXPORT, qw(BTWKLASSE));

unless ( caller ) {
    print STDOUT ("-- Constants\n\n",
		  "COMMENT ON TABLE Constants IS\n",
		  "  'This is generated from ", __PACKAGE__, ". DO NOT CHANGE.';\n\n",
		  "COPY Constants (name, value) FROM stdin;\n");

    foreach my $key ( sort(@EXPORT) ) {
	no strict;
	next if ref($key->());
	print STDOUT ("$key\t", $key->(), "\n");
    }
    print STDOUT ("\\.\n");
}

1;
