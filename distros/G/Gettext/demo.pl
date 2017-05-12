use strict;
use diagnostics;

use POSIX 'locale_h';
use locale;

use Gettext;

   setlocale(LC_CTYPE, 'es_ES');

   my $gt = new Gettext;

   $gt->bindtextdomain("messages", "/root/work");

   print $gt->gettext("flower"),"\n";
   print $gt->gettext("yellow"),"\n";

   print $gt->dgettext("messages", "flower"),"\n";
   print $gt->dgettext("messages", "yellow"),"\n";

   print $gt->dcgettext("messages", "flower", "fr_FR"),"\n";
   print $gt->dcgettext("messages", "yellow", "fr_FR"),"\n";

   print $gt->textdomain(),"\n";
   print $gt->textdomain(''),"\n";
