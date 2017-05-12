
package Filter::Uncomment ;

use strict;
use warnings ;

BEGIN 
{
use vars qw ($VERSION @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.03';
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;
use Filter::Simple ;

#-------------------------------------------------------------------------------

=head1 NAME

 Filter::Uncomment - Efficiently uncomment sections of your code

=head1 SYNOPSIS

	#~ use Filter::Uncomment qw(multi single) ;
	#~ use Filter::Uncomment qw(multi) ;

	use Filter::Uncomment 
		GROUPS =>
			{
			multi  => ['multi_line', 'multi line with spaces'] ,
			single => ['single_line', 'single line with spaces'] ,
			all    => 
				[
				'multi_line', 'multi line with spaces',
				'single_line', 'single line with spaces',
				] ,
			};

	$> perl -MFilter::Uncomment=multi test.pl

=head1 DESCRIPTION

This module write code that you want be active in only certain circumstances.

=head1 DOCUMENTATION

Contrast:

	#example 1
	
	for my $variable (1 .. $lots)
		{
		## debug Debug($variable) ;
		
		DoSomethingWith($value) ;
		}

with

	# example 2
	
	for my $variable (1 .. $lots)
		{
		Debug($variable) if($debug)  ;
		
		DoSomethingWith($value) ;
		}

In example #2, you will always pay for checking the $debug variable. This might be significant in a 
very tight loop or when you have lots of sections you comment out.

B<Filter::Uncomment> is a source code filter that will uncomment sections of perl code only on demand.
The uncommenting is done before compile time, you pay only once for it at the program load time.

Example #1 would effectively become:

	#example 1, uncommented
	
	for my $variable (1 .. $lots)
		{
		Debug($variable) ;
		
		DoSomethingWith($value) ;
		}

B<Filter::Uncomment> can uncomment single line perl comments, or multiline perl comments.

	## debug Debug($variable) ;
	
	=for flag
	
	PerlCode() ;
	MorePerlCode() ;
	
	=cut
	
	## tag_can_be_a_single_word HereIsTheCode() ;
	
	## or it can be a multiple wors separated by spaces HereIsTheCode() ;
	

=head2 Defining tags

	use Filter::Uncomment 
		GROUPS =>
			{
			# name    # elements for each group
			multi  => ['multi_line', 'multi line with spaces'] ,
			single => ['single_line', 'single line with spaces'] ,
			} ;

=head2 Uncommenting

Uncommenting is most often done on the command line but can also be done from a module or your script.

From the command line:

	perl -MFilter::Uncomment=multi script.pl
	perl -MFilter::Uncomment=multi -MFilter::Uncomment=single script.pl
	

From a module or script;

	use Filter::Uncomment qw(multi single) ;

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

my (%activated, $setup) ;

#-------------------------------------------------------------------------------

sub import
{
	
=head2 import

This is automatically called for you by Perl

=cut
	
my ($my_name, $argument_type, $argument_value, @other) = @_ ;

if(defined $argument_type)
	{
	$setup = undef ;

	if($argument_type =~ /^GROUPS$/sxm)
		{
		unless(defined $argument_value && 'HASH' eq ref $argument_value)
			{
			confess "Filter::Uncomment bad 'GROUPS' arguments!\n" ;
			}
		
		$setup = $argument_value ;
		}
	else
		{
		my @groups = defined $argument_value 
				? ($argument_type, $argument_value, @other) 
				: ($argument_type) ;
		
		@activated{@groups} = (1 .. @groups) ;
		}
	}
else
	{
	carp "Filter::Uncomment needs arguments!\n" ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

FILTER 
{

=head2 FILTER

This is automatically called for you by Perl

=cut

if($setup)
	{
	my $coumpound_regex 
		= join q[|], 
			map {s{\ }{\\\ }sxgm ; $_ ;}                  # so we can use x option for regex
				map{@{$setup->{$_}}}                  # elements in the activated groups
					grep {exists $activated{$_}}  # only activated groups
						keys %{$setup} ;      # all the groups
	
	#~ print "=> $coumpound_regex\n" ;
	
	s{
	^=for\s+                   # a pod =for tag
	(?:$coumpound_regex)\s+    # tag and at least a space
	(.*?)                      # pod section content
	=cut                       # end of pod section
	}
	# section position in your code is kept, line number in errors will be right
	{
	$1                         # keep only pod section content
	}xgsm ;
	
	s{
	\#\#                       # two octopods
	(?:$coumpound_regex)\s+    # tag and at least a space
	}
	{
	                           # replace with nothing
	}xgsm ;
	
	}
} ;

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

    perldoc Filter::Uncomment

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filter-Uncomment>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-filter-uncomment@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Filter-Uncomment>

=back

=head1 SEE ALSO

The excellent L<Filter::Simple>.

=cut
