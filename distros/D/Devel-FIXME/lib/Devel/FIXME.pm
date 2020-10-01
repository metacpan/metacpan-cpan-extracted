#!/usr/bin/perl

package Devel::FIXME;
use fields qw/text line file package script time/;

use 5.008_000; # needs open to work on scalar ref

use strict;
use warnings;

use Exporter;
use Scalar::Util qw/reftype/;
use List::Util qw/first/;
use Carp qw/carp croak/;

our @EXPORT_OK = qw/FIXME SHOUT DROP CONT/;
our %EXPORT_TAGS = ( "constants" => \@EXPORT_OK );

our $VERSION = 0.02;

# some constants for rules
sub CONT () { 0 };
sub SHOUT () { 1 };
sub DROP () { 2 };

our $REPAIR_INC = undef; # do not "repair" @INC by default

my %lock; # to prevent recursion
our %rets; # return value cache
our $cur; # the current file, used in an eval
our $err; # the current error, for rethrowal
our $inited; # whether the code ref was installed in @INC, and all 

{ my $anon = ''; open my $fh, "<", \$anon or die $!; close $fh; } # otherwise perlio require stuff breaks

sub init {
	my $pkg = shift;
	unless($inited){
		$pkg->readfile($_) for ($0, sort grep { $_ ne __FILE__ } (values %INC)); # readfile on everything loaded, but not us (we don't want to match our own docs)
		$pkg->install_inc;
	}

	$inited = 1;
}

our $carprec = 0;

sub install_inc {
	my $pkg = shift;
	
	unshift @INC, sub { # YUCK! but tying %INC didn't work, and source filters are applied per caller. XS for source filter purposes is yucki/er/
		my $self = shift;
		my $file = shift;
		
		return undef if $lock{$file}; # if we're already processing the file, then we're in the eval several lines down. return.
		local $lock{$file} = 1; # set this lock that prevents recursion

		unless (ref $INC[0] and $INC[0] == $self){ # if this happens, some stuff won't be filtered. It shouldn't happen often though.
			local @INC = grep { !ref or $_ != $self } @INC; # make sure we don't recurse when carp loads it's various innards, it causes a mess
			carp "FIXME's magic sub is no longer first in \@INC" . ($REPAIR_INC ? ", repairing" : "");
			if ($REPAIR_INC){
				my $i = 0;
				while ($i < @INC) {
					ref $INC[$i] or next;
					if ($INC[$i] == $self) {
						unshift @INC, splice(@INC, $i, 1);
						last;
					}
				} continue {
					$i++;
				}
			}
		}

		# create some perl code that gives back the return value of the original package, and thus looks like you're really requiring the same thing
		my $buffer = "\${ delete \$Devel::FIXME::rets{q{$file}} };"; # return what the last module returned. I don't know why it doesn't work without refs
		# really load the file
		local $cur = $file;
		my $ret = eval 'require $Devel::FIXME::cur'; # require always evaluates the return from an evalfile in scalar context, so we don't need to worry about list

		($err = "$@\n") =~ s/\nCompilation failed in require at \(eval \d+\)(?:\[.*?\])? line 1\.\n//s; # trim off the eval's appendix to the error
		$buffer = 'die $Devel::FIXME::err' if $@; # rethrow this way, so that base.pm shuts up
		
		# save the return value so that the original require can have it
		$rets{$file} = \$ret; # see above for why it's a ref

		# look for FIXME comments in the file that was really required
		$pkg->readfile($INC{$file}) if ($INC{$file});

		# return a filehandle containing source code that simply returns the value the real file did
		open my $fh, "<", \$buffer;
		$fh;
	};
}

sub regex {
	qr/#\s*(?:FIXME|XXX)\s+(.*)$/; # match a FIXME or an XXX, in a comment, with some lax whitespace rules, and suck in anything afterwords as the text
}

sub readfile { # FIXME refactor to something classier
	my $pkg = shift;
	my $file = shift;

	return unless -f $file;	

	open my $src, "<", $file or die "couldn't open $file: $!";
	local $_;

	while(<$src>){
		$pkg->FIXME( # if the line matches the fixme, generate a fixme
			text => "$1",
			line => $., # the current line number for <$src>
			file => $file,
		) if $_ =~ $pkg->regex;
	} continue { last if eof $src }; # is this a platform bug on OSX?
	close $src;
}

