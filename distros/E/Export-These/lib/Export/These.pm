package Export::These;

use strict;
use warnings;

our $VERSION="v0.2.0";

sub import {
  my $package=shift;
  my $exporter=caller;

  # Treat args as key value pairs, unless the value is a string.  in
  # this case it is the name of a symbol to export directly

  my ($k, $v);

  no strict "refs";

  # Locate or create the EXPORT, EXPORT_OK and EXPORT_TAGS package
  # variables.  v0.2.0 adds EXPORT_PASS an array of names to allow to
  # pass through for reexporting
  # These are used to accumulate our exported symbol names across
  # multiple use Export::Terse ...; statements
  # 
  my $export_ok= \@{"@{[$exporter]}::EXPORT_OK"};
  my $export= \@{"@{[$exporter]}::EXPORT"};
  my $export_tags= \%{"@{[$exporter]}::EXPORT_TAGS"};

  #my $export_pass= \@{"@{[$exporter]}::EXPORT_PASS"};
  
  # This is a reference to a scalar, which is either undef
  # or a reference to an array
  my $export_pass=\${"@{[$exporter]}::EXPORT_PASS"};

  
  while(@_){
    $k=shift;

    die "Expecting symbol name or group name" if ref $k;
    my $r=ref $_[0];
    unless($r){
      push @$export, $k;
      push @$export_ok, $k;
      next
    }
    my $v=shift; 

    for($k){
      if(/export_ok$/ and $r eq "ARRAY"){
        push @$export_ok, @$v;
      }
      elsif(/export$/ and $r eq "ARRAY"){
        push @$export, @$v;
        push @$export_ok, @$v;
      }
      elsif(/export_pass/ and $r eq "ARRAY"){
        unless($$export_pass){
          $$export_pass=[];
        }
        push @$$export_pass, @$v;
      }
      elsif($r eq "ARRAY"){
        #Assume key is a tag name
        push $export_tags->{$k}->@*, @$v;
        push @$export_ok, @$v;
      }
      else {
        die "Unkown export grouping: $k";
      }
    }
  }

  # Generate the import sub here if it doesn't exist already

  local $"= " ";
  my $exist=eval {*{\${$exporter."::"}{import}}{CODE}};
  if($exist){
    return;
  }

  my $res=eval qq|
  package $exporter;
  no strict "refs";


  sub _self_export {
    shift;

    my \$ref_export_ok= \\\@@{[$exporter]}::EXPORT_OK;
    my \$ref_export= \\\@@{[$exporter]}::EXPORT;
    my \$ref_tags= \\\%@{[$exporter]}::EXPORT_TAGS;
    my \$ref_export_pass= \\\$@{[$exporter]}::EXPORT_PASS;

    my \$target=shift;

    # Filter out any refs.. this config not symbol names
    \@_=grep !ref, \@_;
    no strict "refs";
    for(\@_ ? \@_ : \@\$ref_export){
      my \@syms;
      if(ref){
        # If not a simple scalar don't process here, but don error also
        next;
      }
      elsif(/^:/){
        my \$name= s/^://r;

        my \$group=\$ref_tags->{\$name};
        #die  "Tag \$name does not exists" unless \$group;
        push \@syms, \@\$group if \$group;
      }
      else {
        #non tag symbol
        my \$t=\$_;
        \$t="\\\\\$t" if \$t =~ /^\\\$/;
        my \$found=grep /\$t/, \@\$ref_export_ok;
         
        push \@syms, \$_ if \$found;

        \$found\|\|=grep /^\$t\$/, \@\$\$ref_export_pass;



        # If ref export is an empty array, we pass everything
        \$found\|\|=((defined(\$\$ref_export_pass) and !\@\$\$ref_export_pass));
        die "\$_ is not exported or reexported from ".__PACKAGE__."\n" unless \$found;
      }
      
      my \%map=(
        '\$'=>"SCALAR",
        '\@'=>"ARRAY",
        '\%'=>"HASH",
        '\&'=>"CODE"
        );

      for(\@syms){
        my \$prefix=substr(\$_,0,1);
        my \$name=\$_; 
        my \$type=\$map{\$prefix};

        \$name=substr \$_, 1 if \$type;
        unless(\$type){
          \$type//="CODE";
          \$prefix="";
        }

        no warnings "redefine";
        eval { *{\$target."::".\$name}= *{ \\\${__PACKAGE__ ."::"}{\$name}}{\$type}; };
        die "Could not export \$prefix\$name from ".__PACKAGE__ if \$\@;


      }
    }


  }


  sub import {
    my \$package=shift;
    \$Exporter::ExportLevel//=0;
    my \$target=(caller(\$Exporter::ExportLevel))[0];

    my \$ref=eval {*{\\\${\$package."::"}{_preexport}}{CODE}};
    my \@args;
    if(\$ref){
      \@args=$exporter->_preexport(\$target, \@_);
    }
    else {
      \@args=\@_;
    }



    $exporter->_self_export(\$target, \@args);
    
    local \$Exporter::ExportLevel=\$Exporter::ExportLevel+3;
    \$ref=eval {*{\\\${\$package."::"}{_reexport}}{CODE}};

    if(\$ref){
      $exporter->_reexport(\$target, \@args);
    }

  }

  1;
  |;
  die $@ unless $res;
}
1;


