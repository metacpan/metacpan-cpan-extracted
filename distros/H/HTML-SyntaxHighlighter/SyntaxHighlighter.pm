package HTML::SyntaxHighlighter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Carp ();
use HTML::Entities;
use HTML::Parser;

require Exporter;

@ISA = qw(HTML::Parser Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
);

$VERSION = '0.03';

my %default_args = (
                    out_func => \*STDOUT,
                    header => 1,
                    default_type => 'html',
                    force_type => 0,
                    debug => 0,
                    br => '<br />',
                    collapse_inline => 0,
                    indent_level => 2
                   );

# Preloaded methods go here.

sub new {
  my $class = shift;
  my %args = @_;
  my $self = bless {}, $class;

  $self->init(%args);
  return $self;
}

sub init {
  my $self = shift;
  my %args = @_;

  foreach ( keys %default_args ) {
    $self->$_( exists( $args{$_} ) ? delete $args{$_} : $default_args{$_} );
  }

  $self->SUPER::init(%args);
  $self->unbroken_text( 1 );

  $self->handler(comment => 'comment', 'self, text');
  $self->handler(declaration => 'declaration', 'self, tokens');
  $self->handler(start_document => 'start_document', 'self');
  $self->handler(end_document => 'end_document', 'self');
}

# SETTINGS

sub debug {
  my ($self, $debug ) = @_;
  $self->{debug} = $debug;
}

sub out_func {
  my ($self, $output) = @_;
  my $ref = ref( $output );
  if( $ref eq 'CODE' ) {
    $self->{out_func} = sub { $output->( "@_\n" ) };
  } elsif ( $ref eq 'GLOB' ) {
    $self->{out_func} = sub { print $output "@_\n" };
  } elsif ( $ref eq 'SCALAR' ) {
    $self->{out_func} = sub { $$output .= "@_\n" };
  } else {
    Carp::croak( "Output argument ot type '$ref' not supported" );
  }
}

sub header {
  my ($self, $header ) = @_;
  $self->{header} = $header;
}

sub default_type {
  my ($self, $type ) = @_;
  unless ( ($type eq 'html') ||
           ($type eq 'xhtml') ) {
    Carp::croak( "Type '$type' not supported" );
  }
  $self->{default_type} = $type;
}

sub force_type {
  my ($self, $force ) = @_;
  $self->{force_type} = $force;
}

sub type {
  my ($self, $type ) = @_;
  unless ( ($type eq 'html') ||
           ($type eq 'xhtml') ) {
    Carp::croak( "Type '$type' not supported" );
  }

  $self->{type} = $type;
}

sub br {
  my ($self, $br ) = @_;
  $self->{br} = $br;
}

sub collapse_inline {
  my ($self, $collapse_inline ) = @_;
  $self->{collapse_inline} = $collapse_inline;
}

sub indent_level {
  my ($self, $indent_level ) = @_;
  $self->{indent_level} = $indent_level;
}

# HANDLERS

sub start_document {
  my $self = shift;

  # reset html tag stack
  $self->{stack} = [];

  # set type to default in case we don't encounter a DTD
  $self->type( $self->{default_type} );

  # header on: turn off output initially
  $self->{silent} = $self->{header} ? 0 : 1;
  $self->{threshold} = 0;
  $self->{past_first_line} = 0;

  $self->{out_func}->( '<code>' );
}

sub end_document {
  my $self = shift;

  $self->{out_func}->( '</code>' );
}

