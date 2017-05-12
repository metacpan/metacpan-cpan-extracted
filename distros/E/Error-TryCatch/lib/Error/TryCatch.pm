# Error::TryCatch
#
# Copyright (c) 2005-2009 Nilson Santos Figueiredo Jr. <nilsonsfj@cpan.org>.
# All rights reserved.  This program is free software; 
# you can redistribute it and/or modify it under the same 
# terms as perl itself.
#
# Some portions based on Error.pm from Graham Barr <gbarr@ti.com>

#####################################################################
# WARNING!                                                          #
# This code is old, don't blame me if it's an unreadable mess.      #
# Some day I might clean it up. Be glad that, apparently, it works. #
#####################################################################

package Error::TryCatch;
use warnings;
use strict;
use vars qw($VERSION @EXPORT $DEFAULT_EXCEPTION $DEBUG);
use base 'Exporter';
use Filter::Simple;
use Parse::RecDescent;
use Carp;

$VERSION = '0.07';
@EXPORT = qw(throw);

$DEFAULT_EXCEPTION = 'Error::Unhandled' unless defined $DEFAULT_EXCEPTION;

my $grammar = q!
<autotree>
program: <skip: qr/[ \t]*/> statement(s)
statement: starting_bracket | except_handler(s) | non_relevant 
starting_bracket: /^[\s]*[{}]/
non_relevant: <perl_quotelike>
                 { bless { __VALUE__ => join "", @{ $item[1] } }, $item[0] }
   | /[^\n]*\n?/
exception_type: /[\w_]+(?:::[\w_]+)*/
except_handler: "try" /[\s]*/ <perl_codeblock> /[\s]*/
			  | "catch" /[\s]*/ exception_type with(?) <perl_codeblock> /[\s]*/
			  | "otherwise" /[\s]*/ <perl_codeblock> /[\s]*/
			  | "finally" /[\s]*/ <perl_codeblock> /[\s]*/

with: "with"

!;

my $parser = new Parse::RecDescent($grammar);

FILTER {
	return unless defined $_;
	my $tree = $parser->program($_);
	$_ = _traverse($tree);
};

sub _traverse {
	my $tree = shift;
	my $code;
	for my $stm (@{$tree->{'statement(s)'}}) {
		if (defined $stm->{'non_relevant'}) {
			$code .= $stm->{'non_relevant'}->{'__VALUE__'}
				if defined $stm->{'non_relevant'}->{'__VALUE__'};
		}
		elsif (defined $stm->{'starting_bracket'}) {
			$code .= $stm->{'starting_bracket'}->{'__VALUE__'};
		}
		elsif (defined $stm->{'except_handler(s)'}) {
			my %clauses;
			for my $eh (@{$stm->{'except_handler(s)'}}) {
				my $innertree = $parser->program($eh->{'__DIRECTIVE1__'});
				my $innercode = _traverse($innertree);
				
				# try to keep line count
				$eh->{'__PATTERN1__'} =~ s/[^\n]//g;
				$eh->{'__PATTERN2__'} =~ s/[^\n]//g;
				$innercode = $eh->{'__PATTERN1__'} . $innercode . $eh->{'__PATTERN2__'};

				my $clause = $eh->{'__STRING1__'};
				if ($clause ne 'catch') {
					$clauses{$clause} = $innercode;
				}
				elsif ($clause eq 'catch') {
					push(@{$clauses{'catch'}}, {
						exception => $eh->{'exception_type'}->{'__VALUE__'}, 
						code	  => $innercode
					});
				}
				else { die 'unexpected parse error(1)' }
			}
			if (defined $clauses{try}) {
				my $innercode = "eval $clauses{try};";
				if (defined($clauses{catch}) || defined $clauses{otherwise}) {
					$innercode .= 'if ($@) {$@ = new '.$DEFAULT_EXCEPTION.'($@) unless ref($@);';
					my $catch = defined $clauses{catch};
					if ($catch) {
						my $els = '';
						for my $clause (@{$clauses{catch}}) {
							$innercode .= "${els}if (\$\@->isa('$clause->{exception}')) $clause->{code}";
							$els = 'els' if ($els eq '');
						}
					}
					if (defined $clauses{otherwise}) {
						$innercode .= 'else' if $catch;
						$innercode .= $clauses{otherwise};
					}
                    elsif ($catch) {
                        $innercode .= 'else{Carp::croak($@)}';
                    }
					$innercode .= '}';
				}
				if (defined $clauses{finally}) {
					$innercode = "eval{$innercode};$clauses{finally};if(\$\@){die \$\@}";
				}
				$code .= $innercode;
			}
			else { die "syntax error: no try clause found\n"	}
		}
		else { die "unexpected parse error(2)\n" }
	}
	return $code;
}

sub throw { croak @_ }

1;

package Error::Generic;
use base 'Class::Accessor';
use Carp;

# overloadable
__PACKAGE__->mk_accessors(qw[package file line text value]);
sub stringify { $_[0]->text }

use overload (
	'""'	   =>	'stringify',
	'0+'	   =>	'value',
	'bool'     =>	sub { return 1 },
	'fallback' =>	1
);

sub get { $_[0]->{"-$_[1]"} }
sub set { $_[0]->{"-$_[1]"} = $_[2] }

sub new {
	my $class  = shift;
	my ($pkg, $file, $line) = caller(1);
	my %e = (
		'-package'	=> $pkg,
		'-file'		=> $file,
		'-line'		=> $line,
		'-value'	=> 0,
		@_
	);
	if ($Error::TryCatch::DEBUG) {
		warn "thrown $class\n";
		for (keys %e) { warn "\t$_ => ". (defined($e{$_}) ? $e{$_} : "(undef)") ."\n" }
	}
    bless { %e }, $class;
}

