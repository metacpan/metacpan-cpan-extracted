#

package HTML::WebMake::DataSources::DirOfFiles;

require Exporter;
use File::Find;
use Carp;
use strict;

use HTML::WebMake::DataSourceBase;
use HTML::WebMake::MetaTable;

use vars	qw{
  	@ISA @EXPORT
	$TmpGlobalSelf
};

@ISA = qw(HTML::WebMake::DataSourceBase);
@EXPORT = qw();

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new (@_);
  bless ($self, $class);

  $self;
}

# -------------------------------------------------------------------------

sub add {
  my ($self) = @_;
  local ($_);

  my $main = $self->{main};
  my $src = $self->{src};

  if ($src eq '') { $src = '.'; }

  my $use_find = 0;
  if ($self->{name} =~ s/^(RE:|)\.\.\.\//$1/) {
    $use_find = 1;
  }
  my $patt = $main->{util}->glob_to_re ($self->{name});
  my $pattskip = $main->{util}->glob_to_re ($self->{skip});
  my $pattmetas = $main->{util}->glob_to_re ($self->{metatable});
  my @matched;
  my @matchedmetas;

  $self->{metas} = 0;
  if (defined $pattmetas) {
    $self->{metas} = 1;
    dbg ("searching for files that match \"$patt\" or \"$pattmetas\"");
  } else {
    dbg ("searching for files that match \"$patt\"");
  }

  $src =~ s,/+$,,;

  my $realsrc;
  if ($main->{base_dir} ne '') {
    $realsrc = File::Spec->catdir ($main->{base_dir}, $src);
  } else {
    $realsrc = $src;
  }

  # this regexp is used to convert "/home/jm/jmason.org/raw/index.txt"
  # to just "index.txt", when "raw" is the searched dir and "/home/jm/jmason.org"
  # is the $main->{base_dir}.
  $self->{real_to_underdir_re} = qr/\Q$realsrc\E/;

  if ($use_find) {
    $self->{found} = [ ];
    $self->{foundmetas} = [ ];

    if ($patt =~ m,/,) {
      $self->{find_using_full_path} = 1;
      $patt =~ s/^\^/\//;		# replace start-of-string marker with /
      if (defined $pattskip) { $pattskip =~ s/^\^/\//; }
      if (defined $pattmetas) { $pattmetas =~ s/^\^/\//; }

    } else {
      $self->{find_using_full_path} = 0;
    }

    $self->{find_file_pattern} = $patt;
    $self->{find_file_pattern_skip} = $pattskip;
    $self->{find_file_pattern_metas} = $pattmetas;

    $TmpGlobalSelf = $self;
    find (\&find_wanted, $realsrc);
    undef $TmpGlobalSelf;

    @matched = @{$self->{found}};
    delete $self->{found};

    if ($self->{metas}) {
      @matchedmetas = @{$self->{foundmetas}};
      delete $self->{foundmetas};
    }

  } else {
    if (!opendir (DIR, $realsrc)) {
      warn "can't open ".$self->as_string()." src dir \"$realsrc\": $!\n";
      return;
    }

    # grep for files that (a) match the pattern and (b) are files, not dirs
    my @files = readdir(DIR);

    @matched = grep {
      /^${patt}$/ &&
		(!defined $pattskip || !/^${pattskip}$/) &&
		-f (File::Spec->catfile ($realsrc, $_));
    } @files;

    if (defined $pattmetas) {
      @matchedmetas = grep {
	/^${pattmetas}$/ &&
		(!defined $pattskip || !/^${pattskip}$/) &&
		-f (File::Spec->catfile ($realsrc, $_));
      } @files;
    }

    closedir DIR;
  }

  # add all the data content items
  foreach my $name (@matched) {
    my $fname = File::Spec->catfile ($realsrc, $name);
    my $mtime = $main->cached_get_modtime ($fname);
    if (!defined $mtime || $mtime == 0) {
      warn "cannot stat file $fname\n";
      next;
    }

    $main->add_source_files ($fname);

    my $fixed = $self->{parent}->fixname ($name);
    $self->{parent}->add_file_to_list ($fixed);
    $self->{parent}->add_location ($fixed, "file:".$fname, $mtime);
  }

  # and parse all the metadata files
  foreach my $name (@matchedmetas) {
    my $fname = File::Spec->catfile ($realsrc, $name);
    my $mtime = $main->cached_get_modtime ($fname);
    if (!defined $mtime || $mtime == 0) {
      warn "cannot stat file $fname\n";
      next;
    }

    $main->add_source_files ($fname);
    open (IN, "<$fname");
    my $text = join ('', <IN>);
    close IN;

    # if the metatable was loaded from a subdir, all the content
    # items in that dir will be called e.g. "foo/bar/baz", but the
    # metatable will contain references to "baz".  Fix this...
    $self->{metatable_name_prefix} = '';
    if ($name =~ /^(.+[\/\\])[^\/\\]+/) {
      $self->{metatable_name_prefix} = $1;
    }

    my $tbl = new HTML::WebMake::MetaTable ($self->{main});
    $tbl->set_name_sed_callback ($self, \&fix_names_for_metatable);
    $tbl->parse_metatable ($self->{attrs}, $text);
  }
}

sub fix_names_for_metatable {
  my ($self, $name) = @_;
  $name = $self->{metatable_name_prefix} . $name;
  $name = $self->{parent}->fixname ($name);
  return $name;
}

sub find_wanted {
  -f $_ or return;		# ensure not a dir etc.

  my $self = $TmpGlobalSelf;

  my $matchstr;
  if ($self->{find_using_full_path}) {
    $matchstr = $File::Find::name;
  } else {
    $matchstr = $_;
  }

  my $skip = $self->{find_file_pattern_skip};
  return if (defined $skip && $matchstr =~ /${skip}/);

  ($matchstr =~ /$self->{find_file_pattern}/) and $self->found_datafile();
  if ($self->{metas}) {
    ($matchstr =~ /$self->{find_file_pattern_metas}/) and $self->found_metafile();
  }
}

sub found_datafile {
  my $self = shift;
  my $name = $File::Find::name;
  $name =~ s/^$self->{real_to_underdir_re}\/+//g;
  push (@{$self->{found}}, $name);
}

sub found_metafile {
  my $self = shift;
  my $name = $File::Find::name;
  $name =~ s/^$self->{real_to_underdir_re}\/+//g;
  push (@{$self->{foundmetas}}, $name);
}

# -------------------------------------------------------------------------

sub get_location_url {
  my ($self, $fname) = @_;

  $fname =~ s/^file://;
  return $fname;
}

# -------------------------------------------------------------------------

sub get_location_contents {
  my ($self, $fname) = @_;

  $fname =~ s/^file://;
  if (!open (IN, "<$fname")) {
    carp "cannot open file \"$fname\"\n"; return "";
  }
  my $text = join ('', <IN>); close IN;
  return $text;
}

# -------------------------------------------------------------------------

sub get_location_mod_time {
  my ($self, $fname) = @_;
  $fname =~ /^file:/;
  $self->{main}->cached_get_modtime ($');
}

# -------------------------------------------------------------------------

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

1;
