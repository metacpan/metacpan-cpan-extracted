#!/usr/bin/env perl
#PODNAME: mksent.pl
#ABSTRACT: Generate silly Russian sentences


use 5.014;
use utf8;

use Lingua::RU::Declension;

binmode STDOUT, ":utf8";

die "Supply a case\n" if ( scalar @ARGV < 1 );

my $rus = Lingua::RU::Declension->new();

for ( 1..10 ) {
    my $noun = $rus->choose_random_noun();
    my $plural = (rand(1) > 0.50) ? "plural" : 0;
    my $adj = $rus->decline_random_adjective($noun, $ARGV[0], $plural);
    my $pronoun = $rus->decline_random_pronoun($noun, $ARGV[0], $plural);

    say $rus->russian_sentence_stem($ARGV[0]) . " $pronoun $adj "
                        . $rus->decline_noun($noun, $ARGV[0], $plural);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

mksent.pl - Generate silly Russian sentences

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    $ mksent.pl acc

=head1 OVERVIEW

This is a simple script which generates some random silly Russian sentences
where the pronoun, adjective and noun are all declined to the specified
case given on the command line.

It's both a test script and a tool to help get Russian language students
familiar with how case endings look with different nouns

=head1 NAME mksent.pl

=head1 AUTHOR

Mark Allen <mallen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