1;

package Error::Unhandled;
use base 'Error::Generic';

sub new {
	my $class = shift;
	my $text = shift;
	chomp $text;
	
	my @args;
	@args = ( -file => $1, -line => $2)
	  if($text =~ s/ at (\S+) line (\d+)([.\n]+)?$//s);

	__PACKAGE__->SUPER::new(-text => $text, -value => $text, @args);
}

sub stringify { $_[0]->text . " at " . $_[0]->file . " line " . $_[0]->line . ".\n" }

1;
__END__

=head1 NAME

Error::TryCatch - OO-ish Exception Handling through source filtering

=head1 SYNOPSIS

  use Error::TryCatch;
  try {
	  dangerous_code();
	  even_more_dangerous_code();
	  throw new Error::Generic 
		  -text => "well, no one can live in danger forever";
  } 
  catch Error::Unhandled with {
	  # normal die()s are translated into Error::Unhandled exceptions
	  print "caught an unhandled perl exception: $@\n";
  }
  catch Error::NewExceptionClass with {
	  # code that handles Error::NewExceptionClass
  }
  catch Error::YetAnotherExceptions {
      # note that 'with' is optional (this differs from Error.pm)
  }
  otherwise {
	  # catch any other exception which might not have been caught
	  my $exception_class = ref($@};
	  print "someone has thrown a $exception_class exception: $@\n";
  }
  finally {
	  clean_up(); # which will always be executed
  }; 
  # don't forget the trailing ';' otherwise bad things *will* happen

=head1 DESCRIPTION

Error::TryCatch implements exception handling (try-catch) blocks 
functionality with an interface similiar to Error.pm (in fact, it's almost 
a drop-in replacement). The main difference is that it's a source filter 
module.

As a source filter it can implement the same convenient interface without 
those nasty memory leaks and implicit anonymous subroutines (which can trick 
you, if you're not careful). Also after source parsing it converts the code
into "native" perl code, so it's probably a little faster than Error.pm's
approach.

And, well. As far as I can tell, Error::TryCatch accomplishes its duty nicely.

=head1 FUNCTIONS

The interface is pretty straight-forward. I think that reading the synopsis is
enough documentation.

If you *really* need an explanation about how exception handling blocks work,
you should take a look at Error.pm documentation. The only clause which I 
chose not to implement was the 'except' clause, since I consider it rather
"exotic" and pretty much useless (at least for my purposes). And it would be
a pain to implement.

Unlike Error.pm, with Error::TryCatch you can return() from anywhere, but see
CAVEATS below.

=head1 EXCEPTION CLASSES

Error::TryCatch was built with exception classes in mind and will even wrap
anything it catches that is not a reference into a default unhandled exception
class, which defaults to Error::Unhandled (which inherits from Error::Generic).

If you want to use another exception class for any reason, you should set the
package variable $Error::TryCatch::DEFAULT_EXCEPTION to the classname. There's
a little gotcha, though: you need to do this *before* the module is loaded, 
like so:

  use warnings;
  use strict;
  BEGIN { $Error::TryCatch::DEFAULT_EXCEPTION = "Error::MyExceptionClass" }
  use Error::TryCatch;

  < ... code ... >

When creating unhandled exceptions, a single string argument (which is the
original die()/throw() message) will be passed to the constructor. So, you 
should implement this sort of constructor.

Error::TryCatch also provides a base generic exception class (Error::Generic), 
which you can inherit from or not. This class provides getter/setter methods 
for the basic supported exception properties: package, file, line, text and 
value. It also defines a stringify() method, which defaults to returning the
'text' property, however it should be overriden for more complex exception 
classes. Besides that, Error::Generic has overloaded operators for stringifying
(which calls the stringify() method) and for numeric context (where the "value"
property is returned by default). It also returns true in boolean context.

For maximum compatibility with Error.pm, Error::Generic is compatible with
Error::Simple and should work as a drop-in replacement for it, as long as class
names aren't checked.

=head1 CAVEATS

The trailing ';' at the of the block is absolutely necessary right now. This
may change in the future but, unfortunately, right now, if you forget the 
trailing ';' you'll get somewhat ugly errors. 
Error.pm also needs them but, in its case, Perl always warns you about bad 
syntax at compile time.

Syntax errors related to '}' (maybe '{' too) become a little harder to track,
since they end up confusing the parser's notion of "what a perl code block is".
So be sure to balance the '{' and '}' your code. Maybe in a later version I'll 
come up with a better solution for this problem.

When you return from inside of an exception handling block, the "finally" 
clause will not execute. I thought about work-arounds for this but all of them
seemed rather ugly, so I decided not to implement any of them.

Although throw() seems to work nicely, somehow I don't trust it and think that
it will make bad things happen somewhere. So, since it's plain syntatic sugar,
die() can be used as a replacement for it anywhere you like. 

If you throw() or die() a reference which is not an object bad things may
happen. If there's any demand, I'll consider using Scalar::Util's blessed()
instead of just checking if it's a reference.

=head1 BUGS

If you have a try-catch construct inside a string it might get filtered too 
(although the grammar tries to avoid id). If the try-catch construct is in a 
heredoc it's almost certain it will get filtered.

There needs to be at least one line (it can be an empty one) after a exception
handling block. So if it's the last thing in your program, you better add a
newline at the end.

Besides those, there are no other known issues. In fact, if the code is 
well-formed (no syntax errors) I could almost guarantee that it works as 
expected.

If you find any other bugs, please, report them directly to the author.

=head1 SEE ALSO

L<Error>, L<Parse::RecDescent>

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005-2009 Nilson Santos Figueiredo Junior.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
