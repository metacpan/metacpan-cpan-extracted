package MSWord::ToHTML::Roles::HasHTML;
{
  $MSWord::ToHTML::Roles::HasHTML::VERSION = '0.010';
}

use Moose::Role;
use namespace::autoclean;
use strictures 1;
use MSWord::ToHTML::HTML;
use MooseX::Method::Signatures;
use Digest::SHA1 qw/sha1_hex/;
use XML::LibXML;
use XML::LibXSLT;
use IO::All;
use Try::Tiny;
use autodie;
use HTML::HTML5::Writer;
use HTML::TreeBuilder;
use HTML::Entities;
use Encode;
use Encode::Guess;
use CSS;
use List::MoreUtils qw/any/;
use Path::Class::File;
use Cwd;
use feature 'say';

has 'style' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->parser->load_xml(
            location =>
                'http://docbook.sourceforge.net/release/xsl/current/xhtml-1_1/docbook.xsl',
            no_cdata => 1
        );
    },
);

has 'parser' => (
    is      => 'ro',
    isa     => 'XML::LibXML',
    lazy    => 1,
    default => sub {
        XML::LibXML->new;
    },
);
has 'transformer' => (
    is      => 'ro',
    isa     => 'XML::LibXSLT',
    lazy    => 1,
    default => sub {
        XML::LibXSLT->new;
    },
);

has 'writer' => (
    is      => 'ro',
    isa     => 'HTML::HTML5::Writer',
    lazy    => 1,
    default => sub {
        HTML::HTML5::Writer->new( markup => 'html' );
    },
);

has 'css' => (
    is      => 'ro',
    isa     => 'CSS',
    lazy    => 1,
    default => sub {
        CSS->new(
            {   'parser' => 'CSS::Parse::Heavy',
                adaptor  => 'CSS::Adaptor::Debug'
            }
        );
    },
);

has 'html5_parser' => (
    is      => 'ro',
    isa     => 'HTML::HTML5::Parser',
    lazy    => 1,
    default => sub {
        return HTML::HTML5::Parser->new;
    },
);

method get_html {
    my $base_html = $self->extract_base_html(@_);
    return $self->html_to_html5($base_html);
}

method get_dom($file) {
    return $self->parser->parse_file($file);
}

method extract_base_html {
    my $new_file =
      io->catfile( io->tmpdir, sha1_hex( $self->file->slurp ) . '.html' );
    system( 'libreoffice', '--convert-to', 'html', '--invisible', '--headless', '--minimized', $self->file );
    # We have to construct the filename, because libreoffice does not take
    # file destination arguments. Blech.
    (my $oo_file = $self->file) =~ s/\.doc.*$/.html/;
    my $oo_file_obj = Path::Class::File->new($oo_file);
    my $oo_file_name = $oo_file_obj->basename;
    $oo_file = Path::Class::File->new(getcwd, $oo_file_name);

    system('mv', $oo_file, $new_file);
    return $self->pre_clean_html($new_file);
}

method prepare_charset($html) {
    return utf8::decode($html)
      if utf8::is_utf8($html);
    my $decoder = Encode::Guess->guess($html);
    if ( ref($decoder) ) {
      return $decoder->decode($html);
    }
    else {
      return $html;
    }
}

