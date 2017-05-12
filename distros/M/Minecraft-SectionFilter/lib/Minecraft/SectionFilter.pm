use 5.010;    # state
use strict;
use warnings;

package Minecraft::SectionFilter;

our $VERSION = '0.003003';

# ABSTRACT: Strip/Process magical § characters from minecraft

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Sub::Exporter::Progressive -setup => {
  exports => [qw( translate_sections strip_sections ansi_encode_sections )],
  groups  => {
    default => [qw( strip_sections ansi_encode_sections )],
  },
};

use Carp qw( carp );

















sub translate_sections {
  my ($line) = @_;

  state $section = chr 0xA7;

  my (@out);
  while ( length $line > 0 ) {
    if ( $line =~ /\A([^$section]+)/msx ) {
      push @out, { type => text =>, content => "$1", };
      substr $line, 0, length "$1", q{};
      next;
    }
    if ( $line =~ /\A$section(.)/msx ) {
      push @out, { type => section =>, section_code => "$1" };
      substr $line, 0, 2, q{};
    }

  }
  return @out;
}









sub _section_to_stripped {
  my ($section) = @_;
  return $section->{content} if 'text' eq $section->{type};
  return q{};
}

sub strip_sections {
  my ($section_string) = @_;
  return join q{}, map { _section_to_stripped($_) } translate_sections($section_string);
}

sub _ansi_translation_table {
  return state $translation_table = {
    0 => 'black',
    1 => 'blue',
    2 => 'green',
    3 => 'cyan',
    4 => 'red',
    5 => 'magenta',
    6 => 'yellow',
    7 => 'white',
    8 => 'bright_black',
    9 => 'bright_blue',
    a => 'bright_green',
    b => 'bright_cyan',
    c => 'bright_red',
    d => 'bright_magenta',
    e => 'bright_yellow',
    f => 'bright_white',

    l => 'bold',
    m => 'concealed',
    n => 'underscore',
    o => 'reverse',

    r => 'reset',
  };
}

sub _warn {
  my (@args) = @_;
  return carp( sprintf '[%s] %s', __PACKAGE__, join q{ }, @args );
}

sub _warnf {
  my (@args) = @_;
  my $format = '[%s] ' . shift;
  return carp( sprintf $format, __PACKAGE__, @args );
}

sub _section_to_ansi {
  my ($section) = @_;
  return $section->{content} unless 'section' eq $section->{type};
  state $colorize = do {
    require Term::ANSIColor;
    \&Term::ANSIColor::color;
  };
  state $trt = _ansi_translation_table();
  my ($code) = $section->{section_code};
  if ( exists $trt->{$code} ) {
    return $colorize->( $trt->{$code} );
  }
  if ( exists $trt->{ lc $code } ) {
    _warnf( 'uppercase section code "%s" (ord=%s)', $section->{section_code}, ord $section->{section_code} );
    return $colorize->( $trt->{ lc $code } );
  }
  _warnf( 'unknown section code "%s" (ord=%s)', $section->{section_code}, ord $section->{section_code} );
  return '<unknown section ' . $section->{section_code} . '>';
}









sub ansi_encode_sections {
  my ($section_string) = @_;
  return join q{}, map { _section_to_ansi($_) } translate_sections($section_string);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Minecraft::SectionFilter - Strip/Process magical § characters from minecraft

=head1 VERSION

version 0.003003

=head1 SYNOPSIS

    use Minecraft::SectionFilter;
    while(<$some_stream_of_text>){
        if( $ENV{MODE} eq 'STRIP' ) {
            print(strip_sections($_))
        }
        else {
            print(ansi_encode_sections($_));
        }
    }

=head1 FUNCTIONS

=head2 translate_sections

Parse a string into a series of elements;

    my (@list) = translate_sections($string)

Resulting list will be a list of hashrefs, either:

    { type => text , content => "the string itself" }

or

    { type => section, section_code => $char }

=head2 strip_sections

Strip section codes from a string.

    my $output = strip_sections( $input );

=head2 ansi_encode_sections

Translate section codes to Term::ANSIColor color codes.

    STDOUT->print( ansi_encode_sections( $minecraft_string ) );

=head1 SEE ALSO

L<Minecraft::RCON|Minecraft::RCON> which has a similar feature, except its not user-acessible/reusable.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
