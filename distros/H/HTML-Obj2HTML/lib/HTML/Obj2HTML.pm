package HTML::Obj2HTML;

$HTML::Obj2HTML::VERSION = '0.11';

use strict;
use warnings;

use Carp;
use HTML::Entities;
use Text::Markdown;
use Text::Pluralize;
use Locale::Currency::Format;
use List::MoreUtils qw(uniq);
use Module::Pluggable require => 1;

use constant {
  END_TAG_OPTIONAL => 0x0,
  END_TAG_REQUIRED => 0x1,
  END_TAG_FORBIDDEN => 0x2,
  OBSOLETE => 0x4
};

# storage is a sort of top-level stash for an object. It doesn't have to be used
# you can get away with building your own object variable and passing it to "gen"
my $storage = [];
# Opts are simple storage that could be referred to in extensions (not typically
# in the base class). A good example is "readonly" (true/false)
my %opt;
# extensions are stored here
my %extensions = ();
# snippets are stored here
my $snippets = {};
# A dictionary of substitutions are stored here and can be referenced in _content_
my %dictionary;

my %dofiles;

# Whether or not to close empty tags with /
my $mode = "XHTML";
# Whether or not to output a warning when something that doesn't look like a valid
# html 5 tag is used
my $warn_on_unknown_tag = 1;
# Whether or not to use HTML::FromArrayref format ("elementname {attributes} content" triplets)
my $html_fromarrayref_format = 0;
# Default currency to use
my $default_currency = "GBP";

our $db;

# Load up the extensions
plugins();

sub import {
  my @extra = ();
  while (my $opt = shift) {
    if ($opt eq "components") {
      my $arg = shift;
      foreach my $file (split("\n", `find $arg -name "*.po"`)) {
        chomp($file);
        my $l = $file;
        $l =~ s/$arg\///;
        $l =~ s/\.po$//;
        $l =~ s/\//::/g;
        #print STDERR "HTML::Obj2HTML registering component $l\n";
        HTML::Obj2HTML::register_extension($l, {
          tag => "",
          before => sub {
            my $o = shift;
            if (ref $o eq "HASH") {
              return HTML::Obj2HTML::fetch($file, $o);
            } else {
              return HTML::Obj2HTML::fetch($file, { _ => $o });
            }
          }
        });
      }
    }
    elsif ($opt eq "default_currency") {
      $default_currency = shift;
    }
    elsif ($opt eq "mode") {
      $mode = shift;
    }
    elsif ($opt eq "warn_on_unknown_tag") {
      $warn_on_unknown_tag = shift;
    }
    elsif ($opt eq "html_fromarrayref_format") {
      $html_fromarrayref_format = shift;
    }
    else {
      push(@extra, $opt);
    }
  }
}

