package File::TVShow::Info;

use 5.10.0;
use strict;
use warnings;
use File::TVShow::EpisodeName 0.01 qw (@episode_name_patterns);
use File::TVShow::Networks 0.01 qw(@networks);

use vars qw(@filePatterns);

=head1 NAME

File::TVShow::Info - Perl meta data extractor from file name for TV Show file.

=head1 VERSION

Version 0.01.0.0

=cut

our $VERSION = '0.01.0.0';


=head1 SYNOPSIS

This module is intended to identify and extract nformation in the file name of a TV show. These details can then be accessed
by calling the relevant methods. It does B<NOT> attempt to read the contents of the file.

Note: This module will be modelled off L<https://metacpan.org/pod/Video::Filename> created by Behan Webster, but will focus on TV Shows only and with additional features.

If the file name is parsed and can not be identified as a TV show then L</is_tv_show> will return 0.

    use File::TVShow::Info;
    my $show = File::TVShow::Info->new('file');

=cut


@filePatterns = (
        { # TV Show Support -   By Date no Season or Episode
          # Perl > v5.10
          re => '(?<show_name>.*?)[.\s_-](?<year>\d{4})[.\s_-](?<month>\d{1,2})[.\s_-](?<date>\d{1,2})(?:[.\s_-](?<extra_meta>.*)|)[.](?<ext>(?:[a-z]{3}|[a-z]{2}[0-9]))$',

          # Perl < v5.10
          re_compat => '(.*?)[.\s_-](\d{4})[.\s_-](\d{1,2})[.\s_-](\d{1,2})(?:[.\s_-](.*)|)[.]((?:[a-z]{3}|[a-z]{2}[0-9]))$',
          keys_compat => [qw(filename show_name year month date extra_meta ext)],
        },
        { # TV Show Support - SssEee or Season_ss_Episode_ss
          # Perl > v5.10
          re => '^(?:(?<show_name>.*?)[\/\s._-]+)?(?:s|se|season|series)[\s._-]?(?<season>\d{1,2})[x\/\s._-]*(?:e|ep|episode|[\/\s._-]+)[\s._-]?(?<episode>\d{1,2})(?:-?(?:(?:e|ep)[\s._]*)?(?<endep>\d{1,2}))?(?:[\s._]?(?:p|part)[\s._]?(?<part>\d+))?(?<subep>[a-z])?(?:[\/\s._-]*(?<extra_meta>[^\/]+?))?[.](?<ext>(?:[a-z]{3}|[a-z]{2}[0-9]))$',

          # Perl < v5.10
          re_compat => '^(?:(.*?)[\/\s._-]+)?(?:s|se|season|series)[\s._-]?(\d{1,2})[x\/\s._-]*(?:e|ep|episode|[\/\s._-]+)[\s._-]?(\d{1,2})(?:-?(?:(?:e|ep)[\s._]*)?(\d{1,2}))?(?:[\s._]?(?:p|part)[\s._]?(\d+))?([a-z])?(?:[\/\s._-]*([^\/]+?))?[.](?<ext>(?:[a-z]{3}|[a-z]{2}[0-9]))$',
          keys_compat => [qw(show_name season episode endep part subep extra_meta)],
        },
        { # TV Show Support - sxee
          # Perl > v5.10
          re => '^(?:(?<show_name>.*?)[\/\s._-]*)?(?<openb>\[)?(?<season>\d{1,2})[x\/](?<episode>\d{1,2})(?:-(?:\k<season>x)?(?<endep>\d{1,2}))?(?(<openb>)\])(?:[\s._-]*(?<extra_meta>[^\/]+?))?[.](?<ext>(?:[a-z]{3}|[a-z]{2}[0-9]))$',

          # Perl < v5.10
          re_compat => '^(?:(.*?)[\/\s._-]*)?\[?(\d{1,2})[x\/](\d{1,2})(?:-(?:\d{1,2}x)?(\d{1,2}))?\]?(?:[\s._-]*([^\/]+?))?[.](?<ext>(?:[a-z]{3}|[a-z]{2}[0-9]))$',
          keys_compat => [qw(show_name season episode endep extra_meta)],
        },
);

=head1 Methods

=head2 new

Create a Info object to extract meta information from the file name.

    my $show = File::TVShow::Info->new('file');

=cut

=head3 Object attributes.

Attributes may be accessed through $show->{attribute_name} however methods
do exist for all required operations.

=over 4

=item * show_name:
Name of the show.

