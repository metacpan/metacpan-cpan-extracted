#!/usr/bin/env perl
package Markdown::Render::CLI;

use strict;
use warnings;

use Carp;
use Cwd;
use Config::Tiny;
use CLI::Simple::Constants qw(:chars :booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename;
use Getopt::Long qw(:config no_ignore_case auto_abbrev);
use Readonly;

use Markdown::Render;

our $VERSION = '2.0.4';

use parent qw(CLI::Simple);

########################################################################
sub choose(&) { ## no critic
########################################################################
  return $_[0]->();
}

########################################################################
sub cmd_version {
########################################################################
  my ($self) = @_;

  my ($name) = File::Basename::fileparse( $PROGRAM_NAME, qr/[.][^.]+$/xsm );

  print {*STDOUT} "$name $VERSION\n";

  return $SUCCESS;
}

########################################################################
sub get_git_user {
########################################################################
  my ($self) = @_;

  my ( $git_user, $git_email );

  for ( ( getcwd . '.git/config' ), "$ENV{HOME}/.gitconfig" ) {
    next if !-e $_;

    my $config = eval { Config::Tiny->read($_); };

    ( $git_user, $git_email ) = @{ $config->{user} }{qw(name email)};

    last if $git_user && $git_email;
  }

  return ( $git_user, $git_email );
}

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  # spoof CLI::Simple - force command render and preserve argument position
  unshift @ARGV, 'render';

  return $class->SUPER::new(@args);
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  if ( $self->get_raw ) {
    $self->set_body($FALSE);
  }

  return;
}

########################################################################
sub cmd_render {
########################################################################
  my ($self) = @_;

  my $markdown;

  my $infile = $self->get_infile;

  if ( !$infile ) {
    ($infile) = $self->get_args;

    my $fh = choose {
      return *STDIN
        if !$infile && !-t STDIN;

      open my $fh, '<', $infile
        or croak sprintf "ERROR: could not open %s for reading\n%s", $infile, $OS_ERROR;

      return $fh;
    };

    local $RS = undef;

    $markdown = <$fh>;
  }

  my ( $git_user, $git_email ) = $self->get_git_user();

  my $md = Markdown::Render->new(
    markdown  => $markdown,
    body      => $self->get_body,
    css       => $self->get_css,
    engine    => $self->get_engine,
    git_email => $git_email,
    user      => $git_user,
    html      => $self->get_html,
    mode      => $self->get_mode,
    no_title  => $self->get_no_title,
    raw       => $self->get_raw,
    render    => $self->get_render,
    title     => $self->get_title,
  );

  my $ofh = choose {
    my $outfile = $self->get_outfile;

    return *STDOUT
      if !$outfile;

    open my $fh, '>', $outfile
      or croak sprintf "ERROR: could not open output file\n%s", $self->get_outfile, $OS_ERROR;

    return $fh;
  };

  eval {
    if ( $self->get_both ) {
      $md->finalize_markdown->render_markdown;

      $md->print_html(
        fh    => $ofh,
        body  => $self->get_body,
        css   => $self->get_css,
        title => $self->get_title,
      );
    }
    elsif ( $self->get_render ) {
      $md->render_markdown;
      $md->print_html(
        fh    => $ofh,
        body  => $self->get_body,
        css   => $self->get_css,
        title => $self->get_title,
      );
    }
    else {
      $md->finalize_markdown;
      print {$ofh} $md->get_markdown;
    }
  };

  croak "ERROR: $EVAL_ERROR"
    if $EVAL_ERROR;

  close $ofh;

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################

  my @option_specs = qw(
    body|B!
    both|b
    css=s
    debug
    engine=s
    help
    infile=s
    mode=s
    no-title
    nocss|N
    outfile=s
    raw|R
    render|r
    title=s
    version
  );

  my %commands = ( version => \&cmd_version, render => \&cmd_render );

  my $cli = Markdown::Render::CLI->new(
    option_specs    => \@option_specs,
    commands        => \%commands,
    default_options => { body => $TRUE, },
    extra_options   => [qw(git_user git_email html)],
  );

  return $cli->run();

}

exit main();

__END__

=pod

=head1 USAGE

 md-utils.pl options [markdown-file]

Utility to add a table of contents and other goodies to your GitHub
flavored markdown.

=over 4

=item * @TOC@ where you want to see your TOC.

=item * @TOC_BACK@ to insert an internal link to TOC

=item * @DATE(format-str)@ where you want to see a formatted date

=item * @GIT_USER@ where you want to see your git user name

=item * @GIT_EMAIL@ where you want to see your git email address

=item * the --render option to render the HTML for the markdown

=back

=head2 Examples

 md-utils.pl README.md.in > README.md

 md-utils.pl -r README.md.in


=head2 Options

 -B, --body     default is to add body tag, use --nobody to prevent    
 -b, --both     interpolates intermediate file and renders HTML
 -c, --css      css file
 -e, --engine   github, text_markdown (default: github)
 -h             help
 -i, --infile   input file, default: STDIN
 -m, --mode     for GitHub API mode is 'gfm' or 'markdown' (default: markdown)
 -n, --no-titl  do not print a title for the TOC
 -o, --outfile  outfile, default: STDOUT
 -r, --render   render only, does NOT interpolate keywords
 -R, --raw      return raw HTML from engine
 -t, --title    string to use for a custom title, default: "Table of Contents"
 -v, --version  version
 -N, --nocss    do not add any CSS link

=head2 Tips

=over 4

=item *  Use !# to prevent a header from being include in the table of contents.

Add your own custom back to TOC message @TOC_BACK(Back to Index)@

=item *  Date format strings are based on format strings supported by the Perl module 'Date::Format'.

The default format is %Y-%m-%d if not format is given.

=item *  use the --nobody tag to return the HTML without the <html><body></body></html>
  wrapper. 

C<--raw> mode will also return HTML without wrapper.

=back

=cut
