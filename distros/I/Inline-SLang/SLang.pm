#
# $Id: SLang.pm,v 1.51 2005/01/04 17:06:57 dburke Exp $
#
# Inline package for S-Lang (http://www.s-lang.org/)
# - the name has been changed to Inline::SLang since hyphens
#   seem to confuse ExtUtils
#
# Similarities to Inline::Python and Ruby are to be expected
# since I used these modules as a base rather than bother to
# think about things. However, all errors are likely to be
# mine
#

#
# This software is Copyright (C) 2003, 2004, 2005 Smithsonian
# Astrophysical Observatory. All rights are reserved.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA
# 
# Or, surf on over to
# 
#  http://www.fsf.org/copyleft/gpl.html
#

package Inline::SLang;

use strict;

use Carp;
use IO::File;
use Math::Complex;

require Inline;
require DynaLoader;
require Exporter;

require Inline::denter;

use vars qw(@ISA $VERSION @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.00';
@ISA = qw(Inline DynaLoader Exporter);

# since using Inline we can't use the standard way
# of importing symbols, so we add an EXPORT config option
# which we use to mimic the Exporter interface
#
# EXPORT_OK will be added to below once we know what S-Lang
# types are defined. EXPORT_TAGS will be filled up at that
# time too
#
@EXPORT_OK =
    qw(
       sl_array sl_array2perl sl_eval sl_have_pdl
       sl_setup_as_slsh sl_setup_called
       sl_typeof sl_version
       );

%EXPORT_TAGS =
  (
   'types' => [],
   );

# do I need this [left over from code taken from Inline::Ruby/Python
# modules but not sure what it's really for and too lazy to read
# about Exporter...]
#
## adding this doesn't stop module from seg faulting when PDL support is
## selected on Linux
##
##sub dl_load_flags { 0x01 }
Inline::SLang->bootstrap($VERSION);

#==============================================================================
# Register S-Lang.pm as a valid Inline language
#==============================================================================
sub register {
    return {
            language => 'SLang',
            aliases => ['sl', 'slang'], # not sure hyphens are allowed
            type => 'interpreted',
            suffix => 'sldat', # contains source code AND namespace info
           };
}

#==============================================================================
# Validate the S-Lang config options
#==============================================================================
sub usage_validate ($) {
  "'$_[0]' is not a valid configuration option\n";
}

sub usage_config_bind_ns {
  "Invalid value for Inline::SLang option 'BIND_NS';\n" .
    "It must be a string (either \"Global\" or \"All\") or an array reference";
}

sub usage_config_bind_slfuncs {
  "The Inline::SLang option 'BIND_SLFUNCS' must be given an array reference";
}

sub usage_config_export {
  "The Inline::SLang option 'EXPORT' must be sent an array reference";
}

sub usage_config_setup {
  "The Inline::SLang option 'SETUP' must be sent either 'slsh' or 'none'.";
}

sub validate {
  my $o = shift;
    
  # default ILSM values
  $o->{ILSM} ||= {};
  # do I need to add support for the FILTERS key in the loop below?
  $o->{ILSM}{FILTERS} ||= [];
  $o->{ILSM}{EXPORT}  = undef;
  $o->{ILSM}{bind_ns} = [ "Global" ];
  $o->{ILSM}{bind_slfuncs} = [];
  $o->{ILSM}{slang_setup} = "slsh"; # valid values are none or slsh

  # loop through the options    
  my $flag = 0;
  while ( @_ ) {
    my ( $key, $value ) = ( shift, shift );

    # note: if the user supplies options and they still want the
    # Global namespace bound then they need to include it in the
    # list (ie we over-write the defaults, not append to it)
    #
    if ( $key eq "BIND_NS" ) {
      my $type = ref($value);
      # note: we could make a better stab of ensuring the package name
      # in the 'Global' regexp is correct Perl
      #
      croak usage_config_bind_ns()
	unless ($type eq "" and
		($value =~ m/^Global(=[A-Za-z_0-9]+)?$/ or
		 $value eq "All"))
	or $type eq "ARRAY";
      # we let build() worry about the actual contents
      $o->{ILSM}{bind_ns} = $value;
      next;
    } # BIND_NS

    if ( $key eq "BIND_SLFUNCS" ) {
      my $type = ref($value);
      croak usage_config_bind_slfuncs()
	unless $type eq "ARRAY";
      $o->{ILSM}{bind_slfuncs} = $value;
      next;
    } # BIND_SLFUNCS

    if ( $key eq "EXPORT" ) {
      my $type = ref($value);
      croak usage_config_export()
	unless $type eq "ARRAY";
      $o->{ILSM}{EXPORT} = $value;
      next;
    } # EXPORT

    if ( $key eq "SETUP" ) {
      my $type = ref($value);
      croak usage_config_setup()
	unless $type eq "" and 
	( $value eq "slsh" or $value eq "none" );
      $o->{ILSM}{slang_setup} = $value;
      next;
    } # SETUP

    print usage_validate $key;
    $flag = 1;
  }
  die if $flag;

  # set up other useful values 
  # - not the best place to define these
  #   since this is only run when the code has been changed?
  $o->{ILSM}{built}     ||= 0;
  $o->{ILSM}{loaded}    ||= 0;

} # sub: validate()

#==========================================================================
# Pass the code off to S-Lang, let it interpret it, and then
# parse the namespaces to find the functions.
#
# We also call the "setup as slsh" code (if required) here. We do it here,
# rather than in the BOOT code of the module, so that users can turn it
# on or off as they require. It has to be done before the user-supplied code
# is evaluated (to ensure that user-defined routines are available).
#
# Have considered allowing a compile-time option to use a
# byte-compiled version of the code, but decided it was too
# much effort.
#
# Have a nasty little hack to allow exporting of Inline::SLang::xxx
# functions (can't work out how to do this properly)
#
#==========================================================================
sub build {
    my $o = shift;
    return if $o->{ILSM}{built};

    # Filter the code
    $o->{ILSM}{code} = $o->filter(@{$o->{ILSM}{FILTERS}});

    # do we have to setup the interpreter?
    #
    if ( $o->{ILSM}{slang_setup} eq "slsh" ) {
	sl_setup_as_slsh ();
    }

    # bind_ns = [ $ns1, ..., $nsN ]
    # where $ns1 is either the name of the S-Lang
    # namespace (eg "Global") or "Global=foo", 
    # which means to bind S-Lang namespace Global
    # to Perl package foo
    # (not sure if this is really necessary, but it's easy
    #  to implement ;)
    #
    # The keys of %ns_map are the S-Lang namespace names,
    # and the value the Perl package name (they're going to
    # be the same for virtually all cases)
    #
    # It's complicated by allowing bind_ns = "All", which says
    # to bind all known namespaces.
    #
    # Since we use the _get_namespaces() routine we require
    # S-Lang >= v1.4.7. This is checked for by Makefile.PL
    # so we can assume it is true here.
    #
    # It's also complicated by allowing the user to specify
    # S-Lang intrinsic functions that are to be bound
    # (bind_slfuncs)
    #
    # And because we explicitly EXCLUDE the _inline namespace
    # from being bound (since that is for use by this module only)
    #
    # First off we need to check for bind_ns eq "All" or "Global"
    my $bind_ns = $o->{ILSM}{bind_ns};
    my $bind_all_ns = 0;
    if ( ref($bind_ns) eq "" ) {
      if ( $bind_ns =~ "^Global" ) { $bind_ns = [ $bind_ns ]; }
      else {
	# if "All" then we have to list all the namespaces,
	# we will need to append to this after running sl_eval()
	$bind_ns = sl_eval( "_get_namespaces();" );
	$bind_all_ns = 1;
      }			  
    }

    # remove _inline if it exists
    $bind_ns = [ grep { $_ ne "_inline" } @{$bind_ns} ];

    my %ns_map = map {
      my ( $slns, $plns ) = split(/=/,$_,2);
      $plns ||= $slns;
      ( $slns, $plns );
    } @{ $bind_ns };

    # parse the bind_slfuncs information
    my %intrin_funs = map {
      my ( $slfn, $plfn ) = split(/=/,$_,2);
      $plfn ||= $slfn;
      ( $slfn, $plfn );
    } @{ $o->{ILSM}{bind_slfuncs} };

    # What does the current namespace look like before evaluating
    # the user-supplied code?
    # - we only need to worry about those namespaces listed
    #   in the bind_ns array
    #
    # Perhaps we should hack the Perl namespace of Global to main
    # (if it hasn't been explicitly specified)
    #
    my %ns_orig = ();
    foreach my $ns ( keys %ns_map ) {
      # we do not exclude any values in %intrin_funs since
      # they are processed slightly differently from other
      # functions (they can be renamed, but not placed into
      # a different namespace)
      #
      $ns_orig{$ns} = 
      {
	map { ($_,1); } @{ sl_eval( '_apropos("' . $ns . '","",3);' ) || [] }
      };
    }

    # Run the code: sl_eval falls over on error
    eval { sl_eval( $o->{ILSM}{code} ); };
    die "Error evaluating S-Lang code: message is\n\n$@\n"
      if $@;

    # update the list of namespaces if BIND_NS was set to "All"
    #
    if ( $bind_all_ns ) {
      foreach my $ns ( @{ sl_eval( "_get_namespaces();" ) || [] } ) {
	unless ( exists $ns_map{$ns} ) {
	  $ns_map{$ns} = $ns;
	  $ns_orig{$ns} = {};
	}
      }
    }

    # now find out what we've got available
    # - we use the bind_ns array to tell us what namespaces
    #   to bind to
    #
    # - we bind all functions that are NOT S-Lang intrinsics:
    #   more specifically, we only add those functions that
    #   were added to the S-Lang namespace by the eval call
    #   above
    #
    my %namespaces = ();
    foreach my $ns ( keys %ns_map ) {
      my $funclist = sl_eval( '_apropos("' . $ns . '","",3);' );

      # remove those we already know about
      my $orig = $ns_orig{$ns};
      my @bind = ();
      foreach my $fname ( @$funclist ) {
	push @bind, $fname unless exists $$orig{$fname};
      }

      # decided that the warning was annoying
      ##warn "No functions found in $ns namespace!" if $#bind == -1;
      $namespaces{$ns} = \@bind;
    }

    # now bind any S-Lang intrinsics
    # note that they get bound into whatever package the
    # Global namespace is mapped to
    #
    my $href = $ns_orig{Global};
    my $aref = $namespaces{Global};
    while ( my ( $slfn, $plfn ) = each %intrin_funs ) {
      if ( exists $$href{$slfn} ) {
	push @{$aref}, [$slfn,$plfn];
      } else {
	warn "Requested S-Lang intrinsic function $slfn is not found in the Global namespace";
      }
    }

    # now find the defined data types, set up
    # Inline::SLang::xxx functions that return these as DataType_Type
    # objects, and create the necessary perl classes
    #
    # From slang v1.4.8, the S-Lang defined types that we
    # want to handle are:
    #   Any_Type
    #   BString_Type
    #   FD_Type
    #   File_Type
    #   Ref_Type
    #
    # [would like to handle FD/File handles via PerlIO but that
    #  may be hard/impossible]
    #
    # The list below is the remaining types - ie those we plan
    # to handle separately - either by using native Perl
    # types or hand-crafted classes
    # - ignoring the fact that 12/14 are both UInteger_Type
    #   and that some types are synonyms for others
    #   [see the tortured internals of _sl_defined_types]
    #
    my %ignore = map { ($_,1); }
      (
       'Undefined_Type', 
       'Integer_Type', 
       'Double_Type', 
       'Char_Type', 
       '_IntegerP_Type', 
       'Complex_Type', 
       'Null_Type', 
       'UChar_Type', 
       'Short_Type', 
       'UShort_Type', 
       'UInteger_Type', 
       'Integer_Type', 
       'Long_Type',
       'ULong_Type',
       'String_Type', 
       'Float_Type', 
       'Struct_Type', 
       'Array_Type', 
       'DataType_Type', 
       'Assoc_Type', 
       );

    my $dtypes = Inline::SLang::_sl_defined_types();

    my $pl_code = "";
    while ( my ( $dname, $dref ) = each %$dtypes ) {
      # set up the function with a name equal to the data type
      # - we will export this to the main package later on
      #   if required (look for handling of the EXPORT option)
      #
      push @EXPORT_OK, $dname;
      push @{ $EXPORT_TAGS{types} }, $dname;
      $pl_code .= 
	"sub Inline::SLang::$dname () { return DataType_Type->new('" .
	($$dref[1]==2 ? $$dref[0] : $dname ).
	"'); }\n";

      # we do not want a class if we explicitly want to ignore it
      # OR it's a class synonym (ie $$dref[1] == 2
      next if exists $ignore{$dname} or $$dref[1] == 2;

      # create the Perl class code
      if ( $$dref[1] ) {
	# a sub-class of Struct_Type
	$pl_code .= qq{
package $dname;
use strict;
use vars qw( \@ISA );
\@ISA = ( "Struct_Type" );
};

	# find out the field names and create the 'constructor'
	my $fields = Inline::SLang::sl_eval(
	     "get_struct_field_names(@" . $dname . ");"
	);

	$pl_code .=
'
use Carp;

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  tie( my %self, $class );
  bless \%self, $class;
}

# really should use ref($this) to get class name
# rather than hard coding it
#
sub _define_struct { return "\$1 = \@' . $dname . ';"; }

sub TIEHASH { 
  croak "Usage: tie( %hash, \'$_[0]\' )"
    unless $#_ == 0;

  my $class  = shift;
  my @fields = qw( ' . join(" ",@$fields) . ' );

  # [0] = hash reference
  # [1] = array reference (field names)
  # [2] = scalar: counter used when iterating through the hash
  #
  my $struct = { map { ($_,undef); } @fields };
  return bless [ $struct, \@fields, 0 ], $class;
}
';

      } else {
	# a sub-class of Inline::SLang::_Type
	$pl_code .= qq{
package $dname;
use strict;
use vars qw( \@ISA );
\@ISA = ( "Inline::SLang::_Type" );
sub new {
  my \$this  = shift;
  my \$class = ref(\$this) || \$this;
  my \$key   = shift;
  return bless \\\$key, \$class;
}
sub DESTROY {
  my \$self = shift;
  Inline::SLang::sl_eval( "_inline->_delete_data(\\"\$\$self\\");" );
}
};

      }
    } # while: each %$dtypes

    # build the horrible exporter hack
    #
    # handle the EXPORT method in a minimal way. We only
    # support individual names and the !<key in export_tags>
    # syntax
    #
    # - this is a *horrible* way to do it; don't seem to be
    #   able to do it easily via
    #     Inline::SLang->export_to_level( 1|2, @{ $o->{ILSM}{EXPORT} } );
    #   so we do this hack
    #
    my $export = "";
    if ( defined $o->{ILSM}{EXPORT} ) {
      my @funcs = @{ $o->{ILSM}{EXPORT} };

      # expand out any !<key> entries
      @funcs = map
        {
          my $name = $_;
          # apparently can't use a return within this block!
          if ( $name =~ /^!/ ) {
            $name = substr($name,1);
            die "Error: unknown tag '!$name' in EXPORT option\n"
              unless exists $EXPORT_TAGS{$name};
            ( @{ $EXPORT_TAGS{$name} } ); # insert all the vals
          } else {
            $name; # leave the value as is
          }
        } @funcs;

      ## Inline::SLang->export_to_level( 2, @funcs);

      my %href = map { ($_,1); } @EXPORT_OK;
      foreach my $func ( @funcs ) {
	die "Error: EXPORT option sent an unknown symbol $func\n"
	  unless exists $href{$func};
	$export .= "*::$func = \\&$func;\n";
      }
    }

    # Cache the results
    #
    my $odir = "$o->{API}{install_lib}/auto/$o->{API}{modpname}";
    $o->mkpath($odir) unless -d $odir;

    my $parse_info = Inline::denter->new->indent(
	*namespaces  => \%namespaces,
        *sl_types    => $dtypes,
        *pl_code     => $pl_code,
        *ns_map      => \%ns_map,
	*code        => $o->{ILSM}{code},
	*export      => $export,
	*slang_setup => $o->{ILSM}{slang_setup},
    );

    my $odat = $o->{API}{location};
    my $fh = IO::File->new( "> $odat" )
	or croak "Inline::SLang couldn't write parse information!";
    $fh->print( $parse_info );
    $fh->close();

    # almost certainly NOT clever to change meaning of EXPORT
    # field here (from array ref to string of perl code to evaluate)
    #
    $o->{ILSM}{namespaces} = \%namespaces;
    $o->{ILSM}{sl_types}   = $dtypes;
    $o->{ILSM}{pl_code}    = $pl_code;
    $o->{ILSM}{ns_map}     = \%ns_map;
    $o->{ILSM}{EXPORT}     = $export;
    $o->{ILSM}{built}++;

} # sub: build()

