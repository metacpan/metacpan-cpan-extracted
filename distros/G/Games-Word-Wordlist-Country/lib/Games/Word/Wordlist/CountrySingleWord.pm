package Games::Word::Wordlist::CountrySingleWord;

our $DATE = '2016-01-13'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Games::Word::Wordlist);
use WordList::EN::CountryNames::SingleWord;

sub new {
    bless Games::Word::Wordlist->new ([WordList::EN::CountryNames::SingleWord->new->all_words]), shift;
}

1;

# ABSTRACT: English names of countries of the world (single words only)



__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Word::Wordlist::CountrySingleWord - English names of countries of the world (single words only)

=head1 VERSION

This document describes version 0.04 of Games::Word::Wordlist::CountrySingleWord (from Perl distribution Games-Word-Wordlist-Country), released on 2016-01-13.

=head1 SYNOPSIS

=head2 SEE ALSO

See L<Games::Word::Wordlist::Country>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-Word-Wordlist-Country>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Games-Word-Wordlist-Country>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Word-Wordlist-Country>

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