sub eval { # evaluates all the rules on a fixme object
	my __PACKAGE__ $self = shift;

	foreach my $rule ($self->can("rules") ? $self->rules : ()){

		my $action = &$rule($self); # run the rule as a class method, and get back a return value

		if ($action == SHOUT){ # if the rule said to shout, we shout and stop
			return $self->shout;
		} elsif ($action == DROP){ # if the rule says to drop, we stop
			return undef;
		} # otherwise we keep looping through the rules
	}

	$self->shout; # and shout if there are no more rules left.
}

sub shout { # generate a pretty string and send it to STDERR
	my __PACKAGE__ $self = shift;
	warn("# FIXME: $self->{text} at $self->{file} line $self->{line}.\n");
}

sub new { # an object per FIXME statement
	my $pkg = shift;

	my %args;
	
	if (@_ == 1){ # if we only have one arg
		if (ref $_[0] and reftype($_[0]) eq 'HASH'){ # and it's a hash ref, then we take the hashref to be our args
			%args = %{ $_[0] };
		} else { # if it's one arg and not a hashref, then it's our text
			%args = ( text => $_[0] );
		}
	} elsif (@_ % 2 == 0){ # if there's an even number of arguments, they are key value pairs
		%args = @_;
	} else { # if the argument list is anything else we complain
		croak "Invalid arguments";
	}
	
	
	my __PACKAGE__ $self = $pkg->fields::new();
	%$self = %args;

	# fill in some defaults
	$self->{package} ||= (caller(1))[0];
	$self->{file} ||= (caller(1))[1];
	$self->{line} ||= (caller(1))[2];

	# these are mainly for rules
	$self->{script} ||= $0;
	$self->{time} ||= localtime;

	$self;
}

sub import { # export \&FIXME to our caller, /and/ generate a message if there is one to generate
	my $pkg = $_[0];
	$pkg->init unless @_ > 1;
	if (@_ == 1 or @_ > 2 or (@_ == 2 and first { $_[1] eq $_ or $_[1] eq "&$_" } @EXPORT_OK, map { ":$_" } keys %EXPORT_TAGS)){
		shift;
		local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
		$pkg->Exporter::import(@_);
	} else {
		$pkg->init;
		goto \&FIXME;
	}
}

sub FIXME { # generate a method
	my $pkg = __PACKAGE__;
	$pkg = shift if UNIVERSAL::can($_[0],"isa") and $_[0]->isa(__PACKAGE__); # it's a method or function, we don't care
	$pkg->new(@_)->eval;
}
*msg = \&FIXME; # booya.

__PACKAGE__

__END__

=pod

=head1 NAME

Devel::FIXME - Semi intelligent, pending issue reminder system.

=head1 SYNOPSIS

	this($code)->isa("broken"); # FIXME this line has a bug

=head1 DESCRIPTION

Usually we're too busy to fix things like circular refs, edge cases and so
forth when we're spewing code into the editor. This is because concentration is
usually too valuable a resource to throw to waste over minor issues. But that
doesn't mean the issues don't exist. So usually we remind ourselves they do:

	... # FIXME I hope someone finds this comment


and then search through the source tree for occurrances of I<FIXME> every now
and then, say with C<grep -ri fixme src/>.

This pretty much works until your code base grows, and you have too many FIXMEs
to prioritise them, or even visually tell them apart.

This package's purpose is to provide reminders to FIXMEs (without the user
explicitly searching), and also controlling when, or which reminders will be
displayed.

=head1 DECLARATION INTERFACE

There are several ways to get your code fixed in the indeterminate future.

The first is a sort-of source filter like compile time fix, which does not
affect shipped code.

	$code; # FIXME broken

That's it. When L<Devel::FIXME> is loaded, it will emit warnings for such
comments in any file that was already loaded, and subsequently loaded files as
they are required. The most reasonable way to get it to work is to set the
environment variable I<PERL5OPT>, so that it contains C<-MDevel::FIXME>. When
perl is then started without taint mode on, the module will be loaded
automatically.