my %tags = (
  a => END_TAG_REQUIRED,
  abbr => END_TAG_REQUIRED,
  acronym => END_TAG_REQUIRED | OBSOLETE,
  address => END_TAG_REQUIRED,
  applet => END_TAG_REQUIRED | OBSOLETE,
  area => END_TAG_FORBIDDEN,
  article => END_TAG_REQUIRED,
  aside => END_TAG_REQUIRED,
  audio => END_TAG_REQUIRED,
  b => END_TAG_REQUIRED,
  base => END_TAG_FORBIDDEN,
  basefont => END_TAG_FORBIDDEN | OBSOLETE,
  bdi => END_TAG_REQUIRED,
  bdo => END_TAG_REQUIRED,
  big => END_TAG_REQUIRED | OBSOLETE,
  blockquote => END_TAG_REQUIRED,
  body => END_TAG_OPTIONAL,
  br => END_TAG_FORBIDDEN,
  button => END_TAG_REQUIRED,
  canvas => END_TAG_REQUIRED,
  caption => END_TAG_REQUIRED,
  center => END_TAG_REQUIRED,
  cite => END_TAG_REQUIRED,
  code => END_TAG_REQUIRED,
  col => END_TAG_FORBIDDEN,
  colgroup => END_TAG_REQUIRED,
  data => END_TAG_REQUIRED,
  datalist => END_TAG_REQUIRED,
  dd => END_TAG_OPTIONAL,
  del => END_TAG_REQUIRED,
  details => END_TAG_REQUIRED,
  dfn => END_TAG_REQUIRED,
  dialog => END_TAG_REQUIRED,
  dir => END_TAG_REQUIRED | OBSOLETE,
  div => END_TAG_REQUIRED,
  dl => END_TAG_REQUIRED,
  dt => END_TAG_OPTIONAL,
  em => END_TAG_REQUIRED,
  embed => END_TAG_FORBIDDEN,
  fielset => END_TAG_REQUIRED,
  figcaption => END_TAG_REQUIRED,
  figure => END_TAG_REQUIRED,
  font => END_TAG_REQUIRED | OBSOLETE,
  footer => END_TAG_REQUIRED,
  form => END_TAG_REQUIRED,
  frame => END_TAG_FORBIDDEN | OBSOLETE,
  frameset => END_TAG_REQUIRED | OBSOLETE,
  head => END_TAG_OPTIONAL,
  header => END_TAG_REQUIRED,
  hgroup => END_TAG_REQUIRED,
  h1 => END_TAG_REQUIRED,
  h2 => END_TAG_REQUIRED,
  h3 => END_TAG_REQUIRED,
  h4 => END_TAG_REQUIRED,
  h5 => END_TAG_REQUIRED,
  h6 => END_TAG_REQUIRED,
  hr => END_TAG_FORBIDDEN,
  html => END_TAG_OPTIONAL,
  i => END_TAG_REQUIRED,
  iframe => END_TAG_REQUIRED,
  img => END_TAG_FORBIDDEN,
  input => END_TAG_FORBIDDEN,
  ins => END_TAG_REQUIRED,
  kbd => END_TAG_REQUIRED,
  keygen => END_TAG_FORBIDDEN,
  label => END_TAG_REQUIRED,
  legend => END_TAG_REQUIRED,
  li => END_TAG_REQUIRED,
  link => END_TAG_FORBIDDEN,
  main => END_TAG_REQUIRED,
  map => END_TAG_REQUIRED,
  mark => END_TAG_REQUIRED,
  menu => END_TAG_REQUIRED,
  menuitem => END_TAG_FORBIDDEN,
  meta => END_TAG_FORBIDDEN,
  meter => END_TAG_REQUIRED,
  nav => END_TAG_REQUIRED,
  noframes => END_TAG_REQUIRED | OBSOLETE,
  noscript => END_TAG_REQUIRED,
  object => END_TAG_REQUIRED,
  ol => END_TAG_REQUIRED,
  optgroup => END_TAG_REQUIRED,
  option => END_TAG_OPTIONAL,
  output => END_TAG_REQUIRED,
  p => END_TAG_OPTIONAL,
  param => END_TAG_FORBIDDEN,
  picture => END_TAG_REQUIRED,
  pre => END_TAG_REQUIRED,
  progress => END_TAG_REQUIRED,
  q => END_TAG_REQUIRED,
  rp => END_TAG_REQUIRED,
  rt => END_TAG_REQUIRED,
  ruby => END_TAG_REQUIRED,
  s => END_TAG_REQUIRED,
  samp => END_TAG_REQUIRED,
  script => END_TAG_REQUIRED,
  section => END_TAG_REQUIRED,
  select => END_TAG_REQUIRED,
  small => END_TAG_REQUIRED,
  source => END_TAG_FORBIDDEN,
  span => END_TAG_REQUIRED,
  strike => END_TAG_REQUIRED | OBSOLETE,
  strong => END_TAG_REQUIRED,
  style => END_TAG_REQUIRED,
  sub => END_TAG_REQUIRED,
  summary => END_TAG_REQUIRED,
  sup => END_TAG_REQUIRED,
  svp => END_TAG_REQUIRED,
  table => END_TAG_REQUIRED,
  tbody => END_TAG_REQUIRED,
  td => END_TAG_REQUIRED,
  template => END_TAG_REQUIRED,
  textarea => END_TAG_REQUIRED,
  tfoot => END_TAG_REQUIRED,
  th => END_TAG_OPTIONAL,
  thead => END_TAG_REQUIRED,
  time => END_TAG_REQUIRED,
  title => END_TAG_REQUIRED,
  tr => END_TAG_OPTIONAL,
  track => END_TAG_FORBIDDEN,
  tt => END_TAG_REQUIRED | OBSOLETE,
  u => END_TAG_REQUIRED,
  ul => END_TAG_REQUIRED,
  var => END_TAG_REQUIRED,
  video => END_TAG_REQUIRED,
  wbr => END_TAG_FORBIDDEN
);

sub flush {
  %opt = ();
  %dictionary = ();
  $snippets = {};
}
sub set_opt {
  my $key = shift;
  my $val = shift;
  $opt{$key} = $val;
}
sub get_opt {
  my $key = shift;
  return $opt{$key};
}

sub set_dbh {
  $db = shift;
}

sub set_dictionary {
  my $hashref = shift;
  %dictionary = %{$hashref};
}
sub add_dictionary_items {
  my $hashref = shift;
  %dictionary = (%dictionary, %{$hashref});
}

sub set_snippet {
  my $name = shift;
  my $obj = shift;
  if (!ref $obj) {
    my $args = shift;
    $obj = fetch($obj, $args);
  }
  $snippets->{$name} = $obj;
}
sub get_snippet {
  my $name = shift;
  return $snippets->{$name};
}
sub append_snippet {
  my $name = shift;
  my $obj = shift;
  if (!defined $snippets->{$name}) {
    $snippets->{$name} = [];
  } elsif (ref $snippets->{$name} ne "ARRAY") {
    return;
  }
  if (!ref $obj) {
    my $args = shift;
    $obj = fetch($obj, $args);
  }
  push(@{$snippets->{$name}}, $obj);
}




sub do {
  HTML::Obj2HTML::print($storage);
}

sub init {
  $storage = shift;
}

sub sort {
  my $parentblock = shift;
  my $sortsub = shift;
  my $arr = shift;
  my @ret = ();

  foreach my $c (sort { $sortsub->($a,$b) } @$arr) {
    push(@ret, $parentblock, $c);
  }
  return \@ret;
}

