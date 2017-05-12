# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Translator::POT;
use vars '$VERSION';
$VERSION = '1.06';

use base 'Log::Report::Translator';

use Log::Report 'log-report-lexicon';

use Log::Report::Lexicon::Index;
use Log::Report::Lexicon::POTcompact;

use POSIX qw/:locale_h/;

my %indices;

# Work-around for missing LC_MESSAGES on old Perls and Windows
{ no warnings;
  eval "&LC_MESSAGES";
  *LC_MESSAGES = sub(){5} if $@;
}


sub translate($;$$)
{   my ($self, $msg, $lang, $ctxt) = @_;

    my $domain = $msg->{_domain};
    my $locale = $lang || setlocale(LC_MESSAGES)
        or return $self->SUPER::translate($msg, $lang, $ctxt);

    my $pot
      = exists $self->{pots}{$domain}{$locale}
      ? $self->{pots}{$domain}{$locale}
      : $self->load($domain, $locale);

       ($pot ? $pot->msgstr($msg->{_msgid}, $msg->{_count}, $ctxt) : undef)
    || $self->SUPER::translate($msg, $lang, $ctxt);
}

sub load($$)
{   my ($self, $domain, $locale) = @_;

    foreach my $lex ($self->lexicons)
    {   my $fn = $lex->find($domain, $locale);

        !$fn && $lex->list($domain)
            and last; # there are tables for domain, but not our lang

        $fn or next;

        my ($ext) = lc($fn) =~ m/\.(\w+)$/;
        my $class
          = $ext eq 'mo' ? 'Log::Report::Lexicon::MOTcompact'
          : $ext eq 'po' ? 'Log::Report::Lexicon::POTcompact'
          : error __x"unknown translation table extension '{ext}' in {filename}"
              , ext => $ext, filename => $fn;

        info __x"read table {filename} as {class} for {domain} in {locale}"
          , filename => $fn, class => $class, domain => $domain
          , locale => $locale
              if $domain ne 'log-report';  # avoid recursion

        eval "require $class" or panic $@;
 
        return $self->{pots}{$domain}{$locale}
          = $class->read($fn, charset => $self->charset);
    }

    $self->{pots}{$domain}{$locale} = undef;
}

1;
