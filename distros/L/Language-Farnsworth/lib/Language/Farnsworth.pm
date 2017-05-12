#!/usr/bin/perl

package Language::Farnsworth;

our $VERSION = "0.7.7";

use strict;
use warnings;

use Language::Farnsworth::Evaluate;
use Language::Farnsworth::Value;
use Language::Farnsworth::Dimension;
use Language::Farnsworth::Units;
use Language::Farnsworth::FunctionDispatch;
use Language::Farnsworth::Variables;
use Language::Farnsworth::Output;
use Math::Pari;

use Data::Dumper;

sub new
{
	shift; #get the class off

	my $self = {};
	my @modules = @_; #i get passed a list of modules to use for standard stuff;

	Math::Pari::setprecision(100); #both of these need to be user configurable!
	Math::Pari::allocatemem(40_000_000);

	if (@modules < 1)
	{
		@modules = ("Units::Standard", "Functions::Standard", "Functions::StdMath", "Functions::GoogleTranslate", "Units::Currency"); #standard modules to include
	}

	#print Dumper(\@modules);

	$self->{eval} = Language::Farnsworth::Evaluate->new();

	for my $a (@modules)
	{
		local $@;
		eval 'use Language::Farnsworth::'.$a.'; Language::Farnsworth::'.$a.'::init($self->{eval});';
		#die $@ if $@;
		#print "-------FAILED? $a\n";
		#print $@;
		#print "\n";
	}

	bless $self;
	return $self;
}

sub runString
{
	my $self = shift;
	my @torun = @_; # we can run an array
	my @results;

	push @results, new Language::Farnsworth::Output($self->{eval}{units},$self->{eval}->eval($_), $self->{eval}) for (@torun);

	return wantarray ? @results : $results[-1]; #return all of them in array context, only the last in scalar context
}

sub runFile
{
	my $self = shift;
	my $filename = shift;

	#my @results; #i should really probably only store them all IF they are needed

	open(my $fh, "<", $filename) or die "couldn't open: $!";
	my $lines;
	my $first = 1;
	while(<$fh>)
	{
		$first=0, next if ($first && $_ =~ /^#!/); #skip a shebang line, not part of the language but makes it possible to have executable .frns files!
		$lines .= $_; 
	}
    close($fh);

	#as much as i would like this to work WITHOUT this i need to filter blank lines out #not as sure i need to do this anymore! need tests to check
	$lines =~ s/\s*\n\s*\n\s*/\n/;
		
	return new Language::Farnsworth::Output($self->{eval}{units},$self->{eval}->eval($lines), $self->{eval});

#	while(<$fh>)
#	{
#		chomp;
		#s|//.*$||;
		#s|\s*$||;
#	}

#	close($fh);

		#return wantarray ? @results : $results[-1]; #return all of them in array context, only the last in scalar context
}

#this will wrap around a lot of the funky code for creating a nice looking output
#sub prettyOut
#{
#	my $self = shift;
#	my $input = shift;

#	return $input->toperl($self->{eval}{units});
#}

1;
__END__

=encoding utf8

=head1 NAME

Language::Farnsworth - A Turing Complete Language for Mathematics

=head1 SYNOPSIS

	use Language::Farnsworth;
	
	my $hubert = Language::Farnsworth->new();
	
	my $result = $hubert->runString("10 km -> miles");
	my $result = $hubert->runFile("file.frns");
	
	print $result;

=head1 DESCRIPTION

THIS IS A BETA RELEASE, perpetually so! There are typos in the error messages and in the POD.  
There are also probably plenty of bugs.  While it is not ready for production use, it is most certainly usable as a toy and to see a pure interpreter written in perl.
Not every feature is documented yet (This 0.7.x series will be striving to fix that) and a future release will fix the hairier parts of the internal API (scheduled for 0.8.x).

=head2 PREREQUISITS

Modules and Libraries you need before this will work

=over 4

=item *

The PARI library

=item *

L<Math::Pari>

=item *

L<DateTime>
L<DateTimeX::Easy>

The following are optional

For the Google Translation library

=item *

L<REST::Google::Translate>

=item *

L<HTML::Entities>

For the currency support

=item *

L<Finance::Currency::Convert::XE>

	NOTE: For the currency units to work you currently need to call C<updatecurrencies[]> before they will be available, this will change

=back

=head2 METHODS

ALL of the methods here call C<die> whenever something doesn't go right.  This means that unless you want bad input to them to cause your program to fail you should wrap any calls to them with C<eval {}>.   When they call C<die> they will give you back a message explaining what went wrong, this is useful for telling a user what they have done.

=head3 runString

This method takes a string (or multiple strings) and executes them as Language::Farnsworth expressions.
For more information on making Language::Farnsworth expressions, see L<Language::Farnsworth::Docs::Syntax>.

=head3 runFile

This takes a file name and executes the entire file as a single Language::Farnsworth expression.

=head3 prettyOut

This takes a Language::Farnsworth::Value and turns it into a string for perl to be able to display.  This method WILL disappear in a future version.

=head2 EXPORT

None by default.

=head2 KNOWN BUGS

At the moment all known bugs are related to badly formatted output, this will be rectified in a future release.
And there are a number of unfinished error messages, and a few issues with the way arrays work.

There is also a known issue with the size of scopes.  I do not know if I will be able to fix it, and until then i recommend NOT using recursive algorithms because it will cause everything to balloon way up in memory usage.

=head2 MISSING FEATURES

The following features are currently missing and WILL be implemented in a future version of Language::Farnsworth

=over 4

=item *

Better control over the output

=over 8

=item *

Adjustable precision of numbers (this includes significant digits!)

=item *

Better defaults for certain types of output

=back

=item *

Syntax tree introspection inside the language itself

=item *

Better Documentation

=item *

Objects!

=back

=head1 HISTORY

Language::Farnsworth is a programming language originally inspired by Frink (see http://futureboy.homeip.net/frinkdocs/ ).
However due to creative during the creation of it, the syntax has changed significantly and the capabilities are also different.
Some things Language::Farnsworth can do a little better than Frink, other areas Language::Farnsworth lacks.  
And while ostensibly the language may appear to be named in a similar vein after another cartoon professor that brings good news to everyone,
it is in fact named after the famous physicist Philo T. Farnsworth.

=head1 SEE ALSO

L<Language::Farnsworth::Docs::Syntax> L<Language::Farnsworth::Docs::Functions>

Please use the bug tracker available from CPAN to submit bugs.
There are also things to be 

=head1 AUTHOR

Ryan Voots E<lt>L<simcop@cpan.org>E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ryan Voots

This library is free software; It is licensed exclusively under the Artistic License version 2.0 only.

=cut