sub iterate {
  my $parentblock = shift;
  my $arr = shift;
  my $collapsearrayrefs = shift || 0;
  my @ret = ();

  foreach my $c (@$arr) {
    if (ref($c) eq "ARRAY" && $collapsearrayrefs) {
      my $itr = iterate($parentblock, $c);
      push(@ret, @{$itr});
    } elsif (defined $c) {
      push(@ret, $parentblock, $c);
    }
  }
  return \@ret;
}

sub fetchraw {
  my $f = shift;
  # If we want an absolute path, use document root
  if ($f =~ /\//) {
    $f = $ENV{DOCUMENT_ROOT}.$f;
  }
  # And don't allow back-tracking through the file system!
  $f =~ s|\/[\.\/]+|\/|;
  my $rawfile;
  if (-e $f) {
    local($/);
    open(RAWFILE, $f);
    $rawfile = <RAWFILE>;
    close(RAWFILE);
  }
  return $rawfile;
}
sub fetch {
  my $f = shift;
  our $args = shift;
  my $fetch;
  if ($f !~ /^[\.\/]/) { $f = "./".$f; }
  if (-e $f) {
    $fetch = do($f);
    if (!$fetch) {
      if ($@) {
        carp "Do failed for $f at error: $@\n";
      }
      if ($!) {
        carp "Do failed for $f bang error: $!\n";
      }
    }
    if (ref $fetch eq "CODE") {
      $fetch = $fetch->($args);
    }

  } else {
    my $pwd = `pwd`;
    chomp($pwd);
    carp "Couldn't find $f ($pwd)\n";
    return [];
  }
  return $fetch;
}
sub display {
  my $f = shift;
  my $args = shift;
  my $ret = fetch($f, $args);
  print gen($ret);
}
sub push {
  my $arr = shift;
  my $f = shift;
  my $arg = shift;
  my $ret = fetch($f,$arg);
  push(@{$arr}, @{$ret});
}
sub append {
  my $insertpoint = shift;
  my $inserto = shift;
  my $args = shift;
  if (!ref $inserto && $inserto =~ /staticfile:(.*)/) {
    $inserto = HTML::Obj2HTML::fetchraw($1);
  } elsif (!ref $inserto && $inserto =~ /file:(.*)/) {
    $inserto = fetch($1, $args);
  }
  my $o = find($storage, $insertpoint);
  foreach my $e (@{$o}) {
    # convert to common format
    if (!ref $e->[1]) {
      $e->[1] = { _ => [ _ => $e->[1] ] };
    } elsif (ref $e->[1] eq "ARRAY") {
      $e->[1] = { _ => $e->[1] };
    }
    CORE::push(@{$e->[1]->{_}}, @{$inserto});
  }
}
sub prepend {
  my $insertpoint = shift;
  my $inserto = shift;
  my $args = shift;
  if (!ref $inserto && $inserto =~ /staticfile:(.*)/) {
    $inserto = HTML::Obj2HTML::fetchraw($1);
  } elsif (!ref $inserto && $inserto =~ /file:(.*)/) {
    $inserto = fetch($1, $args);
  }
  my $o = find($storage, $insertpoint);
  foreach my $e (@{$o}) {
    # convert to common format
    if (!ref $e->[1]) {
      $e->[1] = { _ => [ _ => $e->[1] ] };
    } elsif (ref $e->[1] eq "ARRAY") {
      $e->[1] = { _ => $e->[1] };
    }
    unshift(@{$e->[1]->{_}}, @{$inserto});
  }
}

