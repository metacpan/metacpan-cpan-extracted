##-*- Mode: CPerl -*-

package GermaNet::Flat;
use XML::Parser;
use IO::File;
use Fcntl;
use File::Basename qw(basename dirname);
use Carp;
use strict;
use 5.010; ##-- v5.10.0: for // operator

##==============================================================================
## Constants

our $VERSION = 0.04;

##-- constants: verbosity levels
our $vl_silent   = 0;
our $vl_error    = 1;
our $vl_warn     = 2;
our $vl_info     = 3;
our $vl_progress = 4;
our $vl_debug    = 5;

##==============================================================================

## Constructors etc
sub new {
  my $that = shift;
  return bless({
		verbose => $vl_info,
		rel=>{}, ##-- "${relation}:${arg}" => join(' ',@vals), ...
		#dbf=>undef,

		@_,
	       },
	       ref($that)||$that);
}

## $gn = $gn->clear();
sub clear {
  my $gn = shift;
  %{$gn->{rel}} = qw();
  delete @$gn{qw(dbf)};
  return $gn;
}

##==============================================================================
## Verbosity

sub vmsg0 {
  my $gn = shift;
  my $level = shift;
  print STDERR @_ if (ref($gn) && ($gn->{verbose}//0) >= $level);
}
sub vmsg {
  $_[0]->vmsg0($_[1], (ref($_[0])||$_[0]).": ", @_[2..$#_], "\n");
}
sub vpdo {
  my ($gn,$lvl,$msg,$sub) = @_;
  $gn->vmsg0($lvl, (ref($gn)||$gn), ": $msg");
  $sub->() if ($sub);
  $gn->vmsg0($lvl, " done.\n");
}

##==============================================================================
## Utils

## \@array_uniq =      auniq(\@array)
## \@array_uniq = $gn->auniq(\@array)
sub auniq {
  shift if (@_ && UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($prev);
  @{$_[0]} = grep {($prev//'') eq ($_//'') ? qw() : ($prev=$_)} sort @{$_[0]};
  return $_[0];
}

## @uniq =      luniq(@list)
## @uniq = $gn->luniq(@list)
sub luniq {
  shift if (@_ && UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($prev);
  return grep {($prev//'') eq ($_//'') ? qw() : ($prev=$_)} sort @_;
}

## $gn = $gn->sanitize()
sub sanitize {
  my $gn = shift;
  foreach (values %{$gn->{rel}}) {
    $_ = join(' ', luniq split(' ',$_));
  }
  return $gn;
}

##==============================================================================
## API: Relations: Generic

## \@vals = $gn->relation($rel,   $arg)
## \@vals = $gn->relation($rel, \@args)
##  + not necessarily unique values
sub relation {
  #my ($gn,$rel,$arg) = @_;
  return [map {split(' ',($_[0]->{rel}{"$_[1]:$_"}//''))} (UNIVERSAL::isa($_[2],'ARRAY') ? @{$_[2]} : ($_[2]//''))];
}



##----------------------------------------------------------------------
## API: Relations: Common

## \&CODE = relationWrapper($relation)
##  + returns unique values only
sub relationWrapper {
  my $rel = shift;
  return sub {
    return auniq( $_[0]->relation($rel,@_[1..$#_]) );
  };
}

## \@lexids = $gn->orth2lex($lemma)
## \@lemmas = $gn->lex2orth($lemma)
## \@synids = $gn->lex2syn($lexid)
## \@lexids = $gn->syn2lex($synid)
## \@subids  = $gn->hypernyms($synid) = $gn->hyperonyms($synid)
## \@supids  = $gn->hyponyms($synid)
BEGIN {
  *orth2lex = relationWrapper('orth2lex');
  *lex2orth = relationWrapper('lex2orth');
  *lex2syn  = relationWrapper('lex2syn');
  *syn2lex  = relationWrapper('syn2lex');
  *hyperonyms = *hypernyms = relationWrapper('has_hypernym');
  *hyponyms   = relationWrapper('has_hyponym');
}

## $dbversion = $gn->dbversion()
sub dbversion {
  return $_[0]->relation('dbversion')->[0];
}

##----------------------------------------------------------------------
## API: compat

## \@synsets_or_undef = $gn->get_synsets($lemma);
##  + uniqueness not guaranteed
sub get_synsets {
  return $_[0]->relation('lex2syn',$_[0]->relation('orth2lex',$_[1]));
}

## \@terms_or_undef = $gn->synset_terms($synset);
##  + uniqueness not guaranteed
sub synset_terms {
  return $_[0]->relation('lex2orth',$_[0]->relation('syn2lex',$_[1]));
}

##==============================================================================
## Input: generic

## $gn = $CLASS_OR_OBJECT->load($filename_or_xmldirname)
sub load {
  my ($gn,$file) = @_;
  $gn = $gn->new() if (!ref($gn));

  return $gn->loadXmlDir($file) if (-d $file);
  return $gn->loadBin($file) if ($file =~ /\.(?:bin|sto)$/i);
  return $gn->loadDB($file)  if ($file =~ /\.(?:b?)db$/i);
  return $gn->loadCDB($file)  if ($file =~ /\.cdb$/i);
  return $gn->loadText($file);
}


##==============================================================================
## Input: XML

## $gn = CLASS_OR_OBJECT->loadXmlDir($directoryx)
##  + loaded data appended to existing relations, no implicit clear()
sub loadXmlDir {
  my ($gn,$dir) = @_;
  $dir =~ s/\/+$//;
  $gn = $gn->new() if (!ref($gn));

  ##-- try to load db version
  my $dbversion = "unknown";
  if (-r "$dir/VERSION") {
    open(my $fh,"<$dir/VERSION")
      or confess(__PACKAGE__ . "::loadXmlDir(): could not open $dir/VERSION: $!");
    $dbversion = <$fh>;
    close $fh;
  } elsif (basename($dir) =~ /[\.\-](\d[\d\.\-]*$)/) {
    $dbversion = $1;
  }
  chomp($dbversion);
  $gn->{rel}{"dbversion:"} = $dbversion;
  $gn->vmsg($vl_progress, "loadXmlDir(): set dbversion = ", ($dbversion//'-undef-'));

  ##-- load guts
  return $gn->loadXml(glob("$dir/*.xml"));
}


## $gn = CLASS_OR_OBJECT->loadXml(@xml_filenames_or_handles)
##  + loaded data appended to existing relations, no implicit clear()
sub loadXml {
  my $gn = shift;
  $gn = $gn->new() if (!ref($gn));
  $gn->{inmode} = 'xml';

  ##--------------------------------------------------
  ## XML: callbacks
  my ($_xp, $_elt, %attrs);
  my ($dir,$synset,$lexid,$isorth,$oform);
  my $rel = $gn->{rel};
  my %xml_relations = (con_rel=>1, lex_rel=>1);

  ##--------------------------------------------
  ## undef = cb_start($expat, $elt,%attrs)
  my %rel_xlate = (hyperonymy=>'has_hypernym', 'hyponymy'=>'has_hyponym');
  my ($relname);
  my $cb_start = sub {
    ($_xp,$_elt,%attrs) = @_;
    if ($_elt eq 'synset') {
      $synset = $attrs{id};
    } elsif ($_elt eq 'lexUnit') {
      $lexid = $attrs{id};
    } elsif ($_elt eq 'orthForm') {
      $isorth = 1;
      $oform  = '';
    } elsif ($xml_relations{$_elt}) {
      $relname = $rel_xlate{$attrs{name}} // $attrs{name};
      $rel->{"$relname:$attrs{from}"} .= "$attrs{to} ";
      $dir = $attrs{dir}//'one';
      if ($dir eq 'revert' && $attrs{inv}) {
	$relname = $rel_xlate{$attrs{inv}} // $attrs{inv};
	$rel->{"$relname:$attrs{to}"} .= "$attrs{from} ";
      } elsif ($dir eq 'both') {
	$rel->{"$relname:$attrs{to}"} .= "$attrs{from} ";
      }
    }
  };

  ##--------------------------------------------
  ## undef = cb_end($expat,$elt)
  my $cb_end = sub {
    if (defined($synset) && $_[1] eq 'orthForm') {
      $oform =~ s/\s/_/g;
      $rel->{"syn2lex:$synset"} .= "$lexid ";
      $rel->{"lex2syn:$lexid"}  .= "$synset ";
      $rel->{"orth2lex:$oform"} .= "$lexid ";
      $rel->{"lex2orth:$lexid"} .= "$oform ";
    }
    elsif ($_[1] eq 'lexUnit') {
      undef $lexid;
    }
    elsif ($_[1] eq 'synset') {
      undef $synset;
    }
  };

  ##--------------------------------------------
  ## undef = cb_char($expat,$str)
  my $cb_char = sub {
    $oform .= $_[1] if ($isorth);
  };

  ##--------------------------------------------------
  ## XML::Parser object
  my $xp = XML::Parser->new(
			    ErrorContext => 1,
			    ProtocolEncoding => 'UTF-8',
			    #ParseParamEnt => '???',
			    Handlers => {
					 #Init  => $cb_init,
					 Char  => $cb_char,
					 Start => $cb_start,
					 End   => $cb_end,
					 #Default => $cb_default,
					 #Final => $cb_final,
					},
			   )
    or confess(ref($gn)."::loadXml(): ERROR: couldn't create XML::Parser");

  ##-- actual load
  foreach my $xmlfile (@_) {
    $gn->vmsg($vl_progress, "loadXml(): parsing $xmlfile ...");
    if ($xmlfile eq '-') {
      $xp->parse(\*STDIN);
    }
    elsif (ref($xmlfile)) {
      $xp->parse($xmlfile);
    }
    else {
      $xp->parsefile($xmlfile);
    }
  }

  $gn->vmsg($vl_progress, "sanitizing ...");
  return $gn->sanitize;
}

##==============================================================================
## I/O: Text

##----------------------------------------------------------------------
## $bool = $gn->saveText($filename_or_fh)
sub saveText {
  my ($gn,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  confess(__PACKAGE__."::saveText(): open failed for '$file'") if (!$fh);
  binmode($fh,':utf8');

  my ($k,$v);
  while (($k,$v)=each %{$gn->{rel}}) {
    $fh->print("$k\t$v\n");
  }

  $fh->close() if (!ref($file));
  return $gn;
}

##----------------------------------------------------------------------
## $bool = $CLASS_OR_OBJECT->loadText($filename_or_fh)
##  + loaded data clobbers existing relations, but no implicit clear()
sub loadText {
  my ($gn,$file) = @_;
  $gn = $gn->new() if (!ref($gn));
  $gn->{inmode} = 'text';
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  confess(__PACKAGE__."::loadText(): open failed for '$file'") if (!$fh);
  binmode($fh,':utf8');

  my ($k,$v);
  while (<$fh>) {
    chomp;
    next if (/^\%\%/ || /^\s*$/);
    ($k,$v) = split(/\t/,$_,2);
    $gn->{rel}{$k} = $v;
  }

  $fh->close() if (!ref($file));
  return $gn;
}

##==============================================================================
## I/O: DB

##----------------------------------------------------------------------
## $gn = $gn->saveDB($dbfilename)
sub saveDB {
  require Lingua::TT::DBFile;
  my ($gn,$dbfile) = @_;

  ##-- test
  if ($dbfile eq '-') {
    $gn->vmsg($vl_warn, "saveDB(): WARNING: dbfile '-' maps to 'GermaNet-Flat.db'");
    $dbfile = 'GermaNet-Flat.db';
  }

  ##-- get db
  my %dbf = ();
  my $dbf = Lingua::TT::DBFile->new(type=>'BTREE',
				    flags=>O_RDWR|O_CREAT|O_TRUNC,
				    encoding=>'utf8',
				    dbopts=>{cachesize=>'32M'},
				   )
    or confess(__PACKAGE__."::saveDB(): could not create Lingua::TT::DBFile: $!");

  $dbf->open($dbfile)
    or confess(__PACKAGE__."::saveDB(): could not open DB file '$dbfile': $!");

  ##-- copy data
  my $rel  = $gn->{rel};
  my $tied = $dbf->{tied};
  foreach (sort keys %$rel) {
    $tied->put($_,$rel->{$_});
  }

  return $gn;
}

##----------------------------------------------------------------------
## $bool = $CLASS_OR_OBJECT->loadDB($dbfile)
##  + implicitly replaces $gn->{rel} with tied data
sub loadDB {
  require Lingua::TT::DBFile;
  my ($gn,$dbfile) = @_;
  $gn = $gn->new() if (!ref($gn));
  $gn->{inmode} = 'db';

  ##-- get db
  my %dbf = ();
  my $dbf = Lingua::TT::DBFile->new(type=>'BTREE',
				    flags=>O_RDONLY,
				    encoding=>'utf8',
				    dbopts=>{cachesize=>'32M'},
				   )
    or confess(__PACKAGE__."::loadDB(): could not create Lingua::TT::DBFile: $!");

  $dbf->open($dbfile)
    or confess(__PACKAGE__."::loadDB(): could not open DB file '$dbfile': $!");

  ##-- attach data
  $gn->{rel} = $dbf->{data};
  $gn->{dbf} = $dbf;

  return $gn;
}


##==============================================================================
## I/O: CDB

##----------------------------------------------------------------------
## $gn = $gn->saveCDB($dbfilename)
##  + utf-8 broken!
sub saveCDB {
  require Lingua::TT::CDBFile;
  my ($gn,$dbfile) = @_;

  ##-- test
  if ($dbfile eq '-') {
    $gn->vmsg($vl_warn, "saveCDB(): WARNING: cdbfile '-' maps to 'GermaNet-Flat.cdb'");
    $dbfile = 'GermaNet-Flat.cdb';
  }

  ##-- get db
  my %dbf = ();
  my $dbf = Lingua::TT::CDBFile->new(mode=>'w')
    or confess(__PACKAGE__."::saveCDB(): could not create Lingua::TT::CDBFile: $!");

  $dbf->open($dbfile)
    or confess(__PACKAGE__."::saveCDB(): could not open CDB file '$dbfile': $!");

  ##-- copy data
  my $writer = $dbf->{writer};
  my ($k,$v);
  while (($k,$v)=each %{$gn->{rel}}) {
    $writer->insert($k,$v);
  }

  ##-- cleanup
  undef $writer;
  $dbf->close();

  return $gn;
}

##----------------------------------------------------------------------
## $bool = $CLASS_OR_OBJECT->loadCDB($dbfile)
##  + implicitly replaces $gn->{rel} with tied data
##  + utf-8 broken!
sub loadCDB {
  require Lingua::TT::CDBFile;
  my ($gn,$dbfile) = @_;
  $gn = $gn->new() if (!ref($gn));
  $gn->{inmode} = 'cdb';

  ##-- get db
  my %dbf = ();
  my $dbf = Lingua::TT::CDBFile->new(mode=>'r')
    or confess(__PACKAGE__."::loadCDB(): could not create Lingua::TT::CDBFile: $!");

  $dbf->open($dbfile)
    or confess(__PACKAGE__."::loadCDB(): could not open CDB file '$dbfile': $!");

  ##-- attach data
  $gn->{rel} = $dbf->{data};
  $gn->{dbf} = $dbf;

  return $gn;
}

##==============================================================================
## I/O: Storable

##----------------------------------------------------------------------
## $bool = $gn->saveBin($filename_or_fh)
sub saveBin {
  require Storable;
  my ($gn,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  confess(__PACKAGE__."::saveBin(): open failed for '$file'") if (!$fh);
  binmode($fh,':raw');
  my $obj = $gn;
  if ($gn->{dbf}) {
    $obj = $gn->new(%$gn, rel=>{ %{$gn->{rel}} });
    delete @$obj{qw(dbf inmode)};
  }
  my $rc = Storable::nstore_fd($obj, $fh);
  $fh->close() if (!ref($file));
  return $rc;
}

##----------------------------------------------------------------------
## $bool = $gn->loadBin($filename_or_fh)
sub loadBin {
  require Storable;
  my ($gn,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  confess(__PACKAGE__."::loadBin(): open failed for '$file'") if (!$fh);
  binmode($fh,':raw');
  my $loaded = Storable::fd_retrieve($fh);
  $fh->close() if (!ref($file));
  return $loaded if (!ref($gn));
  %$gn = %$loaded;
  $gn->{inmode} = 'bin';
  return $gn;
}
