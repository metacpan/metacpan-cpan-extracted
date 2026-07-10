package #
Locale::VersionedMessages::lm;
# Copyright (c) 2010-2015 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################
require 5.008;
use IO::File;

use strict;
use integer;
use warnings;

use IO::File;
use File::Path qw(make_path);

our $VERSION;
$VERSION='0.96';

###############################################################################

# Create the message set module.
#
sub _set_create {
   my($set,$dir,$def_locale) = @_;

   my $d = "$dir/Locale/VersionedMessages/Sets";
   my $f = "$d/$set.pm";

   if (-f $f) {
      die "ERROR: message set already exists\n";
   }

   make_path($d)  if (! -d $d);

   _set_write($set,$dir,{},$def_locale);
}

# Load the message set module.
#
no strict 'refs';
sub _set_read {
   my($set,$dir) = @_;

   my $m   = "Locale::VersionedMessages::Sets::$set";
   my $d   = "Locale/VersionedMessages/Sets";
   my $f   = "$d/$set.pm";
   delete $INC{$f};

   $d      = "$dir/$d";
   $f      = "$dir/$f";

   if (! -f $f) {
      die "ERROR: message set module does not exist: $f\n";
   }

   eval "use lib '$dir'; require $m";
   if ($@) {
      die "ERROR: failed to load message set module [$m]: $@\n";
   }

   my $def_locale = ${ "${m}::DefaultLocale" };
   my @alllocale = @{ "${m}::AllLocale" };
   my %messages  = %{ "${m}::Messages" };

   if (! @alllocale  ||  $alllocale[0] ne $def_locale) {
      die "ERROR: locales not specified correctly in set module: $m\n";
   }

   return (\%messages,@alllocale);
}
use strict 'refs';

