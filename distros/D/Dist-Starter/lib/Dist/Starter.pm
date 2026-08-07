# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;
use feature qw( say );

#<<<
package Dist::Starter;
BEGIN {
our $VERSION = 'v0.1.1';
}
#>>>

use Fcntl                          qw( S_IWUSR );
use File::Basename                 qw( basename dirname );
use File::Copy                     qw( move );
use File::Copy::Recursive::Reduced qw( dircopy );
use File::Find                     qw( find );
use File::Path                     qw( make_path remove_tree );
use File::ShareDir::Tiny           qw( dist_dir );
use File::Spec::Functions          qw( catdir catfile curdir rel2abs );
use File::Temp                     qw( tempdir );
use Getopt::Guided qw( EOOD EXIT_SUCCESS EXIT_FAILURE EXIT_USAGE print_version_info processopts readopts );
use PerlX::Maybe   qw( maybe );
use Safe::Isa;
use Try::Tiny qw( try catch );

use Dist::Starter::Context   ();
use Dist::Starter::Exception ();

sub DISTNAME_PLACEHOLDER () { '{{distname}}' }

sub croakf ( $@ ) {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

sub print_usage_info () {
  my $script_name = basename( $0 );
  print STDOUT "Usage: $script_name [ -V | -h  ]\n",
"       $script_name [ -T <template> ] [ -o <output directory> ] [ -n ] [ -A <abstract> ] [ -G <git base url> ] [ -M <min perl version> ] [ -a <author> ] <distname>\n";
  EOOD
}

sub resolve_existing_project_conflict ( $$$ ) {
  my ( $before_file, $project, $conflict_resolution ) = @_;

  # Possible conflict resolution enum values:
  # undef => fail
  # ????? => overwrite if file exists
  # ????? => skip if file exists
  unless ( $conflict_resolution ) {
    remove_tree( $before_file );
    die Dist::Starter::Exception->new( message => "Project directory '$project' already exists" )
  }

  undef
}

sub scaffold ( $$$ ) {
  my ( $entry_point, $output_directory, $context ) = @_;

  # This isn't the final project name. The final project name will be created
  # by the last element
  # ...
  # unless ( move $before_file, $after_file ) {
  # ...
  # in the below foreach loop
  my $project =
    catdir( $output_directory eq 'TEMP_DIR' ? tempdir( CLEANUP => $ENV{ HARNESS_ACTIVE } // 0 ) : $output_directory,
    DISTNAME_PLACEHOLDER );

  dircopy( $entry_point, $project ) or croakf $!;

  my @files;
  my $wanted = sub {
    my $file = $_;
    push @files, $file;
    if ( -f $file ) {
      # Add write permission to the owner because dircopy() hasn't kept that
      chmod( ( stat( $file ) )[ 2 ] | S_IWUSR, $file );
      # Enable inplace-editing
      # https://stackoverflow.com/questions/31024980/perl-in-place-editing-within-a-script-rather-than-one-liner
      local $^I   = '';
      local @ARGV = ( $file );
      while ( <ARGV> ) {
        s/\{\{ ( [^}]+ ) \}\}/$context->lookup( $1 )/xeg;
        print;
      }
    }
  };

  # Let $wanted apply in-place edits to the content of each regular file
  find( { wanted => $wanted, no_chdir => 1, bydepth => 1 }, $project );

  my $distname = $context->lookup( 'distname' );
  defined(
    $project = try {
      # Now its time to look for place holders in the file names
      # On purpose declare $after_file before the foreach loop
      my $after_file;
      foreach my $before_file ( @files ) {
        ( $after_file = $before_file ) =~ s/\{\{ ( [^}]+ ) \}\} \z/$context->lookup( $1 )/xe;
        if ( $after_file ne $before_file ) {
          make_path dirname $after_file;
          unless ( move $before_file, $after_file ) {
            croakf "Cannot move '%s' to '%s': %s", $before_file, $after_file, $!
              unless $after_file =~ m/$distname\z/;
            resolve_existing_project_conflict $before_file, $after_file, my $conflict_resolution;
          }
        }
      }
      # The last value of $after_file is the actual $project
      $after_file
    } catch {
      $_->$_isa( 'Dist::Starter::Exception' ) ? say STDERR $_->message : die $_;
      undef
    }
  ) or return EXIT_USAGE;
  # https://cookiecutter.readthedocs.io/en/latest/advanced/replay.html
  # https://github.com/cookiecutter/cookiecutter/issues/104
  # TODO:
  # The name of the replay file is wrong because it does not contain the name
  # of the template (basename( $template )). Furthermore it should be
  # discussed if the replay files should be stored at a central place or local
  # to the new project
  # $context->dump_to_file( catfile( $after_file, '.' . basename( $0 ) . '_replay.yml' ) );
  say STDOUT $project;

  EXIT_SUCCESS
}

sub run {
  shift;
  my @argv = @_ ? @_ : @ARGV;

  # CLI step
  # Set defaults
  unshift @argv, '-T', catdir( dist_dir( 'Dist-Starter' ), qw( templates perl-dist-eummcpf ) );
  unshift @argv, '-o', rel2abs curdir;
  readopts @argv;

  # Parse command-line
  my $template;
  my $rv = processopts
    @argv,
    V    => \&print_version_info,
    h    => \&print_usage_info,
    'T:' => sub { -d ( $template = shift ) or die( sprintf "Template directory '%s' does not exist\n", $template ) },
    n    => \my $dry_run,
    'o:' => \my $output_directory,
    'A:' => \my $abstract,
    'G:' => \my $git_base_url,
    'M:' => \my $min_perl_version,
    'a:' => \my $author
    # https://metacpan.org/pod/CPAN::Meta::Spec#license
    #'L:' => \my $license
    or return EXIT_USAGE;
  ( $rv eq '-V' or $rv eq '-h' ) and return EXIT_SUCCESS;

  1 == scalar @argv
    or ( printf STDERR "Number of required arguments has to be %d but it is %d\n", 1, scalar @argv ),
    return EXIT_USAGE;
  my ( $distname ) = @argv;

  my $entry_point = catdir( $template, DISTNAME_PLACEHOLDER );
  -d $entry_point
    or ( printf STDERR "Template entry point directory '%s' does not exist\n", $entry_point ), return EXIT_USAGE;

  defined(
    my $context = try {
      Dist::Starter::Context->load_from_file(
        catfile( $template, 'context.yml' ),
        # TODO:
        # Check if PerlX::Maybe::provided_deref_with_maybe $condition, $r, @rest
        # can be used
        maybe
          abstract => $abstract,
        maybe
          author => $author,
        maybe
          distname => $distname,
        maybe
          git_base_url => $git_base_url,
        maybe min_perl_version => $min_perl_version
      )
    } catch {
      $_->$_isa( 'Dist::Starter::Exception' ) ? say STDERR $_->message : die $_;
      undef
    }
  ) or return EXIT_USAGE;

  # non-CLI step
  if ( $dry_run ) {
    say STDOUT $context->dump_to_string;
    EXIT_SUCCESS
  } else {
    scaffold( $entry_point, $output_directory, $context )
  }
}

no warnings 'void'; ## no critic ( ProhibitNoWarnings )
__PACKAGE__