method pre_clean_html($html) {
    my $text         = $self->prepare_charset( $html->all );
    # Remove some extra-stupid Word tags
    $text =~ s/<a name="_GoBack".*?<\/a>//gis;
    $text =~ s/<a id="_GoBack".*?<\/a>//gis;
    # Rename footnote/endnote name attrs so they don't collide with the ids that
    # tidy would turn them into. Tidy doesn't like names and ids to match.
    $text =~ s/name="sdfootnote(\d+)(anc|sym)"/name="sdfootnote$1$2" id="sdfootnote$1$2-id"/gi;
    $text =~ s/name="sdendnote(\d+)(anc|sym)"/name="sdendnote$1$2" id="sdendnote$1$2-id"/gi;
    # Remove invalid XML characters
    $text =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;
    my $tree_builder = HTML::TreeBuilder->new;
    my $tree         = $tree_builder->parse($text);
    my @brs          = $tree->look_down('_tag', 'br');
    my @ps           = $tree->look_down( '_tag', 'p' );
    my @spans        = $tree->look_down( '_tag', 'span' );

    # Delete brs
    for my $break (@brs) {
        $break->delete;
    }

    # Destyle <p>s and <span>s.
    for my $verbose (@ps) {
      $verbose->attr( 'dir', undef );
      $verbose->attr( 'style', undef );
      $verbose->attr( 'class', undef );
      $verbose->attr( 'xml:lang', undef );
      $verbose->attr( 'lang',     undef );
    }
    for my $verbose (@spans) {
      $verbose->attr( 'xml:lang', undef );
      $verbose->attr( 'lang',     undef );
    }

    my @all_ps = $tree->look_down( '_tag', 'p' );
    for my $all_p (@all_ps) {
      foreach my $content ( $all_p->content_refs_list ) {
        next if ref $$content;
        $$content =~ s/\s+//g  if $$content =~ /\A\s+\z/;
        $$content =~ s/\R/ /g  if $$content =~ /\R/;
        $$content =~ s/\s+/ /g if $$content =~ /\s+/;
      }
    }

    my @all_spans = $tree->look_down( '_tag', 'span' );
    for my $all_span (@all_spans) {
      foreach my $content ( $all_span->content_refs_list ) {
        next if ref $$content;
        $$content =~ s/\s+//g  if $$content =~ /\A\s+\z/;
        $$content =~ s/\R/ /g  if $$content =~ /\R/;
        $$content =~ s/\s+/ /g if $$content =~ /\s+/;
      }
    }

    my $file = io("$html")->utf8->print( $tree->as_HTML );
    $tree->delete;
    return $file;
}