#==============================================================================
# Load the code, run it, and bind everything to Perl
# -- could we store the S-Lang pointers for each function 
#    - ie that returned by SLang_get_function() ?
#      but there may be issues if the function is re-defined
#
# -- is it even worth loading the data from the file, since
#    we can just evaluate it from the data statement (or
#    wherever it is stored within the file). I guess it depends
#    on what the overheads are (especially if we allow filtering)
#    versus file I/O
#
# -- at some point we also create the Perl classes used to represent
#    many of the S-Lang types
#
# Finish by creating the _inline namespace and it's constituents
#   ( type, key ) = _store_data( value );
#   _remove_data( key );
#   _store = Assoc_Type [String_Type]
#
# -- NOTE: we also handle the EXPORT config option here:
#      a hack to allow exportable function names without
#      messing up the import of fn names from S-Lang
#    Do this AFTER binding the S-Lang functions.
#    May change my mind on this.
#
#==============================================================================
sub load {
    my $o = shift;
    return if $o->{ILSM}{loaded};

    # Load the code
    # - only necessary if we've not already evaluated the code
    #   (part of the build routine)
    #
    unless ( $o->{ILSM}{built} ) {

      my $fh = IO::File->new( "< $o->{API}{location}" )
	or croak "Inline::SLang couldn't open parse information!";
      my $sldat = join '', <$fh>;
      $fh->close();

      my %sldat = Inline::denter->new->undent($sldat);
      $o->{ILSM}{namespaces}  = $sldat{namespaces};
      $o->{ILSM}{sl_types}    = $sldat{sl_types};
      $o->{ILSM}{pl_code}     = $sldat{pl_code};
      $o->{ILSM}{ns_map}      = $sldat{ns_map};
      $o->{ILSM}{code}        = $sldat{code};
      $o->{ILSM}{EXPORT}      = $sldat{export};
      $o->{ILSM}{slang_setup} = $sldat{slang_setup};

      # Do we have to setup the interpreter?
      # Note: we use the value stored in the config file
      #   (ie that used when the code was originally parsed)
      #   rather than the user-supplied one. The values should
      #   be the same (if they aren't then there should have been
      #   a re-compile anyway to make them the same...)
      #
      if ( $o->{ILSM}{slang_setup} eq "slsh" ) {
	sl_setup_as_slsh();
      }

      # Run it
      eval { sl_eval( $o->{ILSM}{code} ); };
      die "Error evaluating S-Lang code: message is\n\n$@\n"
	if $@;
    }

    # Bind the functions
    # The functions in S-Lang namespace foo
    # are placed into the Perl package bar
    # where foo = $o->{ILSM}{ns_map}{foo}
    #
    # In most cases foo == bar
    # We hack Global so that it appears in
    # main ***UNLESS** the user has specified
    # a name for the Perl package (ie they
    # had BIND_NS => [ ..., "Global=foo", ... ]
    # 
    while ( my ( $slns, $plns ) = each %{ $o->{ILSM}{ns_map} } ) { 
      my $qualname = "$o->{API}{pkg}::";
      $qualname .= "${plns}::" unless 
	$slns eq "Global" && $slns eq $plns;
      foreach my $fn ( @{ $o->{ILSM}{namespaces}{$slns} || [] } ) {
	# if it's an array reference then we have
	# [ $slang_name, $perl_name ]
	# This is currently only for S-Lang intrinsic functions
	#
	my ( $slfn, $plfn );
	if ( ref($fn) eq "ARRAY" ) { $slfn = $$fn[0]; $plfn = $$fn[1]; }
	else                       { $slfn = $fn;     $plfn = $fn; }
	sl_bind_function( "$qualname$plfn", $slns, $slfn );
      }
    }

    # Set up the Perl classes to handle the registered types
    # and the functions that (can) make using DataType_Type
    # variables easier
    #
    eval $o->{ILSM}{pl_code};
    die "INTERNAL ERROR: Unable to evaluate Perl code needed to bind the S-Lang types\n" .
      "$@\n" if $@;
      
    # bind the _inline namespace
    # v1.4.9 allows eval() to specify the namespace for the code
    # - do not use apostrohpes (') in the S-Lang comments!!!
    # - have grabbed a random-number generator from the web to
    #   try and have an okay scheme for generating keys; since
    #   has to write a S-Lang intrinsic function to do this could
    #   have chosen other ways to do this
    #   [we just want something random-ish, nothing too complicated]
    #
    sl_eval( 
'
use_namespace("_inline");
private variable _store = Assoc_Type [];

private variable _id_str =
  "abcdefghijklmnopqrstuvwxyz" +
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
  "0123456789 ~!@#$%^&*()_+|-=\[]{};:,<.>/?";
private variable _id_len = strlen(_id_str);
private define _get_letter() { return _id_str[[_qrandom(_id_len)]]; }

static define _store_data( invar ) {
  % need a unique key to store data in _store
  %
  variable key = _get_letter();
  while ( assoc_key_exists(_store,key) ) { key += _get_letter(); }
  if ( assoc_key_exists(_store,key) ) {
    % want to use exit(), but that is not part of S-Lang; slsh provides it
    error( "Internal error: unable to find a unique key when storing data" );
%    message("Internal error: unable to find a unique key when storing data");
%    exit(1);
  }
  _store[key] = invar;
  return ( string(typeof(invar)), key );
} % _store_data

% note: assoc_delete_key() does nothing if the key
% does not exist in the array
%
static define _delete_data( key ) { assoc_delete_key(_store,key); }

% for speed we avoid error checking; if there is an error
% this should cause a S-Lang error
%
static define _push_data( key ) { return _store[key]; }

% useful for debugging
%
static define _dump_data () {
  variable fp;
  switch ( _NARGS )
  { case 0: fp = stdout; }
  { case 1: fp = (); }
  { error( "Internal error: called _inline->dump_data incorrectly" ); }

  () = fprintf( fp, "# Dump of stored S-Lang variables\n" );
  foreach ( _store ) using ( "keys", "values" ) {
    variable k, v;
    ( k, v ) = ();
    () = fprintf( fp, "  %s = \t%s\n", k, string(typeof(v)) );
  }
} % _dump_data
'
	     );
    # do I need to end with an 'implements("Global");' ??

    # handle the EXPORT method
    # - this is a *horrible* way to do it; don't seem to be
    #   able to do it easily via
    #     Inline::SLang->export_to_level( 1|2, @{ $o->{ILSM}{EXPORT} } );
    #   so we do this hack
    #
    if ( $o->{ILSM}{EXPORT} ne "" ) {
      ## Inline::SLang->export_to_level( 2, @{ $o->{ILSM}{EXPORT} } );
      eval $o->{ILSM}{EXPORT};
      croak $@ if $@;
    }
    
    $o->{ILSM}{loaded}++;

} # sub: load()