# Write the message set module.
#
no strict 'refs';
sub _set_write {
   my($set,$dir,$messages,$def_locale,@oth_locale) = @_;

   my $m   = "Locale::VersionedMessages::Sets::$set";
   my $d   = "$dir/Locale/VersionedMessages/Sets";
   my $f   = "$d/$set.pm";

   my $c0  = ${ "${m}::CopyrightBeg" };
   my $c1  = ${ "${m}::CopyrightEnd" };
   if (! $c0) {
      $c0  = ( localtime(time) )[5] + 1900;
   }
   $c1     = ( localtime(time) )[5] + 1900;

   my $out = new IO::File;

   if (! $out->open("> $f")) {
      die "ERROR: unable to write set file: $f: $!\n";
   }

   my $pod  = "pod";   # So I can avoid indexing this as a pod
   my $head = "head1";
   my $over = "over 4";
   my $back = "back";
   my $cut  = "cut";

   print $out
"package Locale::VersionedMessages::Sets::${set};
####################################################
#        *** WARNING WARNING WARNING ***
#
# This file was generated, and is intended to be
# maintained automatically using the Locale::VersionedMessages
# tools.
#
# Any changes to this file may be lost the next
# time these commands are run.
####################################################
# Copyright $c0-$c1

use strict;
use warnings;

our \$CopyrightBeg = $c0;
our \$CopyrightEnd = $c1;

our(\$DefaultLocale,\@AllLocale,\%Messages);

\$DefaultLocale = '$def_locale';
\@AllLocale     = (qw($def_locale @oth_locale));

\%Messages = (
";

   foreach my $msgid (sort keys %$messages) {
      print $out "   '$msgid' => {\n";

      if (exists $$messages{$msgid}{'desc'}) {
         my $desc = $$messages{$msgid}{'desc'};
         while (chomp($desc)) {};
         $$messages{$msgid}{'desc'} = $desc;
         $desc    =~ s,',\\',g;
         print $out "      'desc'  => '$desc',\n",
      }

      if (exists $$messages{$msgid}{'vals'}) {
         my @vals = @{ $$messages{$msgid}{'vals'} };
         my $vals = "['" . join("','",@vals) . "']";
         print $out "      'vals'  => $vals,\n";
      }

      print $out "   },\n";
   }

   print $out ");

1;

=$pod

=encoding utf-8

=$head NAME

Locale::VersionedMessages::Sets::$set -- Description of the $set message set

=$head DESCRIPTION

This module is not intended for public use. It is used internally by
Locale::VersionedMessages to store the description of a set of messages that
will be localized for some application.

This message set has been translated into the following locales:

   $def_locale (Default locale)
";

   foreach my $locale (@oth_locale) {
      print $out "   $locale\n";
   }

   print $out "
=$head MESSAGE IDS

The following message IDs are available in this message set:

=$over

";

   foreach my $msgid (sort keys %$messages) {
      print $out "=item B<'$msgid'>\n\n";

      if (exists $$messages{$msgid}{'vals'}) {
         my @vals = @{ $$messages{$msgid}{'vals'} };
         my $vals = join(' ',@vals);
         print $out "Substitution values: $vals\n\n";
      }

      if (exists $$messages{$msgid}{'desc'}) {
         my $desc = $$messages{$msgid}{'desc'};
         print $out "$desc\n";
      }
      print $out "\n";
   }

   print $out "
=$back

=$cut
";

   $out->close();
}
use strict 'refs';

###############################################################################

# Create a lexicon module.
#
sub _lexicon_create {
   my($set,$dir,$locale) = @_;

   #
   # Create the new lexicon module.
   #

   my $d = "$dir/Locale/VersionedMessages/Sets/$set";
   my $f = "$d/$locale.pm";

   if (-f $f) {
      die "ERROR: message lexicon already exists\n";
   }

   make_path($d)  if (! -d $d);

   _lexicon_write($set,$dir,$locale,{});
}

# Load a lexicon module.
#
no strict 'refs';
sub _lexicon_read {
   my($set,$dir,$locale) = @_;

   my $m = "Locale::VersionedMessages::Sets::${set}::${locale}";
   my $d = "Locale/VersionedMessages/Sets/$set";
   my $f = "$d/$locale.pm";
   delete $INC{$f};

   $d      = "$dir/$d";
   $f      = "$dir/$f";

   if (! -f $f) {
      die "ERROR: lexicon module does not exist: $f\n";
   }

   eval "use lib '$dir'; require $m";
   if ($@) {
      die "ERROR: failed to load lexicon module [$m]: $@\n";
   }

   my %messages  = %{ "${m}::Messages" };

   return \%messages;
}
use strict 'refs';

# Write a lexicon module.
#
no strict 'refs';
sub _lexicon_write {
   my($set,$dir,$locale,$messages) = @_;

   my $m = "Locale::VersionedMessages::Sets::${set}::${locale}";
   my $d = "$dir/Locale/VersionedMessages/Sets/$set";
   my $f = "$d/$locale.pm";

   my $c0  = ${ "${m}::CopyrightBeg" };
   my $c1  = ${ "${m}::CopyrightEnd" };
   if (! $c0) {
      $c0  = ( localtime(time) )[5] + 1900;
   }
   $c1     = ( localtime(time) )[5] + 1900;

   my $out = new IO::File;

   if (! $out->open("> $f")) {
      die "ERROR: unable to write lexicon: $f: $!\n";
   }

   print $out "package #
Locale::VersionedMessages::Sets::${set}::${locale};
####################################################
#        *** WARNING WARNING WARNING ***
#
# This file was generated, and is intended to be
# maintained automatically using the Locale::VersionedMessages
# tools.
#
# Any changes to this file may be lost the next
# time these commands are run.
####################################################
# Copyright $c0-$c1

use strict;
use warnings;

our \$CopyrightBeg = $c0;
our \$CopyrightEnd = $c1;

our(\%Messages);

\%Messages = (
";

   foreach my $msgid (sort keys %$messages) {
      print $out "   '$msgid' => {\n";

      if (exists $$messages{$msgid}{'vers'}) {
         my $vers = $$messages{$msgid}{'vers'};
         print $out "      'vers'  => $vers,\n";
      } else {
         print $out "      'vers'  => 0,\n";
      }

      if (exists $$messages{$msgid}{'text'}) {
         my $text = $$messages{$msgid}{'text'};
         while (chomp($text)) {};
         $$messages{$msgid}{'text'} = $text;
         $text    =~ s,',\\',g;
         print $out "      'text'  => '$text',\n",
      }

      print $out "   },\n";
   }

   print $out ");

1;
";

   $out->close();
}
use strict 'refs';

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
