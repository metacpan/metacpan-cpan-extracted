package Games::Word::Phraselist::Proverb::ChineseTools;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Games::Word::Phraselist);
use WordList::Phrase::ZH::Proverb::ChineseTools;
sub new {
    bless Games::Word::Phraselist->new ([WordList::Phrase::ZH::Proverb::ChineseTools->new->all_words]), shift;
}

1;

# ABSTRACT: Chinese idioms (chengyu) from chinese-tools.com (bridge to WordList::Phrase::ZH::Proverb::ChineseTools)

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Word::Phraselist::Proverb::ChineseTools - Chinese idioms (chengyu) from chinese-tools.com (bridge to WordList::Phrase::ZH::Proverb::ChineseTools)

=head1 VERSION

This document describes version 0.01 of Games::Word::Phraselist::Proverb::ChineseTools (from Perl distribution Games-Word-Phraselist-Proverb-ChineseTools), released on 2016-02-04.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-Word-Phraselist-Proverb-ChineseTools>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Games-Word-Phraselist-Proverb-ChineseTools>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Word-Phraselist-Proverb-ChineseTools>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList::Phrase::ZH::Proverb::ChineseTools>

L<Games::Word::Phraselist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
