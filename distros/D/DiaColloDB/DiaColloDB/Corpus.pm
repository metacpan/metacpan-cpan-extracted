## -*- Mode: CPerl -*-
## File: DiaColloDB::Corpus.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source corpus (raw + common API)

package DiaColloDB::Corpus;
use DiaColloDB::Document;
use DiaColloDB::Document::DDCTabs;
use DiaColloDB::Document::JSON;
use DiaColloDB::Document::Storable;
#use DiaColloDB::Document::TCF; ##-- only loaded on request
use DiaColloDB::Logger;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Logger);
our $DCLASS_DEFAULT = 'DDCTabs';

##==============================================================================
## Constructors etc.

## $corpus = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    files => \@files,   ##-- source files
##    dclass => $dclass,  ##-- DiaColloDB::Document subclass for loading (default=$DCLASS_DEFAULT)
##    dopts  => \%opts,   ##-- options for $dclass->fromFile()
##    cur    => $i,       ##-- index of current file
##    logOpen => $level,  ##-- log-level for open(); default='info'
##   )
sub new {
  my $that = shift;
  my $corpus  = bless({
		       files => [],
		       dclass => $DCLASS_DEFAULT,
		       dopts => {},
		       cur => 0,
		       logOpen => 'info',

		       @_, ##-- user arguments
		      },
		      ref($that)||$that);
  return $corpus;
}

##==============================================================================
## API: open/close

## $bool = $corpus->open(\@ARGV, %opts)
##  + %opts:
##     compiled => $bool, ##-- attempt to load Corpus::Compiled object (default=1)
##     glob => $bool,     ##-- whether to glob arguments
##     list => $bool,     ##-- whether arguments are file-lists
sub open {
  my ($corpus,$sources,%opts) = @_;
  $corpus = $corpus->new() if (!ref($corpus));
  @$corpus{keys %opts} = values %opts;

  ##-- check for pre-compiled corpora (single-arguments)
  if ($opts{compiled} || (!exists($opts{compiled})
                          && UNIVERSAL::isa($sources,'ARRAY')
                          && @$sources==1
                          && !$opts{list}
                          #&& !$opts{glob}
                          && -e "$sources->[0]/header.json"
                         )) {
    require DiaColloDB::Corpus::Compiled;
    bless($corpus,'DiaColloDB::Corpus::Compiled');
    return $corpus->open($sources,%opts);
  }

  @{$corpus->{files}} = $corpus->{glob} ? (map {glob($_)} @$sources) : @$sources;
  if ($corpus->{list}) {
    ##-- read file-lists
    my $listfiles    = $corpus->{files};
    $corpus->{files} = [];
    foreach my $listfile (@$listfiles) {
      CORE::open(my $fh, "<$listfile")
	or $corpus->logconfess("open failed for list-file '$listfile': $!");
      push(@{$corpus->{files}}, grep {($_//'') ne ''} map {chomp; $_} <$fh>);
      CORE::close($fh);
    }
  }
  $corpus->{cur} = 0;

  ##-- setup document-class
  $corpus->{dclass} = $corpus->dclass();
  $corpus->logwarn("open(): can't resolve DiaColloDB::Document subclass for {dclass} argument '$corpus->{dclass}'")
    if (!UNIVERSAL::isa($corpus->{dclass},'DiaColloDB::Document'));
  $corpus->vlog($corpus->{logOpen}, "using document parser class $corpus->{dclass}");

  return $corpus;
}

## $class = $corpus->dclass()
##  + gets fully qualified input document class
sub dclass {
  return $_[0]{dclass} if (ref($_[0]) && UNIVERSAL::isa($_[0]{dclass},'DiaColloDB::Document'));

  ##-- setup document-class
  my $corpus = shift;
  my $dclass = $corpus->{dclass} || 'DDCTabs';
  foreach my $prefix ('','DiaColloDB::','DiaColloDB::Document::') {
    my $tryclass = $prefix.$dclass;
    if (!UNIVERSAL::isa($tryclass,'DiaColloDB::Document')) {
      ##-- try loading class
      eval "use $tryclass;";
    }
    if (UNIVERSAL::isa($tryclass,'DiaColloDB::Document')) {
      $dclass = $tryclass;
      last;
    }
  }
  $corpus->logwarn("open(): can't resolve DiaColloDB::Document subclass for {dclass} argument '$dclass'")
    if (!UNIVERSAL::isa($dclass,'DiaColloDB::Document'));

  return $dclass;
}

## $bool = $corpus->close()
sub close {
  my $corpus = shift;
  $corpus->{files} = [];
  $corpus->{cur} = 0;
  return $corpus;
}

##==============================================================================
## API: iteration

## $nfiles = $corpus->size()
sub size {
  return scalar(@{$_[0]{files}});
}

## undef = $corpus->ibegin()
##  + reset iterator
sub ibegin {
  $_[0]{cur}=0;
}

## $bool = $corpus->iok()
##  + true if iterator is valid
sub iok {
  return $_[0]{cur} <= $#{$_[0]{files}};
}

## $label = $corpus->ifile()
## $label = $corpus->ifile($pos)
##  + current iterator label
sub ifile {
  return $_[0]{files}[$_[1]//$_[0]{cur}];
}

## $doc_or_undef = $corpus->idocument()
## $doc_or_undef = $corpus->idocument($pos)
##  + gets current document
sub idocument {
  my ($corpus,$pos) = @_;
  $pos //= $corpus->{cur};
  return undef if ($pos > $#{$corpus->{files}});
  return $corpus->{dclass}->fromFile($corpus->{files}[$pos], %{$corpus->{dopts}//{}});
}

## $pos = $corpus->inext()
##  + increment iterator
sub inext {
  ++$_[0]{cur};
}

## $pos = $corpus->icur()
##  + returns current position
sub icur {
  return $_[0]{cur};
}

##==============================================================================
## API: compilation

## $compiled_corpus = $src_corpus->compile($compiled_dbdir, %opts)
##  + wrapper for DiaColloDB::Corpus::Compiled->create($src_corpus, %opts, dbdir=>$compiled_dbdir)
sub compile {
  my ($corpus,$odir,%opts) = @_;
  require DiaColloDB::Corpus::Compiled;
  return DiaColloDB::Corpus::Compiled->create($corpus, %opts, dbdir=>$odir);
}


##==============================================================================
## Footer
1;

__END__




