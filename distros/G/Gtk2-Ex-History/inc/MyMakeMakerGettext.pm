# MyMakeMakerGettext.pm -- my shared MakeMaker extras

# Copyright 2009, 2010 Kevin Ryde

# MyMakeMakerGettext.pm is shared by several distributions.
#
# MyMakeMakerGettext.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyMakeMakerGettext.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyMakeMakerGettext;
use strict;
use warnings;
use ExtUtils::Manifest;
use File::Basename;
use File::Spec;

# $makemaker is an ExtUtils::MakeMaker object, return a string of rules for
# the po/mo files
#
sub postamble {
  my ($makemaker) = @_;
  #   use Data::Dumper;
  #   print Dumper($makemaker);

  my $po_domain = ($makemaker->{'PO_DOMAIN'}
                   || '$(DISTNAME)');
  my $pot_copyright_holder = ($makemaker->{'POT_COPYRIGHT_HOLDER'}
                              || author_sans_email($makemaker));

  my @pot_inputs = grep {/\.pm$/} keys %{$makemaker->{'PM'}};
  my $pot_inputs = $makemaker->wraplist (@pot_inputs);

  my $manifest = ExtUtils::Manifest::maniread();
  my @manifest_files = keys %$manifest;
  my @po_files = grep {/\.po$/} @manifest_files;

  my @mo_files;
  foreach my $pofile (@po_files) {
    my $lang = File::Basename::basename ($pofile, '.po');
    my $mofile = "lib/LocaleData/$lang/LC_MESSAGES/\$(PO_DOMAIN).mo";
    push @mo_files, $mofile;
  }
  my $po_files = $makemaker->wraplist (@po_files);
  my $mo_files = $makemaker->wraplist (@mo_files);

  my $ret = <<"HERE";

#---------------------------------------------------------------------------
# message translation stuff -- from MyMakeMakerGettext

PO_DOMAIN = $po_domain
POT_COPYRIGHT_HOLDER = $pot_copyright_holder
POT_FILE = po/\$(PO_DOMAIN).pot
POT_INPUTS = $pot_inputs
PO_FILES = $po_files
MO_FILES = $mo_files

HERE
  $ret .= <<'HERE';

pot: $(POT_FILE)
po: pot $(PO_FILES)
mo: po $(MO_FILES)

# "--keyword" options needed for 0.17, maybe they'll be builtin in later
# gettext.
#
POT_TEMP_FILE = $(PO_DOMAIN)-messages.tmp
$(POT_FILE): po/header.pot $(POT_INPUTS)
	xgettext \
	  --omit-header \
	  --add-comments=TRANSLATORS: \
	  --width=78 \
	  --msgid-bugs-address='$(AUTHOR)' \
	  --copyright-holder='$(POT_COPYRIGHT_HOLDER)' \
	  --default-domain=$(PO_DOMAIN) \
	  --package-name=$(DISTNAME) \
	  --package-version='$(VERSION)' \
	  --output=$(POT_TEMP_FILE) \
	  --from-code=utf-8 \
	  --language=Perl \
	  --keyword=__ \
	  --keyword=__x \
	  --keyword=N__ \
	  --keyword=__nx:1,2 \
	  --keyword=__p:1c,2 \
	  --keyword=__px:1c,2 \
	  $(POT_INPUTS)
	cat po/header.pot $(POT_TEMP_FILE) >$(POT_FILE)
	rm $(POT_TEMP_FILE)

# Each po/XX.po is msgmerged from the .pot, and generates a .mo under
# LocaleData.
#
HERE

  foreach my $i (0 .. $#po_files) {
    my $pofile = $po_files[$i];
    my $mofile = $mo_files[$i];
    my $modir = File::Basename::dirname($mofile);

    $ret .= <<"HERE";
$pofile: \$(POT_FILE)
	msgmerge --verbose --update \$@ \$<
	touch \$@
$mofile: $pofile
	mkdir -p $modir
	msgfmt --check --statistics --verbose -o \$@ \$<
HERE
  }

  my $devnull = File::Spec->devnull;
  $ret .= <<"HERE";
# $devnull included in case \$(PO_FILES) is empty
check-fuzzy-po:
	if grep -n fuzzy $devnull \$(PO_FILES); then \\
	  echo "Fuzzy entries in po file(s)"; \\
	  exit 1; \\
	else \\
	  exit 0; \\
	fi
HERE

  return $ret;
}

sub author_sans_email {
  my ($makemaker) = @_;
  my $author = $makemaker->{'AUTHOR'};
  $author =~ s/\s*<.*>//;
  $author
}

# not used ...
#
# # cf String::ShellQuote
# sub shell_quote {
#   my ($str) = @_;
#   $str =~ s/[\\']/\\$1/;
#   return "'$str'";
# }

# this didn't work, or something ...
#
# sub MY::special_targets {
#   my $makemaker = shift;
#   my $inherited = $makemaker->SUPER::special_targets(@_);
#   $inherited =~ s/^\.SUFFIXES *:/$& .mo .po/
#     or die "Oops, couldn't add to .SUFFIXES";
# #   $inherited =~ s/^\.PHONY *:/$& mo pot/
# #     or die "Oops, couldn't add to .PHONY";
#   return $inherited;
# }

1;
__END__
