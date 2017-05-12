## -*- Mode: CPerl -*-
## File: DiaColloDB::Relation::TDF::Query.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: (term x document) frequency matrix: query hacks
##  + formerly DiaColloDB::Relation::Vsem::Query ("vector-space distributional semantic index")

package DiaColloDB::Relation::TDF::Query;
use DiaColloDB::Utils qw(:pdl);
#use DDC::Any; ##-- should already be loaded
use PDL;
use PDL::VectorValued;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Logger);

##==============================================================================
## Constructors etc.

## $vq = CLASS_OR_OBJECT->new(%args)
## $vq = CLASS_OR_OBJECT->new($cquery)
## + %args, object structure:
##   (
##    ##-- ddc query guts
##    cq => $cquery,      ##-- underlying DDC::Any::CQuery object
##    ti => $ti_pdl,      ##-- pdl ($NTi) : selected term-indices (undef: all)
##    ci => $ci_pdl,      ##-- pdl ($NCi) : selected cat-indices (undef: all)
##    ##
##    ##-- slice guts
##    #cdate   => $cdate ,   ##-- pdl ($NCi)
##    #cslice  => $cslice ,  ##-- pdl ($NCi)     : [$cii]    => $c_slice_label
##    #slices  => $slices,   ##-- pdl ($NSlices) : [$slicei] => $slice_label    (all slices)
##   )
sub new {
  my $that = shift;
  my $cq   = (@_%2)==1 ? shift : undef;
  return bless({
		cq=>$cq,
		#ti=>undef,
		#ci=>undef,
		@_
	       }, ref($that)||$that);
}

##==============================================================================
## API: compilation

## $vq_or_undef = $vq->compile(%opts)
##  + wraps $vq->compileLocal() #->compileDate() #->compileSlice()
##  + %opts: as for DiaColloDB::profile(), also
##    (
##     coldb => $coldb,   ##-- DiaColloDB context (for enums)
##     tdf   => $tdf,     ##-- DiaColloDB::Relation::TDF context (for meta-enums)
##     #dlo   => $dlo,     ##-- minimum date (undef or '': no minimum)
##     #dhi   => $dhi,     ##-- maximum date (undef or '': no maximum)
##    )
sub compile {
  my $vq = shift;
  return undef if (!defined($vq->compileLocal(@_)));
  return $vq->compileOptions(@_); #->compileDate(@_); #->compileSlice(@_);
}

## $vq_or_undef = $vq->compileLocal(%opts)
##  + calls $vq->{cq}->__dcvs_compile($vq,%opts), and optionally $vq->compileOptions()
##  + %opts: as for DiaColloDB::profile(), also
##    (
##     coldb => $coldb,   ##-- DiaColloDB context (for enums)
##     tdf  => $tdf,    ##-- DiaColloDB::Relation::TDF context (for meta-enums)
##     #dlo   => $dlo,     ##-- minimum date (undef or '': no minimum)
##     #dhi   => $dhi,     ##-- maximum date (undef or '': no maximum)
##    )
sub compileLocal {
  my $vq = shift;
  return undef if (!defined($vq->{cq}));
  return undef if (!defined($vq->{cq}->__dcvs_compile($vq,@_)));
  return $vq->compileOptions(@_);
}

## $vq_or_undef = $vq->compileOptions(%opts)
##  + merges underlying CQueryOptions restrictions into $vq piddles
##  + %opts: as for DiaColloDB::Relation::TDF::Query::compile()
sub compileOptions {
  my $vq = shift;
  return $vq if (!$vq->{cq}->can('getOptions') || !defined(my $qo=$vq->{cq}->getOptions));
  return $qo->__dcvs_compile($vq,@_);
}


##==============================================================================
## Utils: set operations

## $vq = $vq->_intersect($vq2)
##   + destructive intersection
sub _intersect {
  my ($vq,$vq2) = @_;
  $vq->{ti} = DiaColloDB::Utils::_intersect_p($vq->{ti},$vq2->{ti});
  $vq->{ci} = DiaColloDB::Utils::_intersect_p($vq->{ci},$vq2->{ci});
  return $vq;
}

