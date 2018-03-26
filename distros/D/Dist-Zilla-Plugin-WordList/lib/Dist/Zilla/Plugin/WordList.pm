package Dist::Zilla::Plugin::WordList;

our $DATE = '2018-03-23'; # DATE
our $VERSION = '0.054'; # VERSION

use 5.014;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Data::Dmp;
use WordList::Namespace qw(is_actual_wordlist_module);

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

sub __length_in_graphemes {
    my $length = () = $_[0] =~ m/\X/g;
    return $length;
}

sub munge_files {
    no strict 'refs';
    my $self = shift;

    local @INC = ("lib", @INC);

    my %seen_mods;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!\Alib/((WordList/.+)\.pm)\z!;

        my $package_pm = $1;
        my $package = $2; $package =~ s!/!::!g;
        unless (is_actual_wordlist_module($package)) {
            $self->log(["Module %s is not an actual wordlist module, skipped", $package]);
            next;
        }

        my $content = $file->content;

        # Add statistics to %STATS variable
        {
            require $package_pm;
            my $wl = $package->new;

            my $total_len = 0;
            my %stats = (
                num_words => 0,
                num_words_contains_unicode => 0,
                num_words_contains_whitespace => 0,
                num_words_contains_nonword_chars => 0,
                shortest_word_len => undef,
                longest_word_len => undef,
            );
            my $last_word;
            $wl->each_word(
                sub {
                    my $word = shift;

                    # check that word is sorted
                    if (!${"$package\::SORT"} && defined $last_word) {
                        if ($last_word eq $word) {
                            die "Duplicate entry '$word'";
                        } elsif ($last_word gt $word) {
                            die "Wordlist is not sorted! ('$last_word' gt '$word')";
                        }
                    }
                    $last_word = $word;

                    $stats{num_words}++;
                    $stats{num_words_contains_unicode}++ if $word =~ /[\x80-\x{10ffff}]/;
                    $stats{num_words_contains_whitespace}++ if $word =~ /\s/;
                    $stats{num_words_contains_nonword_chars}++ if $word =~ /\W/u;
                    my $len = __length_in_graphemes($word);
                    $total_len += $len;
                    $stats{shortest_word_len} = $len
                        if !defined($stats{shortest_word_len}) ||
                        $len < $stats{shortest_word_len};
                    $stats{longest_word_len} = $len
                        if !defined($stats{longest_word_len}) ||
                        $len > $stats{longest_word_len};
                });
            $stats{avg_word_len} = $total_len / $stats{num_words} if $total_len;

            $content =~ s{^(#\s*STATS)$}{"our \%STATS = ".dmp(%stats)."; " . $1}em
                or die "Can't replace #STATS for ".$file->name.", make sure you put the #STATS placeholder in modules";
            $self->log(["replacing #STATS for %s", $file->name]);

            $file->content($content);
        }
    } # foreach file
    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building WordList::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::WordList - Plugin to use when building WordList::* distribution

=head1 VERSION

This document describes version 0.054 of Dist::Zilla::Plugin::WordList (from Perl distribution Dist-Zilla-Plugin-WordList), released on 2018-03-23.

=head1 SYNOPSIS

In F<dist.ini>:

 [WordList]

=head1 DESCRIPTION

This plugin is to be used when building C<WordList::*> distribution. Currently
it does the following:

=over

=item * Check that wordlist is sorted

=item * Check that wordlist does not contain any duplicates

=item * Replace C<# STATS> placeholder (which must exist) with word list statistics

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Pod::Weaver::Plugin::WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