method post_clean_html( IO::All $html, Str $title) {
    my $tree_builder = HTML::TreeBuilder->new;
    my $tree = $tree_builder->parse( HTML::Entities::decode( $html->all ) );

    my $html_tag = $tree->look_down( '_tag', 'html' );
    $html_tag->attr( 'xmlns', undef );

    my $meta = $tree->look_down( '_tag', 'meta', 'name', 'generator' );
    $meta->delete;

    my $title_obj = $tree->look_down( '_tag', 'title' );
    if ($title) {
      foreach my $title_content ( $title_obj->content_refs_list ) {
        next if ref $$title_content;
        $$title_content = $title;
      }
    }

    my @style_tags = $tree->look_down( '_tag', 'style' );

    for my $style (@style_tags) {
      my $parsed_style;
      {
        local *STDERR;
        local *STDOUT;
        open( STDOUT, '>', File::Spec->devnull() );
        open( STDERR, '>', File::Spec->devnull() );
        $parsed_style = $self->css->read_string( $style->as_HTML );
      }
      next unless $parsed_style;
      my @selectors;
      for my $parsed (@$parsed_style) {
        push @selectors, $parsed->selectors;
      }
      if ( any { $_ =~ /#toc/ } @selectors ) {
        $style->delete;
      }
    }

    $tree = $self->filter_css($tree);

    ### Final cleaning...

    my @ps = $tree->look_down( '_tag', 'p' );
    for my $p (@ps) {
      $p->attr( 'class', undef );
      $p->attr( 'style', undef );
    }

    my @spans = $tree->look_down( '_tag', 'span' );
    for my $s (@spans) {
      $s->attr( 'class', undef );
      $s->attr( 'style', undef );
    }

    my @empty_spans = $tree->look_down( '_tag', 'span', 'id', undef );
    for my $empty_span (@empty_spans) {
      $empty_span->replace_with_content->delete;
    }

    my @classed_elements =
      $tree->look_down( sub { defined $_[0]->attr('class') } );

    # Retain footnote classes for end-user manipulation, after
    # this module has done its work.
    for my $classed (@classed_elements) {
      $classed->attr( 'class', undef ) unless $classed->attr('class') =~ /sdfootnote(anc|sym)/;
    }

    my $final_style_tag = $tree->look_down( '_tag', 'style' );
    $final_style_tag->delete if $final_style_tag;

    ### End final cleaning

    my $text = $tree->as_HTML;
    $tree->delete;
    io("$html")->print($text);
    return $html;
}

method filter_css($tree) {
    my $style_tag = $tree->look_down( '_tag', 'style' );
    my $parsed_style;

    if ($style_tag) {
        {
          local *STDERR;
          local *STDOUT;
          open( STDOUT, '>', File::Spec->devnull() );
          open( STDERR, '>', File::Spec->devnull() );
          my $style_string = HTML::Entities::decode( $style_tag->as_HTML );
          $style_string =~ s/font\-family\:'.+?'//g;
          $parsed_style = $self->css->read_string($style_string);
        }
    }

    if ($parsed_style) {
      my @italic_selectors = grep { $_ }
        map {
        $_->selectors =~ /^(?<tag>\w+\.)(?<class>\w+)$/;
        $+{class};
        }
        grep { $_->properties =~ /italic/ } @$parsed_style;
      my @bold_selectors = grep { $_ }
        map {
        $_->selectors =~ /^(?<tag>\w+\.)(?<class>\w+)$/;
        $+{class};
        }
        grep { $_->properties =~ /bold/ } @$parsed_style;
      my %bolds          = map  { $_ => 1 } @bold_selectors;
      my @both_selectors = grep { defined $bolds{$_} } @italic_selectors;
      my %array_for      = (
        both   => \@both_selectors,
        bold   => \@bold_selectors,
        italic => \@italic_selectors
      );

      for my $type (qw/both bold italic/) {
        for my $selector ( @{ $array_for{$type} } ) {
          if ($selector) {
            my @to_filter = $tree->look_down( 'class', $selector );
            if ( @to_filter > 0 ) {
              for my $el (@to_filter) {
                if ( $type eq 'both' ) {
                  my $new_bold   = HTML::Element->new('strong');
                  my $new_italic = HTML::Element->new('em');
                  $new_bold->push_content( $el->detach_content );
                  $new_italic->push_content($new_bold);
                  $el->replace_with($new_italic);
                }
                else {
                  my $new =
                    $type eq 'bold'
                    ? HTML::Element->new('strong')
                    : HTML::Element->new('em');
                  $new->push_content( $el->detach_content );
                  $el->replace_with($new);
                }
              }
            }
          }
        }
      }
    }
    return $tree;
}

method html_to_html5( IO::All $base_html) {
    try {
        system(
            "/usr/bin/tidy",                 "-f",
            "$base_html.err",                "-m",
            "-clean",                        "-quiet",
            "--preserve-entities",           "yes",
            "--indent-cdata",                "yes",
            "--escape-cdata",                "yes",
            "--repeated-attributes",         "keep-last",
            "--char-encoding",               "utf8",
            "--output-encoding",             "utf8",
            "--merge-spans",                 "yes",
            "--bare",                        "yes",
            "--logical-emphasis",            "yes",
            "--word-2000",                   "yes",
            "--drop-empty-paras",            "yes",
            "--drop-font-tags",              "yes",
            "--drop-proprietary-attributes", "yes",
            "--hide-endtags",                "no",
            "-language",                     "en",
            "--add-xml-decl",                "yes",
            "--output-xhtml",                "yes",
            "--tidy-mark",                   "no",
            "--doctype",                     "strict",
            "$base_html"
        );
    }
    catch {
      "I could not tidy the base_html: $_";
    };

    ( my $title = $self->file->filename ) =~ s/\s+/ /g;
    $title =~ s/\(|\)|\-//g;
    $title =~ /\A(?<filename>.+?)(?<extension>\.\w+)\z/g;
    my $new_title = $+{filename} || 'Untitled';
    $new_title =~ s/[[:punct:]]/ /g;

    ( my $filename = lc $self->file->filename ) =~ s/\s+/_/g;
    $filename =~ s/\(|\)|\-//g;
    $filename =~ /\A(?<filename>.+?)(?<extension>\.\w+)\z/g;
    $filename = $+{filename};
    $filename =~ s/[[:punct:]]/_/g;

    $base_html = io("$base_html")->utf8;
    my $cleaned_html = $self->post_clean_html( $base_html, $new_title );
    my $new_dom      = $self->parser->parse_html_fh( io("$cleaned_html") );
    my $html5        = $self->writer->document($new_dom);

    my $html5_file = io->catfile( io->tmpdir, $filename . '.html' )->utf8->print($html5);
    my $html5_images = "$base_html" . "_files";
    my $new_filename = $html5_file->file;
    return MSWord::ToHTML::HTML->new(
      file => "$new_filename",
      ( -e $html5_images ? ( images => $html5_images ) : () )
    );
}

1;
