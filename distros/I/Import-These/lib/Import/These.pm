package Import::These;

use strict;
use warnings;
use feature "say";


our $VERSION = 'v0.1.2';

# Marker is pushed to end of argument list to aid in processing.
# Make random to prevent collisions.
#
my $marker=join "", map int rand 26, 1..16;


sub import {
  no strict "refs";

  my $package=shift;

  my $prefix="";
  my $next_prefix="";
  my $k;
  my $version;
  my $mod;
  my $next_mod;
  my $list;


  push @_, $marker;
  
  # Save the target export level
  my $target_level=($Exporter::ExportLevel||0)+1;

  my $i=0;
  while(@_){
    $k=shift;

    # Check if the next item is a ref,  or a scalar
    #
    my $r=ref $k;
    if($r eq "ARRAY"){
      $list=$k;
    }

    elsif($r eq ""){
      if($k eq $marker){
      }
      elsif($k eq "::"){
        # Exact. Clear prefix
        $next_prefix="";
      }
      elsif($k =~ /^::.*?::$/){
        # Double ended. Append new portion to prefix
        $next_prefix=$prefix.substr $k, 2;
      }
      elsif($k =~/::$/){
        # At end. Update prefix
        $next_prefix=$k;
      }
      elsif($k =~ /^v|^\d/){
        # Test if it looks like a version. 
        unless($i){
          # Actually a perl version
          eval "use $k";
          die $@ if $@;
          next;
        }
        else {
          $version=$k;
        }
      }
      else {
        # Module name
        $next_mod=$k;
      }
    }
    else {
      die "Scalar or array ref only";
    }

    # Attempt to execute/load the current state
    
    if($mod){
      #say STDERR "REQUIRE $prefix$mod";
      # Force export level to 0 so any imports of required package are
      # relative to required package
      local $Exporter::ExportLevel=0;
      eval "require $prefix$mod;";
      die "Could not require $prefix$mod: $@" if $@;

      # After the package has been required, set the target level for import
      #
      local $Exporter::ExportLevel=$target_level;

      if($version){
        "$prefix$mod"->VERSION($version);
      }

      if($list and @$list){
        # List import
        "$prefix$mod"->import(@$list);
      }
      elsif($list and @$list ==0){
        # no not import
      }
      else {
        # Default import
        "$prefix$mod"->import();
      }
    }
      
    # Update the state
    $mod=$next_mod;

    $next_mod=undef;
    $prefix=$next_prefix if $next_prefix;
    $next_prefix=undef;
    $list=undef;
    $version=undef;
    $i++;
  }
}

__PACKAGE__;

=head1 NAME

Import::These -  Terse, Prefixed and Multiple Imports with a Single Statement

=head1 SYNOPSIS

Any item ending with :: is a prefix. Any later items in the list will use the
prefix to create the full package name: 

  #Instead of this:
  #
  use Plack::Middleware::Session;
  use Plack::Middleware::Static;
  use Plack::Middleware::Lint;
  use IO::Compress::Gzip;
  use IO::Compress::Gunzip;
  use IO::Compress::Deflate;
  use IO::Compress::Inflate;


  # Do this
  use Import::These qw<
    Plack::Middleware:: Session Static Lint
    IO::Compress::      Gzip GunZip Defalte Inflate
  >;



Any item exactly equal to  :: clears the prefix:

  use Import::These "Prefix::", "Mod", "::", "Prefix::Another";
  # Prefix::Mod
  # Prefix::Another;


A item beginning with :: and ending with :: appends the item to the prefix:

  use Import::These "Plack::", "Test", "::Middleware::", "Lint";
  # Plack::Test,
  # Plack::Middleware::Lint;


Supports default, named/tagged, and no import:

  # Instead of this:
  #
  # use File::Spec::Functions;
  # use File::Spec::Functions "catfile";
  # use File::Spec::Functions ();

  # Do This:
  #
  use Import::These "File::Spec::", Functions, 
                                    Functions=>["catfile"],
                                    Functions=>[]

Supports Perl Version as first argument to list

  use Import::These qw<v5.36 Plack:: Test ::Middleware:: Lint>;
  # use v5.36;
  # Plack::Test,
  # Plack::Middleware::Lint;

Supports Module Version

  use Import::These qw<File::Spec:: Functions 1.3>;
  # use File::Spec::Functions 1.3;
  #
  use Import::These qw<File::Spec:: Functions 1.3>, ["catfile"];
  # use File::Spec::Functions 1.3 "catfile";
  
=head1 DESCRIPTION

