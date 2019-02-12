## -*- Mode: CPerl -*-
## File: Lingua::TT::DBx::Document.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Document via Berkely DB


package Lingua::TT::DBx::Document;
use Lingua::TT::Document;
use Lingua::TT::DBx::Field;
use Lingua::TT::DBFile;
use Lingua::TT::DBFile::Hash;
use Lingua::TT::DBFile::BTree;
use Lingua::TT::DBFile::Array;
use Lingua::TT::DBFile::PackedArray;
use File::Path qw(mkpath);
use File::Basename qw(basename dirname);
use DB_File;
use Fcntl;
use Encode qw(encode decode);
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::Document);

our $DEFAULT_FIELDS = ['ttline'];

##==============================================================================
## Constructors etc.


## $dbdoc = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$dbdoc:
##   ##-- options
##   dir    => $dirname,  ##-- db dirname
##   fields => \@fields,  ##-- data fields (default: none)
##   ##
##   ##-- open() options:
##   nocreate => $bool,   ##-- don't implicitly create $dir (default=0)
##   truncate => $bool,   ##-- implicitly truncate files in $dir (implies nocreate=>0)
##   flags    => $flags,  ##-- Fcntl O_* flags for DB_File (default: O_RDWR|...)
sub new {
  my $that = shift;
  my $dbdoc = bless({
		     ##-- options
		     dir => undef,
		     fields => undef,

		     ##-- open() options
		     flags => O_RDWR,

		     ##-- user args
		     @_,
		    }, ref($that)||$that);
  $dbdoc->fields(@{$dbdoc->{fields}||$DEFAULT_FIELDS});
  return $dbdoc->open($dbdoc->{dir}) if (defined($dbdoc->{dir}));
  return $dbdoc;
}

## $doc = CLASS_OR_OBJECT->newFromString($str)
##  + should be equivalent to CLASS_OR_OBJECT->new()->fromString($str)
##  + INHERITED from Lingua::TT::Document

## \&dummysub = _dummy($SUBNAME)
sub _dummy {
  my $subname = shift;
  return sub {
    croak( __PACKAGE__ . "::$subname() not yet implemented!" );
  };
}

## $doc2 = $doc->copy($depth)
##  + creates a copy of $doc
##  + if $depth is 0, only a shallow copy is created (sentences & tokens are shared)
##  + if $depth is >=1 (or <0), sentences are copied as well (tokens are still shared)
##  + if $depth is >=2 (or <0), tokens are copied as well
BEGIN { *copy = _dummy('copy'); }


##==============================================================================
## Methods: Fields

## \@fields = $dbdoc->fields(@FIELD_SPECS)
##   + compiles $dbdoc->{fields} from @FIELD_SPECS
sub fields {
  my ($dbdoc,@fields) = @_;
  my ($fspec,$f);
  my $fields = $dbdoc->{fields} = [];
  foreach $fspec (@fields) {
    if (UNIVERSAL::isa($fspec,'Lingua::TT::DBx::Field')) {
      $fspec = $fspec->new() if (!ref($fspec));
      push(@$fields,$fspec);
    } elsif (UNIVERSAL::isa(('Lingua::TT::DBx::Field::'.lc($fspec)),'Lingua::TT::DBx::Field')) {
      push(@$fields,('Lingua::TT::DBx::Field::'.lc($fspec))->new);
    } elsif (!ref($fspec)) {
      my ($name,$packfmt) = $fspec =~ /^.*\:.$/ ? ($1,$2) : ($fspec,'L');
      push(@$fields, Lingua::TT::DBx::Field->new(name=>$name,packfmt=>$packfmt));
    } elsif (UNIVERSAL::isa($fspec,'HASH')) {
      push(@$fields,Lingua::TT::DBx::Field->new(%$fspec));
    } elsif (UNIVERSAL::isa($fspec,'ARRAY')) {
      push(@$fields,Lingua::TT::DBx::Field->new(@$fspec));
    } elsif (UNIVERSAL::isa($fspec,'CODE')) {
      push(@$fields,$fspec->($dbdoc));
    } else {
      warn(ref($dbdoc)."::fields(): cannot parse field spec $fspec - skipping");
    }
  }
  $_->{dir} = $dbdoc->{dir} foreach (@{$dbdoc->{fields}});
  return $dbdoc->{fields};
}

##==============================================================================
## Methods: I/O: open, close, sync

## $bool = $dbdoc->opened()
sub opened {
  my $dbdoc = shift;
  return defined($dbdoc->{dir}) && !grep {!$_ || !$_->opened} @{$dbdoc->{fields}}, @$dbdoc{qw(docs sents cmts)};
}