=item * original_show_name:
This will contain the show name found in the file name without any modifications.
This will only be defined if _isolate_name_year has found a year string
within the file name such as name.2019, name.(2019), name 2018, name (2018)

=item * season:
Show season

=item * episode:
Show episode

=item * episode_name

=item * country

=item * endep: (Naming under consideration)
last Episode number found when file name contains SXXEXXEXX

=item * year, month, date:
Show date e.g 2019.03.03
This can be accessed using the method L</ymd>
Note: year will be defined in two cases.
  One: show name contains year. show_name.yyyy or
  Two: File name contains YYYY.MM.DD that are identified by date. These are mutually
  exclusive and no conflict is expected.

=item * source

=item * resolution:
Show resolution 480p/720p and so on. This will be '' if not found.

=item * release_group

=item * is_subtitle

=item * subtitle_lang

=item * ext:
File extension

=back

=cut

sub new {
    my $class = shift;
    my $self =  {};
    bless $self, $class;
    # Set default attributes
    @{$self->{valid_countries}} =  qw( US UK KR);

    # Read default values
    for my $key (qw(file name season episode part options)) {
      last unless defined $_[0];
      if (ref $_[0]) {
        # Use a hashref for values
        while (my ($key, $value) = each %{$_[0]}) {
          $self->{$key} = $value;
        }
      } else {
        $self->{$key} = shift;
      }
    }

    $self->{filename} = $self->{file};

    # Run filename through list of patterns
    for my $pat (@filePatterns) {
      if ($] >= 5.010000) {
        if ($self->{file} =~ /$pat->{re}/i) {
          # We have a match we will exit after this loop
          $self->{regex} = $pat->{re};
          while (my ($key, $data) = each %-) {
            $self->{$key} = $data->[0] if defined $data->[0] && !defined $self->{$key};
          }
          # We have a match so we are skipping all other @filePatterns
          last;
        }
      } else { # No named groups in regexes
        my @matches;
        if (@matches = ($self->{file} =~ /$pat->{re_compat}/i)) {
          #print "MACTHES: ".join(',', @matches)."\n";
          $self->{regex} = $pat->{re_compat};
          my $count = 0;
          foreach my $key (@{$pat->{keys_compat}}) {
            $self->{$key} = $matches[$count] unless defined $self->{$key};
            $count++;
          }
          last;
        }
      }
    }
    $self->_set_tvshow_organize_name();
    $self->_isolate_name_year();
    $self->_get_resolution();
    $self->_get_network();
    $self->_get_release_group();
    $self->_is_tv_subtitle();
    $self->_get_subtitle_lang();
    $self->_get_country();
    $self->_get_episode_name();
    return $self;
}

=head2 show_name

Return the show name found in the file name.

=cut

sub show_name {

    my $self = shift;
    my $attr = 'show_name';
    $self->__get_obj_attr($attr);
}

=head2 strip_show_name

Return show_name after removing string delimiters

=cut

sub strip_show_name {

    my $self = shift;

    return if !$self->is_tv_show();

    return $self->{show_name} if defined $self->{do_not_strip};
    (my $newString = $self->{show_name}) =~ s/[\._-]/ /g;
    return $newString;

}

=head2 clean_show_name

Return complete show name with year and country in brackets if they exist.
Also remove any delimiters, replaced with spaces

=cut

sub clean_show_name {

    my $self = shift;

    return if !$self->is_tv_show();

    my $newString = $self->strip_show_name();
    if ($self->has_year()) {
      $newString .= ' (' . $self->year() . ')';
    } elsif ($self->has_country()) {
      $newString .= ' (' . $self->country() . ')';
    }
    return $newString;
}

=head2 original_show_name

Return the original show name.

This method will return the orginal show name if original_show_name is defined.
This will be defined if show_name contains a year string (YYYY) or YYYY

If not defined it will return {show_name}

=cut

sub original_show_name {

    my $self = shift;

    return $self->{original_show_name} if defined $self->{original_show_name};
    return $self->{show_name};
}

=head2 season

Return the season found in the file name. Return '' if {season} is not defined.

=cut

sub season {

    my $self = shift;
    my $attr = 'season';
    $self->__get_obj_attr($attr);
}

=head2 season_to_int

Return season as an integer

=cut

sub season_to_int {

    my $self = shift;
    return int($self->season()) if defined $self->{season};
    return undef;
}

=head2 episode

Return the episode found in the file name. Return '' if {episode} is not defined.