sub start {
  my ($self, $tagname, $attr, $attrseq) = @_;
  my $indent = $self->mk_indent();
  my ($output, $error);

  my $type = sel_type($tagname);
  if( exists( $attr->{'/'} ) ) {
    # standalone xhtml tag, e.g. '<br />'
  } elsif( ($self->{type} eq 'html') &&
           ($tagname eq 'br') ||
           ($tagname eq 'hr') ||
           ($tagname eq 'img') ||
           ($tagname eq 'input') ||
           ($tagname eq 'link') ||
           ($tagname eq 'meta') ||
           ($tagname eq 'area') ||
           ($tagname eq 'col') ||
           ($tagname eq 'base') ||
           ($tagname eq 'param') ) {
    # allowable standalone tag in html
  } else {
    # check for commonly unclosed tags
    if( ($tagname eq 'p') ||
        ($tagname eq 'select') ||
        ($tagname eq 'li') ||
        ($tagname eq 'td') ||
        ($tagname eq 'th') ||
        ($tagname eq 'tr') ) {
      my $close = $self->{stack}->[-1];
      if( $close eq $tagname ) {
        # tag is same as the one above, and can't be
        # assume missing closed tag, go up a level
        # unless it looks like we have a missing open tag too (ugh!)
        if( $close ne $self->{last_block} ) {
          pop @{$self->{stack}};
          $indent = $self->mk_indent();
          if( $self->{debug} ) {
            $output = gen_tag('X', "/$close", undef, undef, { error => "Missing closing '$close' tag" } );
            $self->output( $indent, "<small>$output</small>" );
          }
        }
      }
    }
    # one level deeper
    push @{$self->{stack}}, $tagname;
  }

  if( ($type eq 'B') && !$self->block_allowed ) {
    $error = "Block-level element '$tagname' within illegal inline element '$self->{stack}->[-1]'";
    $type = 'X';
  }

  $output = gen_tag($type, $tagname, $attr, $attrseq,
                    ($error && $self->{debug}) ? { error => $error } : ()
                    );

  if( $self->{collapse_inline} ) {
    if( ($type ne 'I') or is_element($tagname) or is_row($tagname) or $self->in_head() ) {
      $self->{no_indent} = 0;
    }
  }

  # header off: no line break before first line of body
  my $nobr;
  if( !$self->{header} && !$self->{past_first_line} && ($self->{stack}->[-2] eq 'body') ) {
    $nobr = 1;
    $self->{past_first_line} = 1;
  }

  $self->output( $indent, $output, $nobr );

  if( $self->{collapse_inline} ) {
    if( ($type eq 'I') and !is_script($tagname) ) {
      $self->{no_indent} = 1;
    }
  }

  # header off: turn on output as we enter the body
  if( !$self->{header} && ($tagname eq 'body') ) {
    $self->{silent} = 0;
    $self->{threshold} = scalar( @{$self->{stack}} );
  }

  $self->{last_block} = undef if $type eq 'B';
}

sub end {
  my ($self, $tagname) = @_;
  my $start = pop @{$self->{stack}};
  my ($output, $error);

  my $type = sel_type($tagname);
  if( $start ne $tagname ) {
    # mismatched tags
    # check if tag is on the level above if we're using block-level components
    # if so, go up a level. if close tag same as the last, assume missing open tag
    $error = "Mismatched tag '$start' / '$tagname'";

    if( $type eq 'B') {
      if( $self->{stack}->[-1] eq $tagname ) {
        my $up = pop @{$self->{stack}};
        $error .= ", going up a level to '$up'";
      } elsif( $self->{last_block} eq $tagname ) {
        push @{$self->{stack}}, $tagname;
        $error .= ", assuming missing open '$self->{last_block}' tag";
      }
    }

    $type = 'X' if( $self->{debug} );
  }

  my $indent = $self->mk_indent();

  # header off: turn off output as we leave the body
  $self->{silent} = 1 if !$self->{header} && ($tagname eq 'body');

  $output = gen_tag($type, "/$tagname", undef, undef,
                    ($error && $self->{debug}) ? { error => $error } : ()
                   );

  if( $self->{no_indent} ) {
    if( ($type ne 'I') or is_row($tagname) ) {
      $self->{no_indent} = 0;
    }
  }

  $self->output( $indent, $output );

  # store tagname for missing open tag checking
  $self->{last_block} = $tagname if $type eq 'B';
}

sub text {
  my ($self, $origtext) = @_;
  my $indent = $self->mk_indent();
  my $output;

  my $text = encode_entities($origtext);

  if( $text =~ /\S/ ) {
    # different formatting for the contents of 'script' and 'style' tags
    my $parent = $self->{stack}->[-1];
    if( is_script($parent) ) {
      $text =~ s/^\n//;
      $text =~ s/\n\s*$//;
      $output = qq[<span class="S">$text</span>];
      $self->output( '', $output );
    } else {
      $text =~ s/\n//g;
      $text =~ s/^\s+//;
      $text =~ s/\s+$//;

      # header off: no line break before first line of body
      my $nobr;
      if( !$self->{header} && !$self->{past_first_line} && ($self->{stack}->[-1] eq 'body') ) {
        $nobr = 1;
        $self->{past_first_line} = 1;
      }

      $output = qq[<span class="T">$text</span>];
      $self->output( $indent, $output, $nobr );

      if( $self->{collapse_inline} ) {
        $self->{no_indent} = 1;
      }
    }
  }
}