## $vq = $vq->_union($vq2)
##   + destructive union
sub _union {
  my ($vq,$vq2) = @_;
  $vq->{ti} = DiaColloDB::Utils::_union_p($vq->{ti},$vq2->{ti});
  $vq->{ci} = DiaColloDB::Utils::_union_p($vq->{ci},$vq2->{ci});
  return $vq;
}


##==============================================================================
## Wrappers: DDC::Any::Object
##  + each supported DDC::Any::CQuery or DDC::Any::CQFilter subclass gets its
##    API extended by method(s):
##      __dcvs_compile($vq,%opts) : compile query

BEGIN {
  ##-- enable logging for DDC::Any::Object
  push(@DDC::Any::Object::ISA, 'DiaColloDB::Logger') if (!UNIVERSAL::isa('DDC::Any::Object', 'DiaColloDB::Logger'));
}

##----------------------------------------------------------------------
## $vq = $DDC_XS_OBJECT->__dcvs_compile($vq,%opts)
##  + compiles DDC::Any::Object (CQuery or CQFilter) $cquery
##  + returns a new DiaColloDB::Relation::TDF::Query object representing the evalution, or undef on failure
##  + %opts: as for DiaColloDB::Relation::TDF::Query::compile()
sub DDC::Any::Object::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  if ((ref($cq)||$cq) =~ /^DDC::\w+::(.*)$/) {
    ##-- manual dispatch to avoid inheritance snafu with DDC::Any
    my $class = $1;
    my $code  = "DDC::Any::$class"->can('__dcvs_compile');
    return $code->($cq,$vq,%opts) if ($code && $code ne \&__dcvs_compile);
  }
  else {
    ##-- real fallback
    $vq->logconfess("unsupported query expression of type ", ref($cq), " (", $cq->toString, ")");
  }
}

##======================================================================
## Wrappers: DDC::Any::CQuery: CQToken

##----------------------------------------------------------------------
## $vq_or_undef = $CQToken->__dcvs_init($vq,%opts)
##  + checks+sets $CQToken->IndexName
sub DDC::Any::CQToken::__dcvs_init {
  my ($cq,$vq,%opts) = @_;
  my $aname = $opts{coldb}->attrName($cq->getIndexName || $opts{coldb}{attrs}[0]);
  $vq->logconfess("unsupported token-attribute \`$aname' in ", ref($cq), " expression (", $cq->toString, ")") if (!$opts{coldb}->hasAttr($aname));
  $cq->setIndexName($aname);
  return $vq;
}

## \%adata = $CQToken->__dcvs_attr($vq,%opts)
##   + gets attribute-data for $CQToken->getIndexName()
sub DDC::Any::CQToken::__dcvs_attr {
  my ($cq,$vq,%opts) = @_;
  return $opts{coldb}->attrData([$cq->getIndexName])->[0];
}

## \%adata = $CQToken->__dcvs_compile_neg($vq,%opts)
##   + negates $vq if applicable ({ti} only)
sub DDC::Any::CQToken::__dcvs_compile_neg {
  my ($cq,$vq,%opts) = @_;
  $vq->{ti} = DiaColloDB::Utils::_negate_p($vq->{ti}, $opts{tdf}->nTerms)
    if ($cq->getNegated xor ($cq->can('getRegexNegated') ? $cq->getRegexNegated : 0));
  return $vq;
}

