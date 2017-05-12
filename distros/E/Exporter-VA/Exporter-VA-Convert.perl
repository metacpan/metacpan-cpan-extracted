#!/usr/bin/env perl

=head1 NAME

Exporter-VA-Convert - Script to convert classic Exporter usage to Exporter::VA usage.

=cut

### see the main POD at the end of this file.

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
$Data::Dumper::Indent=1;  # can change to suit.
$Data::Dumper::Pad="\t";  # can change to suit.

our $VERSION= v1.0;

my $simple;  # true if option for simplest direct translation
my $def_versioning;  # true if option to set up for versioning the default exports

checkoptions();

my $module= shift @ARGV;
usage()  unless defined $module;
(my $filename= $module) =~ s[::][/]g;
$filename .= ".pm";
require $filename;
print "loaded file $INC{$filename}\n";

my %new_EXPORT_def;
my $show_my_callback;

no strict 'refs';
my @mod_EXPORT= @{$module . "::EXPORT"};

check_ISA();
check_import();
check_EXPORT_FAIL();
process_EXPORT_OK();
process_EXPORT();
process_EXPORT_TAGS();
 if (0 == keys %new_EXPORT_def) {
    print "There is nothing being exported.\n";
    }
else {
   print "remove the 'require Exporter; (or 'use Exporter();') line,\n";
   print "replace it with\n\tuse Exporter::VA ':normal'\n";
   print "add the definition:\n", dump_def();
   show_my_callback()  if $show_my_callback;

   print "done.\n";
   }

####################################3

sub dump_def
 {
 my $dumper= Data::Dumper->new ([\%new_EXPORT_def], ['*EXPORT']);
 my $retval= $dumper->Dump;
 $retval =~ s/'\*\*emulate export_fail'/\\&my_callback/g;
 return $retval;
 }

sub show_my_callback
 {
 print "The format for callbacks are:\n";
 print "\tsub my_callback {\n\t\tmy (\$self, \$caller, \$version, \$symbol, \$param_list_tail)= @_;\n\t\t# put logic here.\n\t\tSee export_fail in original module, and use \$symbol parameter.\n\t\t}\n";

 }
 
####################################3

sub checkoptions
 {
 GetOptions (
    'simple!' => \$simple,
    'dev_version!' => \$def_versioning,
   );
 if (defined $simple || defined $def_versioning) {
    die "options not implemented yet.";
    }
 }

sub usage
 {
 print STDERR "Usage: $0 [options] Modulename\n";
 exit (1);
 }

sub check_ISA
 {
 no strict 'refs';
 my @mod_ISA= @{$module . "::ISA"};
 my @new_ISA= grep (!/^Exporter$/, @mod_ISA);
 if (1+ scalar @new_ISA != scalar @mod_ISA) {
    print "Warning: the \@ISA definition doesn't contain exactly one occurance of 'Exporter'.  This module may be doing something funny, so be careful.\n";
    }
 elsif (!@new_ISA) {
    print "Remove the definition of \@ISA.\n";
    }
 else {
    print "Change the definition\n", Data::Dumper->Dump ([\@new_ISA], ['*ISA']);
    }
 }

sub check_import
 {
 my $mi= $module->can ("import");
 print "Warning: module contains its own sub import, rather than inheriting from Exporter.  Direct automatic translation is not possible.\nThe rest of this report assumes that the meanings of the package globals are the same as for the Exporter::import function, in case that proves useful to you.\n"
 unless defined($mi) && $mi == Exporter->can("import");
 }

sub check_EXPORT_FAIL
 {
 no strict 'refs';
 my @mod_EXPORT_FAIL= @{$module . "::EXPORT_FAIL"};
 if (@mod_EXPORT_FAIL) {
    print "Remove the definition of \@EXPORT_FAIL.\n";
    foreach my $item (@mod_EXPORT_FAIL) {
       $new_EXPORT_def{$item}= "**emulate export_fail";
       $show_my_callback= 1;
       }
    }
 }

sub add_export
 {
 my $item= shift;
 # isolated so it can be different based on switches.
 push @{$new_EXPORT_def{'.plain'}}, $item;
 }
 
sub add_default
 {
 my $item= shift;
 # isolated so it can be different based on switches.
 push @{$new_EXPORT_def{':DEFAULT'}}, $item;
 }

sub add_tag
 {
 my ($item, $list)= @_;
 $item= ":" . $item;
 $new_EXPORT_def{$item}= $list;
 }
 
