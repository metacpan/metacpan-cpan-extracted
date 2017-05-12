#############################################################################
## Name:        Lingua::MSWordSpell
## Purpose:     Spell-check using MS Word
## Author:      Simon Flack
## Modified by: $Author: mattheww $ on $Date: 2006/05/18 10:54:19 $
## Created:     21/03/2003
## RCS-ID:      $Id: MSWordSpell.pm,v 1.11 2006/05/18 10:54:19 mattheww Exp $
#############################################################################
package Lingua::MSWordSpell;

use strict;
use Win32::OLE qw(in);
use Carp;
use vars '$VERSION';

$VERSION = sprintf"%d.%03d", q$Revision: 1.11 $ =~ /: (\d+)\.(\d+)/;

sub new {
    my $class = shift;
    my $word = Win32::OLE->GetActiveObject('Word.Application')
            || new Win32::OLE('Word.Application', sub {$_[0]->Quit});
    $word->{Visible} = 0;

    carp (q[Couldn't launch Microsoft Word]) unless $word;
    carp (q[Microsoft Word 9 or higher is required])
            unless $word->{Version} && $word->{Version} >= 9;
    bless { _msword => $word, _temp_doc => $word->WordBasic()->FileNew() },
            $class;
}


sub spellcheck {
    my $self = shift;
    my $text = shift;

    my $msword = $self -> {_msword};
    my @errors;
    while ($text =~ m/(\S+)\b/g) {
        my $offset = pos($text) - length($1) + 1;
        my $term = { term => $1, offset => $offset };

        # If is correctly spelled proceed to the next word
        next if $msword->CheckSpelling($term -> {term});

        # Otherwise look for spelling suggestions
        my $suggestions = $msword->GetSpellingSuggestions($term -> {term});

        # No suggestions:
        if (!$suggestions || !$suggestions -> {Count}) {
            $term -> {type} = 'none';
            $term -> {guesses} = [];
            push @errors, $term;

        # Some suggestions:
        } else {
            my @suggest;
            foreach (in $suggestions) {
                push @suggest, $_->{Name};
            }
            $term -> {type} = 'guess';
            $term -> {guesses} = \@suggest;
            push @errors, $term;
        }
    }
    return @errors;
}


1;


=pod

=head1 NAME

Lingua::MSWordSpell - Word spellchecker

=head1 SYNOPSIS

    use Lingua::MSWordSpell;
    my $spchecker = new Lingua::MSWordSpell;

    my @errors = $spchecker->spellcheck($text);

=head1 DESCRIPTION

This is a rough and ready replacement for Lingua::Ispell that uses Microsoft
Word's Spellchecker over OLE automation. It requires Microsoft Word 9 or
higher.

=head1 METHODS

=over 4

=item spellcheck($text)

This method uses the Microsoft Word spellchecker to check each word in the
supplied C<$text> string. It will return a hash reference for each misspelled
word:

    term       # The mis-spelled word
    offset     # The offset of the first character of 'term' from the start of
               # the string, where the first char is at offset '1'
    guesses    # List of alternative spelling suggestions

If there are no misspelled words in the string, C<spellcheck()> will return an
empty list.

=back

=head1 AUTHOR

Simon Flack <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 SEE ALSO

=head2 B<Interfaces to online spelling services (google):>

=over 4

=item L<Net::Google::Spelling>

=item L<WebService::GoogleHack::Spelling>

=back

=head2 B<Interfaces to local spell checking binaries and libraries (aspell, pspell, ispell):>

=over 4

=item L<Lingua::Ispell>

=item L<Text::Pspell>

=item L<Text::Aspell>

=item L<Text::SpellCheck>

=back

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or
modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

'Microsoft Word' and 'Microsoft' are trademarks owned by Microsoft (L<http://microsoft.com/>)

=cut
