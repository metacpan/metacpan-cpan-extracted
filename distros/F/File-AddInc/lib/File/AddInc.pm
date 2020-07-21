package File::AddInc;
use 5.008001;
use strict;
use warnings;
use mro qw/c3/;

our $VERSION = "0.002";

use File::Spec;
use File::Basename;
use Cwd ();
use lib ();
use Carp ();

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

{
  package
    File::AddInc::Opts;
  use fields qw/caller callpack filename line/;

  # This Opts->new does not bless the hash.
  sub new {
    my ($pack, %opts) = @_;
    my __PACKAGE__ $opts = \%opts;
    ($opts->{callpack}, $opts->{filename}, $opts->{line})
      = @{$opts->{caller}};
    $opts;
  }
}
sub Opts () {'File::AddInc::Opts'}

#
# Limited version of MOP4Import::Declare#import()
#
sub import {
  my ($pack, @pragma) = @_;

  my Opts $opts = $pack->Opts->new(caller => [caller]);

  @pragma = (-file_inc) unless @pragma;

  $pack->dispatch_declare($opts, @pragma);
}

sub dispatch_declare {
  (my $pack, my Opts $opts, my @pragma) = @_;

  foreach my $pragmaSpec (@pragma) {

    my ($pragma, @args) = do {
      if (ref $pragmaSpec eq 'ARRAY') {
        @$pragmaSpec
      }
      elsif (not ref $pragmaSpec and $pragmaSpec =~ /^-(\w+)$/) {
        $1
      }
      elsif (not ref $pragmaSpec and $pragmaSpec =~ /^\$\w+\z/) {
        (libdir_var => $pragmaSpec)
      }
      else {
        Carp::croak "Unsupported pragma: $pragmaSpec";
      }
    };

    my $sub = $pack->can("declare_$pragma")
      or Carp::croak "Unknown pragma: $pragma";

    $sub->($pack, $opts, @args);
  }
}

sub declare_file_inc {
  (my $pack, my Opts $opts) = @_;

  my $libdir = libdir($pack, $opts->{callpack}, $opts->{filename});

  $pack->add_inc_if_necessary($libdir);
}

sub declare_local_lib {
  (my $pack, my Opts $opts) = @_;

  $pack->declare_these_libdirs($opts, '', [dirname => "local/lib/perl5"]);
}

sub add_inc_if_necessary {
  my ($pack, @libdir) = @_;

  if (my @necessary = grep {

    my $dir = $_;
    -d $dir and not grep {$dir eq $_} @INC;

  } @libdir) {

    print STDERR "# use lib ", join(", ", map(qq{'$_'}, @necessary))
      , "\n" if DEBUG;

    lib->import(@necessary);

  } else {

    print STDERR "# No need to add libs: ", join(", ", map(qq{'$_'}, @libdir))
      , "\n" if DEBUG;
  }
}

sub declare_libdir_var {
  (my $pack, my Opts $opts, my $varname) = @_;

  my $libdir = libdir($pack, $opts->{callpack}, $opts->{filename});

  $varname =~ s/^\$//;

  my $fullvarname = join("::", $opts->{callpack}, $varname);

  my $glob = do {no strict qw/refs/; \*{$fullvarname}};

  print STDERR "# set \$$fullvarname = '$libdir'\n" if DEBUG;

  *$glob = \$libdir;
}

sub declare_these_libdirs {
  (my $pack, my Opts $opts, my @dirSpec) = @_;

  my $libdir = libdir($pack, $opts->{callpack}, $opts->{filename});

  my @libdir = map {
    if (ref $_) {

      my ($kind, @rest) = @$_;

      my $sub = $pack->can("libdir_to_$kind")
        or Carp::croak "Unknown libdir spec: $kind";

      my $realPrefix = $sub->($pack, $libdir);

      File::Spec->catfile($realPrefix, map {split(m{/}, $_)} @rest);

    }
    # elsif (/\%s/) {
    #   File::Spec->catfile(split m{/}, sprintf($_, $libdir));
    # }
    else {

      File::Spec->catfile($libdir, split(m{/}, $_));
    }
  } @dirSpec;

  add_inc_if_necessary($pack, @libdir);
}

sub libdir_to_libdir {
  my ($pack, $libdir) = @_;
  $libdir;
}

sub libdir_to_dirname {
  my ($pack, $libdir) = @_;
  dirname($libdir);
}

sub libdir {
  my ($pack, @caller) = @_;

  my ($callpack, $filename) = @caller ? @caller : caller;

  (my $packfn = $callpack) =~ s,::,/,g;
  $packfn .= ".pm";

  my $realFn = -l $filename
    ? resolve_symlink($pack, $filename)
    : $filename;

  my $absfn = File::Spec->rel2abs($realFn);

  $absfn =~ /\Q$packfn\E\z/
    or Carp::croak("Can't handle this case! absfn=$absfn; packfn=$packfn");

  substr($absfn, 0, length($absfn) - length($packfn) - 1);
}

sub resolve_symlink {
  my ($pack, $filePath) = @_;

  print STDERR "# resolve_symlink($filePath)...\n" if DEBUG;

  (undef, my ($realDir)) = fileparse($filePath);

  while (defined (my $linkText = readlink $filePath)) {
    ($filePath, $realDir) = resolve_symlink_1($pack, $linkText, $realDir);
    print STDERR "# => $filePath (realDir=$realDir)\n" if DEBUG;
  }

  return $filePath;
}

sub resolve_symlink_1 {
  my ($pack, $linkText, $realDir) = @_;

  my $filePath = do {
    if (File::Spec->file_name_is_absolute($linkText)) {
      $linkText;
    } else {
      File::Spec->catfile($realDir, $linkText);
    }
  };

  if (wantarray) {
    # purify x/../y to y
    my $realPath = Cwd::realpath($filePath);
    (undef, $realDir) = fileparse($realPath);
    ($realPath, $realDir);
  } else {
    $filePath;
  }
}

1;