=head1 NAME

Export::These - Terse Module Configuration and Symbol (Re)Exporting


=head1 SYNOPSIS

Take a fine package, exporting subroutines,

  package My::ModA;

  use Export::These "dog", "cat", ":colors"=>[qw<blue green>];

  sub dog {...}  
  sub cat {...} 
  sub blue {...} 
  sub green {...}
  1;


Another package which would like to reexport the subs from My::ModA:

  package My::ModB;
  use My::ModA;

  use Export::These ":colors"=>["more_colours"];

  sub _reexport {
    my ($packate, $target, @names)=@_;
    My::ModA->import(":colours") if grep /:colours/, @names;
  }
 
  sub more_colours { ....  }
  1;


Use package like usual:

  use My::ModB qw<:colors dog>

  # suburtines blue, green , more_colors and dog  imported



Also can use to pass in configuration information to a module:

  package My::ModB;

  use Export::These;

  sub _preexport {
    
    my @refs=grep ref, @_;
    my @non_ref= grep !ref, @_;
    
    # Use @refs as configuration data
    
    @non_ref;
  }


  # Import the module, with configuration data
  use My::ModB {option1=>"hello"}, "symbol";

  ...


=head1 DESCRIPTION

A module to make exporting symbols less verbose and more powerful. Facilitate
reexporting and filtering of symbols from dependencies with minimal input from
the module author. Also provide the ability to pass in 'config data' data to a
module during import.

By default listing a symbol for export, even in a group/tag, means it will be
automatically marked as 'export_ok', saving on duplication and managing two
separate lists.

It B<DOES NOT> inherit from C<Exporter> nor does it utilise the C<import>
routine from C<Exporter>. It injects its own C<import> subroutine into the each
calling package. This injected subroutine adds the desired symbols to the
target package  as you would expect.

If the exporting package has a C<_preexport> subroutine, it is called as a
filter 'hook' prior to normal 'importing' to allow module wide configuration or
pre processing of requested import list. The return from this subroutine will
be the arguments used at subsequent stages so remember to return an appropriate
list.

If the exporting package has a C<_reexport> subroutine, it is called after
normal importing. This is the 'hook' location where its safe to call
C<-E<gt>import> on any dependencies modules it might want to export. The
symbols from these packages will automatically be installed into the target
package with no extra configuration needed.

Any reference types specified in an import are ignored during the normal import
process.  This allows custom module configuration to be passed during import
and processed in the C<_preexport> and C<_reexport> hooks.

Finally, warnings about symbols redefinition in the export process (i.e. exporting
to two subroutines with the same name into the same namespace) are silenced to
keep warning noise to a minimum. The last symbol definition will ultimately be
the one used.



=head1 MOTIVATION

Suppose you have a server module, which uses a configuration module to process
configuration data. However the main program (which imported the server module)
also needs to use the subroutines from the configuration module. The consumer
of the server module has to also add the configuration module as a dependency.

With this module the server can simply reexport the required configuration
routines, injecting the dependency, instead of the consumer hard coding it.


=head1 USAGE
  
=head2 Importing a module which uses this module

