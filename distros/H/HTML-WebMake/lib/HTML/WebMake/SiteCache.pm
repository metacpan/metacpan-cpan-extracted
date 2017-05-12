#

package HTML::WebMake::SiteCache;

###########################################################################


use Carp;

BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File SDBM_File); }
use AnyDBM_File;

use Fcntl;
use File::Spec;
use strict;

use HTML::WebMake::Main;

use vars	qw{
  	@ISA $DB_MODULE $UNDEF_SYMBOL
};

@ISA = qw();

$DB_MODULE = undef;

$UNDEF_SYMBOL = '!!UnDeF';

###########################################################################

sub new ($$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $fname) = @_;

  die ("no cache filename") unless defined($fname);

  my $self = {
    'main'		=> $main,
    'filename'		=> $fname,

    'front_metadata_cache'	=> { }
  };

  bless ($self, $class);

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

sub tie {
  my ($self) = @_;

  my $try = 0;
  my %db;
  for ($try = 0; $try < 4; $try++)
  {
    my $dbobj = tie (%db, 'AnyDBM_File', $self->{filename},
				  O_CREAT|O_RDWR, 0600)
	  or die "Cannot open/create site cache: $self->{filename}\n";

    if ($AnyDBM_File::ISA[0] ne 'DB_File') {
      dbg ("cannot do db ownership security check on this platform");
      goto all_ok;
    }

    # check the open db file for ownership, to make sure it really
    # is owned by us and we're not the victim of a race exploit.
    my $fd = $dbobj->fd(); undef $dbobj;
    # dbg ("checking ownership of site cache: $self->{filename} fd=$fd");
    open (DB_FH, "+<&=$fd") || die "dup $!";
    if (-o DB_FH) { goto all_ok; }

    warn "Site cache file is not owned by us. Deleting and retrying.\n";
    system ("ls -l '".$self->{filename}."' 1>&2");
    untie ($self->{db});
    unlink ($self->{filename});
  }

  die "Site cache file is not owned by us. Giving up.\n";

all_ok:
  # all's well, no funny tricks are underway
  dbg ("opened site cache: $self->{filename}");
  $self->{db} = \%db;
  return;
}

# -------------------------------------------------------------------------

sub untie {
  my ($self) = @_;

  untie ($self->{db}) or die "untie failed";
  dbg ("closed site cache: $self->{filename}");
}

# -------------------------------------------------------------------------

sub get_modtime {
  my ($self, $file) = @_;
  return $self->{db}{'m#'.$file};
}

sub set_modtime {
  my ($self, $fname, $mod) = @_;
  $self->{db}{'m#'.$fname} = $mod;
}

# -------------------------------------------------------------------------

sub set_content_deps {
  my ($self, $file, %deps) = @_;
  my ($fname, $mod);

  my $depstr = '';
  while (($fname, $mod) = each %deps) {
    $self->{db}{'m#'.$fname} = $mod;
    $depstr .= "\0".$fname;
  }
  $self->{db}{'d#'.$file} = $depstr;
}

sub get_content_deps {
  my ($self, $file) = @_;
  my $str = $self->{db}{'d#'.$file};

  if (defined $str) {
    return split (/\0/, $self->{db}{'d#'.$file});
  } else {
    return ();		# an empty list
  }
}

# -------------------------------------------------------------------------

sub get_metadata {
  my ($self, $key) = @_;
  my $val = $self->{db}{'M#'.$key};

  # we use an additional, in-memory cache to avoid writing metadata
  # that matches what was already there
  $self->{front_metadata_cache}->{$key} = $val;

  if (defined $val && $val eq $UNDEF_SYMBOL) { return undef; }
  return $val;
}

sub put_metadata {
  my ($self, $key, $val) = @_;
  if (!defined $key) { return; }
  if (!defined $val) { $val = $UNDEF_SYMBOL; }

  # we use an additional, in-memory cache to avoid writing metadata
  # that matches what was already there
  my $front = $self->{front_metadata_cache}->{$key};
  if (defined $front && $front eq $val) { return; }

  dbg ("caching metadata '$key' = '$val'");
  $self->{db}{'M#'.$key} = $val;
}

# -------------------------------------------------------------------------

sub get_format_conversion {
  my ($self, $contobj, $fmts, $pretext) = @_;

  my $cachename = $self->{db}{'F#'.$fmts.'#'.$contobj->{name}};
  if (!defined $cachename) { return; }

  my $thenmtime = $self->{main}->cached_get_modtime ($cachename);
  if (!defined $thenmtime) { return; }

  my $nowmtime = $contobj->get_modtime ();

  if ($thenmtime < $nowmtime || !open (IN, "<$cachename")) {
    return;
  }

  dbg ("using cached format conversion for ".$contobj->as_string());
  my $txt = join ('', <IN>);
  close IN;
  return $txt;
}

sub store_format_conversion {
  my ($self, $contobj, $fmts, $posttext) = @_;

  # convert the content object's name and formats to a checksum
  # value, to avoid filename clashes whereever possible.
  my $fname = $fmts.'#'.$contobj->{name};
  $fname = $contobj->{name}.'.'.unpack("%32C*", $fname);
  $fname =~ s/[^A-Za-z0-9]/_/g;

  my $cachename = File::Spec->catfile ($self->{main}->cachedir(), $fname);

  if (!open (OUT, ">$cachename")) { goto giveup; }
  print OUT $posttext;
  if (!close OUT) { goto giveup; }

  $self->{db}{'F#'.$fmts.'#'.$contobj->{name}} = $cachename;
  dbg ("cached format conversion for ".$contobj->as_string().": $cachename");
  return;

giveup:
  warn "cannot write to $cachename\n";
  unlink ($cachename);
  return;
}

# -------------------------------------------------------------------------

1;
