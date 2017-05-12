#!/usr/local/bin/perl -w
# $Id: mswordspell.t,v 1.3 2005/03/11 11:54:55 simonf Exp $
use strict;
require Test::More;
use Getopt::Std;

getopts('tT', \my %opt);
if ($opt{t} || $opt{T}) {
    require Log::Trace;
    import Log::Trace 'print' if $opt{t};
    import Log::Trace 'print' => {Deep => 1} if $opt{T};
}

# Check the platform
import Test::More skip_all => 'Lingua::MSWordSpell requires Win32'
    unless $^O eq 'MSWin32';

# Check whether MS Word is installed
require Win32::OLE;
my $word_app = Win32::OLE->new('Word.Application', sub {$_[0]->Quit});
my $ok_word = $word_app && $word_app->{Version} >= 9;
import Test::More skip_all => 'Microsoft Word 9+ is not available'
    unless $ok_word;

# Proceed with unit tests
import Test::More tests => 5;
require_ok('Lingua::MSWordSpell');
ok($ok_word, 'Word is installed');

my $spell = Lingua::MSWordSpell->new();
my (@bad) = $spell->spellcheck('xxxyyyzzz Microsoft aaabbbccc');
ok(@bad == 2, 'found 2 misspelled words');
DUMP(\@bad);
ok(
  $bad[0]->{offset} == 1 && $bad[0]->{term} eq 'xxxyyyzzz',
  'found first misspelled word'
);
ok(
  $bad[1]->{offset} == 21 && $bad[1]->{term} eq 'aaabbbccc',
  'found second misspelled word'
);

sub TRACE {}
sub DUMP  {}
