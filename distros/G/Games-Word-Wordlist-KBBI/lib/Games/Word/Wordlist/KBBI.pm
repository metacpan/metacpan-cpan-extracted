package Games::Word::Wordlist::KBBI;

our $DATE = '2016-01-13'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Games::Word::Wordlist);
use WordList::ID::KBBI;

sub new {
    bless Games::Word::Wordlist->new ([WordList::ID::KBBI->new->all_words]), shift;
}

1;

# ABSTRACT: Wordlist from Kamus Besar Bahasa Indonesia (Indonesian)



__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Word::Wordlist::KBBI - Wordlist from Kamus Besar Bahasa Indonesia (Indonesian)

=head1 VERSION

This document describes version 0.03 of Games::Word::Wordlist::KBBI (from Perl distribution Games-Word-Wordlist-KBBI), released on 2016-01-13.

=head1 SYNOPSIS

  use Games::Word::Wordlist::KBBI;
  my $wl = Games::Word::Wordlist::KBBI->new;
  my $word = $wl->random_word;
  print "We have a word." if $wl->is_word ($word);

=head1 DESCRIPTION

=head1 SEE ALSO

L<< Games::Word::Wordlist >>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-Word-Wordlist-KBBI>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Games-Word-Wordlist-KBBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Word-Wordlist-KBBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

