
package Devel::Depend::Cpp;

use 5.006;
use warnings ;
use strict ;
use Carp ;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw($PreprocessorDepend);

our $VERSION = '0.10';

=head1 NAME

Devel::Depend::Cpp - Extract dependency trees from c files

=head1 SYNOPSIS

  use Devel::Depend::Cpp;
  
 my ($success, $includ_levels, $included_files) 
	= Devel::Depend::Cpp::Depend
 		(
		undef, # use default 'cpp' command
 		'/usr/include/stdio.h',
 		'',  # switches to cpp
		0,  # include system includes
		0,  # dump 'cpp' output in terminal
 		) ;
 

=head1 OUTPUT

 include levels for '/usr/include/stdio.h':
 |- 1
 |  |- /usr/include/bits/stdio_lim.h
 |  |- /usr/include/bits/sys_errlist.h
 |  |- /usr/include/bits/types.h
 |  |- /usr/include/features.h
 |  |- /usr/include/libio.h
 |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |- 2
 |  |- /usr/include/_G_config.h
 |  |- /usr/include/bits/typesizes.h
 |  |- /usr/include/bits/wordsize.h
 |  |- /usr/include/gnu/stubs.h
 |  |- /usr/include/sys/cdefs.h
 |  |- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stdarg.h
 |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |- 3
 |  |- /usr/include/gconv.h
 |  |- /usr/include/wchar.h
 |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |- 4
 |  |- /usr/include/bits/wchar.h
 |  |- /usr/include/wchar.h
 |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 `- 5
    `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 
 '/usr/include/stdio.h' included files:
 |- /usr/include/_G_config.h
 |- /usr/include/bits/stdio_lim.h
 |- /usr/include/bits/sys_errlist.h
 |- /usr/include/bits/types.h
 |- /usr/include/bits/typesizes.h
 |- /usr/include/bits/wchar.h
 |- /usr/include/bits/wordsize.h
 |- /usr/include/features.h
 |- /usr/include/gconv.h
 |- /usr/include/gnu/stubs.h
 |- /usr/include/libio.h
 |- /usr/include/sys/cdefs.h
 |- /usr/include/wchar.h
 |- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stdarg.h
 `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 
 '/usr/include/stdio.h' included files tree:
 |- /usr/include/bits/stdio_lim.h
 |- /usr/include/bits/sys_errlist.h
 |- /usr/include/bits/types.h
 |  |- /usr/include/bits/typesizes.h
 |  |- /usr/include/bits/wordsize.h
 |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |- /usr/include/features.h
 |  |- /usr/include/gnu/stubs.h
 |  `- /usr/include/sys/cdefs.h
 |- /usr/include/libio.h
 |  |- /usr/include/_G_config.h
 |  |  |- /usr/include/gconv.h
 |  |  |  |- /usr/include/wchar.h
 |  |  |  |  |- /usr/include/bits/wchar.h
 |  |  |  |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |  |  |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |  |  |- /usr/include/wchar.h
 |  |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h
 |  `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stdarg.h
 `- /usr/lib/gcc/i686-pc-linux-gnu/3.4.5/include/stddef.h

=head1 DESCRIPTION

Extract dependency trees from c files.

=head1 MEMBER FUNCTIONS

=cut

#------------------------------------------------------------------------------------------------

sub Depend
{

=head2 Depend

B<Depend> calls I<cpp> (the c pre-processor) to extract all the included files.

=head3 Returns

=over  2

=item * Success flag

=item * A reference to a hash where the included files are sorted perl level. A file can appear at different levels

=item * A reference to a hash with one file per entry

=item * A reference to a hash representing an include tree

=item * A string containing an error message, if any

=back

=head3 Arguments

=over  2

=item * the name of the 'cpp' binary to use. undef to use the first 'cpp' in your path

=item * The name of the file to depend

=item * A string to be passed to cpp, ex: '-DDEBUG'

=item * A boolean indicating if the system include files should be included in the result (anything under /usr/)

=item * a sub reference to be called everytime a node is added (see I<depender.pl> for an example)

=item * A boolean indicating if the output of B<cpp> should be dumped on the screen

=back

This sub is a wrapper around B<RunAndParse>.

=cut

my $cpp                     = shift || 'cpp' ;
my $file_to_depend          = shift || confess "No file to depend!\n" ;
my $switches                = shift ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

#handle OS differences
my $redir_to_null = $^O eq "MSWin32" ? '> nul' : '1>/dev/null';
my $command = "$cpp -H -M $switches $file_to_depend 2>&1 $redir_to_null" ;

return
	(
	RunAndParse
		(
		  $file_to_depend
		, $command
		, $include_system_includes
		, $add_child_callback
		, $display_cpp_output
		)
	) ;
}