A tiny module for importing multiple modules in one statement utilising a
prefix. The prefix can be set, cleared, or appended multiple times in a list,
making long lists of imports much easier to type!

It works with any package providing a C<import> subroutine (i.e. compatible
with L<Exporter>. It also is compatible with recursive exporters such as
L<Export::These> manipulating the export levels.


=head1 USAGE

When using this pragma, the list of arguments are interpreted as either a Perl
version, prefix mutation, module name, module version  or  array ref of symbols
to import. The current value of the prefix is applied to module names as they
appear in the list.


=over

=item The prefix always starts out as an empty string.

=item The first item in the list is optionally a Perl version 

=item Module version optionally comes after a module name (prefixed or not)

=item Symbols list optionally comes after a module name or module version if used

=item The prefix can be set/cleared/appended as many times as needed 

=back

=head2 Prefix Manipulation

The current prefix is used for all module names as they occur. However, changes
to the prefix can be interleaved within module names.


=head3 Set the Prefix

 Name::

 # Prefix equals "Name::"

Any item in the list ending in "::" with result in the prefix being set to item (including the ::)

=head3 Append The Prefix

  ::Name::

  # Prefix equals "OLDPREFIX::Name::"
 
Any item in the list starting and ending with "::" will result in the prefix
having the item appended to it. The item has the leading "::" removed before
appending.


=head3 Clear the Prefix

  ::
  
  #Prefix is ""
  
Any item in the list equal to "::" exactly will clear the prefix to an empty
string

=head1 EXAMPLES

The following examples make it easier to see the benefits of using this module:

=head2 Simple Prefix

A single prefix used for  multiple packages:

  use Import::These qw<IO::Compress:: Gzip GunZip Defalte Inflate >;

  # Equivalent to:
  # use IO::Compress::Gzip
  # use IO::Compress::GunZip
  # use IO::Compress::Deflate
  # use IO::Compress::Inflate

=head2 Appending Prefix

Prefix is appended along the way:

  use Import::These qw<IO:: File ::Compress:: Gzip GunZip Defalte Inflate >;
  
  # Equivalent to:
  # use IO::File
  # use IO::Compress::Gzip
  # use IO::Compress::GunZip
  # use IO::Compress::Deflate
  # use IO::Compress::Inflate

=head2 Reset Prefix

Completely change (reset) prefix to something else:

  use Import::These qw<File::Spec Functions :: Compress:: Gzip GunZip Defalte Inflate >;

  # Equivalent to: 
  # use File::Spec::Functions
  # use IO::Compress::Gzip
  # use IO::Compress::GunZip
  # use IO::Compress::Deflate
  # use IO::Compress::Inflate


=head2 No Default Import

  use Import::These "File::Spec::", "Functions"=>[];

  # Equivalent to:
  # use File::Spec::Functions ();
  
=head2 Import Names/groups

  use Import::These "File::Spec::", "Functions"=>["catfile"];

  # Equivalent to:
  # use File::Spec::Functions ("catfile");


=head2 With Perl Version

  use Import::These "v5.36", "File::Spec::", "Functions";

  # Equivalent to:
  # use v5.36;
  # use File::Spec::Functions;

=head2 With Module Version

  use Import::These "File::Spec::", "Functions", "v1.2";

  # Equivalent to:
  # use File::Spec::Functions v1.2;


=head2 All Together Now

  use Import::These qw<v5.36 File:: IO ::Spec:: Functions v1.2>, ["catfile"],  qw<:: IO::Compress:: Gzip GunZip Deflate Inflate>;

  # Equivalent to:
  # use v5.36;
  # use File::IO;
  # use File::Spec::Functions v1.2 "catfile"
  # use IO::Compress::Gzip;
  # use IO::Compress::GunZip;
  # use IO::Compress::Deflate;
  # use IO::Compress::Inflate;


=head1 COMPARISON TO OTHER MODULES

L<Import::Base> Performs can perform multiple imports, however requires a
custom package to group the imports and reexport them. Does not support
prefixes.

L<use> is very similar however does not support prefixes.


L<import> works by loading ALL packages under a common prefix. Whether you need
them or not.  That could be a lot of disk access and memory usage.

L<modules> has automatic module installation using CPAN. However no
prefix support and uses B<a lot> of RAM for basic importing

L<Importer> has some nice features but not a 'simple' package prefix. It also
looks like it only handles a single package per invocation

=head1 REPOSITOTY and BUGS

Please report and feature requests or bugs via the github repo:

L<https://github.com/drclaw1394/perl-import-these.git>

=head1 AUTHOR

Ruben Westerberg, E<lt>drclaw@mac.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

Licensed under MIT

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

=cut
 

