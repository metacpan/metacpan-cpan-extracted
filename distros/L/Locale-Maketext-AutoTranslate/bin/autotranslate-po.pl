#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use Pod::Usage;
use Getopt::Std;
use Locale::Maketext::AutoTranslate;

$ENV{AUTOTRANSLATE_DEBUG} = 1;

sub main {
    pod2usage(1) if !@_;
    getopts('f:t:i:o:h', \my %opts);
    pod2usage(1) if $opts{h};
    
    if (!$opts{f}) {
        $opts{f} ||= 'en';
        warn "Source language defaults to English\n\n";
    }
    if (!$opts{i}) {
        $opts{i} ||= $opts{f} . '.po';
        warn "Input file defaults to $opts{i}\n\n";
    }
    if (!$opts{o}) {
        $opts{o} ||= $opts{t} . '.po';
        warn "Output file defaults to $opts{o}\n\n";
    }

    die "Please specify the target language" if !$opts{t};

    my $t = Locale::Maketext::AutoTranslate->new();
    
    $t->from($opts{f});
    $t->to($opts{t});

    $t->translate($opts{i} => $opts{o});

    warn "\nTranslation is done.\n\n";
}

main(@ARGV);

__END__

=pod

=head1 NAME

autotranslate-po - Automatic .po file translator

=head1 SYNOPSIS

    % autotranslate-po.pl -f source_lang -t target_lang -i input_file -o output_file

    % autotranslate-po.pl -f en -t zh-tw -i en.po -o zh-tw.po

=head1 SEE ALSO

L<Locale::Maketext::AutoTranslate>
    
=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yung-chung Lin (henearkrxern@gmail.com)

=cut
