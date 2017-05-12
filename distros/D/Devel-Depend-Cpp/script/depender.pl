#!/usr/bin/perl

use warnings ;
use strict ;
use Carp ;

use Devel::Depend::Cpp ;
use Data::TreeDumper ;

#------------------------------------------------------------------------------------------------

die <<HELP unless @ARGV ;
perl depender.pl file_to_depend [switch [switch] ...]

Install Data::TreeDumper (and/or PBS) for this script to be of any use.

ex:

\$> depender.pl /usr/include/stdio.h

include levels
|- 1 [H1]
|  |- /usr/include/bits/stdio_lim.h [H2]
|  |- /usr/include/bits/types.h [H3]
|  |- /usr/include/features.h [H4]
|  |- /usr/include/libio.h [H5]
|  `- /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h [H6]
|- 2 [H7]
|  |- /usr/include/_G_config.h [H8]
|  |- /usr/include/bits/pthreadtypes.h [H9]
|  |- /usr/include/gnu/stubs.h [H10]
|  |- /usr/include/sys/cdefs.h [H11]
|  |- /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stdarg.h [H12]
|  `- /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h [@ H6]
|- 3 [H13]
|  |- /usr/include/bits/sched.h [H14]
|  |- /usr/include/gconv.h [H15]
|  |- /usr/include/wchar.h [H16]
|  `- /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h [@ H6]
|- 4 [H17]
|  |- /usr/include/bits/wchar.h [H18]
|  |- /usr/include/features.h [@ H4]
|  |- /usr/include/wchar.h [@ H16]
|  `- /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h [@ H6]
`- 5 [H19]
   `- /usr/lib/gcc-lib/i386-redhat-linux/2.96/include/stddef.h [@ H6]
...

HELP

my $file_to_depend = shift @ARGV ;
my $switches = '' . join '', @ARGV ;

FrontEnd
	(
	  $file_to_depend
	, $switches
	, 1 # include system includes
	, 1 # display_nodes
	, 1 # display_levels
	, 1 # display_tree
	, 0 # disply cpp output
	, 0 # generate_graph_through_pbs
	, 0 # display_pbsfile
	) ;

#-----------------------------------------------------------------------------------------------------

sub FrontEnd
{
my $file_to_depend             = shift ;
my $switches                   = shift ;
my $include_system_includes    = shift ;
my $display_nodes              = shift ;
my $display_levels             = shift ;
my $display_tree               = shift ;
my $display_cpp_output         = shift ;
my $generate_graph_through_pbs = shift ;
my $display_pbsfile            = shift ;

my $pbsfile = "ExcludeFromDigestGeneration('header files' => qr/\.h\$/) ;\n" ;
my $sub = sub
	{
	my ($parent, $child) = @_ ;
	$pbsfile .= "AddRule '$parent => $child', ['$parent' => '$child'], BuildOk() ;\n" ;
	} ;

my ($depend_ok, $levels, $nodes, $tree, $errors) = Devel::Depend::Cpp::Depend(undef, $file_to_depend, $switches, $include_system_includes, $sub, $display_cpp_output) ;

if($depend_ok)
	{
	my $GetDependenciesOnly = sub
				{
				my $tree = shift ;
				
				return( 'HASH', undef, sort grep {! /^__/} keys %$tree) if('HASH' eq ref $tree) ;
				return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
				} ;
	
	if($display_nodes)
		{
		print STDERR DumpTree
				(
				$nodes
				, "'$file_to_depend' included files"
				, USE_ASCII       => 1
				, FILTER          => $GetDependenciesOnly
				, MAX_DEPTH       => 1
				, DISPLAY_ADDRESS => 0
				) ;
				
		print "\n" ;
		}
		
	if($display_levels)
		{
		print STDERR DumpTree
				(
				$levels
				, "include levels for '$file_to_depend'"
				, USE_ASCII       => 1
				, FILTER          => $GetDependenciesOnly
				, MAX_DEPTH       => 2
				, DISPLAY_ADDRESS => 0
				) ;
				
		print "\n" ;
		}
		
	if($display_tree)
		{
		print STDERR DumpTree
				(
				$tree
				, "'$file_to_depend' included files tree"
				, USE_ASCII       => 1
				, FILTER          => $GetDependenciesOnly
				, MAX_DEPTH       => -1
				, DISPLAY_ADDRESS => 0
				) ;
				
		print "\n" ;
		}
		
	print $pbsfile if ($display_pbsfile) ;
	
	if($generate_graph_through_pbs)
		{
		use PBS::FrontEnd ;
			
		PBS::FrontEnd::Pbs
			(
			  COMMAND_LINE_ARGUMENTS => [ qw(-p virtual -gtg tree -nh -sd . -no_build), $file_to_depend]
			, PBSFILE_CONTENT => $pbsfile
			) ;
		}
	}
else
	{
	die "Error depending $file_to_depend:\n$errors\n" ;
	}
}