sub comment {
  my ($self, $origtext) = @_;
  my $indent = $self->mk_indent();
  my $output;

  my $text = encode_entities($origtext);
  $output = qq[<span class="C">$text</span>];
  $self->output( $indent, $output );
}

sub declaration {
  my $self = shift;
  my @tokens = @{shift()};
  my $output;

  $output = qq[<span class="D">&lt;];
  map { s!^"(.*)"$!"<var>$1</var>"! } @tokens;
  $output .= join ' ', @tokens;
  $output .= qq[&gt;</span>];
  $self->output( '', $output, 1 );

  unless( $self->{force_type} ) {
    if( my $identifier = $tokens[3] ){
      if( $identifier =~ m!(X?HTML)! ) {
        my $type = lc( $1 );
        $self->type( $type );
      }
    }
  }
}

# OTHER METHODS

sub block_allowed {
  my $self = shift;
  my $tag = $self->{stack}->[-1];
  if( (sel_type( $tag ) ne 'I' ) ||
      ($tag eq 'li') ||
      ($tag eq 'dd') ||
      ($tag eq 'td') ||
      ($tag eq 'th') ||
      ($tag eq 'object') ||
      ($tag eq 'ins') ||
      ($tag eq 'del') ||
      ($tag eq 'ins') ||
      ($tag eq 'button') ) {
    return 1;
  } else {
    return 0;
  }
}

sub is_element {
  my $tag = shift;
  if( ($tag eq 'li') ||
      ($tag eq 'dt') ||
      ($tag eq 'dd') ||
      ($tag eq 'td') ||
      ($tag eq 'th') ) {
    return 1;
  } else {
    return 0;
  }
}

sub is_row {
  my $tag = shift;
  if( ($tag eq 'tr') ||
      ($tag eq 'thead') ||
      ($tag eq 'tbody') ||
      ($tag eq 'tfoot') ) {
    return 1;
  } else {
    return 0;
  }
}

sub is_script {
  my $tag = shift;
  if( ($tag eq 'script') ||
      ($tag eq 'style') ) {
    return 1;
  } else {
    return 0;
  }
}

sub in_head {
  my $self = shift;
  my $doc_level = $self->{stack}[1];
  if( ($doc_level eq 'head') ) {
    return 1;
  } else {
    return 0;
  }
}

sub output {
  my ($self, $indent, $output, $nobr ) = @_;
  if( !$self->{no_indent} ) {
    $output = $indent . $output;
    $output = $self->{br} . $output unless $nobr;
  }
  $self->{out_func}->( $output ) unless $self->{silent};
}

sub gen_tag {
    my ($type, $tagname, $attr, $attrseq, $opts) = @_;
    my $output;

    if( defined $opts->{error} ) {
      $output = qq[<span class="$type" title="$opts->{error}">&lt;$tagname];
    } else {
      $output = qq[<span class="$type">&lt;$tagname];
    }

    foreach ( @{$attrseq} ) {
      if( $attr->{$_} ne $_ ) {
        $output .= qq[ $_=<span class="A">"<var>$attr->{$_}</var>"</span>];
      } else {
        $output .= " $_";
      }
    }
    $output .= '&gt;</span>';
    return $output;
}

sub sel_type {
  my $tag = shift;
  if( ($tag eq 'html') ||
      ($tag eq 'body') ||
      ($tag eq 'head') ) {
    return 'H';
  } elsif( ($tag eq 'address') ||
           ($tag eq 'blockquote') ||
           ($tag eq 'center') || # deprecated, but people are still (unfortunately) going to use it
           ($tag eq 'div') ||
           ($tag eq 'dl') ||
           ($tag eq 'form') ||
           ($tag eq 'ol') ||
           ($tag eq 'p') ||
           ($tag eq 'pre') ||
           ($tag eq 'table') ||
           ($tag eq 'ul') ||
           ($tag eq 'noscript') ||
           ($tag eq 'noframes') ||
           ($tag eq 'fieldset') ||
           ($tag =~ /^h[1-6]$/) ) {
    return 'B';
  } else {
    return 'I';
  }
}

