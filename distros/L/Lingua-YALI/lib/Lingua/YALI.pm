package Lingua::YALI;
# ABSTRACT: YALI - Yet Another Language Identifier.

use strict;
use warnings;
use Carp;

our $VERSION = '0.015'; # VERSION



# TODO: refactor - remove bzcat
sub _open
{
    my ($f) = @_;

    croak("Not found: $f") if !-e $f;

    my $opn;
    my $hdl;
    my $ft = qx(file '$f');

    # file might not recognize some files!
    if ( $f =~ /\.gz$/ || $ft =~ /gzip compressed data/ ) {
        $opn = "zcat $f |";
    }
    elsif ( $f =~ /\.bz2$/ || $ft =~ /bzip2 compressed data/ ) {
        $opn = "bzcat $f |";
    }
    else {
        $opn = "$f";
    }
    open($hdl,"<:bytes", $opn) or croak ("Can't open '$opn': $!");
    binmode $hdl, ":bytes";
    return $hdl;
}

sub _identify_handle
{
    my ($identifier, $fh, $format, $languages, $each_line) = @_;
    if ( $each_line ) {
        while (<$fh>) {
            chomp;
            _identify_string($identifier, $_, $format, $languages);
        }
    } else {
        my $result = $identifier->identify_handle($fh);
        _print_result($result, $format, $languages);
    }
}

sub _identify
{
    my ($identifier, $file, $format, $languages, $each_line) = @_;
    my $fh = Lingua::YALI::_open($file);
    _identify_handle($identifier, $fh, $format, $languages, $each_line);
}

sub _identify_string
{
    my ($identifier, $string, $format, $languages) = @_;
    my $result = $identifier->identify_string($string);
    _print_result($result, $format, $languages);
}

sub _print_result
{
    my ($result, $format, $languages) = @_;
    my $line = "";
    if ( $format eq "single" ) {
        if ( scalar @$result > 0 ) {
            $line = $result->[0]->[0];
        }
    } elsif ( $format eq "all" ) {
        $line = join("\t", map { $_->[0] } @{$result});
    } elsif ( $format eq "all_p" ) {
        $line = join("\t", map { $_->[0].":".$_->[1] } @{$result});
    } elsif ( $format eq "tabbed" ) {
        my %res = ();
        map { $res{$_->[0]} = $_->[1] } @{$result};
        $line = join("\t", map { $res{$_} } @$languages);
    } else {
        croak("Unsupported format $format");
    }

    print $line . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::YALI - YALI - Yet Another Language Identifier.

=head1 VERSION

version 0.015

=head1 SYNOPSIS

The YALI package is a collection of modules and tools for language identification.

It was developed at the L<Institute of Formal and Applied Linguistics|http://ufal.mff.cuni.cz/> at Charles University in Prague.

More information can be found at the L<YALI homepage|http://ufal.mff.cuni.cz/~majlis/yali/>.

=head2 Modules

=over

=item * L<Lingua::YALI::Examples|Lingua::YALI::Examples> - contains examples.

=item * L<Lingua::YALI::LanguageIdentifier|Lingua::YALI::LanguageIdentifier> - is a language identification module capable of identifying 122 languages.

=item * L<Lingua::YALI::Builder|Lingua::YALI::Builder> - is a module used to train custom language models.

=item * L<Lingua::YALI::Identifier|Lingua::YALI::Identifier> - allows to use your own models for identification.

=back

=head2 Tools

=over

=item * L<yali-language-identifier|bin/yali-language-identifier> - tool for a language identification with pretrained models

=item * L<yali-builder|bin/yali-builder> - tool for a building custom language models.

=item * L<yali-identifier|bin/yali-identifier> - tool for a language identification with custom language models.

=back

=head1 WHY TO USE YALI

=over

=item * Contains pretrained models for identifying 122 languages.

=item * Allows to create own models, trained on texts from specific domain, which outperforms the pretrained ones.

=item * It is based on published paper L<http://ufal.mff.cuni.cz/~majlis/yali/>.

=back

=head1 COMPARISON WITH OTHERS

=over

=item * L<Lingua::Lid|Lingua::Lid> can recognize 45 languages and returns only the most probable result without any weight.

=item * L<Lingua::Ident|Lingua::Ident> requires training files, so it is similar to L<Lingua::YALI::LanguageIdentifier|Lingua::YALI::LanguageIdentifier>,
but it does not provide any options for constructing models.

=item * L<Lingua::Identify|Lingua::Identify> can recognize 33 languages but it does not allows you to use different models.

=back

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