#==============================================================================
# Evaluate a string as a piece of S-Lang code
#
# want to allow sl_eval( '$1=(); ...($1);', $var1, ... );
#
#==============================================================================
sub sl_eval ($) {
  my $str = shift;
  # too lazy to do a possibly-quicker check than this regexp
  $str .= ";" unless $str =~ /;\s*$/;

  # _sl_eval() sets $@ with the S-Lang error (if there is
  # one). To allow sl_eval() to be wrapped in an eval block
  # (and so catch the error), we don't do any checks for
  # errors here
  #
  return _sl_eval($str);
}

#==============================================================================
# sl_typeof()
#
# Our version of S-Lang's typeof() command. This avoids having
# to convert variables from Perl to S-Lang to just get the type
# of the variable. Then again, since we delegate all the processing to
# the typeof() method for the object class (if there is one) we're
# not really that efficient
#
# If the variable is unrecognised then return undef
# (if sent an undef then "Null_Type" is returned)
#
# we delegate all the work to _guess_sltype() which means we're
# not as efficient as we could be (since opaque types will
# have ->typeof->stringify called and then the output turned
# back into a DataType_Type object) but I'm not too bothered about that
# at the moment.
#
#==============================================================================
sub sl_typeof ($) {
  my $invar = shift || return Null_Type();
  return DataType_Type->new( _guess_sltype($invar) );
}