sub mk_indent {
  my $self = shift;
  my $i = scalar( @{$self->{stack}} ) - $self->{threshold};
  return '&nbsp' x ($i * $self->{indent_level});
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

HTML::SyntaxHighlighter - a module for converting raw HTML into
html-escaped, highlighted code; suitable for inclusion within a web page.


=head1 SYNOPSIS

Standalone

 my $p = HTML::SyntaxHighlighter->new();
 $p->parse_file( "$file" ) or die "Cannot open '$file': $!"...

From within HTML::Mason

 <& /lib/header.m, title => "Formatted source code for '$file'", stylesheet => [ 'html_highlight.css' ] &>

 <%perl>
  my $path = "/usr/data/www/hyperspeed.org/projects/html/examples";
  my $p = HTML::SyntaxHighlighter->new(
                                       out_func => sub{ $m->out( @_ ) },
                                       header => 0,
                                      );

  $p->parse_file( "$path/$file" ) or die "Cannot open '$path/$file': $!";
 </%perl>

 <& /lib/footer.m &>

 <%once>
  use HTML::SyntaxHighlighter;
 </%once>

 <%args>
  $file
 </%args>


=head1 DESCRIPTION

This module is designed to take raw HTML code, either from a variable
or a file, html-escape it and highlight it (using stylesheets),
rendering it suitable for inclusion in a web page. It is build on top
of HTML::Parser.

It is intended primarily for people wanting to include 'example HTML
code' in an dynamically generated web page (be it created with CGI,
HTML::Mason, or whatever); if you find other uses, please let me know.


=head1 OPTIONS

Options can either be set from the constructor:

 my $p = HTML::SyntaxHighlighter->new(
                                      default_type => 'xhtml'
                                      force_type => 1,
                                     );

Or by calling method with the same name:

 $p->debug( 1 );

=over

=item C<out_func>

The output function. Can be one of the following:

=over

=item A coderef

The function is called whenever output is generated.

 $p->out_func( sub { $r->print( @_ ) } );

=item A filehandle globref

Output is redirected to the filehandle.

 $p->out_func( \*DATAFILE );

=item A scalar ref

Output is saved to the scalar variable.

 $p->out_func( \$data );

=back

The default value is '\*STDOUT'.

=item C<collapse_inline>

If this option is turned on, then inline tags and text will be
collapsed onto a single line; only block-level elements and table rows
being indented as normal.
This should probably only be used on small html snippets, since it has
not been extensively tested against large ones, and I'd be surprised
if it stood up well to handling complex or less-than-perfect code.

=item C<header>

If this option is turned off, then only tags between '<body>' and
'</body>' will be outputted.

=item C<default_type>

Determines whether we expect documents to be html or xhtml, which
affects parsing slightly. Default is 'html'.

=item C<force_type>

Normally, the doctype declaration will override default_type. If this
option is set, then default_type will be used in all cases.

=item C<debug>

Turns on debugging mode, which marks out sections of erroneous code,
and attempt to correct some basic errors (e.g. not closing '<p>' tags).

=item C<br>

The string to be used to generate line breaks in the output. Default
value is '<br />'.

=back

=head1 METHODS

Pretty much all of the other methods you will use are inherited from
L<HTML::Parser>.

Included are slightly adapted docs for the two most commonly used
methods.

=over

=item C<parse_file( $file )>

Take code to be highlighted directly from a file. The $file argument
can be a filename, an open file handle, or a reference to a an open
file handle. If $file contains a filename and the file can't be
opened, then themethod returns an undefined value and $! tells why it
failed. Otherwise the return value is a reference to the
syntaxhighlighter object.

=item C<parse( $string )>

Parse $string as the next chunk of the HTML document. The return value
is normally a reference to the syntaxhighlighter object.

=back


=head1 NOTES

The module only generates the HTML. You will also require a
stylesheet, which must either be included in or linked from your html
file. One is included with this module 
('F<examples/html_highlight.css>'),
which gives roughly the same colours as xemacs' html-mode does by default.

If you decide to make your own stylesheet, you will need definitions
for the following:

=over

=item D

The document type declaration.

=item H

Html, head and body tags.

=item B

Block-level elements; e.g. p, table, ol.

=item I

Inline elements; e.g. b, i, tt.

=item A

Tag attributes.

=item T

Plain text.

=item S

Text within 'script' and 'style' tags.

=item C

HTML comments.

=item X

Errors; only appear when 'debug' mode is on.

=back

=head1 AUTHOR

Alex Bowley <kilinrax@cpan.org>


=head1 SEE ALSO

L<HTML::Parser>.

=cut
