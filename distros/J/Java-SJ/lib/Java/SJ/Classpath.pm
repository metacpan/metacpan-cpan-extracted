###########################################################################
#
# Java::SJ::Classpath
#
# $Id: Classpath.pm,v 1.3 2003/07/20 18:52:21 wiggly Exp $
#
# $Author: wiggly $
#
# $DateTime$
#
# $Revision: 1.3 $
#
###########################################################################

package Java::SJ::Classpath;

use Carp;
use English;
use Data::Dumper;
use File::Glob qw( :glob );

our $VERSION = '0.01';

###########################################################################
#
# Constructor
#
###########################################################################
sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'dir'} = [];
	$self->{'jar'} = [];
	
	#print STDERR "[DEBUG] CLASSPATH\n" . Dumper( $self ) . "\n\n";
	return $self;		
}

###########################################################################
#
# add_dir
#
###########################################################################
sub add_dir
{
	my $self = shift;

	my $path = shift;

	push @{$self->{'dir'}}, $path;

	1;
}

###########################################################################
#
# add_jar
#
###########################################################################
sub add_jar
{
	my $self = shift;

	my %hash = @_;

	push @{$self->{'jar'}}, \%hash;

	1;
}

###########################################################################
#
# generate_classpath
#
# This is where much of the SJ magic goes on.
#
# Given the base SJ directory where classes are stored we go off and figure
# out if the Jars we want exist, if so we figure out their full paths. We
# use these and any fully specified jar filenames and classpath directories
# to build a full classpath.
#
###########################################################################
sub generate_classpath
{
	my $self = shift;

	my $base = shift;

	my $jar = undef;

	my $dir = undef;

	my $file = '';
	
	my @classpath = ();

	#print STDERR "[INFO] generate_classpath\n";
	#print STDERR "[INFO] SJ Jar File Directory : $base\n";

	foreach $jar ( @{$self->{'jar'}} )
	{
		if( $jar->{'file'} !~ /^$/ )
		{
			push @classpath, $jar->{'file'};
		}
		else
		{
			#
			# To figure out which JAR file to use we do the following;
			#
			# 1) If both a name and version are specified then we build up the
			# path by concatenating the base lib dir, a path seperator token, the
			# name, a hyphen, the version and '.jar'.
			#
			# 2) If only a name is supplied then we look for all of the filenames
			# in the base lib dir that start with the name specified, sort them
			# lexicographically and take the last one in the list.
			#
			# We take the last because it should be the highest version number for
			# that JAR file.
			#
			#
			if( $jar->{'version'} !~ /^$/ )
			{
				# construct jar pathname
				$file = $base . '/' . $jar->{'name'} . '-' . $jar->{'version'} . '.jar';

				# add it to our list
				push @classpath, $file;

				$file = '';
			}
			else
			{
				# construct base pathname
				$file = $base . '/' . $jar->{'name'} . '-*';
				
				# BSD glob will sort them into ASCII order for us
				@files = bsd_glob( $file );

				# we want the last one
				$file = $files[-1];

				# add it to our list				
				push @classpath, $file;

				$file = '';
			}
		}
	}	

	return join( ':', ( @classpath, @{$self->{'dir'}} ) );
}

###########################################################################
1;

=pod

=head1 NAME

Java::SJ::Classpath - Java classpath generator

=head1 DESCRIPTION

This module is used by L<Java::SJ::Config> when generating complete
classpaths.

=head1 TODO

Test, test, test.

=head1 BUGS

None known so far. Please report any and all to Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

The Java::SJ::Classpath module is Copyright (c) 2003 Nigel Rantor. England.
All rights reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 AUTHORS

Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SEE ALSO

L<Java::SJ>. L<Java::SJ::Config>.

=cut
