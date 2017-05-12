package Filter::HereDocIndent;
use strict;
use Filter::Util::Call;
# use Debug::ShowStuff ':all';
use re 'taint';
use vars qw($VERSION $debug);

# documentation at end of file


# version
$VERSION = '1.01';

# constants
use constant REG => 1;
use constant HEREDOC => 2;
use constant POD => 3; # reserved for later improvement


#------------------------------------------------------------------
# new
#
sub new {
	my ($class, %opts) = @_;
	my $self = bless({}, $class);
	
	# default INDENT_CONTENT
	defined($opts{'INDENT_CONTENT'}) or $opts{'INDENT_CONTENT'} = 1;
	$self->{'INDENT_CONTENT'} = $opts{'INDENT_CONTENT'};
	
	# NWS: strip {nws} out of heredocs
	$self->{'NWS'} = $opts{'NWS'};
	
	# default state
	$self->{'state'} = REG;
	
	# return object
	return $self;
}
#
# new
#------------------------------------------------------------------


#------------------------------------------------------------------
# import routine: creates filter object and adds it
# to the filters array
#
sub import {
	my ($class, %opts) = @_;
	
	# add filter if set to do so
	if ( defined($opts{'filter_add'}) ? $opts{'filter_add'} : 1 ) {
		filter_add($class->new(%opts));
	}
}
#
# import routine
#------------------------------------------------------------------


#------------------------------------------------------------------
# filter: this sub is run for every line in the calling script
#
sub filter {
	my $self = shift;
	my $status = filter_read() ;
	my $line = $_;
	
	($status, $line) = $self->process_line($status, $line);
	
	# set line and return value
	$_= $line;
	$status;
}
#
# filter
#------------------------------------------------------------------



#------------------------------------------------------------------
# filter_block
#
sub filter_block {
	my ($self, $block) = @_;
	my (@lines, $status, $rv);
	
	# parse block into lines
	@lines = split("\n", $block);
	
	# loop through lines
	LINE_LOOP:
	foreach my $line (@lines) {
		($status, $line) = $self->process_line(1, "$line\n");
	}
	
	# get return string
	$rv = join('', @lines);
	
	# return
	return $rv;
}
#
# filter_block
#------------------------------------------------------------------



#------------------------------------------------------------------
# process_line
#
sub process_line {
	my ($self, $status, $line) = @_;
	
	# if we're at the end of the file
	if (! $status) {
		# for debugging this module
		if ($debug)
			{print STDERR "\n--------------------------\n"}
	}
	
	# if in here doc
	elsif ($self->{'state'} == HEREDOC) {
		# if this is the end of the heredoc
		if ($line =~ m|^(\s*)$self->{'del_regex'}\s*$|) {
			my $len = length($1);
			
			if ($self->{'INDENT_CONTENT'}) {
				foreach my $el (@{$self->{'lines'}}) {
					$el =~ s|^\s{$len}|| or $el =~ s|^\s+||;
					$el eq '' and $el = "\n";
				}
			}
			
			$line = join('', @{$self->{'lines'}}, $self->{'del'}, "\n");
			
			# add empty lines so that line numbers match up with original code
			# NOTE: The following line still doesn't address the issue of
			# {nws} removals
			# $line .= "\n" x scalar(@{$self->{'lines'}});
			
			foreach (@{$self->{'lines'}})
				{ $line .= "\n" }
			
			# remove whitespace
			if ($self->{'NWS'}) {
				$line =~ s|\s*\{nws\}\s*||gs;
			}
			
			# set state to regular code
			$self->{'state'} = REG;
		}
		
		# else add to lines array
		else {
			push @{$self->{'lines'}}, $line;
			$line = '';
		}
	}
	
	# else in regular code
	else {
		# if this line starts a heredoc
		if ($line =~ m/
			^              # start of line
			[^#]*          # anything except a comment marker
			<<
			\s*
			
			(
				'[^']+'
				|
				"[^"]+"
				|
				\w+
			)
			
			[^'"]*
			;
			\s*
			
			/sx
			) {
			
			$self->{'del'} = $1;
			$self->{'del'} =~ s|^'(.*)'$|$1| or $self->{'del'} =~ s|^"(.*)"$|$1|;
			$self->{'del_regex'} = quotemeta($self->{'del'});
			
			$self->{'lines'} = [];
			$self->{'state'} = HEREDOC;
		}
	}
	
	# for debugging this module
	print STDERR $line if $debug;
	
	return ($status, $line);
}
#
# process_line
#------------------------------------------------------------------



# return true
1;

__END__

=head1 NAME

Filter::HereDocIndent - Indent here documents

=head1 SYNOPSIS

 use Filter::HereDocIndent;

 # an indented block with an indented here doc
 if ($sometest) {
         print <<'(MYDOC)';
         Melody
         Starflower
         Miko
         (MYDOC)
 }

outputs (with text beginning at start of line):

 Melody
 Starflower
 Miko

HereDocIndent mimics the planned behavior of here documents in Perl 6.

=head1 INSTALLATION

Filter::HereDocIndent can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 DEPENDENCIES

HereDocIndent requires C<Filter::Util::Call>, which is part of the standard
distribution starting with Perl 5.6.0.  For earlier versions of Perl you will
need to install C<Filter::Util::Call>, which requires either a C compiler or
a pre-compiled binary.

=head1 DESCRIPTION

HereDocIndent allows you to indent your here documents along with the rest of
the code.  The contents of the here doc and the ending delimiter itself may be
indented with any amount of whitespace.  Each line of content will have the
leading whitespace stripped off up to the amount of whitespace that the
closing delimiter is indented. Only whitespace is stripped off the beginning
of the line, never any other characters

