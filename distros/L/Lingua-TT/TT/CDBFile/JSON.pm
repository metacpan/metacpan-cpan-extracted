## -*- Mode: CPerl -*-
## File: Lingua::TT::CDBFile,,1S6N.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: CDB: tied read-only access via CDB_File, JSON values

package Lingua::TT::CDBFile::JSON;
use Lingua::TT::CDBFile;
use Lingua::TT::Dict::JSON;
use JSON::XS;
use Carp;
use IO::File;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::CDBFile Lingua::TT::Dict::JSON);

##==============================================================================
## Constructors etc.

## $dbf = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$doc:
##   ##-- new options
##   jxs    => $jxs,           ##-- underlying JSON::XS object; see jsonxs() method
##   ##
##   ##-- user options, inherited from TT::CDBFile
##   file     => $filename,    ##-- default: undef (none)
##   tmpfile  => $tmpfilename, ##-- defualt: "$filename.$$" (not used correctly due to CDB_File bug)
##   mode     => $mode,        ##-- open mode 'r', 'w', 'rw', '<', '>', '>>': default='r'
##   utf8     => $bool,        ##-- if true, keys/values are stored as UTF8 (default=1) -- n/a here, always utf8
##   ##
##   ##-- low-level data, inherited from TT::CDBFile
##   data   => \%data,         ##-- tied data (hash)
##   tied   => $ref,           ##-- read-only: reference returned by tie()
##   writer => $ref,           ##-- read/write: reference returned by CDB_File::new()
##   fetch  => \&fetch,        ##-- fetch subroutine: $val = $fetch->($key)
##   store  => \&store,        ##-- store subroutine: $val = $store->($key,$val)#
##   jxs    => $jxs,           ##-- underlying JSON::XS object; see jsonxs() method
sub new {
  my $that = shift;
  return $that->Lingua::TT::CDBFile::new(@_,utf8=>1);
}

##==============================================================================
## Methods: low-level utilities

## $jxs = $obj->jsonxs()
##  + INHERITED from TT::Dict::JSON

##==============================================================================
## Methods: I/O

## $dbf = $dbf->open($file,%opts)
##  + %opts are as for new()
##  + $file defaults to $dbf->{file}
##  + INHERITED

##==============================================================================
## Methods: Lookup

## \&sub = $dbf->fetchSub($key)
##   + subroutine to return (decoded) value
sub fetchSub {
  my $tied = $_[0]{tied};
  my $jxs  = $_[0]->jsonxs;
  my ($val);
  return sub {
    return undef if (!defined($val = $tied->FETCH($_[0])));
    utf8::decode($val);
    return $jxs->decode($val);
  };
}

## $storeSub = $dbf->store($key,$val)
sub storeSub {
  my $tied = $_[0]{tied};
  my $jxs = $_[0]->jsonxs;
  return sub {
    return $tied->STORE($_[0],$jxs->encode($_[1]));
  };
}

##==============================================================================
## Methods: Apply

## \&apply = $dict->applySub(%opts)
##   + returns a CODE-ref for applying dictionary analysis to a single item
##   + returned sub is called without arguments
##     - data line to be analyzed (chomped) is in $_
##     - output for current data line should be stored in $_
sub applySub {
  my ($dict,%opts)  = @_;
  my $jxs           = $dict->jsonxs;
  my $jxs0          = JSON::XS->new->utf8(1)->allow_nonref(1);
  my $tied          = $dict->{tied};
  #my $include_empty = $opts{allow_empty};
  my ($text,$a_in,$a_dict);
  return sub {
    ($text,$a_in) = split(/\t/,$_,2);
    $a_dict       = $tied->FETCH($text);

    $a_in   = $jxs->decode($a_in) if (defined($a_in));
    $a_dict = $jxs0->decode($a_dict) if (defined($a_dict));

    if (!defined($a_dict)) {
      ##-- +in, -dict
      ;
    }
    elsif (!defined($a_in)) {
      ##-- -in, +dict
      $a_in = $a_dict;
    }
    elsif (ref($a_in) eq 'HASH' && ref($a_dict) eq 'HASH') {
      ##-- +in, +dict: HASH
      @$a_in{keys %$a_dict} = values %$a_dict;
    }
    elsif (ref($a_in) eq 'ARRAY' && ref($a_dict) eq 'ARRAY') {
      ##-- +in, +dict: ARRAY
      push(@$a_in, @$a_dict);
    }
    else {
      ##-- +in, +dict: OTHER
      warn(ref($dict)."::applySub(): cannot merge values $a_in, $a_dict for key '$text'");
      $a_in = $a_dict;
    }
    $_ = join("\t", $text, (defined($a_in) ? $jxs->encode($a_in) : qw()))."\n";
  };
}


##==============================================================================
## Methods: TT::Persistent

## @keys = $dbf->noSaveKeys()
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys(), qw(jxs));
}

##==============================================================================
## Footer
1;

__END__
