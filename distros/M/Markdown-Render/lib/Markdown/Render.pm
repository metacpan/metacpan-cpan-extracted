package Markdown::Render;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use HTTP::Request;
use IO::Scalar;
use JSON;
use LWP::UserAgent;
use List::Util qw(none);

our $VERSION = '1.60.1';

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;

__PACKAGE__->mk_accessors(
  qw(
    body
    css
    engine
    git_email
    git_user
    html
    infile
    markdown
    mode
    no_title
    raw
    render
    title
  )
);

use Readonly;

Readonly our $GITHUB_API  => 'https://api.github.com/markdown';
Readonly our $EMPTY       => q{};
Readonly our $SPACE       => q{ };
Readonly our $TOC_TITLE   => 'Table of Contents';
Readonly our $TOC_BACK    => 'Back to Table of Contents';
Readonly our $DEFAULT_CSS => 'https://cdn.simplecss.org/simple-v1.css';

caller or __PACKAGE__->main;

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my %options = ref $args[0] ? %{ $args[0] } : @args;

  $options{title}  //= $TOC_TITLE;
  $options{css}    //= $options{nocss} ? $EMPTY : $DEFAULT_CSS;
  $options{mode}   //= 'markdown';
  $options{engine} //= 'github';

  my $self = $class->SUPER::new( \%options );

  if ( $self->get_infile ) {
    open my $fh, '<', $self->get_infile
      or die 'could not open ' . $self->get_infile;

    local $RS = undef;

    $self->set_markdown(<$fh>);

    close $fh;
  }

  return $self;
}

########################################################################
sub toc_back {
########################################################################
  my ($self) = @_;

  my $back_link = lc $self->get_title;
  $back_link =~ s/\s/-/gxsm;

  return $back_link;
}

