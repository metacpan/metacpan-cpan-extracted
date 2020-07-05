package Filename::Audio;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-01'; # DATE
our $DIST = 'Filename-Audio'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(check_audio_filename);

# sorted by length then asciibetical
our $STR_RE = "mpega|aifc|aiff|flac|midi|mpga|opus|aif|amr|awb|axa|csd|gsm|kar|m3u|m4a|mid|mp2|mp3|oga|ogg|orc|pls|ram|sco|sd2|sid|snd|spx|wav|wax|wma|au|ra|rm"; # STR_RE
our $RE = qr(\.(?:$STR_RE)\z)i;

sub check_audio_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being an audio file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Audio - Check whether filename indicates being an audio file

=head1 VERSION

This document describes version 0.002 of Filename::Audio (from Perl distribution Filename-Audio), released on 2020-04-01.

=head1 SYNOPSIS

 use Filename::Audio qw(check_audio_filename);
 my $res = check_audio_filename(filename => "foo.mp3");
 if ($res) {
     printf "File is audio";
 } else {
     print "File is not audio\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 check_audio_filename

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Audio>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Audio>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Audio>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Video>

L<Filename::Image>

L<Filename::Media>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
