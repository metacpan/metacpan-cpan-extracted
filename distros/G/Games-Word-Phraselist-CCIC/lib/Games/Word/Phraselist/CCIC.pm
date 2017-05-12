package Games::Word::Phraselist::CCIC;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Games::Word::Phraselist);
use WordList::Phrase::ZH::CCIC;
sub new {
    bless Games::Word::Phraselist->new ([WordList::Phrase::ZH::CCIC->new->all_words]), shift;
}

1;

# ABSTRACT: Mainland Mandarin vocabulary from CCIC (bridge to WordList::Phrase::ZH::CCIC)

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Word::Phraselist::CCIC - Mainland Mandarin vocabulary from CCIC (bridge to WordList::Phrase::ZH::CCIC)

=head1 VERSION

This document describes version 0.01 of Games::Word::Phraselist::CCIC (from Perl distribution Games-Word-Phraselist-CCIC), released on 2016-02-04.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-Word-Phraselist-CCIC>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Games-Word-Phraselist-CCIC>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Word-Phraselist-CCIC>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList::Phrase::ZH::CCIC>

L<Games::Word::Phraselist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