#==============================================================================
#
# Usage:
#   $obj = sl_array( $aref )
#   $obj = sl_array( $aref, $adims )  - dims of $aref
#   $obj = sl_array( $aref, $type )   - type of $aref (string or DataType_Type)
#   $obj = sl_array( $aref, $adims, $type )
#
# Aim:
#   Convert a Perl array reference to an Array_Type object
#
#   This is a utility routine which is just a wrapper around
#   Array_Type->new() - with a few little convenince functions
#   and is intended really for use when calling S-lang funcs - ie
#      some_sl_func( ..., sl_array([0,1,2],"Integer_Type"), ... )
#   ie so you don't have to mess around with the Array_Type class
#   as long as possible
#
#==============================================================================
sub sl_array {

  # checking of input is not bullet proof
  #
  my $usage = <<'EOD';
Usage:
  my $obj = sl_array( $aref );
  my $obj = sl_array( $aref, $adims );
  my $obj = sl_array( $aref, $atype );
  my $obj = sl_array( $aref, $adims, $atype );
EOD

  my $narg = 1 + $#_;
  die $usage unless $narg > 0 and $narg < 4 and
    ref($_[0]) eq "ARRAY";
  my $aref = shift;

  # do we need to calculate the dims and/or type?
  #
  my $adims;
  my $atype;
  if ( $narg == 3 ) {
    $adims = shift;
    $atype = shift;
  } else {
    my $val;
    if ( $narg == 2 ) {
      $val = shift;
      if ( ref($val) eq "ARRAY" ) { $adims = $val; }
      else                        { $atype = $val; }
    }

    if ( defined( $adims ) ) {
      # get the first item: only need to loop through the
      # number of dims; the actual size of each axis is irrelevant here
      $val = $aref;
      foreach ( 0 .. $#$adims ) { $val = $$val[0]; }
    } else {
      $adims = [];
      $val = $aref;
      while ( ref($val) eq "ARRAY" ) {
	push @{$adims}, 1+$#$val;
	$val = $$val[0];
      }
    }

    $atype = _guess_sltype( $val ) unless defined $atype;

    # note: not a necessary check for a string
    die "Error: array type must either be a string or DataType_Type object\n"
      unless ref($atype) eq "" or UNIVERSAL::isa($atype,"DataType_Type");
    
  }

  return Array_Type->new( $atype, $adims, $aref );
} # sl_array

#==============================================================================
# Wrap a S-Lang function with a Perl sub which calls it.
#==============================================================================
sub sl_bind_function {
    my $perlfunc = shift;	# The fully-qualified Perl sub name to create
    my $slangns  = shift;       # The namespace for the S-Lang sub
    my $slangfn  = shift;	# The S-Lang sub name to wrap

    my $qualname;
    if ( $slangns eq "Global" ) {
      $qualname = $slangfn;
    } else {
      $qualname = "${slangns}->${slangfn}";
    }

    my $bind = <<END;
sub $perlfunc {
    unshift \@_, "$qualname";
    return &Inline::SLang::sl_call_function;
}
END

    eval $bind;
    croak $@ if $@;
}

#==============================================================================
# Return a small report about the S-Lang code
#==============================================================================

sub info {
    my $o = shift;

    $o->build unless $o->{ILSM}{built};

    my $info = "Configuration details\n---------------------\n\n";

    # get the version of the S-Lang library: if we bind variables then
    # we won't need to do this
    #
    my $ver = sl_eval("_slang_version_string");
    $info .= "Version of S-Lang:";
    if ( sl_version() eq $ver ) {
      $info .= " $ver\n";
    } else {
      $info .= " compiled with " . sl_version();
      $info .= " but using $ver\n";
    }
    $info .= "Perl module version is $VERSION";
    if ( sl_have_pdl() ) {
      $info .= " and supports PDL" 
    } else {
      $info .= " with no support for PDL" 
    }
    $info .= "\n\n";

    $info .= "The following S-Lang types are recognised:\n";
    my $str = "";
    while ( my ( $dname, $dref ) = each %{ $o->{ILSM}{sl_types} } ) {
      my $curr = " $dname";
      $curr .= "[Struct_Type]" if $$dref[1] == 1;
      if ( length($str) + length($curr) > 70 ) {
	$info .= "$str\n";
	$str = $curr;
      } else {
	$str .= $curr;
      }
    }
    $info .= "$str\n\n";

    $info .= "The following S-Lang namespaces have been bound to Perl:\n\n";
    while ( my ( $slns, $plns ) = each %{ $o->{ILSM}{ns_map} } ) {

      $plns = "main" if $slns eq "Global" and $slns eq $plns;
      my $aref = $o->{ILSM}{namespaces}{$slns} || [];
      my $nfn  = 1 + $#$aref;
      if ( $nfn == 1 ) {
	$info .= sprintf( "  1 function from namespace %s is bound to package %s\n",
			  $slns, $plns );
      } else {
	$info .= sprintf( "  %d functions from namespace %s are bound to package %s\n",
			  1+$#$aref, $slns, $plns );
      }
      foreach my $fn ( @$aref ) {
	if ( ref($fn) eq "ARRAY" ) {
	  $info .= "\t$$fn[0]() -> $$fn[1]()\n";
	} else {
	  $info .= "\t$fn()\n";
	}
      }
      $info .= "\n";
    }
    return $info;

} # sub: info()

#==============================================================================
# S-Lang datatypes as perl objects, all based on the Inline::SLang::_Type 
# class. Note that all other classes are just called <SLang type name>
# rather than Inline::SLang::<SLang Type Name>, as of v0.07.
# This may turn out to be a bad idea, since we don't check for name
# clashes. We could use SLang::<Slang Type name> as a compromise?
#
# Inline::SLang::_Type
#
# - base class of all the S-Lang types that aren't convertable to a 
#   common Perl type/object
# - essentially all this does (at the moment) is ensure that every class 
#   has 4 methods:
#     an overloaded "print/stringify" function
#     typeof() - returns a DataType_Type object
#     _typeof() - returns a DataType_Type object
#     is_struct_type() [only useful when we support type-deffed structs]
#
#   Might want to add new() to this list (and have it croak)?
#
#==============================================================================

package Inline::SLang::_Type;

use strict;
use Carp;

# returns the name of the object (which we take to be the last part of the
# object name with '::' as the separator)
# 
sub typeof {
  my $self  = shift;
  my $class = ref($self) || $self;
  return DataType_Type->new( ((split("::",$class))[-1]) );
}

# _typeof is only really relevant for array types where it is over-ridden
# so we ignore efficiency for ease of coding
# 
sub _typeof { return $_[0]->typeof; }

# pretty printer, which just calls typeof
# [would be quicker to include the typeof code directly]
#
use overload ( "\"\"" => \&Inline::SLang::_Type::stringify );
sub stringify { return $_[0]->typeof()->stringify; }

sub is_struct_type { 0; }

#==============================================================================
# Assoc_Type
#
#  Handle Assoc_Type arrays.
#
#  We use a tied hash to allow users to use a hash syntax for
#  read/write of the fields (so we don't have to 'invent' our
#  own API), whilst using tied routines. The reason for needing
#  a tied hash, rather than use a hash outright - is so that we
#  can store the 'type' of the Assoc_Type array, ie whether it
#  was created as
#    Assoc_Type [String_Type]
#  or
#    Assoc_Type [Any_Type]
#
#  See also Struct_Type
#
#  Usage:
#    S-Lang: foo = Assoc_Type [String_Type];
#    Perl:   $o1 = Assoc_Type->new( "String_Type" );
#            $o1 = Assoc_Type->new( DataType_Type->new("String_Type") );
#            $o1 = Assoc_Type->new( String_Type() );
#      the last option assumes you have asked Inline::SLang to export !types
#
#  Note that Assoc_Type is a subclass of Inline::SLang::_Type, so
#  $o1 has a number of methods (typeof, is_struct_type [returns 0],
#  and an over-loaded stringify)
#
# Although we do provide the S-Lang struct mutators as object methods
# I strongly suggest using the native hash interface instead since this
# is Perl *AND* I do not guarantee these methods will reminan [they
# only exist since they are useful internally when converting Perl -> S-Lang]
#
# S-Lang             Perl
#  get_keys()          keys %$o1   *** but NOT 'keys %$o2' I think ***
#                      keys %foo       ^^^ this could have been due to a bug?
#    NOTE: do not guarantee the same order as S-Lang; in fact almost guarantee they'll be different
#
#  get_values()        values %$o1
#
#  key_exists()        exists $$o1{baz}
#
#  delete_key()        delete $$o1{baz}
#
#  length()            ??
#
# Also going to add get/set_value() which aren't in S-Lang but are useful internally
#
# To do:
#   either copy() or dup()
#
# Over-ride Inline::SLang::_Type's _typeof method to return the type of 
# the values stored in the array
# [unlike S-Lang's _typeof which returns Assoc_Type]
#
#==============================================================================

package Assoc_Type;

## Want to use Tie::ExtraHash but this is not in Perl 5.6.0
## and I can't find out when it was added. So we just use
## the ExtraHash code from the 5.8.0/Tie/Hash.pm module
##
##require Tie::Hash;

use strict;
use vars qw( @ISA );
##@ISA = qw( Tie::ExtraHash Inline::SLang::_Type );
@ISA = qw( Inline::SLang::_Type );

use Carp;

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  tie( my %self, $class, shift );
  bless \%self, $class;
}

sub _typeof {
  my $self = shift;
  my $aref = tied(%$self);
  return $$aref[1];
}

# these are private methods: user code should *NOT* use this, or even
# assume it's going to exist in future versions of the module
# note: we return the hash reference stored within the array
# reference and NOT the array reference itself
#
# for speed we de-reference the DataType_Type object directly in
# _private_get_typeof rather than call stringify on it
sub _private_get_hashref { return ${ tied( %{$_[0]} ) }[0]; }
sub _private_get_typeof  { return ${ ${ tied( %{$_[0]} ) }[1] }; }

# and now methods that match S-Lang function names
# I don't particularly want them (there are more Perl like
# ways to perform these functions), but they are currently
# used by the Perl -> S-Lang code [see util.c]
#
# note: got get_keys/values order is NOT guaranteed to match that of S-Lang
#
sub get_keys   { return [ keys %{$_[0]} ]; }
sub get_values { return [ values %{$_[0]} ]; }
sub get_value  { return $_[0]->{$_[1]}; }
sub set_value  { return $_[0]->{$_[1]} = $_[2]; }
sub key_exists { return exists $_[0]->{$_[1]}; }
sub delete_key { return delete $_[0]->{$_[1]}; }

# a general array function
sub length     { return scalar( keys %{$_[0]} ); } # not very efficient

# now the tied methods
#
# We only bother with TIEHASH since everything else is inherited from Tie::ExtraHash
#
sub TIEHASH {
  croak "Usage: tie %hash, '$_[0]', type (either a string or DataType_Type object)"
    unless $#_ == 1 and ( ref($_[1]) eq "" or UNIVERSAL::isa($_[1],"DataType_Type") );

  my $class  = shift;
  my $intype = shift;
  my $type;
  if ( UNIVERSAL::isa($intype,"DataType_Type") ) {
    $type = $intype;
  } else {
    $type = DataType_Type->new($intype) ||
      die "Error: unrecognised type $intype when creating $class object";
  }

  # [0] = hash reference
  # [1] = DataType_Type object representing the type of the assoc array
  #
  return bless [ {}, $type ], $class;
}

# the rest are from Tie::ExtraHash
#
sub STORE    { $_[0][0]{$_[1]} = $_[2] }
sub FETCH    { $_[0][0]{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0][0]}; each %{$_[0][0]} }
sub NEXTKEY  { each %{$_[0][0]} }
sub EXISTS   { exists $_[0][0]->{$_[1]} }
sub DELETE   { delete $_[0][0]->{$_[1]} }
sub CLEAR    { %{$_[0][0]} = () }

