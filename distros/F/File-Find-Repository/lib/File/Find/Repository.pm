
package File::Find::Repository ;

use strict;
use warnings ;

BEGIN 
{
use vars qw ($VERSION);
$VERSION = '0.03';
}

#-------------------------------------------------------------------------------

use Carp qw(carp croak confess) ;
use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use File::Spec;
use Tie::Hash::Indexed ;

#-------------------------------------------------------------------------------

=head1 NAME

 File::Find::Repository - Find files in your repositories.

=head1 SYNOPSIS

	use File::Find::Repository ;
	
	my $locator = new File::Find::Repository
			(
			NAME => 'name you want to see when messages are displayed',
			
			REPOSITORIES =>
				[
				'path',
				\&sub,
				...
				],
			) ;
				
	# single scalar argument
	my $located_file = $locator->Find($file_to_locate) ;
	
	# multiple arguments
	my $located_files = $locator->Find
				(
				FILES        => [...],
				REPOSITORIES => ['path', \&sub, ...],
				VERBOSE      => 1,
				) ;

=head1 DESCRIPTION

This module will find files in a set of repositories.

=head1 DOCUMENTATION

This module will try to locate a file in the repositories you define.  The repositories are either
a string representing a local filesystem path or a sub. 

When locating a file, multiple file  match can occur (each in a different repository). The default behavior is 
to return the first match. 

You can customize the behavior of the search with two callbacks.

B<FULL_INFO> will be called to allow you to add relevant information to the files that have been located.

B<WHICH> will be  called to let you decide which found files is returned.

=head3 Advanced example

This module was extracted from B<PBS>, a build system, made generic and will be re-integrated in B<PBS>
in next version. Here is how it could be used for a more advanced repository search.

Let's imagine we have multiple matches for an object file in our repositories. The goal here is to not rebuild the object
file. Selecting the first object file in the list would be too naive so we define a B<WHICH> callback that will select
the most appropriate. In this case, it might involve looking in the object file digest and/or check what configuration was
used when the object file was build.

	my $located_file = $locator->Find
				(
				FILES => [$file_to_locate],
				REPOSITORIES => [$build_directory, @repositories],
				WHICH => FIND_NODE_WITH_DEPENDENCIES($information_needed_to_select_the_found_file)
				
				# bote that FIND_NODE_WITH_DEPENDENCIES returns a sub reference
				) ;
	
	$located_file ||= "$build_directory/$located_file" ;
	

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