## $bool = $dbdoc->sync()
##  + syncs all files
sub sync {
  my $dbdoc = shift;
  my $rc = $dbdoc->saveLocalFiles();
  foreach (@{$dbdoc->{fields}}, @$dbdoc{qw(docs sents cmts)}) {
    $rc &&= $_->sync();
  }
  return $rc;
}

## $bool = $dbdoc->close(%opts)
##  + %opts:
##     nosync => $bool,     ##-- if true, no implicit sync() will be performed (default=0)
sub close {
  my ($dbdoc,%opts) = @_;
  my $rc = $opts{nosync} ? 1 : $dbdoc->sync();
  foreach (@{$dbdoc->{fields}}, @$dbdoc{qw(docs sents cmts)}) {
    $rc &&= $_->close(%opts);
  }
  return $rc;
}

## $dbdoc = $dbdoc->open($dir,%opts)
##  + %opts:
##     nocreate => $bool,   ##-- don't implicitly create $dir (default=0)
##     truncate => $bool,   ##-- implicitly truncate files in $dir (implies nocreate=>0)
##     mode     => $mode,   ##-- Fcntl mode for DB_File (default: O_RDWR|...)
sub open {
  my ($dbdoc,$dir,%opts) = @_;
  $dir =~ s/\/+$//;
  $dbdoc->close if ($dbdoc->opened);
  @$dbdoc{keys %opts} = values(%opts);
  $dbdoc->{dir} = $dir;

  $dbdoc->{flags} = O_RDWR if (!defined($dbdoc->{flags}));

  ##-- implicit create?
  if (!$dbdoc->{nocreate}) {
    $dbdoc->{flags} |= O_CREAT;
    -d $dir || File::Path::mkpath($dir)
	or confess(ref($dbdoc)."::open(+create): mkpath() failed for '$dir': $!");
  }

  ##-- load local files (only if not truncating)
  $dbdoc->loadLocalFiles if (!$dbdoc->{truncate});

  ##-- set basic field data dir
  @$_{qw(dir flags)} = @$dbdoc{qw(dir flags)} foreach (@{$dbdoc->{fields}});

  ##-- truncate field datafiles before open?
  if ($dbdoc->{truncate}) {
    $dbdoc->{flags} |= O_TRUNC;
    foreach (@{$dbdoc->{fields}}) {
      next if ($dbdoc->{nocreate} && !$_->fileExists);
      $_->truncate();
    }
  }
  ##-- open local data files
  ##  + docs:   ARRAY: $file_i => join("\t", $doc_offset_nsents, $doc_filename)."\n"
  ##  + sents:  ARRAY: $sent_i =>  pack('L', $sent_offset_ntoks)
  ##  + cmts:   BTREE: $tok_i  => join("\n", @comment_lines_before_tok_i)
  $dbdoc->{docs} = Lingua::TT::DBFile::Array->new(file=>"$dir/docs.db",
						    flags=>$dbdoc->{flags}
						   )
    or confess(ref($dbdoc)."::open(): open failed for '$dir/docs.db': $!");
  $dbdoc->{sents} = Lingua::TT::DBFile::PackedArray->new(file=>"$dir/sents.db",
							   flags=>$dbdoc->{flags},
							   packfmt=>'L')
    or confess(ref($dbdoc)."::open(): open failed for '$dir/sents.db': $!");
  $dbdoc->{cmts} = Lingua::TT::DBFile::BTree->new(file=>"$dir/cmts.db",
						    flags=>$dbdoc->{flags},
						    dbopts=>{compare=>sub { $_[0] <=> $_[1] }},
						   )
    or confess(ref($dbdoc)."::open(): open failed for '$dir/cmts.db': $!");

  ##-- open field data files
  foreach (@{$dbdoc->{fields}}) {
    $_->open(flags=>$dbdoc->{flags})
      or confess(ref($dbdoc)."::open(): open failed for field name '$_->{name}': $!");
  }

  ##-- compile field closures
  $_->compileClosures() foreach (@{$dbdoc->{fields}});

  return $dbdoc;
}

##==============================================================================
## Methods: I/O: utils

## $dbdoc = $dbdoc->truncate()
sub truncate {
  my $dbdoc = shift;
  my $dir = $dbdoc->{dir};
  return if (!defined($dir));
  CORE::truncate("$dir/config.pm",0);
  $_->truncate() foreach (@{$dbdoc->{fields}}, @$dbdoc{qw(docs sents cmts)});
  return $dbdoc;
}

## $dbdoc = $dbdoc->loadLocalFiles()
sub loadLocalFiles {
  my $dbdoc = shift;
  my $dir   = $dbdoc->{dir}||'.';

  ##-- load: config
  $dbdoc->loadPerlFile("$dir/config.plm")
    or confess(ref($dbdoc)."::loadLocalFiles(): load failed for '$dir/config.plm': $!");

  return $dbdoc;
}