The regex for finding FIXMEs in a line of source is returned by the C<regex>
class method (thus it is overridable). It's quite crummy, really. It matches an
occurrance of a hash sign (C<#>), followed by optional white space and then
C<FIXME> or C<XXX>. After that any white space is skipped, and whatever comes
next is the fixme message.

Given some subclassing you could whip up a format for FIXME messages with
metadata such as priorities, or whatnot. See the implementation of C<readfile>.

The second interface is a compile time, somewhat more explicit way of emmitting
messages.

	use Devel::FIXME "broken";

This can be repeated for additional messages as needed. This is useful if you
want your FIXMEs to ruin deployment, so you're forced to get rid of them. Make
sure you run your final tests in a perl tree that doesn't have L<Devel::FIXME>
in it.

The third, and probably most problematic is a runtime, explicit way of emmitting
messages:

	use Devel::FIXME qw/FIXME/;
	$code; FIXME("broken");

This relies on FIXME to have been imported into the current namespace, which is
probably not always the case. Provided you know FIXME is loaded I<somewhere> in
the running perl interpreter, you can use a fully qualified version:

	$code; Devel::FIXME::FIXME("broken");

or if you feel that repeating a word is clunky, do:

	$code; Devel::FIXME->msg("broken");
	# or
	$code; Devel::FIXME::msg("broken");

But do use the first FIXME declaration style. Seriously.

=head1 OUTPUT FILTERING

=head2 Rationale

There are some problems with simply grepping for occurances of I<FIXME>:

=over 4

=item *

It's messy - you get a bajillion lines, if your source tree is big enough.

=item *

You need context. While grep can provide for it, that isn't necessarily simple
to read.

=item *

You (well I<I> do anyway) forget to do it. And no, cron is not really a
solution.

=back

The solution to the first two problems is to make the reporting smart, so that
it decides which FIXMEs are printed and which arent.

The solution to the last problem is to have it happen automatically whenever
the source code in question is used, and furthermore, to report context too.

=head2 Principle

The way FIXMEs are filtered is similar to how a firewall filters packets.

Each FIXME statement is considered as it is found, by iterating through some
rules, which ultimately decide whether to print the statement or not.

This may sound a bit overkill, but I think it's useful.

What it means is that you can get reminded of FIXMEs in source files that are
more than a week old, or when your release schedule reaches feature freeze, or
if your program is in the stable tree if your source management repository, or
whatever.

There are many modules that know how to parse SCM meta data, for CVS, Perforce,
SVN, and so forth. L<File::Find::Rule> can be used in nasty ways to ask
questions about files (like I<was it modified in the last week?>). The
possibilities are quite vast.

=head2 Practice

Currently the FIXMEs are filtered by calling the class method C<rules>, and
evaluating the subroutine references that are returned, as methods on the fixme
object.

The subclass L<Devel::FIXME::Rules::PerlFile> is a convenient way to get rules
from a file.

=head1 DIAGNOSIS

=over 4

=item FIXME's magic sub is no longer first in @INC

When C<require> is called and the @INC hook is entered, it makes sure that it's
first in the @INC array. If it isn't, some files might be required without
being filtered. If the global variable C<$Devel::FIXME::REPAIR_INC> is set to a
true value (it's undef by default), then the magic sub will put itself back in
the begining of @INC as required.

=back

=head1 BUGS

If I had a nickle for every bug you could find in this module, I would have
C<< $nickles >= 0 >>.

Amongst them:

=over 4

=item The regex for finding FIXMEs is stupid.

It will find FIXME's in a quoted string, or other such edge cases. I don't
care. Patches welcome.

C<$nickles++>;

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/Devel-FIXME/>, and use C<darcs send>
to commit changes.

=head1 AUTHOR

Original Author:
Yuval Kogman, C<< <nothingmuch@woobling.org> >>

Current maintainer:
Nigel Horne, C<< <njh@bandsman.co.uk> >>

=head1 COPYRIGHT & LICENCE

	Copyright (c) 2004 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Devel::Messenger>, L<grep(1)>
