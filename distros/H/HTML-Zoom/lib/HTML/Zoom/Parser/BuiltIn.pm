package HTML::Zoom::Parser::BuiltIn;

use strictures 1;
use base qw(HTML::Zoom::SubObject);

sub html_to_events {
  my ($self, $text) = @_;
  my @events;
  _hacky_tag_parser($text => sub { push @events, $_[0] });
  return \@events;
}

sub html_to_stream {
  my ($self, $text) = @_;
  return $self->_zconfig->stream_utils
              ->stream_from_array(@{$self->html_to_events($text)});
}

# DO NOT BE AFRAID.
#
# Well, ok. Be afraid. A little. But this is lexing HTML with a regexp,
# not really parsing (since the structure nesting isn't handled here) so
# it's relatively not dangerous.
#
# Certainly it's not really any more or any less heinous than anything else
# I could do in a handful of lines of pure perl.

sub _hacky_tag_parser {
  my ($text, $handler) = @_;
  $text =~ m{^([^<]*)}g;
  if ( length $1 ) { # leading PCDATA
      $handler->({ type => 'TEXT', raw => $1 });
  }
  while (
    $text =~ m{
      (
        (?:[^<]*) < (?:
            ( / )? ( [^/!<>\s"'=]+ )
            ( (?:"[^"]*"|'[^']*'|[^/"'<>])+? )?
        |   
            (!-- .*? -- | ![^\-] .*? )
        ) (\s*/\s*)? >
      )
      ([^<]*)
    }sxg
  ) {
    my ($whole, $is_close, $tag_name, $attributes, $is_special,
        $in_place_close, $content)
      = ($1, $2, $3, $4, $5, $6, $7, $8);
    if ($is_special) {
      $handler->({ type => 'SPECIAL', raw => $whole });
    } else {
      $tag_name =~ tr/A-Z/a-z/;
      if ($is_close) {
        $handler->({ type => 'CLOSE', name => $tag_name, raw => $whole });
      } else {
        $attributes = '' if !defined($attributes) or $attributes =~ /^ +$/;
        $handler->({
          type => 'OPEN',
          name => $tag_name,
          is_in_place_close => $in_place_close,
          _hacky_attribute_parser($attributes),
          raw_attrs => $attributes||'',
          raw => $whole,
        });
        if ($in_place_close) {
          $handler->({
            type => 'CLOSE', name => $tag_name, raw => '',
            is_in_place_close => 1
          });
        }
      }
    }
    if (length $content) {
      $handler->({ type => 'TEXT', raw => $content });
    }
  }
}

sub _hacky_attribute_parser {
  my ($attr_text) = @_;
  my (%attrs, @attr_names);
  while (
    $attr_text =~ m{
      ([^\s\=\"\']+)(\s*=\s*(?:(")(.*?)"|(')(.*?)'|([^'"\s=]+)['"]*))?
    }sgx
  ) {
    my $key  = $1;
    my $test = $2;
    my $val  = ( $3 ? $4 : ( $5 ? $6 : $7 ));
    my $lckey = lc($key);
    if ($test) {
      $attrs{$lckey} = _simple_unescape($val);
    } else {
      $attrs{$lckey} = $lckey;
    }
    push(@attr_names, $lckey);
  }
  (attrs => \%attrs, attr_names => \@attr_names);
}

sub _simple_unescape {
  my $str = shift;
  $str =~ s/&quot;/"/g;
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&amp;/&/g;
  $str;
}

sub _simple_escape {
  my $str = shift;
  $str =~ s/&/&amp;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str;
}

sub html_escape { _simple_escape($_[1]) }

sub html_unescape { _simple_unescape($_[1]) }

1;
