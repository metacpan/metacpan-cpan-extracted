#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use Cwd;
use Config::Tiny;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename;
use Getopt::Long qw(:config no_ignore_case auto_abbrev);
use Readonly;

use Markdown::Render;

our $VERSION = $Markdown::Render::VERSION;

Readonly our $EMPTY => q{};
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

########################################################################
sub version {
########################################################################
  my ($name) = File::Basename::fileparse( $PROGRAM_NAME, qr/[.][^.]+$/xsm );

  print "$name $VERSION\n";

  return;
}

########################################################################
sub usage {
########################################################################
  print <<'END_OF_USAGE';
usage: md-utils.pl options [markdown-file]

Utility to add a table of contents and other goodies to your GitHub
flavored markdown.

 - Add @TOC@ where you want to see your TOC.
 - Add @TOC_BACK@ to insert an internal link to TOC
 - Add @DATE(format-str)@ where you want to see a formatted date
 - Add @GIT_USER@ where you want to see your git user name
 - Add @GIT_EMAIL@ where you want to see your git email address
 - Use the --render option to render the HTML for the markdown

Examples:
---------
 md-utils.pl README.md.in > README.md

 md-utils.pl -r README.md.in

Options
-------
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

Tips
----
* Use !# to prevent a header from being include in the table of contents.
  Add your own custom back to TOC message @TOC_BACK(Back to Index)@

* Date format strings are based on format strings supported by the Perl
  module 'Date::Format'.  The default format is %Y-%m-%d if not format is given.

* use the --nobody tag to return the HTML without the <html><body></body></html>
  wrapper. --raw mode will also return HTML without wrapper
END_OF_USAGE
  return;
}

########################################################################
sub get_git_user {
########################################################################
  my ( $git_user, $git_email );

  for ( ( getcwd . '.git/config' ), "$ENV{HOME}/.gitconfig" ) {
    next if !-e $_;

    my $config = eval { Config::Tiny->read($_); };

    ( $git_user, $git_email ) = @{ $config->{user} }{qw(name email)};

    last if $git_user && $git_email;
  }

  return ( $git_user, $git_email );
}

# +------------------------ +
# | MAIN SCRIPT STARTS HERE |
# +------------------------ +

my %options;

my @options_spec = qw(
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

GetOptions( \%options, @options_spec )
  or croak 'could not parse options';

$options{body} //= $TRUE;

if ( $options{raw} ) {
  $options{body} = $FALSE;
}

if ( exists $options{help} ) {
  usage;
  exit 0;
}

if ( exists $options{version} ) {
  version;
  exit 0;
}

$options{no_title} = delete $options{'no-title'};

my $markdown;

if ( !$options{infile} ) {

  if (@ARGV) {
    $options{infile} = shift @ARGV;
  }
  elsif ( !-t STDIN ) {  ## no critic (ProhibitInteractiveTest)
    local $RS = undef;

    my $fh = *STDIN;

    $markdown = <$fh>;
  }
}

my ( $git_user, $git_email ) = get_git_user();

$options{git_user}  = $git_user  // $EMPTY;
$options{git_email} = $git_email // $EMPTY;

my $md = Markdown::Render->new( %options, markdown => $markdown );

my $ofh = *STDOUT;

if ( exists $options{outfile} ) {
  open $ofh, '>', $options{outfile}  ## no critic (RequireBriefOpen)
    or croak "could not open output file\n";
}

eval {
  if ( $options{both} ) {
    $md->finalize_markdown->render_markdown;
    $md->print_html( %options, fh => $ofh );
  }
  elsif ( $options{render} ) {
    $md->render_markdown;
    $md->print_html( %options, fh => $ofh );
  }
  else {
    $md->finalize_markdown;
    print {$ofh} $md->get_markdown;
  }
};

croak "ERROR: $EVAL_ERROR"
  if $EVAL_ERROR;

close $ofh;

exit 0;

__END__
