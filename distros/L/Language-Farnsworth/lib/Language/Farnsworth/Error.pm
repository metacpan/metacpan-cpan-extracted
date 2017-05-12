#!/usr/bin/perl

package Language::Farnsworth::Error;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use enum qw(RETURN EINTERP EPERL EPARI);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(error debug perlwrap farnsreturn RETURN EINTERP EPERL EPARI);

use overload '""' => \&tostring,
			 'eq' => \&eq;

our $level = 0; #debugging level, 0 means nothing, 1 means informative, 2 means all kinds of shit.

sub error
{
	my $type;
	$type = shift if @_==2;
	$type = EINTERP unless defined $type;
	my $err = shift;
	
	#make already existing errors pass through transparently, fixes bug with return[], but i should find more direct route
	#i had originally thought this might be a bug but now that i think about it, what is going on is...
	#  foo{x} := {return[1]; 2};
	#     Function Dispatch, evaluate the function;
    #     We then end up calling return[] which is a perl function, so it gets wrapped with perlwrap()
    #     This then causes the error to get wrapped by perlwrap()
    #Circumventing this also allows perl code to correctly use error() to signify an error to the script rather than die
	if (ref($err) && $err->isa("Language::Farnsworth::Error"))
	{
		die $err;
	}
	
	my $eobj = {};
    $eobj->{msg} = $err;
    $eobj->{type} = $type;
    $eobj->{caller} = [caller()];
	bless $eobj;

	die $eobj;
}

sub farnsreturn
{
	my $return = shift;

	my $eobj = {};
    $eobj->{msg} = $return;
    $eobj->{type} = RETURN;
    $eobj->{caller} = [caller()];
	bless $eobj;

	die $eobj;
}

sub isreturn
{
	my $self = shift;
	return 1 if ($self->{type} == RETURN);
	return 0;
}

sub getmsg
{
	$_[0]->{msg};
}

#wraps code and catches die() and wraps the error in our class
sub perlwrap(&;$)
{
#	print "INPERLWRAP\n";
	my $code=shift;
	my $default=shift;
	$default=EPERL unless defined $default;
	
#	print "WANTARRAY: ", wantarray(), "\n";
	#preserve the context, makes things easier
	if (wantarray) #array context
	{
		my @ret = eval {$code->()};
#		print "DUMPER: ", Dumper(@ret), "\n";
#		print "DUMP ERR: ", Dumper($@), "\n";
		error $default, $@ if ($@);
		return @ret;
	}
	else #scalar context
	{
		my $ret = eval {$code->()};
#		print "DUMPER: ", Dumper($ret), "\n";
#		print "DUMP ERR: ", Dumper($@), "\n";
		error $default, $@ if ($@);
		return $ret;
	}
}

sub tostring
{
	my $self = shift;
	return $self->{msg};
}

sub eq
{
	my ($one, $two, $rev) = @_;

	my $str = $one->tostring();
	return $str eq $two;
}

#i'd love something a little more efficient but, oh well.
sub debug
{
	my ($mlevel, @messages) = @_;
    
    no warnings;
	print @messages,"\n" if ($mlevel <= $level && @messages);
}

1;
__END__

=encoding utf8

=head1 NAME

Language::Farnsworth - A Turing Complete Language for Mathematics

=head1 SYNOPSIS

  use Language::Farnsworth::Error;
  
  error "Error message here";
  debug 1, "This only happens when the user isn't thinking properly";
  
  $Language::Farnsworth::Error::level = 3; # Change the level of debugging output for the current perl interpreter
  
=head1 DESCRIPTION

This is an internally used class for producing errors (Eventually it will be the standard way of producing errors in Language::Farnsworth plugins).
As I don't have a proper plugin system yet, nor all the features in here that i'd like i'm going to leave things like they are.

=head1 TODO

Add capturing information (maybe with a scope walker or something) to capture the current position in the farnsworth source.  This will also require support in the parser to annotate the source position and store the filename and things.

=head1 AUTHOR

Ryan Voots E<lt>simcop@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ryan Voots

This library is free software; It is licensed exclusively under the Artistic License version 2.0 only.