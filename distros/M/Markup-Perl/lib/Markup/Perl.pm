package Markup::Perl; # $Id: Perl.pm,v 1.3 2006/09/04 15:30:15 michael Exp $
our $VERSION = '0.5';
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser set_message);

my %headers = (-type=>'text/html', -cookie=>[], -charset=>'UTF-8'); # defaults
my $output = '';
my $print_start = ";\nprint substr(<<'mupl_EOS', 0, -1);\n";
my $print_end   = "\nmupl_EOS\n";
my $in_file = $0;

BEGIN { # catch prints into a variable, and dump at the end
	{	package Buffer;
		sub TIEHANDLE { my ($class, $b) = @_; bless $b => $class;              }
		sub PRINT	  { my $b = shift; $$b .= join '', @_;                     }
		sub PRINTF	  { my $b = shift; my $fm = shift; $$b .= sprintf($fm, @_);}
	} tie *STDOUT=>"Buffer", \$output;
	
	set_message(sub{ # for pretty CGI::Carp output
		my $message = shift;
		$message =~ s!&lt;SCRIPT&gt;!$in_file!g;
		$output = qq{\n\n<p style="font:14px arial;border:2px dotted #966;padding:10px">
		<em>There was an error with "$in_file"</em><br />$message</p>};
	});
}