## $vq = $CQToken->__dcvs_compile_re($vq,$regex,%opts)
sub DDC::Any::CQToken::__dcvs_compile_re {
  my ($cq,$vq,$regex,%opts) = @_;
  $cq->__dcvs_init($vq,%opts);
  my $attr = $cq->__dcvs_attr($vq,%opts);
  my $ais  = $attr->{enum}->re2i($regex);
  my $ti = $vq->{ti} = $opts{tdf}->termIds($attr->{a}, $ais);
  return $cq->__dcvs_compile_neg($vq,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokExact->__dcvs_compile($vq,%opts)
##  + cals DDC::Any::CQToken::__dcvs_compile_neg()
##  + basically a no-op
sub DDC::Any::CQTokAny::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  $cq->__dcvs_init($vq,%opts);
  my $attr = $cq->__dcvs_attr($vq,%opts);    ##-- ensure valid attribute (even though we don't really need it)
  return $cq->__dcvs_compile_neg($vq,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokExact->__dcvs_compile($vq,%opts)
##  + sets $vq->{ti}
##  + cals DDC::Any::CQToken::__dcvs_compile_neg()
sub DDC::Any::CQTokExact::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  $cq->__dcvs_init($vq,%opts);
  my $attr = $cq->__dcvs_attr($vq,%opts);
  my $ai = $attr->{enum}->s2i($cq->getValue);
  my $ti = $vq->{ti} = $opts{tdf}->termIds($attr->{a}, $ai);
  return $cq->__dcvs_compile_neg($vq,%opts);
}


##----------------------------------------------------------------------
## $vq = $CQTokInfl->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokInfl::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile(@_) if (ref($cq) !~ /^DDC::\w+::CQTokInfl$/);
  $vq->logwarn("ignoring non-trivial expansion chain in ", ref($cq), " expression (", $cq->toString, ")")
    if (@{$cq->getExpanders//[]});
  return DDC::Any::CQTokExact::__dcvs_compile(@_);
}

##----------------------------------------------------------------------
## $vq = $CQTokSet->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokSet::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile(@_) if (ref($cq) !~ /^DDC::\w+::CQTokSet(?:Infl)?$/);
  $cq->__dcvs_init($vq,%opts);
  my $attr = $cq->__dcvs_attr($vq,%opts);
  my $enum = $attr->{enum};
  my $ais  = [map {$enum->s2i($_)} @{$cq->getValues}];
  my $ti   = $vq->{ti} = $opts{tdf}->termIds($attr->{a}, $ais);
  return $cq->__dcvs_compile_neg($vq,%opts);
}


##----------------------------------------------------------------------
## $vq = $CQTokSetInfl->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokSetInfl::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  $vq->logwarn("ignoring non-trivial expansion chain in ", ref($cq), " expression (", $cq->toString, ")")
    if (@{$cq->getExpanders//[]});
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokSetInfl$/);
  return $cq->DDC::Any::CQTokSet::__dcvs_compile($vq,@_);
}


##----------------------------------------------------------------------
## $vq = $CQTokRegex->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokRegex::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::Any::CQTokRegex$/);
  return $cq->__dcvs_compile_re($vq,$cq->getValue,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokPrefix->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokPrefix::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::Any::CQTokPrefix$/);
  return $cq->__dcvs_compile_re($vq,('^'.quotemeta($cq->getValue)),%opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokSuffix->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokSuffix::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokSuffix$/);
  return $cq->__dcvs_compile_re($vq,(quotemeta($cq->getValue).'$'),%opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokInfix->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokInfix::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokInfix$/);
  return $cq->__dcvs_compile_re($vq,quotemeta($cq->getValue),%opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokPrefixSet->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokPrefixSet::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokPrefixSet$/);
  return $cq->__dcvs_compile_re($vq, ('^(?:'.join('|', map {quotemeta($_)} @{$cq->getValues}).')'), %opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokSuffixSet->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokSuffixSet::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokSuffixSet$/);
  return $cq->__dcvs_compile_re($vq, ('(?:'.join('|', map {quotemeta($_)} @{$cq->getValues}).')$'), %opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokInfixSet->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokInfixSet::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokInfixSet$/);
  return $cq->__dcvs_compile_re($vq, ('(?:'.join('|', map {quotemeta($_)} @{$cq->getValues}).')'), %opts);
}

##----------------------------------------------------------------------
## $vq = $CQTokLemma->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}
sub DDC::Any::CQTokLemma::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQTokLemma$/);
  return DDC::Any::CQTokExact::__dcvs_compile(@_);
}

