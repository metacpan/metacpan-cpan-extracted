# Copyrights 2007-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Translator::Gettext;
use vars '$VERSION';
$VERSION = '1.10';

use base 'Log::Report::Translator';

use warnings;
use strict;

use Log::Report 'log-report-lexicon';

use Locale::gettext;


sub translate($;$$)
{   my ($msg, $lang, $ctxt) = @_;

#XXX MO: how to use $lang when specified?
    my $domain = $msg->{_textdomain};
    load_domain $domain;

    my $count  = $msg->{_count};

    defined $count
    ? ( defined $msg->{_category}
      ? dcngettext($domain, $msg->{_msgid}, $msg->{_plural}, $count
                  , $msg->{_category})
      : dngettext($domain, $msg->{_msgid}, $msg->{_plural}, $count)
      )
    : ( defined $msg->{_category}
      ? dcgettext($domain, $msg->{_msgid}, $msg->{_category})
      : dgettext($domain, $msg->{_msgid})
      );
}

1;
