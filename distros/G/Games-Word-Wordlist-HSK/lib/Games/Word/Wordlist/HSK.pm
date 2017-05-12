package Games::Word::Wordlist::HSK;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Games::Word::Wordlist);
use WordList::ZH::HSK;

sub new {
    bless Games::Word::Wordlist->new ([WordList::ZH::HSK->new->all_words]), shift;
}

1;

# ABSTRACT: HSK words (bridge to WordList::ZH::HSK)

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Word::Wordlist::HSK - HSK words (bridge to WordList::ZH::HSK)

=head1 VERSION

This document describes version 0.01 of Games::Word::Wordlist::HSK (from Perl distribution Games-Word-Wordlist-HSK), released on 2016-02-04.

=head1 SYNOPSIS

  use Games::Word::Wordlist::HSK;
  my $wl = Games::Word::Wordlist::HSK->new;
  my $word = $wl->random_word;
  print "We have a word." if $wl->is_word ($word);

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-Word-Wordlist-HSK>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Games-Word-Wordlist-HSK>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Word-Wordlist-HSK>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList::ZH::HSK> (which also comes with per-level word lists as well as
character lists).

L<Games::Word::Wordlist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
