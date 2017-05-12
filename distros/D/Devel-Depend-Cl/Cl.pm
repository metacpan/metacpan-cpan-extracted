
package Devel::Depend::Cl;

use 5.006;
use strict ;
use warnings ;
use Carp ;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw($PreprocessorDepend);
our $VERSION = '0.06';

=head1 NAME

Devel::Depend::Cl - Extract dependency trees from c files

=head1 DESCRIPTION

Extract dependency trees from c files. See L<Devel::Depend::Cpp> for more an example.

=head1 MEMBER FUNCTIONS

=cut

#------------------------------------------------------------------------------------------------

sub Depend
{

=head2 Depend

B<Depend> calls I<cl> (the microsoft C compiler) to extract included files.

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

=item * the name of the 'cl' binary to use. undef to use the first 'cl' in your path

=item * The name of the file to depend

=item * A string to be passed to cpp, ex: '-DDEBUG'

=item * A boolean indicating if the system include files should be included in the result

=item * a sub reference to be called everytime a node is added (see I<depender.pl> for an example)

=item * A boolean indicating if the output of B<cpp> should be dumped on the screen

=back

This sub is a wrapper around B<RunAndParse>.

=cut

my $cpp                     = shift || 'cl.exe' ;
my $file_to_depend          = shift || confess "No file to depend!\n" ;
my $switches                = shift ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

my $command = "$cpp -nologo -showIncludes -Zs $switches $file_to_depend" ;

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
the I<cl> output format. This sub allows finer control of the preprocessing. Try L<Depend> first.

=cut

my $file_to_depend          = shift || confess "No file to depend!\n" ;
my $command                 = shift || die "No command defined!" ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

my $errors = '' ;

my @cpp_output = `$command` ;

$errors .= "command: $command : " . join("\n", @cpp_output)  if $?;
$errors .= "command: $command : $!" if $! ;

print STDERR "$command\n" if($display_cpp_output) ;

for(@cpp_output)
	{
        print STDERR $_ if($display_cpp_output) ;
	$errors .= $_ if(/No such file or directory/) ;
	}
	
@cpp_output = grep {/^\QNote: including file:/} @cpp_output ;

@cpp_output = map { s|\\|/|g; $_ } @cpp_output ;

unless($include_system_includes)
{
	my @includes = defined $ENV{INCLUDE} ? split(';', $ENV{INCLUDE}) : () ;
	for my $include (@includes)
	{
		$include =~ s|\\|/|g;
		@cpp_output = grep { ! m~^\QNote: including file:\E\s+\Q$include~i} @cpp_output ;
	}

}
	
my %node_levels ;
my %nodes ;
my %parent_at_level = (0 => {__NAME => $file_to_depend}) ;

for(@cpp_output)
	{
	print STDERR $_ if($display_cpp_output) ;

	chomp ;
	my ($level, $name) = /^\QNote: including file:\E(\s+)(.*)/ ;
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

=head1 AUTHORS

   Emil Jansson based on Devel::Depend::Cpp.

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

B<Devel::Depend::Cpp> and B<PerlBuildSystem>.

=cut