##======================================================================
## Wrappers: DDC::Any::CQuery: CQNegatable

##----------------------------------------------------------------------
## \%adata = $CQNegatable->__dcvs_compile_neg($vq,%opts)
##   + negates $vq if applicable (both {ti} and {ci})
sub DDC::Any::CQNegatable::__dcvs_compile_neg {
  my ($cq,$vq,%opts) = @_;
  if ($cq->getNegated) {
    $vq->{ti} = DiaColloDB::Utils::_negate_p($vq->{ti}, $opts{tdf}->nTerms);
    $vq->{ci} = DiaColloDB::Utils::_negate_p($vq->{ci}, $opts{tdf}->nCats);
  }
  return $vq;
}

##======================================================================
## Wrappers: DDC::Any::CQuery: CQBinOp

##----------------------------------------------------------------------
## ($vq1,$vq2) = $CQBinOp->__dcvs_compile_dtrs($vq,%opts)
##  + compiles daughter nodes
sub DDC::Any::CQBinOp::__dcvs_compile_dtrs {
  my ($cq,$vq,%opts) = @_;
  my $dtr1 = $cq->getDtr1;
  my $dtr2 = $cq->getDtr2;
  my $vq1 = ($dtr1 ? $dtr1->__dcvs_compile(ref($vq)->new(), %opts) : ref($vq)->new)
    or $vq->logconfess("failed to compile ", ref($cq), " sub-query expression (", $dtr1->toString, ")");
  my $vq2 = ($dtr2 ? $dtr2->__dcvs_compile(ref($vq)->new(), %opts) : ref($vq)->new)
      or $vq->logconfess("failed to compile ", ref($cq), " sub-query expression (", $dtr2->toString, ")");
  return ($vq1,$vq2);
}

##----------------------------------------------------------------------
## $vq = $CQWith->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti} (term-intersection only)
sub DDC::Any::CQWith::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQWith$/);
  my ($vq1,$vq2) = $cq->__dcvs_compile_dtrs($vq,%opts);
  $vq->{ti} = DiaColloDB::Utils::_intersect_p($vq1->{ti},$vq2->{ti});
  return DDC::Any::CQToken::__dcvs_compile_neg($cq,$vq,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQWith->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti} (term-difference only)
sub DDC::Any::CQWithout::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQWithout$/);
  my ($vq1,$vq2) = $cq->__dcvs_compile_dtrs($vq,%opts);
  $vq->{ti} = DiaColloDB::Utils::_setdiff_p($vq1->{ti},$vq2->{ti},$opts{tdf}->nTerms);
  return DDC::Any::CQToken::__dcvs_compile_neg($cq,$vq,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQWith->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}, $vq->{ci} (cat-intersection, term-union)
##  + TODO: fix this to use minimum tdm0 frequency of compiled daughters
##    - requires generalizing Query.pm to allow explicit frequencies (full tdm?) -- LATER!
sub DDC::Any::CQAnd::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQAnd$/);
  my ($vq1,$vq2) = $cq->__dcvs_compile_dtrs($vq,%opts);
  $vq->{ti} = DiaColloDB::Utils::_union_p($vq1->{ti}, $vq2->{ti});
  $vq->{ci} = DiaColloDB::Utils::_intersect_p($opts{tdf}->catSubset($vq1->{ti}, $vq1->{ci}),
					      $opts{tdf}->catSubset($vq2->{ti}, $vq2->{ci}));
  return $cq->__dcvs_compile_neg($vq,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQWith->__dcvs_compile($vq,%opts)
##  + should set $vq->{ti}, $vq->{ci} (cat-union, term-union)
sub DDC::Any::CQOr::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  return DDC::Any::Object::__dcvs_compile($vq,@_) if (ref($cq) !~ /^DDC::\w+::CQOr$/);
  my ($vq1,$vq2) = $cq->__dcvs_compile_dtrs($vq,%opts);
  $vq->{ti} = DiaColloDB::Utils::_union_p($vq1->{ti}, $vq2->{ti});
  $vq->{ci} = DiaColloDB::Utils::_union_p($vq1->{ci}, $vq2->{ci});
  return $cq->__dcvs_compile_neg($vq,%opts);
}