=cut

sub episode {

    my $self = shift;
    my $attr = 'episode';
    $self->__get_obj_attr($attr);
}

=head2 episode_to_int

Return episode as an integer

=cut

sub episode_to_int {

    my $self = shift;
    return int($self->episode()) if defined $self->{episode};
    return undef;
}

=head2 source

Return the source of tv show. Return '' if not defined.
Yet to be coded.

=cut


=head2 is_multi_episode

Return 1 if this is a multi-episode file SXXEXXEXX. Return 0 if false

This is true if {endep} is defined.

=cut

sub is_multi_episode {

    my $self = shift;

    return 1 if defined $self->{endep};
    return 0;

}

=head2 season_episode

Return SXXEXX or SXXEXXEXX for single or multi episode files. Return '' if not
created

This would only return an empty string if the show_name is not formated as
show_name.SXX.*

=cut

sub season_episode {

    my $self = shift;
    my $s_e = '';

    #  endep indicates that this is is_multi_episode file. SXXEXXEXX
    if ((defined $self->{episode}) && (!defined $self->{endep})) {
      $s_e = sprintf("S%02dE%02d", $self->{season}, $self->{episode});
    } elsif ((defined $self->{episode}) && (defined $self->{endep})) {
    #  This is a multi-Episde
      $s_e = sprintf("S%02dE%02dE%02d", $self->{season}, $self->{episode},
        $self->{endep});
    };
    return $s_e;

}

=head2 has_year

Return 1 if year is defined else return 0

=cut

sub has_year {

    my $self = shift;

    return 1 if defined $self->{year};
    return 0;

}

=head2 year

Return the year found in the file name. Return '' if {year} is not defined.

=cut

sub year {

    my $self = shift;
    my $attr = 'year';
    $self->__get_obj_attr($attr);
}

=head2 month

Return the month found in the file name. Return '' if {month} is not defined.

=cut

sub month {

    my $self = shift;
    my $attr = 'month';
    $self->__get_obj_attr($attr);
}

=head2 date

Return the date found in the file name. Return '' if {date} is not defined.

=cut

sub date {

    my $self = shift;
    my $attr = 'date';
    $self->__get_obj_attr($attr);
}

=head2 ymd

Return the complete date string as 'YYYY.MM.DD' Ruturn '' if attributes
{year}, {month}, and {date} are not defined.

=cut

sub ymd {

    my $self = shift;

    return $self->{year} . "." . $self->{month} . "." . $self->{date}
      if defined $self->{year} && defined $self->{month};
    return '';
}

=head2 resolution

Return resolution found in the file name. Return '' if {resolution} is not defined.

=cut

sub resolution {

    my $self = shift;
    my $attr = 'resolution';
    $self->__get_obj_attr($attr);
}

#=head2 network

#Return network if found '' if not defined.

#Networks: AMZN, HULU, ABC and so on.

#=cut

sub _network {

  my $self = shift;
  my $attr = 'network';
  $self->__get_obj_attr($attr);


}

=head2 release_group

Return release_group found in the file name. Return '' if {release_group} is not defined.

=cut

sub release_group {

    my $self = shift;
    my $attr = 'release_group';
    $self->__get_obj_attr($attr);
}

=head2 episode_name

Return episode_name. Return '' if {extra_meta} is not defined or can not
determine episode name.

Note: episode name MUST directly follow SXXEXX or it can not be found.

=cut

sub episode_name {

    my $self = shift;
    my $attr = 'episode_name';
    $self->__get_obj_attr($attr);
}

=head2 strip_episode_name

Return episode name without delimiters.

=cut

sub strip_episode_name {

    my $self = shift;

    return if !$self->is_tv_show();

    (my $newString = $self->{episode_name}) =~ s/[\._-]/ /g;
    return $newString;

}

=head2 country

Return country found in {show_name}. Return '' if not defined

=cut

sub country {

    my $self = shift;
    my $attr = 'country';
    $self->__get_obj_attr($attr);
}

=head2 ext

Return file extension. {ext}

=cut

sub ext {

    my $self = shift;

    return $self->{ext} if defined $self->{ext};
    # Return '' or undef? this sould never even happen.
    return undef;

}

=head2 is_tv_show

Return 1 if identified as a TV Show. Default is 0

=cut

sub is_tv_show {

    my ($self) = @_;

    if (defined $self->{season} && defined $self->{episode}) {
        return 1;
    } elsif (defined $self->{year} && $self->{month} && $self->{date}) {
        return 1;
    }
    # This is not a TVshow
    return 0;
}