For example, in the following code the closing delimiter is indented eight spaces:

 if ($sometest) {
         print <<'(MYDOC)';
         Melody
         Starflower
         Miko
         (MYDOC)
 }

All of the content lines in the example will have the leading eight whitespace
characters removed, thereby outputting the content at the beginning of the line:

 Melody
 Starflower
 Miko

If a line is indented more than the closing delimiter, it will be indented by
the extra amount in the results.  For example, this code (+ is used to indicate
spaces):

 if ($sometest) {
 ++++++++print <<'(MYDOC)';
 ++++++++Melody
 +++++++++++Starflower
 ++++++++Miko
 ++++++++(MYDOC)
 }

produces this output:

 Melody
 +++Starflower
 Miko

HereDocIndent does not distinguish between different types of whitespace.  If
you indent the closing delimiter with a single tab, and the contents eight
spaces, each line of content will lose just one space character.  The best
practice is to be consistent in how you indent, using just tabs or just spaces.

HereDocIndent will only remove leading whitespace.  If one of the lines of
content is not indented, the non-whitespace characters will B<not> be removed.
The trailing newline is never removed.

=head2 INDENT_CONTENT

By default the contents of the here document are indented to the same extent
as the closing delimiter.  If you want to leave the contents indented, but
still indent the closing delimiter so that it lines up with its content, set
the C<INDENT_CONTENT> option to zero in when you load HereDocIndent:

 use Filter::HereDocIndent INDENT_CONTENT=>0;

=head2 NWS

B<BUG>: Please note that there is a bug I haven't resolved with NWS filtering.
If the {nws} string appears at the beginning or end of the heredoc then
it's not stripped out.  In the middle it should be OK.

The NWS option helps you clean up the contents of heredocs by allowing you
to add whitespace in your perl code but have it stripped out when your program
runs.

To enable NWS ("no whitespace") filtering, add the NWS option to the "use" command:

 use Filter::HereDocIndent NWS=>1;

Anywhere in a heredoc that HereDocIndent sees the string {nws} it will strip out
that string and all surrounding whitespace.  NWS is handy for outputting strings
like HTML where avoiding whitespace can clutter up your code.  For example, the
following code will output HTML without any spaces between the tags:

	print <<"(HTML)";
	<a href="whatever.pl"> {nws}
	<img src="logo.png" alt="logo"> {nws}
	</a>
	(HTML)


=head1 LIMITATIONS

HereDocIndent was written to be conservative in what it decides are here
documents.  HereDocIndent recognizes the most common usage for here docs and
disregards other less common usages.  If you constrain your here doc
declarations to the format recognized by HereDocIndent (which is by far the
most popular format) then your code will compile just fine.

The format recognized by HereDocIndent is a single print statement or variable
assignment, followed by C<E<lt>E<lt>>, then a quoted string or unquoted string
of word characters, then a semicolon, then the end of line.  Here are a few
examples that would be parsed properly by HereDocIndent:

 print << '(MYDOC)';
 print << "MYDOC";
 my $var = <<EOT;
 push @arr, <<  '(MYDOC)';
 mysub (<<'MYDOC');

Here are a few examples that would B<not> be recognized by HereDocIndent:

 push @arr, <<'MYDOC', 'foo';
 print <<'MYDOC', "------\n";

HereDocIndent does not currently recognize POD notation, so there could be
unintended problems if you put text in your POD that looks like a here doc.
This issue will need to be fixed in a later release.  HereDocIndent also does
not recognize if an entire line is inside quotes from another line, or even
inside a here doc that it didn't recognize.

COMPARISON TO OTHER HEREDOC INDENTATION TECHNIQUES

There are several other here doc indentation techniques,
particularly those discussed in the Perl FAQ.  Those
techniques generally have several shortcomings.

First, they require you to modify how you create the here
doc.  Instead of simply creating the here doc as you usually
would, except that it is indented, you have to pass the
entire string into a function of through a regex to modify
it.

Second, they usually require that the ending delimiter is
still flush against the left margin.  It should be noted
that this shortcoming can be overcome by creating the
heredoc delimiter with padded spaces in the left.  However,
even that technique requires you to ensure that the here
doc declaration and the actual delimiter have matching
amounts of padded space... something I personally find
to be a distasteful extra drain on my brain resources.
HereDocIndent allows you to simply create a delimeter
and use it as usual.

Finally, many techniques either produce a string with
padded spaces in the left margin, or force a function to
guess how many spaces it should remove.  With
HereDocIndent, that information is cleanly and
unambiguously determined by the indentation of the
delimiter.

HereDocIndent mimics the planned behavior of here docs
in Perl 6.

BUGS AND OTHER ISSUES

There have been some problems where commented out code that includes
here docs causes a compiler crash.  If your code won't compile check
if any commented out code uses here docs.  Usually to work around the
problem I just put a space between the two <'s.

HereDocIndent changes the number of lines in your document, so when you
get an error that includes the line number of your code, you might find that
that actual problematic code is a few lines away from that line number.

=head1 TERMS AND CONDITIONS

Copyright (c) 2002 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>


=head1 VERSION

=over

=item Version 0.90    August 6, 2002

Initial release

=item Version 0.91    November 8, 2010

Modified to fit the situation where the heredoc is an argument in a call to a
function.

Minor edits to documentation.

=item Version 1.00    July, 2012

Added NWS option.

Minor edits to documentation.

=item Version 1.01 January 2, 2015

Fixed CR/LF and encoding issues with the files. Improved tests so that they
have test names.

=back



=cut