sub process_EXPORT_OK
 {
 no strict 'refs';
 my @mod_EXPORT_OK= @{$module . "::EXPORT_OK"};
 return unless @mod_EXPORT_OK;
 print "Remove the definition of \@EXPORT_OK.\n";
 add_export ($_)  foreach @mod_EXPORT_OK;
 }

sub process_EXPORT
 {
 no strict 'refs';
 my @mod_EXPORT= @{$module . "::EXPORT"};
 return unless @mod_EXPORT;
 print "Remove the definition of \@EXPORT.\n";
 foreach my $item (@mod_EXPORT) {
    add_export ($item);  # all have to be added.
    add_default ($item);
    }
 }

sub process_EXPORT_TAGS
 {
 no strict 'refs';
 my %mod_EXPORT_TAGS= %{$module . "::EXPORT_TAGS"};
 return unless keys %mod_EXPORT_TAGS;
 print "Remove the definition of \%EXPORT_TAGS.\n";
 while (my ($key, $value)=each %mod_EXPORT_TAGS) {
    add_tag ($key, $value);
    }
 }

__END__

=head1 AUTHOR

John M. Dlugosz

=head1 SYNOPSIS

On the command line, 

	Exporter-VA-Convert.perl [options] module-name

will produce a report of changes to make to that module.  E.g.

	Exporter-VA-Convert.perl carp
	Exporter-VA-Convert.perl Sys::Hostname

The module-name parameter is the same as you would put in a C<use> or C<require> statement
as a bareword.

=head2 options

With no options, it wil produce a direct translation.  That is, the resulting usage of Exporter::VA will
do the same thing as the original.  If you're switching to Exporter::VA, you might be needing something
beyond that, so optionally you can set up a more elaborate definition, for example to eliminate the
default exports as of the current version, or set up for versioning.

There are no options implemented yet.

=head1 Instructions

This utility will load the module and examine the definitions of all the package globals used by
the classic Exporter module.  It will then generate a report telling you what to change to use
Exporter::VA.  It does not alter the code, since it doesn't directly parse the code.  Rather, it
only cares about the resulting values in the package globals after the module loads.  The advantage is
that it doesn't care how the values are computed, and does not limit your syntax or creativity.


=head2 @ISA

The occurance of Expoter in @ISA will be removed.  If that was the only thing in there, it will
instruct you to just remove the definition of @ISA.  Otherwise, it tells you what's left.  If Expoter
was not listed at all, it will give you a warning as the subsequent results are dubious--did that
module even use Expoter to begin with?

=head2 @EXPORT

You'll always be instructed to remove the definition for @EXPORT, since Exporter::VA doesn't use
that.  Instead, all the values will be incorporated into the export definition for Exporter::VA.
A straight translation will make these members of the :DEFAULT tag as things that are exported
by default.  Command-line switches might change this behavior if you tell it to do something
other than a direct translation.

=head2 @EXPORT_OK

You'll always be instructed to remove the definition for @EXPORT, since Exporter::VA doesn't use
that.  Instead, all the values will be incorporated into the export definition for Exporter::VA.
All the names of things to be exported will be listed as a .plain field by default, since that is the
simplest way to do this.  Command-line switches might cause them to be individually listed instead,
either because that's what you asked for or because something other than a direct translation needs
more advanced features.

=head2 %EXPORT_TAGS

You'll always be instructed to remove the definition for @EXPORT, since Exporter::VA doesn't use
that.  Instead, all the values will be incorporated into the export definition for Exporter::VA.  All of the
tags will be reproduced as tag definitions in the export definition.

=head2 @EXPORT_FAIL

This is the only thing that is not translated exactly.  Originally, I started generating results to
emulate the mechanism exactly, calling your module's export_fail with the list of all failed
items.  That would allow it to be an exact plug-in replacement without having to otherwise
affect your module.

However, the main reason for using @EXPORT_FAIL is as a primitive pragma/callback
mechanism!  If you really wanted to prevent something from being exported, simply don't
list it as a possible export!  The model for callbacks is easier to use in Exporter::VA, so this
isn't translated exactly.  Instead, it sets up the export definition for that callback and shows you
the code skelleton for you to fill in.  If your export_fail function switches on the items in the
parameter list, you can simply copy the proper case to the new function, since you can get
a callback to a different function on each pragmatic callback.

If you instead point all the callbacks to the same function, you can continue to switch off the
supplied item.  However, this will be called one at a time as they are being processed, as
opposed to one call with a list of all the failing items at once.

=head2 %EXPORT

This is the single structure used for all the configuration details for Exporter::VA.  Add this to your
module by pasting it in.

=head1 HISTORY

v1.0 - exact translation only, no options.  But handles all features of Exporter.