=head2 is_tv_subtitle

Return 1 if the file is a subtitle file, 0 if {is_subtitle} is not defined.

The file must also return true for is_tv_show() or the result is 0

=cut

sub is_tv_subtitle {

    my $self = shift;

    return 1 if (($self->is_tv_show()) && (defined $self->{is_subtitle}));
    return 0;
}

=head2 has_subtitle_lang

Return 1 if subtitle language was found, Return 0 if {subtitle_lang} is not defined.

Must also return 1 for is_tv_subtitle()

=cut

sub has_subtitle_lang {

    my $self = shift;

    return 1 if (($self->is_tv_subtitle()) && (defined $self->{subtitle_lang}));
    return 0;
}

=head2 subtitle_lang

Return the language of the subtitle file: eng or en. Return '' if {subtitle_lang} is not defined.

=cut

sub subtitle_lang {

    my $self = shift;
    my $attr = 'subtitle_lang';
    $self->__get_obj_attr($attr);
}

=head2 has_country

Return 1 if country was found, Return 0 if {country} is not defined.

Must also return 1 for is_tv_subtitle()

=cut

sub has_country {

    my $self = shift;

    return 1 if (($self->is_tv_show()) && (defined $self->{country}));
    return 0;
}

=head2 is_by_date

Return 1 if by date. Default is 0

This will be true where year, month and date are all defined. show_name.yyyy.mm.dd.ext

=cut

sub is_by_date {

    my $self = shift;

    if (defined $self->{year} && defined $self->{month} &&
        defined $self->{date}) {
      return 1;
    }
    return 0;
}

=head2 is_by_season

Return 1 if by season. Default is 0

Requires {season} and {episode} to be defined.

=cut

sub is_by_season {

    my $self = shift;
    if (defined $self->{season} && defined $self->{episode}) {
      return 1;
    }
    return 0;
}

sub _set_tvshow_organize_name {

    my $self = shift;

    # This is not a tv show file. Exit method now.
    return if !$self->is_tv_show();

    $self->{organize_name} = $self->{show_name} if defined $self->{show_name};
}

sub _isolate_name_year {

    my $self = shift;

    # This is not a tv show file. Exit method now.
    return if !$self->is_tv_show();

    my @exceptions = qw(The.4400);

    my $regex;
    if ($] >= 5.010000) { # Perl 5.10 > has regex group support
      $regex = '(?<show_name>.*[^\s(_.])[\s(_.]+(?<year>\d{4})';
    } else { # Perl versions below 5.10 do not have group support
      $regex = '(.*[^\s(_.])[\s(_.]+(\d{4})';
    }
    # Skip isolation if {show_name} is in the array @exceptions
    # We do not want to modify the file name.
    foreach (@exceptions) {
      if ($self->{show_name} =~ m/$_/) {
        $self->{do_not_strip} = 1;
        return;
      }
    }

    # break {show_name} from year
    if ($self->{show_name} =~ /$regex/gi) {
      # First copy {show_name} to new attr
      $self->{original_show_name} = $self->{show_name};
      # Support to handle either case of group or no groups in regex
      $self->{year} = $+{year} || $2; #$2 equals group year
      $self->{show_name} = $+{show_name} || $1; # $1 equals group show_name
    }
}

# TODO: Code _get_source (HTDV, AMZ ?)

sub _get_episode_name {

    my $self = shift;

    # This is not a tv show file. Exit method now.
    return if !$self->is_tv_show() || !defined $self->{extra_meta};

    # Dont bother search as there is no Episode Name extra_meta starts
    # with 720p or AMZN or WEB
    return if $self->{extra_meta} =~ /^([0-9]{3,4}(p|i)|AMZN|WEB)/i;

    # Loop through possible regex list to find suiable regex to use
    for my $pat (@episode_name_patterns) {
        if ($self->{extra_meta} =~ /$pat->{re}/i) {
          # We have a match we will exit after this loop
          # Use this {re} as our regex
          $self->{episode_name_regex} = $pat->{re};
          # We have a match so we are skipping all other @filePatterns
          last;
        }
    }
    # Only do the extraction of we found a matching regex to use
    if (defined $self->{episode_name_regex}) {
      if ($self->{extra_meta} =~ /$self->{episode_name_regex}/i) {
        $self->{episode_name} = $+{episode_name};
      }
    } else {
      # This is only being set for use in testing.
      # There might be an Episode name, but no regex match found
      $self->{no_episode_name_regex} = 1;
    }
}

