package File::PatternMatch;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.044';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw(
    patternmatch
  );
}

use Term::ExtendedColor qw(fg bg);

# Yes, this is extremely fugly.
our %patterns = (
  'S[0-9]{1}[2-9]{1}E[0-9]{1}[2-9]'  => {
    256   => fg('magenta23', 'New Episode'),
    dzen  => "^fg(#ff0000)New Episode^fg()",
    none  => "New Episode",
  },
  'S01E01'                           => {
    256   => fg('red1', 'New Show'),
    dzen  => "^fg(#ffff00)New Show^fg()",
    none  => "New Show",
  },
  'S0\dE01'                          => {
    256   => fg('bold', 'Season Premiere'),
    dzen  => "^fg(#cccd05)Season Premiere^fg()",
    none  => "Season Premiere",
  },
  'do(c|k?)u(ment.+)?|
  (discovery|history)\.(channel)?|
  national\.geographic|
  colossal\.'                        => {
    256   =>  fg('green16', 'Documentary'),
    dzen  =>  "^fg(#87d700)Documentary^fg()",
    none  =>  "Documentary",
  },
  'EPL|WWE|UFC|UEFA|Rugby|La\.Liga|
  Superleague|Allsvenskan|
  Formula\.Ford'                     => {
    256   =>  fg(145, 'Sport'),
    dzen  =>  "^fg(#afaf87)Sport^fg()",
    none  =>  "Sport",
  },
  '(?i)swedish|-se-'                 => {
    256   =>  fg('cyan8', 'Swedish'),
    dzen  =>  "^fg(#87ffd7)Swedish^fg(#121212)",
    none  =>  "Swedish",
  },
  '(?i)jay\.leno'                    => {
    256   =>  fg('purple15', 'Talk Show'),
    dzen  =>  "^fg(87afff)Talk Show^fg()",
    none  =>  "Talk Show",
  },
  'PsyCZ|MYCEL|UPE|HiEM|PSi|gEm'     => {
    256   =>  "\e[38;5;192mPsychedelic\e[0m",
    dzen  =>  "^fg(#d7ff87)Psychedelic^fg()",
    none  =>  "Psychedelic",
  },
  '.+-(H3X|wAx|CMS|BFHMP3|WHOA|RNS|
  C4|CR|UMT|0MNi)(.+)?|FRAY(.+)?$'   => {
    256   =>  "\e[38;5;094mHip-Hop\e[0m",
    dzen  =>  "^fg(#309184)Hip-Hop^fg()",
    none  =>  "Hip-Hop",
  },
  'LzY|qF|SRP|NiF'                   => {
    256   =>  "\e[38;5;126mRock\e[0m",
    dzen  =>  "^fg(#af0087)Rock^fg()",
    none  =>  "Rock",
  },
  '-sour$'                           => {
    256   =>  "\e[38;5;166mDnB\e[0m",
    dzen  =>  "^fg(#d75f00)DnB^fg()",
    none  =>  "DnB",
  },
  'VA(-|_-_).+'                      => {
    256   =>  "\e[38;5;049mV/A\e[0m",
    dzen  =>  "^fg(#00ffaf)V/A^fg()",
    none  =>  "V/A",
  },
  '\(?_?-?CDS-?_?\)?'                => {
    256   =>  "\e[38;5;244mSingle\e[0m",
    dzen  =>  "^fg(#808080)Single^fg()",
    none  =>  "Single",
  },
  '\(?_?-?CDM-?_?\)?'                => {
    256   => "\e[38;5;233mMaxi\e[0m",
    dzen  => "^fg(#1c1c1c)Maxi^fg()",
    none  => "Maxi",
  },
  '\(?_?-?CDA-?_?\)?'                => {
    256   => "\e[38;5;222mAlbum\e[0m",
    dzen  => "^fg(#ffd787)Album^fg()",
    none  => "Album",
  },
  '\(?_?-?DAB-?_?\)?'                => {
    256   => "\e[38;5;211mDAB\e[0m",
    dzen  => "^fg(#ff87af)DAB^fg()",
    none  => "DAB",
  },
  '\(?_?-?CABLE-?_?\)?'              => {
    256   => "\e[38;5;191mCable\e[0m",
    dzen  => "^fg(#d7ff5f)Cable\e[0m",
    none  => "Cable",
  },
  '\(?_?-?VLS|Vinyl-?_?\)?'          => {
    256   => "\e[38;5;201mVinyl\e[0m",
    dzen  => "^fg(#ff00ff)Vinyl^fg()",
    none  => "Vinyl",
  },
  '\(?_?-?WEB-?_?\)?'                => {
    256   => "\e[38;5;19mWEB\e[0m",
    dzen  => "^fg(#ffabcd)WEB^fg()",
    none  => "WEB",
  },
  'Live_(on|at|in)'                  => {
    256   => "\e[38;5;181mLive\e[0m",
    dzen  => "^fg(#d7afaf)Live^fg()",
    none  => "Live",
  },
  '-Recycled.+$'                     => {
    256   => "\e[38;5;215Re-release\e[0m",
    dzen  => "^fg(#ffaf5f)Re-release^fg()",
    none  => "Re-release",
  },

  'TALiON|HB|DV8'       => {
    256   => "\e[38;5;41m\e[1mHardstyle\e[0m",
    dzen  => "^fg(#f95504)Hardstyle^fg()",
    none  => "Hardstyle",
  },
);

