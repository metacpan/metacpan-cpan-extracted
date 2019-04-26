package File::TVShow::EpisodeName;

require Exporter;
our @ISA = qw ( Exporter );
our @EXPORT = qw ( @episode_name_patterns );

=head1 NAME

File::TVShow::EpisodeName - Array of EpisodeName matching regexs.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @episode_name_patterns = (
        { # Matching name followed by resoltion (name.720p)
          re => '^(?<episode_name>.*)[\s.]?(?:(?:\.|\ )[0-9]{3,4})(?:p|i)',
        },
        { # Matching name follwoed by source
          re => '^(?<episode_name>.*)[\s.](AMZN|hdtv|SDTV)',
        },
        { # Matching name followed by web
          re => '^(?<episode_name>.*)[\s.](web)',
        },
);

1;