## $dbdoc = $dbdoc->saveLocalFiles();
sub saveLocalFiles {
  my $dbdoc = shift;
  my $dir = $dbdoc->{dir} || '.';

  ##-- save: config
  $dbdoc->savePerlFile("$dir/config.plm")
    or confess(ref($dbdoc)."::saveLocalFiles(): save failed for '$dir/config.plm': $!");

  return $dbdoc;
}

## @filenames = $dbdoc->datafiles()
sub datafiles {
  my $dbdoc = shift;
  my $dir = $dbdoc->{dir};
  return ("$dir/config.plm",
	  "$dir/docs.db",
	  "$dir/sents.db",
	  "$dir/cmts.db",
	  (map {$_->datafiles} @{$dbdoc->{fields}}),
	 );
}

##==============================================================================
## Methods: I/O: TT::Persistent interface

## @keys = $class_or_obj->noSaveKeys()
sub noSaveKeys {
  return (qw(fields dir truncate nocreate flags docs sents cmts));
}

## $ref = $dbdoc->savePerlRef()
sub savePerlRef {
  my $obj = shift;
  my $ref = $obj->SUPER::savePerlRef();
  $ref->{fields} = [map {$_->savePerlRef} @{$obj->{fields}}];
  delete(@$_{qw(dir file flags)}) foreach (@{$ref->{fields}});
  return $ref;
}

## $ref = $dbdoc->loadPerlRef()
sub loadPerlRef {
  my ($that,$ref) = @_;
  my $obj = $that->SUPER::loadPerlRef($ref);
  foreach (@{$obj->{fields}}) {
    $_->{dir}   = $obj->{dir}   if (defined($obj->{dir}));
    $_->{flags} = $obj->{flags} if (defined($obj->{flags}));
    #$_->{file}  = $_->filename;
  }
  return $obj;
}

##==============================================================================
## Methods: Access: add TT Data

## $offset = $dbdoc->offset()
##  + gets current (max) token offset
sub offset {
  return $_[0]{fields}[0]{dbf}{tied}->length;
}

## $dbdoc = $dbdoc->putLine($tokstr)
sub putLine {
  $_[0]->putToken(Lingua::TT::Token->newFromString($_[1]));
  return $_[0];
}

## $dbdoc = $dbdoc->putToken(\@tok)
sub putToken {
  if ($_[1][0] =~ /^\s*\%\%/) {
    ##-- comment
    my $off = $_[0]->offset;
    if (!exists($_[0]{cmts}{data}{$off})) {
      $_[0]{cmts}{data}{$off} = join("\t", @{$_[1]})."\n";
    } else {
      $_[0]{cmts}{data}{$off} .= join("\t", @{$_[1]})."\n";
    }
  } else {
    ##-- vanilla
    $_->putToken($_[1]) foreach (@{$_[0]{fields}});
  }
  return $_[0];
}