##======================================================================
## Wrappers: DDC::Any::CQuery: TODO

## DDC::Any::CQuery : @ISA=qw(DDC::Any::Object)
# DDC::Any::CQNegatable : @ISA=qw(DDC::Any::CQuery)
# DDC::Any::CQAtomic : @ISA=qw(DDC::Any::CQNegatable)
# DDC::Any::CQBinOp : @ISA=qw(DDC::Any::CQNegatable)
## DDC::Any::CQAnd : @ISA=qw(DDC::Any::CQBinOp)
## DDC::Any::CQOr : @ISA=qw(DDC::Any::CQBinOp)
## DDC::Any::CQWith : @ISA=qw(DDC::Any::CQBinOp)
## DDC::Any::CQWithout : @ISA=qw(DDC::Any::CQWith)
## DDC::Any::CQToken : @ISA=qw(DDC::Any::CQAtomic)
## DDC::Any::CQTokExact : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokAny : @ISA=qw(DDC::Any::CQToken)
# DDC::Any::CQTokAnchor : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokRegex : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokSet : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokInfl : @ISA=qw(DDC::Any::CQTokSet)
## DDC::Any::CQTokSetInfl : @ISA=qw(DDC::Any::CQTokInfl)
## DDC::Any::CQTokPrefix : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokSuffix : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokInfix : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokPrefixSet : @ISA=qw(DDC::Any::CQTokSet)
## DDC::Any::CQTokSuffixSet : @ISA=qw(DDC::Any::CQTokSet)
## DDC::Any::CQTokInfixSet : @ISA=qw(DDC::Any::CQTokSet)
# DDC::Any::CQTokMorph : @ISA=qw(DDC::Any::CQToken)
## DDC::Any::CQTokLemma : @ISA=qw(DDC::Any::CQTokMorph)
# DDC::Any::CQTokThes : @ISA=qw(DDC::Any::CQToken)
# DDC::Any::CQTokChunk : @ISA=qw(DDC::Any::CQToken)
# DDC::Any::CQTokFile : @ISA=qw(DDC::Any::CQToken)
# DDC::Any::CQNear : @ISA=qw(DDC::Any::CQNegatable)
# DDC::Any::CQSeq : @ISA=qw(DDC::Any::CQAtomic)

##----------------------------------------------------------------------
## $vq = $OBJECT->__dcvs_compile($vq,%opts)
##  + ....

##======================================================================
## Wrappers: DDC::Any::CQFilter

##----------------------------------------------------------------------
## $vq = $CQFilter->__dcvs_ignore($vq,%opts)
##  + convenience wrapper: ignore with warning
sub DDC::Any::CQFilter::__dcvs_ignore {
  my ($cq,$vq) = @_;
  $vq->logwarn("ignoring filter expression of type ", ref($cq), " (", $cq->toString, ")");
  return $vq;
}
BEGIN {
  *DDC::Any::CQFRankSort::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFDateSort::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
  *DDC::Any::CQFSizeSort::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
  *DDC::Any::CQFRandomSort::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFBiblSort::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
  *DDC::Any::CQFContextSort::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasField::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasFieldValue::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasFieldRegex::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasFieldPrefix::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasFieldSuffix::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasFieldInfix::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
#  *DDC::Any::CQFHasFieldSet::__dcvs_compile = \&DDC::Any::CQFilter::__dcvs_ignore;
}

##----------------------------------------------------------------------
## $vq_or_undef = $CQFHasField->__dcvs_init($vq,%opts)
##  + ensures that $CQFHasField->Arg0 is a supported metadata attribute
sub DDC::Any::CQFHasField::__dcvs_init {
  my ($cq,$vq,%opts) = @_;
  my $attr = $cq->getArg0;
  $vq->logconfess("unsupported metadata attribute \`$attr' in ", ref($cq), " expression (", $cq->toString, ")")
    if (!$opts{tdf}->hasMeta($attr));
  #$vq->logconfess("negated filters not yet supported in ", ref($cq), " expression (", $cq->toString, ")")
  #  if ($cq->getNegated);
  return $vq;
}