#==============================================================================
# Struct_Type
#
#  Handle structs.
#  type-deffed structs - e.g. 'typedef { foo, bar } Baz_Type;' -
#  are handled by sub-classing this type
#
#  We use a tied hash to allow users to use a hash syntax for
#  read/write of the fields (so we don't have to 'invent' our
#  own API), whilst using tied routines to over-ride some of the
#  default behaviour of the hash, namely:
#    adding new fields
#    providing a 'random' access to the fields via each/next
#    [the order is equal to that of the order of the fields in the struct]
#
#  Similar to handling Assoc_Type arrays
#
#  Usage:
#    S-Lang: foo = struct { bob, foo, bar };
#    Perl:   $o1 = Struct_Type->new( ["bob","foo","bar"] );
#            $o2 = tie %foo, Struct_Type, [ "bob", "foo", "bar" ];
#            ['$o2 =' is optional]
#
#    The use of tie should NOT BE USED: use Struct_Type->new() instead.
#
#  Note that Struct_Type is a subclass of Inline::SLang::_Type, so
#  $o1 [1st Perl example] and $o2 [2nd example] have a number of
#  methods (typeof, is_struct_type [returns 1 ;], and an over-loaded stringify)
#
# Although we do provide the S-Lang struct mutators as object methods
# I strongly suggest using the native hash interface instead since this
# is Perl *AND* I do not guarantee these methods will remain [they
# only exist since they are useful internally when converting 
# Perl -> S-Lang]
#
# S-Lang             Perl
#  get_field_names()   keys %$o1   *** but NOT 'keys %$o2' I think ***
#                      keys %foo       ^^^ this could have been due to a bug?
#
#  get/set_field()     $$o1{baz}
#                      $foo{baz}
#
# Added a "dump" method which returns a string representation of
# the fields/data in the structure. Somewhat like Varmm's print()
# function when given a Struct_Type. Currently not documented
# as needs testing/thinking about. Could have just over-ridden the
# default "stringify" method but want to keep that behaviour (ie returns the
# object type)
#
# To do:
#   either copy() or dup() -- including Mike Nobles's "field-slicing"
#     idea, ie $self->copy("-foo"); removes foo
#
#==============================================================================