sub import { # when we are used
	my ($package, undef, $line) = caller();
	$line or die "can't invoke from command-line\n";
	
	open SCRIPT, "<$0" or die qq(can't open calling file "$0": $!);
	for (1..$line) { <SCRIPT> } # go past lines up to the one that uses us
	
	run(do{ local $/;  <SCRIPT> });
	exit;
} 

sub run { # transform and eval mupl text
	$_ = shift or return;
	
	my $code = $print_start;
	s/<perl>(<!\[CDATA\[)?/$print_end/g;
	s/(\]\]>)?<\/perl>/$print_start/g;
	$code .= ${^TAINT}? (/(.+)/s, $1) : $_; # untaint
	$code .= $print_end;
	eval $code; $@ and die "can't run code: $@";
}

sub src { # get and run mupl text in some other file
	my $path = shift or return '';
	my $tmp = $in_file = $path;
	(open SRC, "<$path" and flock(SRC, 1)) or croak qq(can't get src "$path": $!);
	my $src = do{ local $/; <SRC> };
	close SRC;
	run $src;
	$in_file = $tmp;
}

sub param  { my ($v) = @_; return wantarray? @{[CGI::param($v)]} : CGI::param($v) }
sub header { my ($n, $v) = @_; $headers{"-$n"} = $v }
sub cookie {
	(@_ == 1)?
		  return CGI::cookie(shift)
		: push @{$headers{-cookie}}, CGI::cookie(map{$_=>shift} qw(-name -value -expires -path -domain -secure));
}

END {
	{ no warnings 'untie'; untie *STDOUT } # disconnect from the Buffer
	use bytes ();
	binmode(STDOUT);
	print CGI::header(%headers, 'Content-length'=>bytes::length $output), $output;
}

1;

__END__
=head1 NAME

Markup::Perl - turn your CGI inside-out

=head1 SYNOPSIS
  
  # don't write this...
  print "Content-type: text/html;\n\n";
  print "<html>\n<body>\n";
  print "<p>\nYour \"lucky number\" is\n";
  print "<i>", int rand 10, "</i>\n</p>\n";
  print "</body>\n</html>\n";
  
  # write this instead...
  use Markup::Perl;
  <html>
  <body>
  <p>
  Your "lucky number" is
  <i><perl> print int rand 10 </perl></i>
  </p>
  </body>
  </html>

=head1 DESCRIPTION

For some problems, particularly in the presentation layer, thinking of the solution as a webpage that can run perl is more natural than thinking of it as a perl script that can print a webpage.

It's been done before, but this module is simple. The source code is compact: one file and less than 2k of code. Simply put: if you can do it in Perl, you can do it in Markup::Perl, only without all the print statements, heredocs and quotation marks.

=head1 SYNTAX

=over 3

=item basic

It's a perl script when it starts. But as soon as the following line is encountered the rules all change.

  use Markup::Perl;

Every line after that follows this new rule: Anything inside <perl>...</perl> tags will be executed as perl. Anything not inside <perl>...</perl> tags will be printed as is.

So this...

  use Markup::Perl;
  <body>
    Today's date is <perl> print scalar(localtime) </perl>
  </body>

Is functionally equivalent to...

  print "<body>\n";
  print "Today's date is ";
  print scalar(localtime), "\n";
  print "</body>";
  
If you bear that in mind, you can see that this is also possible...

  use Markup::Perl;
  <body>
    <perl> for (1..3) { </perl>
    <b>bang!</b>
    <perl> } </perl>
  </body>

Naturally, anything you can do in an ordinary perl script you can also do inside <perl></perl> tags. Use your favourite CPAN modules, define your own, whatever.

=item outsourcing

If you would like to have a some shared Markup::Perl code in a separate file, simply "include" it like so...

  use Markup::Perl;
  <body>
    Today's date is <perl>src('inc/dateview.pml')</perl>
  </body>

The included file can have the same mixture of literal text and <perl> tags allowed in the first file, and can even include other Markup::Perl files using its own C<src()> calls. Lexical C<my> variables defined in src files are independent of and inaccessible to code in the original file. Package variables are accessible across src files by using the variable's full package name.

=item print order

Not all output happens in a stream-like way, but rather there is an attempt to be slightly intelligent by reordering certain things, such as printing of HTTP headers (including cookies). Thus you can use the C<header()> call anywhere in your code, even conditionally, but the actual header, if you do print it, will always be at the very start of your document.

=back

=head1 FUNCTIONS

=over 3

=item header(name=>'value')

Adds the given name/value pair to the HTTP header. This can be called from anywhere in your Markup::Perl document.

=item param

Equivalent to CGI::param. Returns the GET or POST value with the given name.

=item cookie

Given a single string argument, returns the value of any cookie by that name, otherwise sets a cookie with the following values from @_: (name, value, expires, path, domain, secure).

=item src('filename')

Transforms the content of the given file to allow mixed literal text and executable <perl>...</perl> code, and evals that content.

=back

=head1 CAVEATS

For the sake of speed and simplicity, I've left some areas of the code less than bullet-proof. However, if you simply avoid the following bullets, this won't be a problem:

=over 3

=item starting out

Keep the C<use Markup::Perl> line simple. Its presence signals the beginning of new Markup::Perl syntax. The C<use> line should be on a single line by itself.

=item tags that aren't tags

The parser is brutally simple. It just looks for <perl> and </perl> tags, regardless of whether or not you meant them to be treated as tags or not. For example printing a literal </perl> tag requires special treatment. You must write it in such a way that it doesn't B<look> like </perl>. This is the same as printing a "</script>" tag from within a JavaScript block.

  &lt;perl>
  <perl>
  print '<'.'/perl>';
  </perl>

=item including yourself

It is possible to include and run Markup::Perl code from other files using the C<src> function. This will lead to a recursive loop if a file included in such a way also includes a file which then includes itself. This is the same as using the Perl C<do 'file.pl'> function in such a way, and it's left to the programmer to avoid doing this.

=item use utf8

I've made every effort to write code that is UTF-8 friendly. So much so that you are likely to experience more problems for B<not> using UTF-8. Saving your documents as UTF-8 (no BOM) is recommended; other settings may or may not work. Files included via the C<src> function are B<always> assumed to be UTF-8.

=back

=head1 COPYRIGHT

The author does not claim copyright on any part of this code; unless otherwise licensed, code in this work should be considered Public Domain.

=head1 AUTHORS

Michael Mathews <micmath@gmail.com>, inspired by !WAHa.06x36 <paracelsus@gmail.com>.

=cut