Importing is achieved just like normal.

    require My::Module;
    My::Moudle->import;

    use My::Moudle qw<:tag_name name2 ...>;

However, from B<v0.2.0> importing of a module can also take a reference value
as a key without error. This allows passing non names as configuration data for
the module to use:

    eg

      use My::Module {prefork=>1, workers=>10}, "symname1", ":group1",['more', 'config'];

In this hypothetical example, the My::Module uses the hash and array ref as
configuration internally, and the normal scalars as the symbols/tag groups to
export

=head2 Specifying Symbols to Export

    use Export::These ...;

The pragma takes a list of arguments to add to the C<@EXPORT> and C<EXPORT_OK>
variables. The items are taken as a name of a symbol or tag, unless the
following argument in the list is an array ref.

    eg:

      use Export::These qw<sym1 sym2>;


If the item name is "export_ok", then the items in the following array ref are
added to the C<@EXPORT_OK> variable.
    

    eg
      use Export::These export_ok=>[qw<sym1>];


If the item name is "export", then the items in the following array ref are
added to the C<@EXPORT_OK>  and the C<EXPORT> variables. This is the same as
simply listing the items at the top level.
  
    eg 

      use Export::These export=>[qw<sym1>];
      # same as
      # use Export::These qw<sym1>;

If the item name is "export_pass", then the items in the following array ref
symbols will be allowed to be requested for import even if the module does not
export them directly.  Use an empty array ref to allow any names for
reexporting:

    eg 

      # Allow sym1 to be reexported from sub modules
      use Export::These export_pass=>[qw<sym1>];

      # Allow any name to be reexported from submodules
      use Export::These export_pass=>[];



If the item has any other name, it is a tag name and the items in the following
array ref are added to the C<%EXPORT_TAGS>  variable and to C<@EXPORT_OK>

    eg use Export::These group1=>["sym1"];



The list can contain any combination of the above:

    eq use Export::These "sym1", group1=>["sym2", "sym3"], export_ok=>"sym4";


=head2 Rexporting Symbols

If a subroutine called C<_reexport> exists in the exporting package, it will be
called on (with the -> notation) during import, after the normal symbols have
been processed. The first argument is the package name of exporter, the second
is the package name of the importer (the target), and the remaining arguments
are the names of symbols or tags to import.

In this subroutine, you call C<import> on as any packages you want to reexport:

  eg 
  use Sub::Module;
  use Another::Mod;

  sub _reexport {
    my ($package, $target, @names)=@_;

    Sub::Module->import;
    Another::Mod->import(@names);
    ...
  }

=head2 Conditional Reexporting

If you would only like to require and export on certain conditions, some extra
steps are needed to ensure correct setup of back end variables. Namely the
C<$Exporter::ExportLevel> variable needs to be localized and set to 0 inside a
block BEFORE calling the C<-E<gt>import> subroutine on the package.

  sub _reexport {
    my ($package, $target, @names)=@_;

    if(SOME_CONDITION){
      {
        # In an localised block, reset the export level
        local $Exporter::ExportLevel=0;
        require Sub::Module;
        require Another::Module;
      }

      Sub::Module->import;
      Another::Mod->import(@names);

    }
  }

=head2 Reexport Super Class Symbols

Any exported symbols from the inheritance chain can be reexported in the same
manner, as long as they are package subroutines and not methods:

  eg 

    package ModChild;
    parent ModParent;

      # or
      
    class ModChild :isa(ModParent)

    
    sub _reexport {
      my ($package, $target, @names)=@_;
      $package->SUPER::import(@names);
    }


=head1 COMPARISON TO OTHER MODULES

L<Import::Into> Provides clean way to reexport symbols, though you will have to
roll your own 'normal' export of symbols from you own package.

L<Import::Base> Requires a custom package to group the imports and reexports
them. This is a different approach and might better suit your needs. 


Reexporting symbols with C<Exporter> directly is a little cumbersome.  You
either need to import everything into you module name space (even if you don't
need it) and then reexport from there. Alternatively you can import directly
into a package, but you need to know at what level in the call stack it is.
This is exactly what this module addresses.


=head1 REPOSITOTY and BUGS

Please report and feature requests or bugs via the github repo:

L<https://github.com/drclaw1394/perl-export-these.git>

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