package Struct_Type;

use strict;
use vars qw( @ISA );
@ISA = ( "Inline::SLang::_Type" );

use Carp;

# first the over-ridden methods from Inline::SLang::_Type
#
# new(), TIEHASH(), and _define_struct() are the only methods that
# will be over-ridden in sub-classes (ie for "named" structs)
#
sub is_struct_type() { 1; }

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  tie( my %self, $class, shift );
  bless \%self, $class;
}

# this is a private method: user code should *NOT* use this, or even
# assume it's going to exist in future versions of the module
# note: we return the hash reference stored within the array
# reference and NOT the array reference itself
#
sub _private_get_hashref { return ${ tied( %{$_[0]} ) }[0]; }

# and now methods that match S-Lang function names
# I don't particularly want them (there are more Perl like
# ways to perform these functions), but they are currently
# used by the Perl -> S-Lang code [see util.c]
#
sub get_field_names { return [ keys %{$_[0]} ]; }
sub get_field { return $_[0]->{$_[1]}; }
sub set_field { return $_[0]->{$_[1]} = $_[2]; }

# return a string contaiining a representation of the
# structs contents. Format may well change.
#
# does not handle complicated structures very well
#
# perhaps the dump method should be in the
# Inline::SLang::_Type class and we over-ride it
# where necessary?
#
sub dump {
    my $self  = shift;
    my $depth = shift || 0;

    my $spacer = '  ' x ($depth-1);

    my $str = "${spacer}Contents of $self variable:\n";
    $spacer .= '  ';

    while ( my ( $field, $val ) = each %{$self} ) {
      $str .= "${spacer}$field\t";
      if ( defined $val ) {
	  if ( UNIVERSAL::isa($val,'Inline::SLang::_Type') ) {
	      $str .= $val->typeof . "\n";
	      $str .= $val->dump($depth+2)
		if UNIVERSAL::isa($val,'Struct_Type');
	  } else {
	      my $ref = ref($val);
	      if ( $ref ) {
		  $str .= $ref . " reference\n";
	      } else {
		  $str .= $val . "\n";
	      }
	  }
      } else {
	  $str .= "Null_Type\n";
      }
    }
    return $str;

} # sub: dump