########################################################################
sub back_to_toc {
########################################################################
  my ( $self, $message ) = @_;

  $message ||= $TOC_BACK;

  $message =~ s/[(]\"?(.*?)\"?[)]/$1/xsm;

  return sprintf '[%s](#%s)', $message, $self->toc_back;
}

########################################################################
sub finalize_markdown {
########################################################################
  my ($self) = @_;

  my $markdown = $self->get_markdown;

  die "no markdown yet\n"
    if !$markdown;

  my $fh = IO::Scalar->new( \$markdown );

  my $final_markdown;
  my $in_code_block;

  while ( my $line = <$fh> ) {

    if ( $line =~ /\A\s*[`]{3}\s*\z/xsm ) {
      $in_code_block ^= 1;
    }

    if ($in_code_block) {
      $final_markdown .= $line;
      next;
    }

    $line =~ s/^\!\#/\#/xsm;  # ! used to prevent including header in TOC

    if ( $line =~ /^\@TOC\@/xsm ) {
      my $toc = $self->create_toc;

      chomp $toc;

      $line =~ s/\@TOC\@/$toc/xsm;
    }

    my $title = $self->get_title;

    if ( $line =~ /\@TOC_TITLE\@/xsm ) {
      $line =~ s/\@TOC_TITLE\@/$title/xsm;
    }

    my $git_user  = $self->get_git_user  // 'anonymouse';
    my $git_email = $self->get_git_email // 'anonymouse@example.com';

    if ( $line =~ /\@GIT_(USER|EMAIL)\@/xsm ) {
      $line =~ s/\@GIT_USER\@/$git_user/xsm;

      $line =~ s/\@GIT_EMAIL\@/$git_email/xsm;
    }

    my $date;

    while ( $line =~ /\@DATE[(]?(.*?)[)]?\@/xsm ) {
      my $format = $1 ? $1 : '%Y-%m-%d';

      $date = $self->format_date($format);

      $line =~ s /\@DATE[(]?(.*?)[)]?\@/$date/xsm;
    }

    if ( $line =~ /\@TOC_BACK[(]?(.*?)[)]?\@/xsm ) {
      my $back = $self->back_to_toc($1);

      $line =~ s/\@TOC_BACK[(]?(.*?)[)]?\@/$back/xsm;
    }

    $final_markdown .= $line;
  }

  close $fh;

  $self->set_markdown($final_markdown);

  return $self;

}

########################################################################
sub _render_with_text_markdown {
########################################################################
  my ($self) = @_;

  eval { require Text::Markdown::Discount; };

  if ($EVAL_ERROR) {
    carp "no Text::Markdown::Discount available...using GitHub API.\n$EVAL_ERROR";
    return $self->_render_with_github;
  }

  my $markdown = $self->get_markdown;
  my $html     = Text::Markdown::Discount::markdown($markdown);

  if ( $self->get_raw ) {
    $self->set_html($html);
  }
  else {
    $self->fix_anchors( Text::Markdown::Discount::markdown($markdown) );
  }

  return $self;
}

########################################################################
sub fix_anchors {
########################################################################
  my ( $self, $html_raw ) = @_;

  my $fh = IO::Scalar->new( \$html_raw );

  my $html;

  while ( my $line = <$fh> ) {
    # remove garbage if there...
    if ( $line =~ /^\s*<h(\d+)><a (.*)>(.*)<\/a>(.*)/xsm ) {
      $line = "<h$1>$3$4</h$1>\n";
    }

    $html .= _fix_header($line);
  }

  close $fh;

  $self->set_html($html);

  return $self;
}

########################################################################
sub _fix_header {
########################################################################
  my ($line) = @_;

  return $line if $line !~ /^\s*<h(\d+)>(.*?)<\/h\d>$/xsm;

  my ( $hn, $anchor, $header ) = ( $1, $2, $2 );  ## no critic (ProhibitCaptureWithoutTest)

  $anchor = lc $anchor;
  $anchor =~ s/\s+/-/gxsm;                        # spaces become '-'
  $anchor =~ s/[.:\?_.\@'(),\`]//xsmg;            # known weird characters, but expect more
  $anchor =~ s/\///xsmg;

  $line
    = sprintf qq{<h%d><a id="%s" class="anchor" href="#%s"></a>%s</h%d>\n},
    $hn,
    $anchor, $anchor, $header, $hn;

  return $line;
}

########################################################################
sub render_markdown {
########################################################################
  my ($self) = @_;

  if ( $self->get_engine eq 'github' ) {
    return $self->_render_with_github;
  }
  elsif ( $self->get_engine eq 'text_markdown' ) {
    return $self->_render_with_text_markdown;
  }
  else {
    croak 'invalid engine: ' . $self->get_engine;
  }
}

########################################################################
sub _render_with_github {
########################################################################
  my ($self) = @_;

  my $markdown = $self->get_markdown;

  my $ua  = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', $GITHUB_API );

  my $mode = $self->get_mode;

  if ( none { $mode eq $_ } qw(gfm markdown) ) {
    $mode = 'markdown';
  }

  my $api_request = {
    text => $markdown,
    mode => $mode,
  };

  $req->content( to_json($api_request) );

  my $rsp = $ua->request($req);

  croak 'could not render using GitHub API: ' . $rsp->status_line
    if !$rsp->is_success;

  if ( $self->get_raw ) {
    $self->set_html( $rsp->content );

    return $self;
  }

  if ( $self->get_mode eq 'gfm' ) {
    return $self->fix_anchors( $rsp->content );
  }
  else {
    return $self->fix_github_html( $rsp->content );
  }
}

########################################################################
sub fix_github_html {
########################################################################
  my ( $self, $html_raw ) = @_;

  my $fh = IO::Scalar->new( \$html_raw );

  my $html = $EMPTY;

  while ( my $line = <$fh> ) {
    chomp $line;

    $line =~ s/(href|id)=\"\#?user-content-/$1=\"/xsm;
    $line =~ s/(href|id)=\"\#?\%60.*\%60/$1=\"#$2/xsm;

    $html .= "$line\n";
  }

  close $fh;

  $self->set_html($html);

  return $self;
}

########################################################################
sub format_date {
########################################################################
  my ( $self, $template ) = @_;

  require Date::Format;

  $template =~ s/[(]\"?(.*?)\"?[)]/$1/xsm;

  my $val = eval { Date::Format::time2str( $template, time ); };

  return $EVAL_ERROR ? '<undef>' : $val;
}

########################################################################
sub create_toc {
########################################################################
  my ($self) = @_;

  my $markdown = $self->get_markdown;

  my $fh = IO::Scalar->new( \$markdown );

  my $toc = $self->get_no_title ? $EMPTY : "# \@TOC_TITLE\@\n\n";

  while (<$fh>) {
    chomp;

    /^(\#+)\s+(.*?)$/xsm && do {
      my $level = $1;

      my $indent = $SPACE x ( 2 * ( length($level) - 1 ) );

      my $topic = $2;

      my $link = $topic;

      $link =~ s/^\s*(.*)\s*$/$1/xsm;

      $link =~ s/\s+/-/gxsm;  # spaces become '-'

      $link =~ s/[\?\_:.\@'(),\`]//xsmg;  # known weird characters, but expect more

      $link =~ s/\///xsmg;

      $link = lc $link;

      # remove HTML entities
      $link =~ s/&\#\d+;//xsmg;

      # remove escaped entities and remaining noisy characters
      $link =~ s/[{}&]//xsmg;

      $toc .= sprintf "%s* [%s](#%s)\n", $indent, $topic, $link;
    };
  }

  close $fh;

  return $toc;
}

########################################################################
sub print_html {
########################################################################
  my ( $self, %options ) = @_;

  my $fh = $options{fh} // *STDOUT;

  if ( !$options{body} ) {
    print {$fh} $self->get_html;

    return;
  }

  my $css   = exists $options{css}   ? $options{css}   : $self->get_css;
  my $title = exists $options{title} ? $options{title} : $self->get_infile;

  my $title_section = $title ? "<title>$title</title>" : $EMPTY;

  my $css_section
    = $css
    ? qq{<link href="$css" rel="stylesheet" type="text/css" />}
    : $EMPTY;

  my @head = grep { $_ ? $_ : () } ( $title_section, $css_section );

  my $head_section;

  if (@head) {
    unshift @head, '<head>';
    push @head, '</head>';

    $head_section = join "\n", @head;
  }

  my $body = $self->get_html;

  print {$fh} <<"END_OF_TEXT";
<html>
  $head_section
  <body>
    $body
  </body>
</html>
END_OF_TEXT

  return;
}

########################################################################
sub main {
########################################################################

  my $md = Markdown::Render->new(
    infile => shift @ARGV,
    css    => $DEFAULT_CSS
  );

  $md->finalize_markdown->render_markdown;

  $md->print_html;

  exit 0;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

Markdown::Render - Render markdown as HTML

=head1 SYNOPSIS

 use Markdown::Render;

 my $md = Markdown::Render->new( infile => 'README.md');

 $md->render_markdown->print_html;

...or from the command line to create HTML

 md-utils.pl -r README.md > README.html

...or from the command line to replace render custom tags

 md-utils.pl README.md.in > README.md

=head1 DESCRIPTION

Renders markdown as HTML using either GitHub's API or
L<Text::Markdown::Discount>. Optionally adds additional metadata to markdown
document using custom tags.

See
L<README.md|https://github.com/rlauer6/markdown-utils/blob/master/README.md>
for more details.

I<Note: This module originally used L<Text::Markdown> as an
alternative to using the GitHub API however, there are too many bugs
and idiosyncracies in that module. This module will now use
L<Text::Markdown::Discount> which is not only faster, but seems to be
more compliant with GFM.>

I<Note: Text::Markdown::Discount relies on the text-markdown library
which did not actually support all of the markdown features (including
code fencing).  You can find an updated version of
L<Text::Markdown::Discount> here:
L<https://github.com/rlauer6/text-markdown-discount>>

=head1 METHODS AND SUBROUTINES

=head2 new

 new( options )

Any of the options passed to the C<new> method can also be set or
retrieved use the C<set_NAME> or C<get_NAME> methods.

=over 5

=item css

URL of a CSS file to add to head section of printed HTML.

=item engine

One of C<github> or C<text_markdown>.

default: github

=item git_user

Name of the git user that is used in the C<GIT_USER> tag.

=item git_email

Email address of the git user that is used in the C<GIT_EMAIL> tag.

=item infile

Path to a file in markdow format.

=item markdown

Text of the markdown to be rendered.

=item mode

If using the GitHub API, mode can be either C<gfm> or C<markdown>.

default: markdown

=item no_title

Boolean that indicates that no title should be added to the table of
contents.

default: false

=item title

Title to be used for the table of contents.

=back

=head2 finalize_markdown

Updates the markdown by interpolating the custom keywords. Invoking this
method will create a table of contents and replace keywords with their
values.

Invoke this method prior to invoking C<render_markdown>.

Returns the L<Markdown::Render> object.

=head2 render_markdown

Passes the markdown to GitHub's markdown rendering engine. After
invoking this method you can retrieve the processed html by invoking
C<get_html> or create a fully rendered HTML page using the C<print_html>
method.

Returns the L<Markdown::Render> object.

=head2 print_html

 print_html(options)

Outputs the fully rendered HTML page.

=over 5

=item css

URL of a CSS style sheet to include in the head section. If no CSS
file option is passed a default CSS file will b used. If a CSS element
is passed but it is undefined or empty, then no CSS will be specified
in the final document.

=item title

Title to be added in the head section of the document. If no title
option is passed the name of the file will be use as the title. If an
title option is passed but is undefined or empty, no title element
will be added to the document.

=back

=head1 AUTHOR

Rob Lauer - rlauer6@comcast.net

=head1 SEE OTHER

L<GitHub Markdown API|https://docs.github.com/en/rest/markdown>
L<Text::Markdown::Discount>

=cut