##----------------------------------------------------------------------
## $vq = $CQFHasFieldSet->__dcvs_compile_neg($vq,%opts)
##  + honors $cq->getNegated() flag, alters $vq->{ci} if applicable
sub DDC::Any::CQFHasField::__dcvs_compile_neg {
  my ($cq,$vq,%opts) = @_;
  $vq->{ci} = DiaColloDB::Utils::_negate_p($vq->{ci}, $opts{tdf}->nCats) if ($cq->getNegated);
  return $vq;
}

##----------------------------------------------------------------------
## $vq = $CQFHasField->__dcvs_compile_p($vq,%opts)
##  + populates $vq->{ci} from @opts{qw(attrs ais)}
##  + calls $CQFHasField->__dcvs_compile_neg($vq,%opts)
##  + requires additional %opts:
##    (
##     attr   => \%attr,   ##-- attribute data as returned by TDF::metaAttr()
##     valids => $valids,  ##-- attribute-value ids
##    )
##  + TODO: use a persistent reverse-index here (but first build it in TDF::create())
sub DDC::Any::CQFHasField::__dcvs_compile_p {
  my ($cq,$vq,%opts) = @_;
  my ($attr,$valids) = @opts{qw(attr valids)};
  $vq->{ci} = $opts{tdf}->catIds(@opts{qw(attr valids)});
  return DDC::Any::CQFHasField::__dcvs_compile_neg($cq,$vq,%opts);
}

##----------------------------------------------------------------------
## $vq = $CQFHasFieldValue->__dcvs_compile($vq,%opts)
##  + populates $vq->{ci}
##  + calls $CQFHasFieldValue->__dcvs_compile_p($vq,%opts,...)
##  + TODO: use a persistent reverse-index here (but first build it in create())
sub DDC::Any::CQFHasFieldValue::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  $cq->__dcvs_init($vq,%opts);
  my $attr  = $cq->getArg0;
  my $enum  = $opts{tdf}->metaEnum($attr);
  my $vals  = $enum->s2i($cq->getArg1);
  return $cq->__dcvs_compile_p($vq, %opts, attr=>$attr, valids=>$vals);
}

##----------------------------------------------------------------------
## $vq = $CQFHasFieldValue->__dcvs_compile($vq,%opts)
##  + populates $vq->{ci}
sub DDC::Any::CQFHasFieldRegex::__dcvs_compile {
  my ($cq,$vq,%opts) = @_;
  $cq->__dcvs_init($vq,%opts);
  my $attr = $cq->getArg0;
  my $enum = $opts{tdf}->metaEnum($attr);
  my $vals = $enum->re2i($cq->getArg1);
  return $cq->__dcvs_compile_p($vq,%opts, attr=>$attr, valids=>$vals);
}



##======================================================================
## Wrappers: DDC::Any::CQOptions

##----------------------------------------------------------------------
## $vq = $CQueryOptions->__dcvs_compile($vq,%opts)
##  + $vq is the parent query, which should already have been compiled
sub DDC::Any::CQueryOptions::__dcvs_compile {
  my ($qo,$vq,%opts) = @_;
  $vq->logwarn("ignoring non-empty #WITHIN clause (".join(',',@{$qo->getWithin}).")") if (@{$qo->getWithin});
  $vq->logwarn("ignoring non-empty subcorpus list (".join(',', @{$qo->getSubcorpora}).")") if (@{$qo->getSubcorpora});
  foreach (@{$qo->getFilters}) {
    $vq->_intersect(ref($vq)->new($_)->compileLocal(%opts)) or return undef;
  }
  return $vq;
}



##==============================================================================
## Footer
1;

__END__