our $PreprocessorDepend = \&Depend;

#------------------------------------------------------------------------------------------------

sub RunAndParse
{

=head2 RunAndParse

This sub runs a, preprocessor, command passed as an argument and parses its output. The output is expected to  follow
the I<cpp> output format. This sub allows finer control of the preprocessing. Try L<Depend> first.

=cut

my $file_to_depend          = shift || confess "****No file to depend!\n" ;
my $command                 = shift || die "No command defined!" ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

my $errors = '';

my @cpp_output = `$command` ;

$errors .= "command: $command : " . join("\n", @cpp_output)  if $?;
$errors .= "command: $command : $!" if $! ;

print STDERR "$command\n" if($display_cpp_output) ;
	
for(@cpp_output)
	{
        print STDERR $_ if($display_cpp_output) ;
	$errors .= $_ if(/No such file or directory/) ;
	}
	
if($include_system_includes)
	{
	@cpp_output = grep {/^\./} @cpp_output ;
	}
else
	{
=comment
Default search path from cpp Info pages:
/usr/local/include
/usr/lib/gcc-lib/TARGET/VERSION/include
/usr/TARGET/include
/usr/include
/usr/include/g++-v3
=cut
	@cpp_output = grep {! m~\.+\s+/usr/~ && /^\./} @cpp_output ;

	if ($^O eq 'MSWin32' && defined $ENV{INCLUDE})
		{
		my @includes = split(';', $ENV{INCLUDE});
		for my $include (@includes)
			{
			$include =~ s|\\|/|g;
			@cpp_output = grep { ! m~\.+\s+\Q$include~ && /^\./} @cpp_output ;
			}
		}
	}
	
my %node_levels ;
my %nodes ;
my %parent_at_level = (0 => {__NAME => $file_to_depend}) ;

for(@cpp_output)
	{
	print STDERR $_ if($display_cpp_output) ;
	
	chomp ;
	my ($level, $name) = /^(\.+)\s+(.*)/ ;
	$name =~ s|\\|/|g;
	$name = CollapsePath($name) ;
   
	$level = length $level ;
	
	my $node ;
	unless (exists $nodes{$name})
		{
		$nodes{$name} = {__NAME => $name} ;
		}
		
	$node = $nodes{$name} ;
		
	$node_levels{$level}{$name} = $node unless exists $node_levels{$level}{$name} ;
	
	$parent_at_level{$level} = $node ;
	
	my $parent = $parent_at_level{$level - 1} ;
	
	unless(exists $parent->{$name})
		{
		$parent->{$name} = $node ;
		$add_child_callback->($parent->{__NAME} => $name) if(defined $add_child_callback) ;
		}
	}
	
return(($errors eq ''), \%node_levels, \%nodes, $parent_at_level{0}, $errors) ;
}

#-------------------------------------------------------------------------------

sub CollapsePath
{

=head2 CollapsePath

Removes '.' and '..' from a path.

=cut

my $collapsed_path = $_[0] ;

$collapsed_path =~ s~(?<!\.)\./~~g ;
$collapsed_path =~ s~/\.$~~ ;

1 while($collapsed_path =~ s~[^/]+/\.\./~~) ;
$collapsed_path =~ s~[^/]+/\.\.$~~ ;
#
## collaps to root
$collapsed_path =~ s~^/(\.\./)+~/~ ;

#remove trailing '/'
$collapsed_path =~ s~/$~~ unless $collapsed_path eq '/' ;

return($collapsed_path) ;
}

#-------------------------------------------------------------------------------

1 ;

=head2 EXPORT

$PreprocessorDepend, a scalar containing a reference to the B<Depend> sub.

=head1 DEPENDENCIES

I<cpp>.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net
	http:// no web site

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

B<PerlBuldSystem>.

=cut