## $dbdoc = $dbdoc->putSentence($sent)
sub putSentence {
  my $off0 = $_[0]{sents}{data}[$#{$_[0]{sents}{data}}];
  my $off1 = pack('L',$_[0]->offset);
  push(@{$_[0]{sents}{data}}, $off1) if (!defined($off0) || $off1 ne $off0);
  $_[0]->putToken($_) foreach (@{$_[1]});
  push(@{$_[0]{sents}{data}}, pack('L',$_[0]->offset)) if (@{$_[1]});
  return $_[0];
}

## $dbdoc = $dbdoc->putDocument($doc)
sub putDocument {
  $_[0]->putSentence($_) foreach (@{$_[1]});
  return $_[0];

}

## $dbdoc = $dbdoc->putIO($io)
sub putIO {
  $_[0]->putDocument($_[1]->getDocument);
}


##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## OLD TT::Document API
##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
__END__

##==============================================================================
## Methods: Access & Manipulation

## $nSents = $doc->nSentences()
sub nSentences {
  return scalar(@{$_[0]});
}

## $nToks = $doc->nTokens()
sub nTokens {
  my $n = 0;
  $n += scalar(@$_) foreach (@{$_[0]});
  return $n;
}

## $bool = $doc->isEmpty()
##  + true iff $sent has no non-empty sentences
sub isEmpty {
  return !grep {!$_->isEmpty} @{$_[0]};
}

## $doc = $doc->rmEmptySentences()
##  + removes empty & undefined sentences from @$doc
sub rmEmptySentences {
  @{$_[0]} = grep {defined($_) && !$_->isEmpty} @{$_[0]};
  return $_[0];
}

## $doc = $doc->rmEmptyTokens()
##  + removes all empty tokens from all sentences in @$doc
sub rmEmptyTokens {
  $_->rmEmptyTokens foreach (@{$_[0]});
  return $_[0];
}

## $doc = $doc->rmComments()
##  + removes all comment pseudo-tokens from all sentences in @$doc
sub rmComments {
  $_->rmComments foreach (@{$_[0]});
  return $_[0];
}

## $doc = $doc->rmNonVanilla()
##  + removes non-vanilla tokens from all sentences in @$doc
sub rmNonVanilla {
  $_->rmNonVanilla foreach (@{$_[0]});
  return $_[0];
}

## $doc = $doc->canonicalize()
##  + removes all non-vanilla tokens and empty setences from @$doc
sub canonicalize {
  $_[0]->rmNonVanilla;
  $_[0]->rmEmptySentences;
  return $_[0];
}

## $tokens = $doc->flat()
##  + returns flat list of pseudo-tokens (sentence boundaries replaced with "empty" tokens)
sub flat {
  my $doc   = shift;
  my $sflat = Lingua::TT::Sentence->new;
  my $eos   = Lingua::TT::Token->new('');
  @$sflat   = map {(@$_,$eos)} @$doc;
  pop(@$sflat); ##-- remove final $eos
  #@$doc     = ($sflat);
  #return $doc;
  ##--
  return $sflat;
}

##==============================================================================
## Methods: I/O

##--------------------------------------------------------------
## Methods: I/O: TT

## $str = $doc->toString()
##  + returns string representing $doc
BEGIN { *saveNativeString = \&toString; }
sub toString {
  return join("\n", map {$_->toString} @{$_[0]})."\n";
}

## $doc = $doc->fromString($str)
##  + parses $doc from string $str
BEGIN { *load = *loadNativeString = \&fromString; }
sub fromString {
  #my ($sent,$str) = @_;
  @{$_[0]} = map {Lingua::TT::Sentence->newFromString($_)} split(/(?:\r?\n){2}/,$_[1]);
  return $_[0];
}

## $doc = $CLASS_OR_OBJECT->fromFile($filename_or_fh,%opts)
##  + parses $doc from file
BEGIN { *loadNativeFile = \&fromFile; }
sub fromFile {
  my ($doc,$file,%opts) = @_;
  my $ttio = Lingua::TT::IO->fromFile($file,%opts)
    or die((ref($doc)||$doc)."::fromFile(): open failed for '$file': $!");
  my $got = $ttio->getDocument;
  $ttio->close();
  return $got if (!ref($doc));
  @$doc = @$got;
  return $doc;
}

## $doc = $CLASS_OR_OBJECT->toFile($filename_or_fh,%opts)
##  + saves $doc to file
BEGIN { *save = *saveNativeFile = \&toFile; }
sub toFile {
  my ($doc,$file,%opts) = @_;
  my $ttio = Lingua::TT::IO->toFile($file,%opts)
    or die((ref($doc)||$doc)."::toFile(): open failed for '$file': $!");
  my $rc = $ttio->putDocument($doc);
  $ttio->close();
  return $rc ? $doc : undef;
}


##==============================================================================
## Methods: Shuffle & Split

## $doc = $doc->shuffle(%opts)
##  + randomly re-orders sentences in @$doc to @$doc2
##  + %opts:
##    seed => $seed, ##-- calls srand($seed) if defined
sub shuffle {
  my ($doc,%opts) = @_;
  srand($opts{seed}) if (defined($opts{seed}));
  my @keys = map {rand} @$doc;
  @$doc = @$doc[sort {$keys[$a]<=>$keys[$b]} (0..$#$doc)];
  return $doc;
}

##  @docs = $doc->splitN($n)  ##-- array context
## \@docs = $doc->splitN($n)  ##-- scalar context
##  + splits $doc deterministically into $n roughly equally-sized @docs
##  + sentence data is shared (refs) between $doc and @docs
##  + for a random split, call $doc->shuffle(seed=>$seed)->splitN($n)
sub splitN {
  my ($doc,$n,%opts) = @_;
  my @odocs  = map {$doc->new} (1..$n);
  my @osizes = map {0} @odocs;
  my ($sent,$oi,$oi_min);
  foreach $sent (@$doc) {
    ##-- find smallest @odoc
    $oi_min = 0;
    foreach $oi (1..$#odocs) {
      $oi_min = $oi if ($osizes[$oi] < $osizes[$oi_min]);
    }
    push(@{$odocs[$oi_min]}, $sent);
    $osizes[$oi_min] += scalar(@$sent);
  }
  return wantarray ? @odocs : \@odocs;
}


##==============================================================================
## Footer
1;

__END__