sub new
{

=head2 new

Create a File::Find::Repository .  

	my $locator = new File::Find::Repository
			(
			# all arguments are optional
			
			NAME => 'name you want to see when messages are displayed',
			
			REPOSITORIES =>
				[
				'path',
				\&sub,
				...
				],
				
			INTERACTION =>
				{
				INFO = \&OnMyTerminal,
				WARN = \&WithBlinkingRedLetters,
				DIE  = \&QuickAndPainless,
				}
				
			VERBOSE   => 1,
			FULL_INFO => \&File::Find::Repository::TIME_AND_SIZE,
			WHICH     => \&File::Find::Repository::FIRST_FOUND,
			) ;

=head3 Options

=over 2

=item * NAME 

Name you want to see when messages are displayed.

=item * REPOSITORIES

An array reference. The elements are either scalars representing a local filesystem path or a code
reference. The code references are passed a single argument, the file to locate, and should either
return the located file or undef.

This allows you to, for example, to locate the files on servers.

=item * INTERACTION

Lets you define subs used to interact with the user.

	INTERACTION      =>
		{
		INFO  => \&sub,
		WARN  => \&sub,
		DIE   => \&sub,
		}

=over 4

=item INFO

This sub will be used when displaying L<VERBOSE> information.

=item WARN

This sub will be used when a warning is displayed.

=item DIE

Used when an error occurs.

=back

The functions default to:

=over 2

=item * INFO => print

=item * WARN => Carp::carp

=item * DIE => Carp::confess

=back

=item * VERBOSE

When set, informative messages will be displayed.

=item * FULL_INFO

This is set to a sub ref which is called for all the found files, this allows you to add information.
See L<File::Find::Repository::TIME_AND_SIZE> for an example.

Passed arguments:

=over 4

=item * the File::Find::Repository object.

This is useful when you want to display a message; use the subroutines defined in $object->{INTERACTION}.

=item * The file name

=item * a hash reference. 

The found file.

=back

=item * WHICH

By defaults, B<File::Find::Repository>  will set I<WHICH> to I<File::Find::Repository::FIRST_FOUND> which 
return the first file found in the repositories.

Define this callback if you wish to return something else, e.g. the newest file or the largest file.

I<WHICH> subroutine will be called with these arguments:

=over 4

=item * the File::Find::Repository object.

This is useful when you want to display a message; use the subroutines defined in $object->{INTERACTION}.

=item * a hash reference. 

Containing all the found files, after processing with L<FULL_INFO>. The hash is ordered.

=back

The subroutine should return one of the array elements or undef. Note that you could also return an element
not present in the hash. In this case, a proper documentation of your algorithm will help maintenance.

=back

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 Setup

Helper sub called by new. This is a private sub.

=cut

my ($object, $package, $file_name, $line, @setup_data) = @_ ;

%{$object} = 
	(
	NAME           => "Anonymous created at $file_name:$line",
	WHICH          => \&FIRST_FOUND,
	
	@setup_data,
	
	AT_FILE        => $file_name,
	AT_LINE        => $line,
	) ;

my $location = "$object->{AT_FILE}:$object->{AT_LINE}" ;

$object->{VALID_OPTIONS} = 
	{ 
	map{$_ => 1}
		qw(
		FILES
		FULL_INFO
		INTERACTION
		REPOSITORIES
		VERBOSE
		WHICH
		
		AT_FILE 
		AT_LINE 
		)
	} ;

#~ $object->{INTERACTION}{INFO} ||= \&CORE::print ;
$object->{INTERACTION}{INFO} ||= sub{print(@_) or croak "Can't print! $!"};
$object->{INTERACTION}{WARN} ||= \&Carp::carp ;
$object->{INTERACTION}{DIE}  ||= \&Carp::confess ;

if(defined $object->{REPOSITORIES})
	{
	if('ARRAY' ne ref $object->{REPOSITORIES})
		{
		$object->{INTERACTION}{DIE}->("$object->{NAME}: REPOSITORIES must be an array reference at '$location'!") ;
		}
		
	for my $repository (@{$object->{REPOSITORIES}})
		{
		if(defined $repository)
			{
			my $type = ref $repository  ;
			
			if($EMPTY_STRING ne $type && 'CODE' ne $type)
				{
				$object->{INTERACTION}{DIE}->("$object->{NAME}: invalid repository type '$type' at '$location'!") ;
				}
			}
		else
			{
			$object->{INTERACTION}{DIE}->("$object->{NAME}: invalid repository [undef] at '$location'!") ;
			}
		}
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub Find
{ ## no critic (ProhibitExcessComplexity)

=head2 Find

	# single scalar argument
	my $located_file = $locator->Find($file_to_locate) ;
	
	# multiple arguments
	my $located_files = $locator->Find
				(
				FILES        => [...],
				
				# optional
				REPOSITORIES => ['path', \&sub, ...],
				VERBOSE      => 1,
				INTERACTION  => { INFO = \&OnMyTerminal,},
				FULL_INFO    => \&File::Find::Repository::TIME_AND_SIZE,
				WHICH        => \&File::Find::Repository::FIRST_FOUND,
				) ;

=head3 SCALAR calling context

Only SCALAR calling context is allowed.

=head3 Arguments

If a single string argument is passed to Find, a string or undef is returned.

If multiple arguments are passed, they will override the object's values for the call duration.

Valid arguments:

=over 2

=item * FILES

An array ref with scalar elements. Each element represents a file to locate. The returned value will be an
ordered hash reference.

=item * AT_FILE and AT_LINE

These will be used in the information message and the history information if set. If not set, the values
returned by I<caller> will be used. B<These options allow you to write wrapper functions> that report the
callers location properly.

All arguments passed to L<New>, except B<NAME> are also valid arguments to L<Find>.

=back

=cut

my ($self, @arguments) = @_ ;

my $single_file_to_find = $EMPTY_STRING ;
my ($number_of_arguments) = scalar(@arguments) ;

my $location = "$self->{AT_FILE}:$self->{AT_LINE}" ;

if($number_of_arguments <= 0)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: No argument at '$location'!") ;
	}
elsif($number_of_arguments == 1)
	{
	if($EMPTY_STRING eq ref $arguments[0])
		{
		$single_file_to_find = $arguments[0] ;
		@arguments = (FILES => [@arguments]) ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: single argument must be scalar at '$location'!") ;
		}
	}

my %arguments = @arguments ;
$self->CheckOptions(\%arguments) ;

## no critic (ProhibitLocalVars ProhibitConditionalDeclarations)

local $self->{FILES} = $arguments{FILES} ;

local $self->{FULL_INFO} = $arguments{FULL_INFO} if exists $arguments{FULL_INFO} ;

local $self->{INTERACTION}{INFO} = $arguments{INTERACTION}{INFO} if exists $arguments{INTERACTION}{INFO} ;
local $self->{INTERACTION}{WARN} = $arguments{INTERACTION}{WARN} if exists $arguments{INTERACTION}{WARN} ;
local $self->{INTERACTION}{DIE} = $arguments{INTERACTION}{DIE} if exists $arguments{INTERACTION}{DIE} ;

local $self->{REPOSITORIES} = $arguments{REPOSITORIES} if exists $arguments{REPOSITORIES} ;
local $self->{VERBOSE} = $arguments{VERBOSE} if exists $arguments{VERBOSE} ;
local $self->{WHICH} = $arguments{WHICH} if exists $arguments{WHICH} ;
local $self->{AT_FILE } = $arguments{AT_FILE } if exists $arguments{AT_FILE } ;
local $self->{AT_LINE } = $arguments{AT_LINE } if exists $arguments{AT_LINE };

## use critic

$location = "$self->{AT_FILE}:$self->{AT_LINE}" ;

if(! defined wantarray) 
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: not called in scalar context at '$location'!") ;
	}
	
if(wantarray)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: not called in scalar context at '$location'!") ;
	}

