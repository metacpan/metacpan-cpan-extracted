# GoSaveTool for Perl

Parse, convert, shift and repair **SRT and WebVTT** subtitles, and count **words, characters and reading time** with **social media character limits**, **Title Case**, **slugs** and other case changes. Perl 5.10+, nothing outside the core.

Made by [GoSaveTool](https://www.gosavetool.com/), free online tools for creators.

## Install

```bash
cpanm GoSaveTool
```

## Subtitles

```perl
use GoSaveTool::Subtitles qw(convert parse shift_cues repair to_srt);

my $vtt = convert($srt_text, 'vtt');
my $cues = parse($text);                         # [ { start => 1000, end => 3500, settings => '', text => 'Hello' }, ... ]
my $later = to_srt(shift_cues($cues, 1500));     # 1.5 s later
my ($fixed, $n) = repair($cues);                 # sorted, no overlaps, no empty cues
```

## Text

```perl
use utf8;
use GoSaveTool::Text qw(stats limits title sentence slug camel clean);

my $st = stats($post);                           # words, chars, charsNoSpaces, lines, sentences, readSeconds
print limits($post)->{'x-post'}{left}, " characters left\n";
print title('the lord of the rings');            # The Lord of the Rings
print slug('Ölçü Birimi & Çeviri!');             # olcu-birimi-ceviri
print camel('best posting time');                # bestPostingTime
```

Limits: X post, Instagram caption, TikTok caption, YouTube title and description, LinkedIn post, Pinterest description, SEO title, meta description. Characters are Unicode code points, so an emoji counts as one. The results are the same as the [`@gosavetool/text`](https://www.npmjs.com/package/@gosavetool/text) and [`@gosavetool/subtitles`](https://www.npmjs.com/package/@gosavetool/subtitles) JavaScript packages.

Full documentation: `perldoc GoSaveTool::Subtitles`, `perldoc GoSaveTool::Text`.

## Tests

```bash
prove -l t
```

## Online tools

[VTT Subtitle Generator](https://www.gosavetool.com/vtt-subtitle-generator), [Auto Captions Generator](https://www.gosavetool.com/auto-captions-generator), [Character Counter](https://www.gosavetool.com/character-counter)

## License

MIT
