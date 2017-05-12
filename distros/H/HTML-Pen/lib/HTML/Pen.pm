package HTML::Pen ;

# use 5.008009;
use strict;
use warnings;

use FileHandle ;

use HTML::Pen::Utils ;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Pen ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '1.01';

our ( $T1, $T2, $T3 ) ;
our ( $pen, $DOCS, $follow ) ;
my ( $skipct, $crashlimit, @fh ) ;
my $undef = '' ;


## request initialization
sub new {
	shift @_ if $_[0] eq __PACKAGE__ ;
	$skipct = 0 ;
	$crashlimit = 200000 ;
	@fh = () ;

	my $path = shift @_ unless ref $_[0] ;
	$pen = shift ;
	$pen ||= {} ;
	$path ||= $pen->{request} ;

	my @path = fromFQPath( $path ) ;

	## special variables $DOCS && $follow are historical
	$pen->{path} ||= $path[0] ;
	$DOCS = $pen->{path} ;
	$pen->{request} ||= $path[1] ;
	$follow = $pen->{request} ;

	include( $path || $pen->{request} ) ;
	return bless {}, __PACKAGE__ ;
	}

sub defaultdocs {
	return filePath( @_ ) ;
	}

sub filePath {
	return join '/', @_ if $_[0] =~ m|^/| ;
	return join '/', $pen->{path}, @_ ;
	}

sub fromFQPath {
	my @path = split m|/|, pathHack( $_[0] ) ;
	my $fn = pop @path ;
	my $path = join '/', @path ;
	return ( $path, $fn ) ;
	}

sub include {
	my $fn = shift ;
	my $skip = @_? shift @_: 0 ;

	## hopefully something else barks first...
	return if scalar @fh > 40 ;

	$fn = filePath( $fn ) ;

	my $fh = new FileHandle pathHack( $fn ) ;
	return unless defined $fh ;
	push @fh, $fh ;

	scalar <$fh> while ( $skip-- ) ;
	while (<$fh>) {
		&parseLine( $_ ) ;
		}

	pop @fh ;
	skip( 0 ) ;
	return comment() ;
	}

sub do {
	my $fn = shift ;
	$fn = filePath( $fn ) ;
	do $fn ;
	return @_? $@ || $!: undef ;
	}

## Given a symlink: ln -s /tmp/foobar foo/bar
## 'foo/bar/..' may resolve to '/tmp' instead of 'foo'
## pathHack explicitly performs the following conversion:
## /the/quick/../brown/fox  =>  /the/brown/fox

sub pathHack {
	my $path = shift ;

	my @tokens = ( '' ) ;
	foreach ( grep $_, HTML::Pen::Utils::split( $path, '/' ) ) {
		push @tokens, '' unless $_ eq '/' ;
		$tokens[-1] .= $_ ;
		}

	my @rv = () ;
	foreach ( grep $_, @tokens ) {
		s|//+|/|g ;
		push @rv, $_ unless $_ eq './' || $_ eq '../' ;
		pop @rv if $_ eq '../' ;
		}

	return join '', @rv ;
	}