my %located_files ;

for my $file_to_locate (@{$arguments{FILES}})
	{
	my $located_files = $self->FindFiles($file_to_locate) ;
		
	if(keys %{$located_files})
		{
		if($self->{FULL_INFO})
			{
			while (my ($file_name, $file) = each %{$located_files})
				{
				$self->{FULL_INFO}->($self, $file_to_locate, $file) ;
				}
			}
		
		$located_files{$file_to_locate} = $self->{WHICH}->($self, $located_files) ;
		}
	else
		{
		$located_files{$file_to_locate} = undef ;
		}
	}
	
if($number_of_arguments == 1)
	{
	return($located_files{$single_file_to_find}{FOUND_AT}) ;
	}
else
	{
	return(\%located_files) ;
	}
}

#-------------------------------------------------------------------------------

sub FindFiles
{

=head2 FindFiles

This is a private sub. Do not use directly.

Finds all the files in the repositories.

=cut

my ($self, $file_to_locate) = @_ ;

my $location = "$self->{AT_FILE}:$self->{AT_LINE}" ;

tie my %files_found, 'Tie::Hash::Indexed' ; ## no critic

if(File::Spec->file_name_is_absolute($file_to_locate))
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: passed absolute file path '$file_to_locate' at $location.\n") ;
	}
else
	{
	$self->{INTERACTION}{INFO}->("Searching for '$file_to_locate':\n") if $self->{VERBOSE} ;
	
	for my $source_directory (@{$self->{REPOSITORIES}})
		{
		my $searched_file = "$source_directory/$file_to_locate" ;
		my $file_found ;
		
		my $type = ref $source_directory ;
		
		if($EMPTY_STRING eq $type)
			{
			$file_found = $searched_file if( -e $searched_file) ;
			}
		elsif('CODE' eq $type)
			{
			$file_found = $source_directory->($file_to_locate);
			}
		else
			{
			$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid repository type '$type' at $location.\n") ;
			}
			
		if(defined $file_found)
			{
			$files_found{$file_found} = {FOUND_AT => $file_found, EXISTS => (-e $file_found)} ;
			$self->{INTERACTION}{INFO}->("   Found in '$source_directory'\n.") if $self->{VERBOSE} ;
			}
		else
			{
			$self->{INTERACTION}{INFO}->("   Not found in '$source_directory'.\n") if $self->{VERBOSE} ;
			}
		}
	}
	
return(\%files_found) ;
}

#-------------------------------------------------------------------------------

sub CheckOptions
{

=head2 CheckOptions

Verifies the options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. This shall not be used directly.

=cut

my ($self, $options) = @_ ;
my $location = "$self->{AT_FILE}:$self->{AT_LINE}" ;

for my $option_name (keys %{$options})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid Option '$option_name' at '$self->{AT_FILE}:$self->{AT_LINE}'!") unless exists $self->{VALID_OPTIONS}{$option_name} ;
	}

if
	(
	   (defined $options->{AT_FILE} && ! defined $options->{AT_LINE})
	|| (!defined $options->{AT_FILE} && defined $options->{AT_LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option AT_FILE::AT_LINE!") ;
	}

# check we have enough to work with
unless(exists $options->{FILES})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: No FILES to find at '$location'!") ;
	}
	
if('ARRAY' ne ref $options->{FILES})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid FILES at '$location'!") ;
	}

if(0 == scalar(@{$options->{FILES}}))
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: no entries in FILES at '$location'!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub FIRST_FOUND
{

=head2 FIRST_FOUND

Returns the first matching file.

=cut

my ($object, $located_files) = @_ ;

my (@keys) = keys %{$located_files} ;

return($located_files->{$keys[0]}) ;
}

#-------------------------------------------------------------------------------

sub TIME_AND_SIZE
{

=head2 TIME_AND_SIZE

Adds time and size information to the matched file.

=cut

my ($object, $file_name, $file) = @_ ;

Readonly my $YEAR_1900 => 1900 ;
Readonly my $STAT_SIZE => 7 ;
Readonly my $STAT_CTIME => 10 ;

if($file->{EXISTS})
	{
	my ($file_size, undef, undef, $modification_time) = (stat($file->{FOUND_AT}))[$STAT_SIZE..$STAT_CTIME];
	my ($sec, $min, $hour, $month_day, $month, $year, $week_day, $year_day) = gmtime($modification_time) ;
	$year += $YEAR_1900 ;
	$month++ ;

	$file->{SIZE} = $file_size ;
	$file->{DATE} =  
		{
		DAY    => $month_day,
		MONTH  => $month,
		YEAR   => $year,
		HOUR   => $hour,
		MINUTE => $min,
		SECOND => $sec,
		};
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Find::Repository

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Find-Repository>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-file-find-repository@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/File-Find-Repository>

=back

=head1 SEE ALSO

L<File::Find::Rules> 

=cut
