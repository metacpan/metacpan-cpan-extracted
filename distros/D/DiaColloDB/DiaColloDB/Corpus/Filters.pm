## -*- Mode: CPerl -*-
## File: DiaColloDB::Corpus::Filters.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source corpus content filters

package DiaColloDB::Corpus::Filters;
use DiaColloDB::Persistent;
use Exporter;
use strict;

##==============================================================================
## Administrivia

our @ISA = qw(Exporter DiaColloDB::Persistent);

our @NAMES = qw(pgood pbad wgood wbad lgood lbad);
our @FILES = map {$_."file"} @NAMES;
our %EXPORT_TAGS =
  (
   'names'    => [qw(@NAMES)],
   'defaults' => [map {uc($_)."_DEFAULT"} @NAMES],
  );
$EXPORT_TAGS{all} = [@{$EXPORT_TAGS{names}},@{$EXPORT_TAGS{defaults}}];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};
our @EXPORT    = qw();

##==============================================================================
## Defaults (formerly in DiaColloDB.pm)

## $PGOOD_DEFAULT
##  + default positive pos regex for document parsing
##  + don't use qr// here, since Storable doesn't like pre-compiled Regexps
our $PGOOD_DEFAULT   = q/^(?:N|TRUNC|VV|ADJ)/; #ITJ|FM|XY

## $PBAD_DEFAULT
##  + default negative pos regex for document parsing
our $PBAD_DEFAULT   = undef;

## $WGOOD_DEFAULT
##  + default positive word regex for document parsing
our $WGOOD_DEFAULT   = q/[[:alpha:]]/;

## $WBAD_DEFAULT
##  + default negative word regex for document parsing
our $WBAD_DEFAULT   = q/[\.]/;

## $LGOOD_DEFAULT
##  + default positive lemma regex for document parsing
our $LGOOD_DEFAULT   = undef;

## $LBAD_DEFAULT
##  + default negative lemma regex for document parsing
our $LBAD_DEFAULT   = undef;

##==============================================================================
## Methods

## $filters = CLASS_OR_OBJECT->new(%opts)
##   + simple HASH-ref wrapping filters
sub new {
  my $that = shift;
  my $filters = bless({
                       pgood => $PGOOD_DEFAULT,
                       pbad  => $PBAD_DEFAULT,
                       wgood => $WGOOD_DEFAULT,
                       wbad  => $WBAD_DEFAULT,
                       lgood => $LGOOD_DEFAULT,
                       lbad  => $LBAD_DEFAULT,
                       (map {($_=>undef)} @FILES),
                       @_,
                      }, ref($that)||$that);
  return $filters;
}

## $filters = $CLASS_OR_OBJECT->null()
sub null {
  my $that = shift;
  return bless({},ref($that)||$that)
}

## $filters = $filters->clear()
sub clear {
  my $filters = shift;
  $_ = undef foreach (values %$filters);
  return $filters;
}

## $bool = $filters->empty()
##  + returns true iff all filters are undefined
sub isnull {
  return !grep {$_} @{$_[0]}{@NAMES,@FILES};
}

## $bool = $filters1->equal($filters2)
## $bool = PACKAGE->equal($filters1,$filters2)
##  + returns true iff filters are equal
sub equal {
  my $that = shift;
  my ($f1,$f2) = map {($_//{})} (@_ > 1 ? @_ : ($that,shift));
  return !grep {($f1->{$_}//'') ne ($f2->{$_}//'')} @NAMES,@FILES;
}

## \%name2obj = $filters->compile()
## \%name2obj = PACKAGE->compile(\%filters)
##  + returns HASH-ref of compiled filter regexes and (stop|go)-hashes
##      ${NAME}     => $REGEX,
##      ${NAME}file => \%HASHREF,
sub compile {
  my $that = shift;
  my $filters = @_ ? shift : $that;
  return {
          ##-- compile: filter regexes
          (map {($_=>qr{$filters->{$_}})} grep {$filters->{$_}} @NAMES),

          ##-- compile: filter list-files
          (map {($_=>$that->loadListFile($filters->{$_}))} grep {$filters->{$_}} @FILES),
         };
}

## \%line2undef = $coldb->loadListFile($filename_or_undef)
sub loadListFile {
  my ($that,$file) = @_;
  return undef if (($file//'') eq '');
  CORE::open(my $fh,"<$file")
      or $that->logconfess("loadListFile(): open failed for '$file': $!");
  my $h = {};
  while (defined($_=<$fh>)) {
    chomp;
    next if (/^\s*(?:\#.*)$/); ##-- skip comments and blank lines
    $h->{$_} = undef;
  }
  CORE::close($file);
  return $h;
}


##==============================================================================
## Footer
1;

__END__