sub innerParse {
	my $html = shift ;

	my @perlfun = HTML::Pen::Utils::split( $html, '&[a-zA-Z0-9_:]*\(' ) ;
	return @perlfun if @perlfun == 1 ;

	my @tokens = grep $_, map { HTML::Pen::Utils::split( $_, '<[^<]+' ) }
			@perlfun ;

	my @out = ( '' ) ;
	while ( $#tokens > 1 ) {
		last if $tokens[1] =~ /^&[a-zA-Z0-9_:]*\($/ ;
		$out[0] .= shift @tokens ;
		}
	
	push @out, [ [ splice @tokens, 0, 2 ] ] ;
	@tokens = grep $_, HTML::Pen::Utils::split( join( '', @tokens ), 
			'&[a-zA-Z0-9_:]*\(', '[\(\)>]' ) ;
	
	tag: while ( @tokens ) {
		for ( my $balance = 0 ; @tokens ; ) {
			if ( $tokens[0] eq ')' && ! $balance ) {
				shift @tokens ;
			last ;
				}
		
			$balance += $tokens[0] eq '('? 1:
					$tokens[0] eq ')'? -1: 0 ;
			$out[1][-1][2] .= shift @tokens ;
			}
	
		push @{ $out[1] }, [ '' ] ;
		unshift @tokens, '' if $tokens[0] =~ /^&[a-zA-Z0-9_:]*\($/ ;
		while ( @tokens > 0 && $tokens[0] !~ /^&[a-zA-Z0-9_:]*\($/ ) {
			my $t = shift @tokens ;
			$out[1][-1][0] .= $t ;
			last tag if $t eq '>' ;
			}
	
		warn "Parsing Error" unless @tokens ;
		push @{ $out[1][-1] }, shift @tokens ;
		}
	
	push @out, join '', @tokens ;
	return @out ;
	}

sub parseLine {
	$T3 = shift ;

	return if $skipct-- ;
	return unless $crashlimit-- > 0 ;

	$skipct = 0 ;

	while ( $T3 ) {
		( $T1, $T2, $T3 ) = innerParse( $T3 ) ;

		print $T1 ;
		my $noembed = $T2->[0][0] =~ /<\s*:/ 
				|| $T2->[0][0] =~ /<!--\s*:/ 
				if $T2 && ref $T2 && @$T2 ;

		foreach my $t ( @$T2 ) {
			my @t = map { $t->[$_] || '' } ( 0..2 ) ;

			print $t[0] unless $noembed ;
			$t[1] =~ s/^.(.*).$/$1/ if $t[1] ;
			print evaluate( $t[1]?
					sprintf( "&%s( %s )", @t[ 1, 2 ] ):
					$t[2] ) 
					if $t[1] || $t[2] ;
			}
		}
	}

my $evalhead =<<EOF ;
package HTML::Pen ;
no strict 'vars' ;
no strict 'subs' ;
EOF

sub eval {
	return evaluate( @_ ) ;
	}

sub evaluate {
	my $rv = eval join "\n", $evalhead, @_ ;
	logError( $@ ) ;
	return $rv || $undef ;
	}

sub evalError {
	my $rv = eval join "\n", $evalhead, @_ ;
	evalError( $@ ) ;
	return $@ || $rv || $undef ;
	}

sub logError {
	my $error = shift ;
	return unless $error && $pen->{errorlog} ;

	my $fh ;
	open $fh, '>> ' .$pen->{errorlog} or return ;
	print $fh $error ;
	close $fh ;
	return ;
	}

sub evalBlock {
	evaluate( @_ ) ;
	return undef ;
	}

sub evalblock {
	return evalBlock( @_ ) ;
	}

sub undef {
	evaluate( @_ ) ;
	return undef ;
	}

sub comment {
	$skipct = $_[0] *1 if @_ ;
	return undef $T3 ;
	}

sub skip {
	return comment( @_ ) ;
	}

sub is {
	skip() unless $_[0] ;
	return undef ;
	}

sub encode {
	my $text = shift ;
	$text =~ s|([^0-9A-Za-z\. ])|sprintf "%%%02X", ord($1)|seg ;
	$text =~ s/ /+/g ;
	return $text ;
	}

sub printf {
	map { printf $T3, isRefType( $_ => 'ARRAY' )? @$_: $_ } @_ ;
	return comment() ;
	}

sub isRefType {
	my $ref = shift ;
	my $type = shift ;

	return undef unless ref $ref ;
	my @primitive = grep ref $ref eq $_, qw( SCALAR ARRAY HASH GLOB ) ;
	return $primitive[0] eq $type if scalar @primitive ;
	return $ref->isa( $type ) ;
	}

sub block {
	return 'missing argument: block()' unless @_ ;

	my $ref = shift ;
	my $blockend = shift ;
	$blockend ||= $pen->{blockend} ;

	return 'missing end: script()' unless $blockend ;

	my $fh = $fh[ -1 ] ;
	my $arrayref ;

	if ( ref \$ref eq 'GLOB' ) {
		use vars qw( @glob ) ;
		local( *glob ) = $ref ;
		$arrayref = \@glob ;
		}
	elsif ( isRefType( $ref => 'ARRAY' ) ) {
		$arrayref = $ref ;
		}
	elsif ( isRefType( $ref => 'SCALAR' ) ) {
		$arrayref = $$ref = [] ;
		}
	else {
		return 'bad argument: block()' ;
		}

	@$arrayref = () ;
	defined $fh or return undef ;
	while ( my $line = <$fh> ) {
		last if $line =~ /^$blockend\b/ ;
		push( @{ $arrayref }, $line ) ;
		}

	return comment() ;
	}

sub evalLine {
	evalBlock( $T3 ) ;
	return comment() ;
	}

sub evalline {
	return evalline( @_ ) ;
	}

sub script {
	my $blockend = shift ;
	$blockend ||= $pen->{blockend} ;
	return 'missing end: script()' unless $blockend ;

	my $block = [] ;
	block( $block, $blockend ) ;
	return evalBlock( @$block ) ;
	}

sub displayBlock {
	map { parseLine( $_ ) } @_ ;
	return undef ;
	}

sub displayblock {
	return displayBlock( @_ ) ;
	}

sub loadBlock {
	my $scalarref = isRefType( $_[0] => 'SCALAR' )? shift @_:  undef ;
	my $out ;

	my $fh = eval { return *H } ;
 	open( $fh, '>', $scalarref? $scalarref: \$out ) ;
	my $stdout = select $fh ;

	displayBlock( @_ ) ;

	select $stdout ;
	close $fh ;
	return $scalarref? undef: $out ;
	}

sub loadblock {
	return loadBlock( @_ ) ;
	}

sub mailBlock {
	return unless $pen->{mailprogram} ;

	my $fh = eval { return *H } ;
 	open( $fh, '|', $pen->{mailprogram} ) ;
	my $stdout = select $fh ;

	displayBlock( @_ ) ;

	select $stdout ;
	close $fh ;
	return undef ;
	}

sub mailblock {
	return loadBlock( @_ ) ;
	}

## TODO:
sub emailBlock {
#	my $fh = eval { return *H } ;
#	open $fh, "| $sendmail -t" ;
#	my $stdout = select $fh ;

	displayBlock( @_ ) ;

#	select $stdout ;
#	close $fh ;
	return undef ;
	}

sub emailblock {
	return emailBlock( @_ ) ;
	}

sub iterator {
	my $globarg = shift ;
	return 'missing GLOB argument: iterator()'
			unless ref \$globarg eq 'GLOB' ;

	use vars qw( @glob $glob ) ;
	local( *glob ) = $globarg ;

	if ( ! @_ ) {}
	elsif ( @_ == 1 && isRefType( $_[0] => 'ARRAY' ) ) {
		@glob = @{ $_[0] } ;
		}
	else {
		@glob = @_ ;
		}

	$glob = \@glob ;
	return undef ;
	}

sub iterate {
	my $globarg = shift ;
	return 'missing GLOB argument: iterate()' 
			unless ref \$globarg eq 'GLOB' ;

	use vars qw( @glob $glob ) ;
	local( *glob ) = $globarg ;
	return undef unless isRefType( $glob => 'ARRAY' ) ;

	my @elements = @$glob ;
	my @block = @_ == 1 && isRefType( $_[0] => 'ARRAY' )? @{ $_[0] }: @_ ;

	foreach my $element ( @elements ) {
		foreach ( @block ) {
			$glob = $element ;
			parseLine( $_ ) ;
			}
		}

	return undef ;
	}

sub iteratorValue {
	my $iterator = shift ;
	my $key = shift ;
	my $ref = $iterator ;

	if ( ref \$iterator eq 'GLOB' ) {
		use vars qw( $glob ) ;
		local( *glob ) = $iterator ;
		$ref = $glob ;
		}

	return iteratorValue( $ref->[0], $key ) 
			if isRefType( $ref => 'ARRAY' ) ;
	return $ref->{ $key } 
			if isRefType( $ref => 'HASH' ) ;
	return $undef ;
	}

sub clear {
	my @protected = qw( ENV ISA EXPORT EXPORT_FAIL EXPORT_TAGS EXPORT_OK 
			VERSION ) ;
	my $cmd = "" ;

	foreach my $v ( values %HTML::Pen:: ) {
		next if grep *{ $v }{NAME} eq $_, @protected ;

		my $scalar = *{ $v }{SCALAR} ;
		my $name = join '', 'HTML::Pen::', *{ $v }{NAME} ;
		next if $name =~ /::$/ ;

		$cmd .= "undef \$$name; " if defined $$scalar ;
		$cmd .= "undef \@$name; " if defined *{ $v }{ARRAY} ;
		$cmd .= "untie \%$name; " if defined *{ $v }{HASH}
				&& eval "tied \%Pen::$name" ;
		$cmd .= "undef \%$name; " if defined *{ $v }{HASH} ;
		}

	eval $cmd ;
	return undef ;
	}

sub DESTROY {
	clear() ;
	}

1
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Pen - Perl Embedding Notation (Yet another parser for embedding Perl in HTML)

=head1 SYNOPSIS

  use Pen ;
  Pen->new( $htmlfilename ) ;
  Pen->new( $htmlfilename, { path => ..., blockend => ..., errorlog => ... } ) ;
  Pen->new( { request => ..., path => ..., blockend => ..., errorlog => ... } ) ;

=head1 DESCRIPTION

Pen performs simple in-line substitution of Perl code.  Its syntax is
consistent with SGML and HTML, but can be used on any file type.  

Pen recognizes the following syntax as a Perl expression and performs a
literal interpretation.

    &subroutine( args1, args2 )

The entire expression is replaced by the subroutine's return value.  The
syntax reflects a usage which distinguishes defined subroutines from Perl's 
internal functions.  For example,

    &join( '/', @path )

=over 2

fails unless C<join()> is explicitly defined.  Some predefined functions
deliberately overlap with internal functions, for example, C<eval()> and
C<undef()>.  In this documentation, the term I<subroutine> reflects 
an explicit definition using Perl's I<sub> keyword and avoids ambiguity 
with internal Perl functions.

=back

Pen functions C<eval()> and C<undef()> are the most basic.  Everything 
delimited by the parentheses is interpreted as a Perl expression.  
C<eval()> returns output and C<undef()> does not.

The subroutine expression must be enclosed within an SGML or HTML tag.
The following defines two complete Perl expressions in Pen:

    <!-- &eval( 'Hello World' ) -->
    <td style="background: &eval( $rowct++ %2? '#ffffff': '#cccccc' )">

=over 2

returns

=back

    <!-- Hello World -->
    <td style="background: #cccccc">

Both of these examples demonstrate how Pen performs in-line substitution.
As HTML, the first example is pretty useless.  But the second example 
demonstrates Pen's effectives for granular in-line substitution.

The colon switch changes the substitution pattern to slurp everything
between the E<lt>E<gt> delimiters.

    <!--: &eval( 'Hello World' ) -->
    <: testing &eval( 'Hello World' )>
    <: &( 'Hello World' )>

=over 2

returns three identical lines:

=back

    Hello World
    Hello World
    Hello World

The first example hides the Perl expression inside an SGML comment, which
may be useful for WYSIWYG editors.  The second example demonstrates that
the SGML comment formatting is optional, and includes the term I<testing>
to underscore everything that the Pen interpreter discards.  And the third 
example illustrates that the C<eval()> subroutine can be invoked implicitly.

Everything is processed within the Pen name space.  Non-localized variables
persist until the constructor is destroyed, normally at the end of the
document.  Then the entire Pen namespace is cleared.  Nothing persists after
the HTTP transaction is complete.

=head1 FUNCTIONS

The Pen package predefines the following subroutines:

=head2 eval I<or> evaluate

C<eval()> takes a Perl expression as an argument, with no delimiters other
than the subroutine parentheses.  The output, which replaces the in-line
expression, is the evaluated result.

If the expression fails, nothing is returned.  The error is written into the
file specified by the I<errorlog> definition in the constructor, or 
C<< $pen->{errorlog} >>.

=head2 evalError

C<evalError()> is nearly identical, except it returns any thrown errors.

=head2 undef

Many Perl expressions return a value as a side effect.  For example,

    <: &( $ctr = 0 )>

=over 2

returns

=back

    0

The following two lines illustrate alternative solutions that print no
output:

    <: &( $ctr = 0 ; undef )>
    <: &undef( $ctr = 0 )>

=head2 include

The C<include()> subroutine performs like the traditional SSI 
directive, and outputs a separate file as an in-line substitution.  Its 
argument is either a file name with a fully qualified path, or a filename
whose path is supplied to the constructor, stored as C<< $pen->{path} >>.

C<include()> takes a positive integer as an optional second argument.
Pen will skip this number of lines at the beginning of the included file.  
This option makes it possible to include the same file in a variety of 
contexts if the included file starts with a series of C<skip()> directives.

=head2 do

C<do()> also takes a file argument and interpretes that file directly as 
Perl script.  

C<do()> takes an optional boolen as a second argument.  If true, any 
encountered errors will be returned.

=head2 filePath

C<filePath()> takes a file name as an argument and returns its fully 
qualified path, using C<< $pen->{path} >> if necessary.

=head2 comment

Pen processes files line by line.  Enclosing HTML or SGML brackets must be
on a single line, as is common practice.  Several Pen functions operate 
on lines of text.

For example, C<comment()> slurps the remainder of the line.

=head2 skip

C<skip()> slurps the remainder of the line plus an additional
number of lines as specified by its argument.  C<skip( 0 )> is 
equivalent to C<comment()>, used to swallow linefeeds for fussy 
file formats other than HTML.  Another idiom, C<skip( -1 )> slurps
all remaining lines in the current file.

C<skip()> should be used carefully.  Any argument greater than two
or three becomes a headache.  See the C<block()> subroutine as an
alternative.  C<skip()> is a useful tool for commenting multiple
lines and also provides if/then functionality.

    <: &is( ! ref $users->{$userid} )><: &skip(2)>
      Welcome <: &( $users->{$userid}->{name} )>!
    <: &skip(1)>
      Unknown User

=head2 evalLine

Two commands take the line remainder as part of the argument as shown in these examples:

    <: evalLine()>print "Hello World"

=over 2

returns

=back

    Hello World

=head2 printf

C<printf()> returns a line for each element in its array argument,  This 
argument can be a one or two dimensional array.  An example of a two 
dimesional array:

    <: &undef( @data = ( [ -1 => 'New User' ], [ 1 => 'Jim S' ] ) )>
    <: printf( @data )><select value="%s">%s</select>

=over 2

outputs

=back

    <select value="-1">New User</select>
    <select value="1">Jim S</select>

=head2 block

C<block( *BLOCK, 'end' )> also slurps lines and saves them as a specified
array.  The first argument is an array reference.  The glob style reference 
is easiest to use.  The second argument is the closing delimiter, that appears 
immediately after the specified lines.  This delimiter must be at the beginning of the line and followed by optional whitespace.  The delimiter argument is
optional if C<< $pen->{blockend} >> is defined.

    <: &block( *BLOCK, 'end' )><!--
    the
    quick
    brown
    fox
    jumps
    end --></code>

This block of code prints out absolutely nothing  and creates the array
C<@BLOCK> consisting of 5 one word lines.  Note each element
corresponds to a line of text, including the terminating newline.  C<block()> 
is intended to reuse portions of the file.  Here's a common example:

=head2 displayBlock

    <: &block( *BADLOGIN, 'end' )><!--
      <script type="text/javascript">
        alert( "Invalid Login" ) ;
        location.back() ;
      </script>
    end -->
    <: &is( ! ref $users->{$userid} )><: &displayBlock( @BADLOGIN )>

Blocks of HTML and, in particular, Pen HTML, are useful for conditionally 
displaying content.  The C<iterate()> subroutine is used to display
a block repeatedly over a data set.

=head2 evalBlock

There are 3 techniques for representing Perl script in a Pen document.

=over

=item 1. Inline, evaluating a single subroutine or expression

=item 2. Using C<do()> to evaluate an entire Perl script file.

=item 3. Defining multiple lines of script as a block.

=back

The last technique is implemented as follows:
  
    <: &block( *PERL, 'end' )><!--
      use Pen::ContentManager ;
      $doc = new Pen::ContentManager $docid ;
      @pages = $doc->pages() ;
    end -->

Use C<evalBlock()> to process a block of script:

    <: &evalBlock( @PERL )>

=head2 script

C<script()> combines definition and evaluation of the block script.  
This example requires that C<< $pen->{blockend} >> be defined, normally as
an argument to the constructor.

    <: &script()><%
      use Pen::ContentManager ;
      $doc = new Pen::ContentManager $docid ;
      @pages = $doc->pages() ;
    %>

=head2 mailBlock

Pen makes it easy to send email from a website.  C<mailBlock()>
demonstrates a simple implementation.  The email headers are embedded inside
the block:

    <: &block( *EMAIL, 'end' )><!--
    To: "<: &( $$user{firstname}.' '.$$user{lastname} ) )>" <: &skip(0)>
    <&( $$user{email} )>
    From: "Do Not Reply" <noreply@tqis.com>
    Subject: Confirmation of your website visit

    <: &include('confirmation.txt')>
    end -->

    <: &mailBlock( @EMAIL )>

The interpreted block can be piped into any application defined by the
I<mailprogram> configuration, C<< $env->{mailprogram} >>.

=head2 loadBlock

Mime::Lite is a useful tool for sending email as an HTML attachment.  
C<loadBlock()> dumps the Pen output into a referenced variable
instead of printing it to the output stream:

    <: &block( *HTML, 'end' )><!--
    <: &include( 'confirmation.htm' )>
    end -->

    <: &loadBlock( \$html, @HTML )>

=over

or

=back

    <: &( $html = loadBlock( @HTML ) )>

    <: &( $mime->attach( $html, 'text/html' ) )>


=head2 iterate

C<iterate()> takes two arguments.  The first is an B<iterator>; the second 
a block array.  The B<iterator> is a glob that represents a data array.
The block is is interpreted repeatedly over each data element.

=head2 iterator

Now somewhat archaic, B<globs> provide an alternative technique 
for passing a variable by reference.  For example, the two statements below 
are equivalent:

    <: &block( *EVENT )>
    <: &block( \@EVENT )>

(Uppercase names are recommended for block definitions.)

A Pen iterator is always passed as a glob.  An iterator must be declared
using the C<iterator> subroutine, which also defines the iterator with
additional arguments: either array elements or an array reference:

    <: &iterator( *event, @data )>
    <: &iterator( *event, \@data )>

Although not strictly a reference, either defintion has the effect: 
C<@event = @data>.

The most simple example is an interator representing an array of scalars:

    ( @states = qw( Alabama .. Wyoming ) )

    <: &iterator( *states, @states )>

In this case, since I<*states> is already the glob equivalent of the second
argument I<@states>.  C<iterator()> can be called as a declaration with a
single argument:

    <: &iterator( *states )>

Here's the rest of the example:

    <: &block( *SELECT, 'end' )><!--
      <option><: &( $states )></option>
    end -->
    <: &iterate( *states, @SELECT )>

C<iterator()> references each data set element as the scalar version of the 
glob.  Since the glob is C<*states>, each element is accessed as
a scalar with the same name, C<$states>.

As a slightly more complicated example, define @states this way:

    @states = ( [ AL => "Alabama" ] .. [ WY => "Wyoming" ] )

    <: &iterator( *states )>
    <: &block( *SELECT, 'end' )><!--
      <option value="&( $$states[0] )"><: &( $$states[1] )></option>
    end -->
    <: &iterate( *states, @SELECT )>

=over

Or if each element is a hash reference:

=back

    <: &block( *SELECT, 'end' )><!--
      <option value="&( $$states{abbreviation} )">
        <: &( $$states{name} )></option>
    end -->
    <: &iterate( *states, @SELECT )>

Regardless of whether the data set elements are scalars or referenced data 
structures, a one dimensional array is fairly easy to implement as an
iterator.

Iterators are designed to handle multi-dimensional arrays as well.  To display 
the 50 states in a table of 10 rows and 5 columns, first construct a tabular
data set, then define an HTML table consisting of a block of rows and a
block of columns:

    <: &script('end')><%
      @states = qw( Alabama .. Wyoming ) ;
      @table = () ;
      push @table, [ splice @states, 0, 5 ] while @states ;
      iterator( *states, @table ) ; ## warning: obliterates @states
    end %>

    <: &block( *COLUMN, 'end' )><%
      <td><: &( $states )></td>
    end %>

    <: &block( *ROW, 'end' )><%
      <!-- &( $states ) - displays "ARRAY(0xa19b0a8)" -->
      <tr><: &iterate( *states, @COLUMN )></tr>
    end %>

    <table>
      <: &iterate( *states, @ROW )>
    </table>

This example illustrates blocks that are nested to correspond with the data
set, in parent-child relationships.  Each block recurses by calling
C<iterate()> with the common iterator and the name of the child 
block.

L<HTML::Pen::Iterator> illustrates a relatively sophisticated example of a 
4 dimensional data set calendar to be presented as a table.  The iterator data 
consists of an array of weeks; each week consists of an array of days; each 
day consists of an array of times; each time consists of an array of events.  
Each event is represented by an event object that is a blessed hash reference.

With a Pen iterator, the rendering code is a few simple lines of HTML.  The
complexity is absorbed in the data structure, which should be defined as
follows:

  \@week -> \@day -> \@time -> \%event

In this example, each day has an integer property (1-31) and each time 
object has a property (hh::mm) which cannot be included within an array 
definition.  The solution is for each event object to inherit all the 
properties of its forebears, so that it includes both day and time 
values.

=head2 iteratorValue

The advantage of this approach is that every recursion can access the 
same property values, regardless of its position in the stack, by 
calling C<iteratorValue()>.  This subroutine takes the iterator as its 
first argument, and a property string as its second.  C<iteratorValue()> 
returns the corresponding value of the bottom-most hash object.

The disadvantage is that every object's properties are replicated across 
all its descendents. The redundancy cost in the size of the data footprint
may be quite high.  Alternatively, define each object as a hash reference,
and maintain its descendents in an array reference named I<elements>.  Then
redefine the scalar before calling C<iterate()>:

    <: &comment()><!-- for every block -->
    <: &undef( $event = $event->{elements} )>
    <: &iterate( *event, @CHILDBLOCK )>

Note: C<iteratorValue()> is not extended to cover these more complex
data structures.

When C<iterate()> is called, the scalar representation of the iterator 
glob must be an array reference or the subroutine does nothing.  This 
mechanism ensures that no output is displayed for empty data sets. 

=head1 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