sub _get_release_group {

    my $self = shift;

    # This is not a tv show file. Exit method now.
    return if !$self->is_tv_show() || !defined $self->{extra_meta};

    my $regex;
    if ($] >= 5.010000) { # Perl 5.10 > has regex group support
      $regex = '[\[]?(?P<release_group>fov|vtv|ettv|rmteam|eztv)[]]?';
    } else { # Perl versions below 5.10 do not have group support
      $regex = '[\[]?(fov|vtv|ettv|rmteam|eztv)[]]?';
    }
    if ($self->{extra_meta} =~ /$regex/gi) {
      $self->{release_group} = $+{release_group} || $1; # $1 equals group release_group
    }
}

sub _get_network {

    my $self = shift;

    return if !$self->is_tv_show() || !defined $self->{extra_meta};

    #Build REGEX from array of Networks
    my $regex = '(?P<network>';
    $regex .= join('|', @networks);
    $regex .= ')';
    #my $regex = '(?P<network>ABC|AMZN|BBC|CBS|CC|CW|DCU|DSNY|FBWatch|FREE|FOX|HULU|iP|LIFE|MTV|NBC|NICK|FC|RED|TF1|STZ)';
    if ($self->{extra_meta} =~ /$regex/gi) {
      $self->{network} = $+{network};
    }
}

sub _get_resolution {

    my $self = shift;

    # This is not a tv show file. Exit method now.
    return if !$self->is_tv_show() || !defined $self->{extra_meta};

    my $regex;
    if ($] >= 5.010000) { # Perl 5.10 > has regex group support
      $regex = '(?P<resolution>[0-9]{3,4}[p|i])';
    } else { # Perl versions below 5.10 do not have group support
      $regex = '([0-9]{3,4}[p|i])';
    }
    if ($self->{extra_meta} =~ /$regex/gi) {
      $self->{resolution} = $+{resolution} || $1; # $1 equals group resolution
    }

}

sub _get_country {

  my $self = shift;

  # This is not a tv show file. Exit method now.
  return if !$self->is_tv_show();

  my $regex;
  if ($] >= 5.010000) { # Perl 5.10 > has regex group support
    $regex = '[(]?(?P<country>\w{2})[)]?$';
  } else { # Perl versions below 5.10 do not have group support
    $regex = '[(]?(\w{2})[)]?$';
  }
  if ($self->{show_name} =~ /$regex/g) {
    # Check if string at the end of {show_name} is in the array of accepted
    # country strings. If not, we do not set {country}
    if (grep { $_ eq $1 } @{$self->{valid_countries}}) {
      $self->{country} = $+{country} || $1; # $1 equals group country
      $self->{show_name} =~ s/\(?$1\)?//;
      chop($self->{show_name});
    }
  }
}

sub _is_tv_subtitle {

    my $self = shift;

    # This is not a tv show file. Exit method now.
    return if !$self->is_tv_show();

    my @list_of_subtitle_ext = qw(srt smi ssa ass vtt);

    # Check if {ext} is a subtitle extension {is_subtitle} set to 1 if true.
    if (grep { $_ eq $self->{ext}} @list_of_subtitle_ext) {
      $self->{is_subtitle} = 1;
    }
}

sub _get_subtitle_lang {

    my $self = shift;

    # This is not a subtitle file. Exit method now.
    return if !defined $self->{is_subtitle};

    my $regex;
    if ($] >= 5.010000) { # Perl 5.10 > has regex group support
      $regex = '(?P<lang>[a-z]{2,})$';
    } else { # Perl versions below 5.10 do not have group support
      $regex = '([a-z]{2,})$';
    }
    if ($self->{extra_meta} =~ /$regex/gi) {
      $self->{subtitle_lang} = $+{lang} || $1; # $1 equals group lang
    }
}

sub __get_obj_attr {

    my ($self, $attr) = @_;

    return $self->{$attr} if defined $self->{$attr};
    return '';

}

=head1 AUTHOR

Adam Spann, C<< <bans at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-tvshow-info at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-TVShow-Info>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::TVShow::Info


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-TVShow-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-TVShow-Info>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/File-TVShow-Info>

=item * Search CPAN

L<https://metacpan.org/release/File-TVShow-Info>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Adam Spann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of File::TVShow::Info