# now define the tied methods

# unlike all the other tied methods, this one is over-ridden
# by the classes representing "named" structures since the
# list of field names is fixed in those cases
#
sub TIEHASH {
  croak "Usage: tie %hash, '$_[0]', [ list of field names ]"
    unless $#_ == 1 or ref($_[1]) != "ARRAY";

  my $class  = shift;
  my $fields = shift;
  croak "Error: can not create an empty $class object."
    if $#$fields == -1;

  # [0] = hash reference
  # [1] = array reference (field names)
  # [2] = scalar: counter used when iterating through the hash
  #
  # note: we do *NOT* set [1] equal to $fields
  #  instead we ensure we use a copy of this information
  #
  my @fieldnames = @$fields; # create a copy
  my $struct = { map { ($_,undef); } @fieldnames };
  return bless [ $struct, [@fieldnames], 0 ], $class;
}

sub FETCH {
  my ( $impl, $key ) = @_;
  croak "Error: field '$key' does not exist in this " . ref($impl) . " structure\n"
    unless exists $$impl[0]{$key};
  return $$impl[0]{$key};
}

sub STORE {
  my ( $impl, $key, $newval ) = @_;
  croak "Error: field '$key' does not exist in this " . ref($impl) . " structure\n"
    unless exists $$impl[0]{$key};
  $$impl[0]{$key} = $newval;
}

sub EXISTS {
  my ( $impl, $key ) = @_;
  return exists $$impl[0]{$key};
}

# do not allow a delete
sub DELETE {
  my ( $impl, $key ) = @_;
  die "Error: unable to delete a field from a " . ref($impl) . " structure\n";
}

# if the user does a clear then we reset all the fields to NULL
# - not convinced that this behaviour is the best thing to do;
#   could die on CLEAR?
#
sub CLEAR {
  my ( $impl ) = @_;
  foreach my $key ( keys %{ $$impl[0] } ) { $$impl[0]{$key} = undef; }
  $$impl[2] = 0; # is this needed?
}

# hope that we get the iteration handled correctly: we try
# and use the order of the keys in the S-Lang structure as 
# the order of the iteration
#
sub FIRSTKEY {
  my ( $impl ) = @_;
  $$impl[2] = 1; # the next key to get is element 1
  return $$impl[1][0];
}

# if we've exceeded the number of fields then we do nothing
sub NEXTKEY {
  my ( $impl ) = @_;
  my $curr = $$impl[2];
  return undef if $curr > $#{$$impl[1]};
  $$impl[2]++;
  return $$impl[1][$curr];
}

## private methods for this object (no guarantee they will
## remain - or behave the same - between releases)

# returns the S-Lang code necessary to create a struct
# with the correct fields in $1, but doesn't actually execute it
# (since this would convert it back into Perl which we don't want)
#
# we make this code also handle the case when called from a sub-class
# of Struct_Type
#
sub _define_struct {
  my $self  = shift;
  my $class = ref($self) or
    die "Error: Struct_Type::_define_struct() can not be called as a class method";
  return "\$1 = struct { " . join( ', ', keys %$self ) . " };";
} # sub: _define_struct()

#==============================================================================
# Array_Type
#
#  Handle arrays: was going to use a tied array but decided against this
#  since it's not obvious how to handle > 1D arrays in this scheme; ie
#     sl = Int_Type [1,3,2];
#  when converted to a tied array would probably have to be
#     pl = ref to tied 1D array with 1 element
#            element is a tied 1D array with 3 elements
#              element is a tied 1D array with 2 values
#  to allow $$pl[0][2][1] to access an element. And that can't be
#  remotely efficient. Plus we'd need to add methods to allow slicing/indexing
#
#  So I'm going to see how a straight Perl object does: ie have to use
#  methods as mutators rather than rely on Perl syntax/base datatypes.
#
# Usage:
#   $a = Assoc_Type->new( "Int_Type", [1,3,2] [, $aref ] );
#   $a = Assoc_Type->new( DataType_Type->new("Int_Type"), [1,3,2], [$aref] );
#   $a = Assoc_Type->new( Integer_Type(), [1,3,2], [$aref] );
# 
# $aref is an array reference of the data being sent in which we
# assume matches the supplied datatype and size -- it's the user's
# fault if it isn't. Note: we do NOT copy the data - so if the user
# changes the data using $aref then they're likely to be surprised
#
#   $val = $a->get(0,2,1);
#   $a->set(0,2,1,$newval);
#
#   $a->reshape/_reshape - need to read S-Lang docs again!
#
#   $a->index( [0,1,3] ); only for 1D arrays
#
#   ( \@dims, $ndims, $array_type ) = $a->array_info()
#
#   $a->toPerl();   return the internal copy of the array; beware!!
#
# To Do:
#   allow slicing?
#
#==============================================================================

package Array_Type;

use strict;
use vars qw( @ISA );
@ISA = ( "Inline::SLang::_Type" );

use Carp;

# first the over-ridden methods from Inline::SLang::_Type
#

sub new {
  my $this   = shift;
  my $class  = ref($this) || $this;
  my $narg = 1 + $#_;
  croak "Usage: \$obj = $class" . "->new( Type, \\\@arraydims [, \$aref ] );"
    unless
      $narg > 1 and $narg < 4 and
      ( ref($_[0]) eq "" or UNIVERSAL::isa($_[0],"DataType_Type")) and
      ref($_[1]) eq "ARRAY" and
      ( $narg == 2 or ref($_[2]) eq "ARRAY" );
  my $intype = shift;
  my $dims   = shift;
  my $aref   = $narg == 3 ? shift : undef;

  my $type;
  if ( UNIVERSAL::isa($intype,"DataType_Type") ) {
    $type = $intype;
  } else {
    $type = DataType_Type->new($intype) ||
      die "Error: unrecognised type $intype when creating $class object";
  }

  # [0] = array reference
  # [1] = DataType_Type object (type of array)
  # [2] = array reference: array dims
  #
  # note that we start off with an array of undef's
  # - although we amy want to change that to the default
  #   value for the type
  # OR we just use the value that was sent in for the data
  # [with ***NO*** validity checking and ***NO*** copying]
  #
  # note that I try and ensure we use copies of the dim array here
  if ( $narg == 3 ) {
    return bless [ $aref, $type, [@$dims] ], $class;
  } else {
    return bless [ Inline::SLang::_create_empty_array( $dims ), $type, [@$dims] ], $class;
  }
}