sub find {
  my $o = shift;
  my $query = shift;
  my $ret = shift || [];

  my @tags = @{$o};
  while (@tags) {
    my $tag = shift(@tags);
    my $attr = shift(@tags);

    if (ref $attr eq "ARRAY") {
      find($attr, $query, $ret);
    } elsif (ref $attr eq "HASH") {
      my %attrs = %{$attr};
      my $content;
      if ($attrs{_}) {
        find($attrs{_}, $query, $ret);
      }
      if ($query =~ /\#(.*)/ && $attrs{id} eq $1) {
        CORE::push(@{$ret}, [$tag, $attr]);
      } elsif ($query =~ /^([^\#\.]\S*)/ && $tag eq $1) {
        CORE::push(@{$ret}, [$tag, $attr]);
      }
    }
  }
  return $ret;
}

sub gen {
  my $o = shift;
  my $ret = "";

  if (!ref $o) {
    $o = web_escape($o);
    return $o;
  }
  if (ref $o eq "HASH") {
    carp "HTML::Obj2HTML::gen called with a hash reference!";
    return "";
  }
  if (ref $o eq "CODE") {
    eval {
      $ret = HTML::Obj2HTML::gen($o->());
    };
    if ($@) { carp "Error parsing HTML::Obj2HTML objects when calling code ref: $@\n"; }
    return $ret;
  }
  if (ref $o ne "ARRAY") {
    return "";
  }

  my @tags = @{$o};
  while (@tags) {
    my $tag = shift(@tags);
    if (!defined $tag) {
      next;
    }
    if (ref $tag eq "ARRAY") {
      $ret .= HTML::Obj2HTML::gen($tag);
      next;
    }
    if (ref $tag eq "CODE") {
      eval {
        $ret .= HTML::Obj2HTML::gen($tag->());
      };
      if ($@) { carp "Error parsing HTML::Obj2HTML objects when calling code ref: $@\n"; }
      next;
    }
    if ($tag =~ /_(.+)/) {
      $ret .= HTML::Obj2HTML::gen(get_snippet($1));
      next;
    }
    # If the tag has a space it's not a valid tag, so output it as content instead
    if ($tag =~ /\s/) {
      $ret .= $tag;
      next;
    }

    my $attr = shift(@tags);
    if ($html_fromarrayref_format) {
      # Make this module behave more like HTML::FromArrayref, where you have elementname, { attributes }, content
      # This should be considered for backward compatibility; The find routine would struggle with this...
      if (ref $attr eq "HASH" && ($tags{$tag} & END_TAG_FORBIDDEN) == 0) {
        $attr->{"_"} = shift(@tags);
      }
    }
    # Typically linking to another file will return an arrayref, but could equally return a hashref to also set the
    # attributes of the element calling it
    if (!ref $attr && $attr =~ /staticfile:(.+)/) {
      $attr = HTML::Obj2HTML::fetchraw($1);
    } elsif (!ref $attr && $attr =~ /file:(.+)/) {
      $attr = HTML::Obj2HTML::fetch($1);
    } elsif (!ref $attr && $attr =~ /raw:(.+)/) {
      $attr = HTML::Obj2HTML::fetchraw($1);
    }

    # Run the current tag through extentions
    my $origtag = $tag;
    if (defined $extensions{$origtag}) {
      if (defined $extensions{$origtag}->{scalarattr} && !ref $attr) { $attr = { $extensions{$origtag}->{scalarattr} => $attr }; }

      if (defined $extensions{$origtag}->{before}) {
        my $o = $extensions{$origtag}->{before}($attr);
        if (ref $o eq "ARRAY") {
          $ret .= HTML::Obj2HTML::gen($o);
        } elsif (ref $o eq "") {
          $ret .= $o;
        }
      }

      if (defined $extensions{$origtag}->{tag}) {
        $tag = $extensions{$origtag}->{tag};
      }
      if (defined $extensions{$origtag}->{attr}) {
        if (ref $attr ne "HASH") {
          $attr = { _ => $attr };
        }
        foreach my $k (keys %{$extensions{$origtag}->{attr}}) {
          if (defined $attr->{$k}) {
            $attr->{$k} = $extensions{$origtag}->{attr}->{$k}." ".$attr->{$k};
            if ($k eq "class") {
              $attr->{$k} = join(" ", uniq(split(/\s+/, $attr->{$k})));
            }
          } else {
            $attr->{$k} = $extensions{$origtag}->{attr}->{$k};
          }
        }
      }

      if (defined $extensions{$origtag}->{replace}) {
        my $o = HTML::Obj2HTML::gen($extensions{$origtag}->{replace}($attr));
        if (ref $o eq "HASH") {
          $ret .= HTML::Obj2HTML::gen($o);
        } elsif (ref $o eq "") {
          $ret .= $o;
        }
        $tag = "";
      }
    }

# Non-HTML functions
    if ($tag eq "_") {
      if (ref $attr) {
        carp("HTML::Obj2HTML: _ element called, but attr wasn't a scalar.");
      } else {
        $ret .= web_escape($attr);
      }

    } elsif ($tag eq "raw") {
      if (ref $attr) {
        carp("HTML::Obj2HTML: raw element called, but attr wasn't a scalar.");
      } else {
        $ret .= "$attr";
      }

    } elsif ($tag eq "if") {
      if (ref $attr eq "HASH") {
        if ($attr->{cond} && $attr->{true}) {
          $ret .= HTML::Obj2HTML::gen($attr->{true});
        } elsif (!$attr->{cond} && $attr->{false}) {
          $ret .= HTML::Obj2HTML::gen($attr->{false});
        }
      } elsif (ref $attr eq "ARRAY") {
        for (my $i = 0; $i<$#{$attr}; $i+=2) {
          if ($attr->[$i]) {
            $ret .= HTML::Obj2HTML::gen($attr->[$i+1]);
            last;
          }
        }
      } else {
        carp("HTML::Obj2HTML: if element called, but attr wasn't a hash ref or array ref.");
      }
    } elsif ($tag eq "switch") {
      if (ref $attr eq "HASH") {
        if (defined $attr->{$attr->{val}}) {
          $ret .= HTML::Obj2HTML::gen($attr->{$attr->{val}});
        } elsif (defined $attr->{"_default"}) {
          $ret .= HTML::Obj2HTML::gen($attr->{"_default"});
        } elsif (defined $attr->{"_"}) {
          $ret .= HTML::Obj2HTML::gen($attr->{"_"});
        }
      } else {
        carp("HTML::Obj2HTML: switch element called, but attr wasn't a hash ref.");
      }

    } elsif ($tag eq "md") {
      if (ref $attr) {
        carp("HTML::Obj2HTML: md element called, but attr wasn't a scalar.");
      } else {
        $ret .= markdown($attr);
      }

    } elsif ($tag eq "plain") {
      if (ref $attr) {
        carp("HTML::Obj2HTML: plain element called, but attr wasn't a scalar.");
      } else {
        $ret .= plain($attr);
      }

    } elsif ($tag eq "currency") {
      if (ref $attr eq "HASH") {
        $ret .= web_escape(currency_format($attr->{currency} || $default_currency, $attr->{"_"}, FMT_SYMBOL));
      } elsif (!ref $attr) {
        $ret .= web_escape(currency_format($default_currency, $attr, FMT_SYMBOL));
      } else {
        carp("HTML::Obj2HTML: currency called, but attr wasn't a hash ref or plain scalar.");
      }

    } elsif ($tag eq "pluralize") {
      if (ref $attr eq "ARRAY") {
        $ret .= pluralize($attr->[0], $attr->[1]);
      } else {
        carp("HTML::Obj2HTML: pluralize called, but attr wasn't a array ref");
      }

    } elsif ($tag eq "include") {
      $ret .= HTML::Obj2HTML::gen(HTML::Obj2HTML::fetch($o->{src}.".po", $attr));

    } elsif ($tag eq "javascript") {
      $ret .= "<script language='javascript' type='text/javascript' defer='1'><!--\n$attr\n//--></script>";

    } elsif ($tag eq "includejs") {
      if (!ref $attr) {
        $ret .= "<script language='javascript' type='text/javascript' defer='1' async='1' src='$attr'></script>";
      } elsif (ref $attr == "HASH") {
        $ret .= "<script language='javascript' type='text/javascript' ";
        if ($attr->{defer}) {
          $ret .= "defer='1' ";
        }
        if ($attr->{async}) {
          $ret .= "async='1' ";
        }
        $ret .= "src='$attr->{src}'></script>";
      }


    } elsif ($tag eq "includecss") {
      $ret .= "<link rel='stylesheet' type='text/css' href='$attr' />";

    } elsif ($tag eq "doctype") {
      $ret .= "<!DOCTYPE $attr>";

    } elsif (ref $attr eq "HASH" && defined $attr->{removeif} && $attr->{removeif}) {
      $ret .= HTML::Obj2HTML::gen($attr->{_});

    # Finally through all the non-HTML elements ;)
    } elsif ($tag) {

      # It's perfectly allowed to omit content from a tag where the end tag was forbidden
      # If we have content, we have to assume that it should appear after the
      # tag - not discard it, or show it within
      # If we've got a hash ref though, we have attributes :)
      # Note that this has to go here, because the attribute might have been a staticfile: or similar
      # to execute some additional code
      if ($tags{$tag} & END_TAG_FORBIDDEN && ref $attr ne "HASH") {
        unshift(@tags, $attr);
        $attr = undef;
      }

      if ($warn_on_unknown_tag && !defined $tags{$tag}) {
        carp "Warning: Unknown tag $tag in HTML::Obj2HTML\n";
      }

      $ret .= "<$tag";
      if (!defined $attr) {
        if ($tags{$tag} & END_TAG_FORBIDDEN) {
          if ($mode eq "XHTML") {
            $ret .= " />";
          } else {
            $ret .= ">";
          }
        } elsif ($tags{$tag} & END_TAG_REQUIRED) {
          $ret .= "></$tag>";
        }

      } elsif (ref $attr eq "ARRAY") {
        $ret .= ">";
        $ret .= HTML::Obj2HTML::gen($attr);
        $ret .= "</$tag>";

      } elsif (ref $attr eq "HASH") {
        my %attrs = %{$attr};
        my $content;
        foreach my $k (keys(%attrs)) {
          if (ref $k eq "ARRAY") {
            $content = $k;

          } elsif (ref $attrs{$k} eq "ARRAY") {
            # shorthand, you can defined the content within the classname, e.g. div => { "ui segment" => [ _ => "Content" ] }
            if ($k ne "_") {
              $ret .= format_attr("class", $k);
            }
            $content = $attrs{$k} || '';

          } elsif (ref $attrs{$k} eq "HASH") {

            if ($k eq "style") {
              my @styles = ();
              while (my ($csskey, $cssval) = each(%{$attrs{$k}})) {
                CORE::push(@styles, $csskey.":".$cssval.";");
              }
              $ret .= format_attr("style", join("",@styles));
            } elsif ($k eq "if") {
              my $val = $attrs{$k};
              if ($val->{cond} && $val->{true}) {
                foreach my $newk (keys(%{$val->{true}})) {
                  $ret .= format_attr($newk, $val->{true}->{$newk})
                }
              } elsif (!$val->{cond} && $val->{false}) {
                foreach my $newk (keys(%{$val->{false}})) {
                  $ret .= format_attr($newk, $val->{false}->{$newk})
                }
              }
            } elsif (defined $attrs{$k}->{if}) {
              if ($attrs{$k}->{if} && defined $attrs{$k}->{true}) {
                $ret .= format_attr($k, $attrs{$k}->{true});
              } elsif (!$attrs{$k}->{if} && defined $attrs{$k}->{false}) {
                $ret .= format_attr($k, $attrs{$k}->{false});
              }
            }

          } elsif ($k eq "_") {
            $content = $attrs{$k} || '';

          } else {
            $ret .= format_attr($k, $attrs{$k});
          }
        }
        if ($tags{$tag} & END_TAG_FORBIDDEN) {
          # content is also forbidden!
          if ($mode eq "XHTML") {
            $ret .= " />";
          } else {
            $ret .= ">";
          }
        } elsif (defined $content) {
          $ret .= ">";
          $ret .= HTML::Obj2HTML::gen($content);
          $ret .= "</$tag>";
        } elsif ($tags{$tag} & END_TAG_REQUIRED) {
          $ret .= "></$tag>";
        } else {
          if ($mode eq "XHTML") {
            $ret .= " />";
          } else {
            $ret .= ">";
          }
        }
      } elsif (ref $attr eq "CODE") {
        $ret .= ">";
        eval {
          $ret .= gen($attr->());
        };
        $ret .= "</$tag>";
        if ($@) { warn "Error parsing HTML::Obj2HTML objects when calling code ref: $@\n"; }
      } elsif (ref $attr eq "") {
        my $val = web_escape($attr);
        $ret .= ">$val</$tag>";
      }
    }

    if (defined $extensions{$origtag} && defined $extensions{$origtag}->{after}) {
      $ret .= $extensions{$origtag}->{after}($attr);
    }

  }
  return $ret;
}

sub format_attr {
  my $k = shift;
  my $val = shift;
  $val = web_escape($val);
  if (defined $val) {
    return " $k=\"$val\"";
  }
  return "";
}
sub substitute_dictionary {
  my $val = shift;
  $val =~ s/%([A-Za-z0-9]+)%/$dictionary{$1}/g;
  return $val;
}
sub web_escape {
  my $val = shift;
  $val = HTML::Entities::encode($val);
  $val = substitute_dictionary($val);
  return $val;
}
sub plain {
  my $txt = shift;
  $txt = web_escape($txt);
  $txt =~ s|\n|<br />|g;
  return $txt;
}
sub markdown {
  my $txt = shift;
  $txt = substitute_dictionary($txt);
  my $m = new Text::Markdown;
  my $val = $m->markdown($txt);
  return $val;
}

sub print {
  my $o = shift;
  print gen($o);
}

sub format {
  my $plain = shift;
  $plain =~ s/\n/<br \/>/g;
  return [ raw => $plain ];
}

sub register_extension {
  my $tag = shift;
  my $def = shift;
  my $flags = shift;
  $extensions{$tag} = $def;
  if (defined $flags) {
    $tags{$tag} = $flags;
  } else {
    $tags{$tag} = END_TAG_OPTIONAL;
  }
}

1;
__END__

=pod

=head1 NAME

HTML::Obj2HTML - Create HTML from a arrays and hashes

=head1 SYNOPSYS

    use HTML::Obj2HTML (components => 'path/to/components', default_currency => 'GBP', mode => 'XHTML', warn_on_unknown_tag => 1, html_fromarrayref_format => 0)

=over 4

=item * C<components>

This is the relative path from the current working directory to components.
Obj2HTML will find all *.po files and automatically register elements that when
called within your object executes the file. (See C<fetch()>)

=item * C<default_currency>

Which currency to format output for when encountering the built in C<currency>
element.

=item * C<mode>

XHTML or HTML

=item * C<warn_on_unknown_tag>

Whether or not to print a warning to STDERR (using carp) when encountering an
element that doesn't look like an HTML element, or registered extension element

=item * C<html_fromarrayref_format>

This module accepts two formats for conversion; one is an HTML::FromArrayref
style arrayref, one is a variation. Differences are noted below.

=back

=head2 Usage

    set_opt('opt-name','value');
    set_dictionary(\%dictionary);
    add_dictionary_items(\%dictionary_items);
    set_snippet('snippet-name', \@Obj2HTMLItems);
    register_extension('element-name', \%definition);

    $result_html = gen(\@Obj2HTMLItems);

An Obj2HTML arrayref is a structure that when processed is turned into HTML.
Without HTML::FromArrayref format eanbled, it looks like this:

    [
       doctype => "HTML",
       html => [
         head => [
           script => { ... },
         ],
         body => { class => 'someclass', _ => [
           h1 => "Test page",
           p => "This is my test page!"
         ]}
       ]
    ];

=head2 Builtin Features

=over 4

=item Add a snippet with _snippet-name syntax

    [
      div => _snippet
    ]

=item Execute a subroutine at generate time

    [
      div => \&generate_something
    ]

=item Ignore things that don't look like elements at all; treat them like content

    [
      p => [
        "I really ",
        b => "really",
        " want an ice-cream"
      ]
    ]

=item Add raw content to the mix

    [
      div => [
        raw => "<h1>Add some HTML directly</h1>"
      ]
    ]

=item Add conditional output

    [
      div => [
        if => { cond => $loggedin, true => "You are logged in!", false => "Log in now!" }
      ]
    ]

You can also use [cond,true,false] syntax.

    [
      div => [
        if => [$loggedin, "You are logged in!", "Log in now!"]
      ]
    ]

=item Switch statement

    [
      div => [
        switch => { val => $permissionlvl, user => "You are a normal user", admin => "You are an admin! Well done you!" }
      ]
    ]

=item Add Markdown with Text::Markdown

    [
      div => [
         md => "**What** do you think you're doing?"
      ]
    ]

=item Or Plain text

    [
      div => [
        plain => "This is unformated text"
      ]
    ]

=item Format Currency with Locale::Currency::Format

    [
      div => [
        "You own us ",
        currency => $amount
      ],
      div => [
        "Or if you'd rather pay in USD, ",
        currency => { currency => "USD", _ => $converted_amount}
      ]
    ]

=item Pluralize with Text::Pluralize

    [
      div => [
        pluralize => ["You have %d item(s) in your basket", $items]
      ]
    ]

=item Include other files that output Obj2HTML formatted objects

    [
       div => include("path/to/file")
    ]

=item Add some javascript

    [
      javascript => q`
$(function) {
  alert("Hi");
};
`
    ]

=item Or include a javascript file (<script src=...>)

    [
      head => [
        includejs => "uri/to/js"
      ]
    ]

=item Conditions in element attributes (experimental)

    [
      div => { if => { cond => $loggedin, true => { class => "green"}, false => { class => "red" } } _ => "My Account" }
    ]

=item Code instead of element attributes (expects back hashref)

    [
      div => \&gen_attributes
    ]

=item Registering Components

You can break apart complex sections of your page into reusable components.
Suppose you create some login modal form and wish to include it on every page
if the user is not logged in. You might therefore define a file called
C<components/account/loginform.po> and then reference the component from your
Obj2HTML object:

    [
      if => [$loggedin, account::loginform => { session => $session }, []]
    ]

Whenever you use a component in this way the contents of the hashref are passed
to the component as $args.

The component is called using a perl 'do'. If the result of calling the file
is a coderef, the coderef is cached and the file is not called directly again.
The coderef is then called with a single argument, the $args hashref.

=item Registering Extensions

Components are called when needed. A better approach for heavily used, more
complex elements would be to create a plugin from which you define your element
as an extention.

Within your Plugin you would:

     HTML::Obj2HTML::register_extension("grid", {
       tag => "div",
       attr => { class => "ui grid" }
     }, END_TAG_REQUIRED);

     HTML::Obj2HTML::register_extension("column", {
       tag => "div",
       attr => { class => "column" }
     }, END_TAG_REQUIRED);

Then within your Obj2HTML object, you can:

    [
      grid => [
        column => "Hello World!"
      ]
    ]

Which renders to:

    <div class='ui grid'><div class='column'>Hello World!</div></div>

=back

=head1 Plugins

Plugins provide a way to extend what is understood as an element in the
Obj2HTML structure. The format for creating extensions is as follows:

    HTML::Obj2HTML::register_extension($element_name, \%definition, $type);

=over 4

=item * C<$element_name> is a string; this is what the element is called

=item * C<\%definition> is a hashref containing elements to define what happens
when an element with this name is encountered

=item * C<$type> is a set of flags defining special conditions for the element

=back

=head2 Plugin Definition

=over 4

=item * before => &before_sub

When the element is encountered, the attribute that follows the element is
passed to the function before_sub, and whatever is returned from before_sub
is added to the HTML stream before the tag being processed is added. Note
that you can further supress generation of the current element by setting the
C<tag> element to an empty string.

    HTML::Obj2HTML::register_extension("line", {
        tag => "hr",
        before => sub {
          return [ div => "Here comes a line!" ];
        }
    }, END_TAG_FORBIDDEN);

When parsing the following:

    [
      line => {}
    ]

Will generate:

    <div>Here comes a line!</div><hr />

=item * tag => $string

This will translate your C<$element_name> into C<$tag>. For example:

    HTML::Obj2HTML::register_extension("line", {
        tag => "hr"
    }, END_TAG_FORBIDDEN);

When parsing the following:

    [
      div => [
        line
      ]
    ]

Will generate:

    <div><hr /></div>

Setting $string to an empty string (C<tag => "">) results in no HTML being
generated, aside that produced from before, replace and after.

=item * attr => \%attributes

The attributes defined here will be combined with the attributes given in
the parsed Obj2HTML object. For example:

    HTML::Obj2HTML::register_extension("line", {
        tag => "hr",
        attr => { class => "ui seperator", style => "display: block" }
    }, END_TAG_FORBIDDEN);

When parsing the following:

    [
      div => [
        line => { class => "red", "data-lineid" => 1 }
      ]
    ]

Will generate:

    <div><hr class = "ui seperator red" style = "display: block" data-lineid = "1" /></div>

=item * scalarattr => $string

If a scalar is passed with the element in the Obj2HTML object, this will be
used as the value for the attribute called $string. For example:

    HTML::Obj2HTML::register_extension("line", {
        tag => "hr",
        scalarattr => "class"
    }, END_TAG_FORBIDDEN);

When parsing the following:

    [
      div => [
        line => "red"
      ]
    ]

Will generate:

    <div><hr class = "red" /></div>

=item * replace => \&replace_sub

The entire element is replaced with the output of replace_sub($attr), where
$attr is whatever was passed after the original element in the Obj2HTML.

If the return value of the replace_sub is an arrayref, it is passed back through
HTML::Obj2HTML::gen.

This will automatically set tag to an empty string, so the original element
is not generated.

=item * after => \&after_sub

Similar to before, this defines code that will run after the tag has been
inserted.

=back

=head2 Ordering is important!

Here's an example of using before and after to produce tabs:

    my @tabs = ();
    my @content = ();
    HTML::Obj2HTML::register_extension("tabsection", {
      tag => "",
      before => sub {
        my $obj = shift;
        @curtabs = ();
        @content = ();
        return HTML::Obj2HTML::gen($obj);
      },
      after => sub {
        my $obj = shift;
        my $divinner = {
          class => "ui tabular menu",
          _ => \@tabs
        };
        if (ref $obj eq "HASH") {
          foreach my $k (%{$obj}) {
            if (defined $divinner->{$k}) { $divinner->{$k} .= " ".$obj->{$k}; } else { $divinner->{$k} = $obj->{$k}; }
          }
          return HTML::Obj2HTML::gen([ div => $divinner, \@content ]);
        } else {
          return HTML::Obj2HTML::gen([ div => { class => "ui top attached tabular menu", _ => \@tabs }, \@content ]);
        }
      }
    });
    HTML::Obj2HTML::register_extension("tab", {
      tag => "",
      before => sub {
        my $obj = shift;
        if ($obj->{class}) { $obj->{class} .= " "; }
        if ($obj->{active}) { $obj->{class} .= "active "; }
        push(@tabs, div => { class => $obj->{class}."item", "data-tab" => $obj->{tab}, _ => $obj->{label} });
        push(@content, div => { class => $obj->{class}."ui bottom attached tab segment", "data-tab" => $obj->{tab}, _ => $obj->{content} });
        return "";
      }
    });

Now all I need to do to generate tabs and contents is:

    [
      tabsection => [
        tab => { active => 1, tab => "intro", label => "Introduction", content => "Here's my intro" },
        tab => { tab => "detail", label => "Detail", content => "And some content!" }
      ]
    ]

This produces a <div> containing the tabs themselves, then each individual tab
content in it's own <div>. See the Semantic UI tabs examples for details!

=head1 WHY

Have you ever built a really complex web page, with many parts replicated with
other pages, sections of page that should only be shown in some circumstances?

Do you get frustrated making edits to HTML to add or remove an element level,
and needing to try to figure out where the end tag should go/needs to be removed
from?

Then this module is for you. This module allows you to build up an HTML like
page, using manipulatable array and hash refs, with added features like
embedding conditionals and coderefs that will only be executed right at the
last moment, while rendering the HTML. This allows true separation of
controller and view!

One of my favorite features is defining a single view that contains a form, but
changing the form into a readonly display of the data simply by performing a
C<set_opt("readonly",1)>. And I don't just mean adding readonly to the form
elements - I mean removing the form elements entirely and leaving just the
values!

=head2 Benefits

1. Providing a more extensible way of parsing a perl objects into HTML objects,
including being able to create framework specific "plugins" that broaden what
you can do

2. Providing the option to provide the content from within an attributes hash.
This simplifies parsing and allows you to do something like:

    div => { class => "segment", _ => "Some text" }

    div => { segment => [ "Some text" ] }

But you can tell this module to use the HTML::FromArrayref syntax, in which case
you would need to do:

    div => { class => "segment" }, "Some text"

This module is also aware of tags that should not have an end tag; you don't
need to provide anything more than the element name

   p => [ "My first paragraph", br, "The next line" ]

But you can of course still provide attributes:

    hr => { class => "ui seperator" }

3. Providing extensions via plugins

Using HTML::Obj2HTML::register_extension you can define your own element and how it
should be treated. It can be a simple substitution:

    HTML::Obj2HTML::register_extension("line", {
        tag => "hr",
        attr => { class => "ui seperator" }
    });

Therefore:

    line => { class => "red" }

Would yield:

    <hr class='ui seperator red' />

Or you can define "before" and "after" subroutines to be executed, which can
return larger pieces of rat HTML or an HTML::Obj2HTML object to be processed.

4. Providing components. Via a plugin you can also create full compents in files
that are execute as perl scripts. These can return HTML::Obj2HTML objects to be
further processed.

All in all, this looks a feels a bit like React, but for Perl (and with vastly
different syntax).

=head1 SEE ALSO

Previous attempts to do this same sort of thing:

=over 4

=item * C<HTML::LoL (last updated 2002)>
=item * C<HTML::FromArrayref (last updated 2013)>
=item * C<XML::FromArrayref (last updated 2013)>

=back

How this is used in Dancer: C<Dancer2::Template::Obj2HTML>

And a different way of routing based on the presence of files, which are
processed as C<HTML::Obj2HTML> objects if they return an arrayref:
C<Dancer2::Plugin::DoFile>
