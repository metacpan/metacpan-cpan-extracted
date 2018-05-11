#!/usr/bin/env perl
#PODNAME: mkflash.pl
#ABSTRACT: Generate comma seperated files for importing into Anki for flashcards


use 5.014;
use utf8;

use Lingua::RU::Declension;
use charnames ();
use Text::CSV qw(csv);

binmode STDOUT, ":utf8";

die "Supply a case\n" if (scalar @ARGV < 1);

my $case = $ARGV[0];
my $plural = defined $ARGV[1] ? 1 : 0;
my $arrow = charnames::string_vianame("RIGHTWARDS ARROW"); # →

my $rus = Lingua::RU::Declension->new();

my @out;
for (1..50) {
    my $noun = $rus->choose_random_noun();
    my $adj = $rus->choose_random_adjective();
    my $pronoun = $rus->choose_random_pronoun();

    my $dp = $rus->decline_pronoun($pronoun, $noun, $case, $plural);
    my $da = $rus->decline_adjective($adj, $noun, $case, $plural);
    my $dn = $rus->decline_noun($noun, $case, $plural);

    my $front = "$pronoun $adj $noun ($case)";
    my  $back = "$dp $da $dn<br>$pronoun $arrow $dp<br>$adj $arrow $da<br>$noun $arrow $dn";
    push @out, [$front, $back];
}

csv( in => \@out, out => "${case}_flash.csv", encoding => "UTF-8" );

__END__

=pod

=encoding UTF-8

=head1 NAME

mkflash.pl - Generate comma seperated files for importing into Anki for flashcards

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    $ mkflash.pl acc [plural]

=head1 OVERVIEW

This is a script to generate a file which will create some flashcards for use with
L<Anki|https://apps.ankiweb.net/>.

=head1 NAME mkflash.pl

=head1 AUTHOR

Mark Allen <mallen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