sub toPerl  { return ${$_[0]}[0]; } # note: this is NOT a copy
sub _typeof { return ${$_[0]}[1]; }

## object methods

# changes the $coords array in place if necessary
sub _validate_pos {
  my $fname  = shift;
  my $dims   = shift;
  my $coords = shift;

  my $ndims   = $#$dims;
  my $ncoords = $#$coords;
  die "Error: ${fname}() called with " . (1+$ncoords) .
      " coordinates but array dimensionality is " . (1+$ndims) . "\n"
      unless $ncoords == $ndims;
  foreach my $i ( 0 .. $ncoords ) {
    my $pos  = $$coords[$i];
    my $npts = $$dims[$i];
    die "Error: coord #$i of ${fname}() call (val=$pos) lies outside valid range of -$npts:" . ($npts-1) . "\n"
      if $pos < -$npts or $pos > $npts-1;
    $$coords[$i] += $npts if $pos < 0;
  }
} # sub: _validate_pos

sub get {
  my $self = shift;
  my $aref = $$self[0];
  my $dims = $$self[2];
  my @pos  = @_;
  _validate_pos( "get", $dims, \@pos );
  # return the value
  my $ref = $aref;
  foreach my $indx ( @pos ) {
    $ref = $$ref[ $indx ];
  }
  return $ref;
} # sub: get

sub set {
  my $self = shift;
  my $aref = $$self[0];
  my $dims = $$self[2];
  my $newval = pop;
  my @pos  = @_;
  _validate_pos( "set", $dims, \@pos );
  # set the value
  my $ref = $aref;
  my $lastpos = pop @pos;
  foreach my $indx ( @pos ) {
    $ref = $$ref[ $indx ];
  }
  return $$ref[$lastpos] = $newval;
} # sub: set

# (Array_Type, Integer_Type, DataType_Type) array_info (Array_Type a)
#
# note: we return the dimensions as a Perl array reference, not
# as an Array_Type object. We make sure to send a copy of it
#
sub array_info {
  my $self = shift;
  return ( [ @{$$self[2]} ], 1+$#{$$self[2]}, $$self[1] );
} # sub: array_info

# can I be bothered with these?
sub reshape  { die "ERROR: reshape method not yet available\n"; }
sub _reshape { die "ERROR: _reshape method not yet available\n"; }
sub index    { die "ERROR: index method not yet available\n"; }

# these are private methods: user code should *NOT* use thes, or even
# assume they're going to exist in future versions of the module
#
# for speed we de-reference the DataType_Type object directly in
# _private_get_typeof rather than call stringify on it
sub _private_get_arrayref { return $_[0][0]; }
sub _private_get_typeof   { return ${ $_[0][1] }; }
sub _private_get_dims     { return $_[0][2]; }

# utility routines called as a class method - ie not on an object
# - used in util.c because I'm too lazy to do it in C
#
sub _private_get_assign_string {
  my $ndim = 1+shift;
  return
    join('', map { "\$$_=();" } reverse(1..$ndim+2)) .
    "\$1[" . join(',', map { "\$$_" } (2..$ndim+1) ) .
    "]=\$" . ($ndim+2) . ";";
}
sub _private_get_read_string {
  my $ndim = 1+shift;
  return
    join('', map { "\$$_=();" } reverse(2..$ndim+1)) .
    "\$1;\$1[" . join(',', map { "\$$_" } (2..$ndim+1) ) .
    "];";
}

# returns the S-Lang code necessary to create an array of the
# correct size and dimensionality
#
sub _private_define_array {
  my $self  = shift;
  my $class = ref($self) or
    die "Error: Array_Type::_define_array() can not be called as a class method";
  return "\$1 = $$self[1] [ " . join(',',@{$$self[2]}) . " ];";
} # sub: _private_define_array()

#==============================================================================
# DataType_Type
#
# - the type is returned as a string (which is the output of
#   'typeof(foo);' for the S-Lang variable foo)
# - the string is blessed into the DataType_Type object
# - we use S-Lang to create a DataType_Type variable so that we can
#     a) check we have a datatype
#     b) handle type synonyms correctly
# - we allow two datatypes to be checked for equality. Unfortunately
#   since we don't have access to all the synonyms for a type it's not
#   quite as useful as in S-Lang
#
# As of 0.11 have added routines to Inline::SLang (can be exported into
# main) which have the name of the type and are just wrappers around
# DataType_Type->new("type name"). So you can say
#   Integer_Type()
# to return an Integer_Type object. 
# As of 0.12 added functions for type synonyms, such as Int_Type
# and Float64_Type.
#
#==============================================================================

package DataType_Type;

use strict;
use vars qw( @ISA );
@ISA = ( "Inline::SLang::_Type" );

# only equality/inequality and stringification
#
# over-ride the base 'stringify' method
# since we actually want to print out the actual datatype,
# and not that this is a DataType_Type object
#
use overload
  (
   "==" => sub { ${$_[0]} eq ${$_[1]}; },
   "eq" => sub { ${$_[0]} eq ${$_[1]}; },
   "!=" => sub { ${$_[0]} ne ${$_[1]}; },
   "ne" => sub { ${$_[0]} ne ${$_[1]}; },
   "\"\"" => \&DataType_Type::stringify
   );

sub stringify { return ${$_[0]}; }

# delegate all the checking to S-Lang itself, so that
# we can handle class synonyms
#
# cheat and say an empty constructor creates a datatype_type
#
sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = shift || "DataType_Type";

    # this will convert class synonyms to their "base" class
    # - naively one would do something like
    #
    #     ( $flag, $val ) = Inline::SLang::sl_eval(
    #       "typeof($self)==DataType_Type;string($self);"
    #      );
    #
    # but this means the S-Lang stack is cleared [by sl_eval] which
    # is not good since this constructor can be called within sl2pl/pl2sl
    # [particularly when converting assoc arrays], which means that
    # the S-Lang stack gets hosed
    #
    # Hence we have a hard-coded function to do what we want
    # [which can still fail, so we still need to wrap it in an eval block]
    #
    my ( $flag, $val );
    eval qq{
      ( \$flag, \$val ) = Inline::SLang::_sl_isa_datatype(\$self);
     };

    # return undef on failure
    return undef unless defined $flag and $flag;

    return bless \$val, $class;
} # sub: new()

#==============================================================================

# End
1;