my $year = (localtime(time))[5] + 1900;

our %wanted = (
  'Fringe'                     => {
    dzen  => "^fg(#000000)^bg(#121212)",
    256   => "\e[48;5;052m\e[1m\e[38;5;196m",
    none  => "",
  },
  'House'                      => {
    dzen  => "^fg(#d5f418)^fg(#ffff00)",
    256   => fg('bold', fg('red1')),
    none  => "",
  },
  '(?:do(c|k)ument(a|ä)ry?|History\.Channel)'   => {
    dzen  => "^fg(#09b33f)",
    256   => "\e[38;5;197m",
    none  => "",
  },

  'pilot'                      => {
    dzen  => "^fg(#c02d07)",
    256   => "\e[38;5;85m\e[1m",
    none  => "",
  },
  'S01E01'                     => {
    dzen  => "^fg(#d7d75f)",
    256   => "\e[38;5;185m",
    none  => "",
  },
  'hdtv'                       => {
    dzen  => "^fg(#cccdda)",
    256   => "\e[38;5;32m\e[3m",
    none  => "",
  },
  'pdtv'                       => {
    dzen  => "^fg(#dacddd)",
    256   => "\e[38;5;29m\e[3m",
    none  => "",
  },
  'swedish'                    => {
    dzen  => "^fg(#ffff00)",
    256   => "\e[38;5;220m\e[1m",
    none  => "",
  },
  'DIMENSION'                  => {
    dzen  => "^fg(#faeec4)",
    256   => "\e[38;5;240m\e[1m",
    none  => "",
  },
  'C4'                      => {
    dzen  => "^fg(#facddc)",
    256   => "\e[38;5;130m\e[1m",
    none  => "",
  },
  'LOL'                     => {
    dzen  => "^fg(#facddc)",
    256   => "\e[38;5;118m\e[1m",
    none  => "",
  },
  '720p'                    => {
    dzen  => "^fg(#ffcccd)",
    256   => "\e[38;5;178m\e[1m",
    none  => "",
  },
  'Promo_CD'                => {
    dzen  => "^fg(#dddc26)",
    256   => "\e[38;5;173m",
    none  => "",
  },
  $year                     => {
    dzen  => "^fg(#93c26b)",
    256   => "\e[1m",
    none  => "",
  },
);

our %end = (
  dzen  => "", # ^bg()^fg()
  256   => "\e[0m",
  none  => "",
);

sub patternmatch {
  my $fmt = shift;
  my @files = @_;

  if( (!defined($fmt)) or ($fmt eq 'plain') ) {
    $fmt = 'none';
  }

  my %results;
  my $i = 0;
  for my $file(@files) {
    for my $keyword(keys(%wanted)) {
      $file =~ s/($keyword)/$wanted{$keyword}->{$fmt}$1$end{$fmt}/gi;
    }

    for my $pattern(keys(%patterns)) {
      if($file =~ /$pattern/x) {
        $results{$i}->{$file} = $patterns{$pattern}->{$fmt};
      }
    }
    $i++;
  }
  return(\%results);
}


1;


__END__

=head1 NAME

File::PatternMatch - parse media information from filenames

=head1 SYNOPSIS

  use File::PatternMatch;

  my @files = glob("$ENV{HOME}/music/*");

  my $plain = patternmatch(@files);

  my $extended_colors = patternmatch(256, @files);


=head1 DESCRIPTION

This module was initially written to be used together with L<File::Media::Sort>
and L<Parse::Flexget>.

B<File::PatternMatch> takes a list of filenames and tries to parse relevant
information from them. If a filename contains the string 'S01E01' we can safely
assume it's a new TV show, the first episode from the first season, and thus we
label it 'New Show'.

There are filters for various music genres, tv shows and music videos.

The labels can be formatted in three ways;

=head2 plaintext

Raw, plain text.

=head2 colored

Colored using extended escape sequences (see L<Term::ExtendedColor>).

=head2 dzen2

Formatted using the L<dzen2(1)> notation.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 patternmatch()

Parameters: $output_format, @files

Returns:    \%results

B<patternmatch()> takes a list of filenames and tries to match them aginst
specific patterns. The result might look like:

  # Plain text
  2 => {
    'Prison.Break.S01E01-FOOBAR'  => 'New Show',
  },
  42 => {
    'Laleh-Prinsessor-FOOBAZ'     => 'Pop/Rock',
  },

  # Using extended color escape sequences
  2 => {
    'Prison.Break.S01E01-FOOBAR'  => "\e[38;5;160mNew Show\e[0m",
  },

  # Using dzen2 format
  2 => {
    'Prison.Break.S01E01-FOOBAR'  => '^fg(#ff0000)New Show^fg()',
  },

=head1 SEE ALSO


=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the File::PatternMatchs L</AUTHOR> and L</CONTRIBUTORS> as
listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
