package GoSaveTool;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.000';

1;

__END__

=encoding utf8

=head1 NAME

GoSaveTool - SRT and WebVTT subtitle tools, word count, social media limits and case changes

=head1 SYNOPSIS

    use utf8;
    use GoSaveTool::Subtitles qw(convert parse repair);
    use GoSaveTool::Text qw(stats limits title slug);

    my $vtt = convert($srt_text, 'vtt');
    my ($cues, $fixed) = repair(parse($text));

    my $words = stats($post)->{words};
    my $fits  = limits($post)->{'x-post'}{fits};
    print title('the lord of the rings'), "\n";   # The Lord of the Rings
    print slug('Ölçü Birimi & Çeviri!'), "\n";    # olcu-birimi-ceviri

=head1 DESCRIPTION

Two small modules from L<GoSaveTool|https://www.gosavetool.com/>, free online
tools for creators, with the same rules as the C<@gosavetool/subtitles> and
C<@gosavetool/text> JavaScript packages. No dependencies outside the Perl core.

=over 4

=item L<GoSaveTool::Subtitles>

Parse, convert, shift and repair SRT and WebVTT subtitles. Online:
L<https://www.gosavetool.com/vtt-subtitle-generator>

=item L<GoSaveTool::Text>

Word, character and reading-time counts, the character limits of X,
Instagram, TikTok, YouTube, LinkedIn, Pinterest and SEO fields, Title Case,
Sentence case, slugs, camelCase, snake_case, kebab-case and whitespace
cleanup. Online: L<https://www.gosavetool.com/character-counter>

=back

=head1 AUTHOR

GoSaveTool L<https://www.gosavetool.com/>

=head1 LICENSE

MIT License. See the LICENSE file.

=cut
