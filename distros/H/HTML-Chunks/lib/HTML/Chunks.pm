package HTML::Chunks;

use strict;

our $VERSION = '1.55';

use constant DATA_REGEX => qr/##[\w\.]+##/;

sub new
{
	my $self = bless {}, shift;

	$self->init(@_);
	return $self;
}

sub init
{
	my $self = shift;

	$self->{crush}     = 1;
	$self->{cascade}   = 1;
	$self->{dataStack} = [];
	$self->{chunk}     = {};
	$self->{default}   = undef;
	
	$self->read(@_) if @_;
}

sub readChunkFile
{
	my $self = shift;

	foreach my $file (@_) {
		if (my $fh = $self->getFilehandle($file)) {
			my @chunkStack;
			
			while (my $line = <$fh>) {
				$self->parse(\@chunkStack, \$line);
			}
			close $fh;
		}
		else {
			warn "Can't open file [$file]\n";
		}
	}
}

sub readSimpleFile
{
	my $self = shift;

	foreach my $file (@_) {
		if (my $fh = $self->getFilehandle($file)) {
			while (<$fh>) {
				next if /^#/ or !/\S/;
				
				s/[\r\n]//g;
				s/^\s+|\s+$//g;
				
				my ($name, $chunk) = split(/\s+/, $_, 2);
				if ($name && $chunk) {
					$self->addNamedChunk($name, $chunk);
				}
			}
			close $fh;
		}
	}
}

sub getFilehandle
{
	my $self = shift;
	my ($file) = @_; 
	
	return $file if ref $file; # already a filehandle
	return open (CHUNKIN, $file) ? \*CHUNKIN : undef;
}
	
sub addChunk
{
	my $self = shift;

	foreach my $chunk (@_) {
		next unless $chunk;
		
		# allow a ref to be passed for efficiency
		my $ref = ref $chunk ? $chunk : \$chunk;
		$self->parse([], $ref);
	}	
}

sub addNamedChunk
{
	my $self = shift;
	my ($name, $chunk) = @_;
	
	return unless ($name && $chunk);
	
	# allow a ref to be passed for efficiency
	my $ref = ref $chunk ? $chunk : \$chunk;
	$self->{chunk}{$name} = undef;
	$self->parse([ \$self->{chunk}{$name} ], $ref);
}

sub parse
{
	my $self = shift;
	my ($chunkStack, $data) = @_;
	my $chunk = $chunkStack->[-1];
	
	# allow a ref to be passed for efficiency
	my $dataRef = ref $data ? $data : \$data;

	foreach (split(/(<!--.*?-->)/, $$dataRef)) {
		if (/<!--\s*BEGIN\s+([\w\.]+)\s+-->/i) {
			$self->{chunk}{$1} = undef;
			push @{$chunkStack}, $chunk = \$self->{chunk}{$1};
		}
		elsif ($chunk && /<!--\s*END\s+.*-->/i) {
			$$chunk =~ s/\s{2,}/\n/sg if $self->{crush}; # crush whitespace
			pop @{$chunkStack};
			$chunk = $chunkStack->[-1];
		}
		elsif ($chunk && ($_ || !$self->{crush})) {
			$$chunk .= $_;
		}
	}
}

sub output
{
	my $self = shift;
	my $name = shift;

	$self->outputAsChunk(\$self->{chunk}{$name}, @_);
}

sub outputAsChunk
{
	my $self  = shift;
	my $chunk = shift;
	my $data  = shift;

	if ($chunk) {
		my $chunkRef = ref $chunk ? $chunk : \$chunk;
		$data ||= {};
		
		push @{$self->{dataStack}}, $data;
		$self->outputBasicChunk($chunkRef, @_);
		pop @{$self->{dataStack}};
	}
}

# basic chunk output including data substitution, using data already
# on the data stack.
sub outputBasicChunk
{
	my $self = shift;
	my $chunk = shift; 
	my $chunkRef = ref $chunk ? $chunk : \$chunk;
	my $data_regex = $self->DATA_REGEX;

	foreach my $piece (split(/(<!--\s*$data_regex\s*-->|$data_regex)/, $$chunkRef)) {
		if ($piece =~ /($data_regex)/) {
			$self->outputData(substr($1, 2, -2), @_);
		}
		else {
			print $piece;
		}
	}
}

sub outputData
{
	my $self = shift;
	my $name = shift;
	my $value = $self->getDataValue($name);
	
	if (ref $value eq 'CODE') {
		&{$value}($self, $name, @_);
	}
	else {
		print $value;
	}
}

sub getDataValue
{
	my ($self, $name) = (shift, shift);
	my $value;
	my $last = $self->{cascade} ? 0 : $#{$self->{dataStack}};
	
	for (my $ndx = $#{$self->{dataStack}}; $ndx >= $last; $ndx--) {
		if (exists($self->{dataStack}[$ndx]{$name})) {
			$value = $self->{dataStack}[$ndx]{$name};
			last;
		}
	}
	
	if ($value eq '') {
		return $self->{default};
	}
	else {
		return $value;
	}
}

sub getChunkNames
{
	my $self = shift;
	return keys %{$self->{chunk}};
}

sub getChunk
{
	my $self = shift;
	my ($name) = @_;
	
	return $self->{chunk}{$name};
}

sub getChunkHash
{
	my $self = shift;
	return { %{$self->{chunk}} };
}

sub setCrush
{
	my $self = shift;
	my $old = $self->{crush};
	($self->{crush}) = (@_);
	return $old;
}

sub setCascade
{
	my $self = shift;
	my $old = $self->{cascade};
	($self->{cascade}) = (@_);
	return $old;
}

sub setDefaultDataValue
{
	my $self = shift;
	($self->{default}) = (@_);
}

# legacy wrappers for backward compatibility

sub crush
{
	my $self = shift;
	return $self->setCrush(@_);
}

sub read
{
	my $self = shift;
	$self->readChunkFile(@_);
}

1;

__END__

=pod

=head1 NAME

HTML::Chunks - A simple nested template engine for HTML, XML and XHTML

=head1 VERSION

1.53

=head1 DESCRIPTION

This class implements a simple text-based template engine, originally
intented to allow web applications to completely separate layout HTML from
programming logic.  However, the engine is flexible enough to be applied
to other text-based situations where templates are helpful, such as
generating email messages, XML data files, etc.

=head1 SYNOPSIS

 my $engine = new HTML::Chunks(@chunkFiles);

 $engine->readChunkFile('morechunks.html');
 $engine->addChunk($smallChunk, \$hugeChunk);
 $engine->addNamedChunk('myChunk', $chunk);
 
 $engine->output('myChunk', {
   firstName => 'Homer',
   lastName => 'Simpson',
   meals => \&outputMeals
 }, @extraData);

 my @names = $engine->getChunkNames();
 my $chunk = $engine->getChunk('myChunk');
 my $oldValue = $engine->setCrush(0);
 
=head1 CHUNK SYNTAX

This template engine is based upon "chunks", which are merely named
chunks of textual information such as HTML.  Each chunk may be individually
addressed by an application to produce output.  A chunk definition may also
contain data elements which will be replaced with dynamic data at
runtime.  A simple chunk definition looks like:

 <!-- BEGIN meal -->
 <tr>
   <td>##date##</td>
   <td>##food##</td>
 </tr>
 <!-- END -->

This defines a chunk named I<meal>.  This chunk contains two data elements
named I<date> and I<food>.  These will both be replaced with real data by
the application at runtime.  The leading and trailing ## characters simply
identify them as data elements and are not part of the actual names.

Chunk definitions can even be embedded within one another.  It's possible
(and recommended!) to construct a definition file as a full HTML file that
you can preview in a web browser.  Embedding one chunk definition within
another does not imply any association or positional placement between the
two chunks.  Things would turn out the same if you put the definitions in
a straight list, one after another.  Embedding is just a cool formatting
convenience that you can choose to take advantage of -- or not.

You may optionally surround a data element with HTML comment characters
so it won't show up when previewing a chunk file in a browser.  For this
to work, the data element must be the only thing in the comment, such as:

 <!-- ##data## -->

The entire comment will be replaced with the data value at run time, so
the resulting data will I<NOT> be within a comment.

See the I<EXAMPLES> section below for a sample.

=head1 ROUTINES

=over

=item my $engine = new HTML::Chunks(@files);

Constructs a new chunk engine object and reads any supplied chunk files.

=item $engine->readChunkFile(@files);

Reads the specified chunk definition files.

=item $engine->readSimpleFile(@files);

Reads chunk definitions from an alternate simpler file format.  This
should only be used for defining very short chunks with minimal HTML.
It comes in very handy for small configuration elements.  The format
allows one definition per line, with each line containing the chunk name
followed by any amount of whitespace followed by the chunk definition.

For example:

  imageURL    http://images.myserver.com/
  errorMsg    Awooga!  Something has gone haywire!

=item $engine->addChunk(@chunks);

Defines new chunks according to the definitions contained in the supplied
list.  Each member of the list must hold at least one full chunk
definition, complete with BEGIN/END statements.  The list may contain
simple string scalars or references to scalars.  References are handy
if you have a large chunk loaded and wish to conserve memory.

=item $engine->addNamedChunk($name, $chunk);

Defines a new chunk named I<$name>.  The chunk definition contained in
I<$chunk> does not need the outer set of BEGIN/END statements since the
name is already specified.  This comes in handy when you are reading
chunk definitions from a database column and don't want to bother with
redundant embedded BEGIN/END statements for each row.  I<$chunk>
may be either a scalar or reference to a scalar.  References are handy
if you have a large chunk loaded and wish to conserve memory.

=item my @names = $engine->getChunkNames();

Returns a list of defined chunk names.

=item my $chunk = $engine->getChunk($name);

Returns the body of a defined chunk named I<$name>.  You I<rarely>
need to do this, and we strongly discourage bypassing the I<output>
routine and printing the chunk body directly.  However, this can
come in handy on occasion.  For example, you might write a utility
that lets the engine load/parse chunk definitions and then inserts
them individually into a database.

=item $engine->output($name, \%data, @extraInfo);

Outputs the body of the chunk named I<$name> to the currently selected
filehandle.  The I<%data> hash is used to expand any data elements
encountered in the chunk.  The keys in I<%data> should be the data
element names without the leading and trailing ## characters.  The
hash values are either simple scalars containing a data value or a
subroutine reference.  For example:

 $engine->output('chunk', {
   firstName => 'Homer',
   lastName => 'Simpson',
   meals => \&outputMeals
 }, $userID);  

When the engine encouters the I<meals> data element, it will call
the I<outputMeals> subroutine.  I<outputMeals> would then be responsible
for outputting the data for data element I<meals>, preferably by
performing some snazzy logic and then outputting another chunk.

Every data subroutine is called by the engine in the following way:

 dataRoutine($engine, $elementName, @extraInfo);
 
So, the I<outputMeals> example above would be invoked as:

 outputMeals($engine, 'meals', $userID);

=item my $oldValue = $engine->setCrush(0);

Sets whether the engine crushes whitespace within chunks or not.
Accepts one parameter that is treated as a boolean (true/false).
The default is on, which is recommended for HTML applications.
If you are using chunks for something whitespace sensitive like
email generation, you should turn this off to have chunks output
exactly as they are defined.

=item my $oldValue = $engine->setCascade(0);

Sets whether or not the engine lets data cascade into nested
calls to I<output>.  For instance, if you output a chunk from
within a data element handling routine, any data that was
defined for the parent chunk will also be available to the
chunk currently being output.  If that doesn't make sense,
don't worry about it.  It's rare that you'd want to turn this
behavior off.  This setting is enabled by default.

=back

=head1 EXAMPLES

Complete separation of code and layout is fairly new to most
people, and the chunky way of life does require a little shift
in your thinking.  However, once you dig it, this can be a
very powerful and productive way to develop.  A more complete
example might help you get there.

Consider the following chunk definition:

 <!-- begin mealPage -->
 <html>
 <head>
   <title>Meal List</title>
 </head>
 <body>
   <h1>Meal List for ##firstName##</h1>

   <table border="1">
     <tr>
       <th>Date/Time</th>
       <th>Food</th>
     </tr>

     <!-- ##meals## -->

     <!-- BEGIN meal -->
     <tr>
       <td>##date##</td>
       <td>##food##</td>
     </tr>
     <!-- END meal -->

   </table>

 </body>
 </html>
 <!-- end MealPage -->

Let's say this were in a file called I<meals.html>.  Because
we embedded some chunk definitions within others, you could
actually view it in a web browser and get a preview of things
to come.  Again, embedding one definition within another means
I<nothing>.  It is simply a formatting convenience to let you
construct chunk definition files that are also valid HTML files.

Now, a fairly small (but commented) script to do something with
it:

 use HTML::Chunks;
 use strict;
 
 # create a new engine and read our chunk definitions
 
 my $engine = new HTML::Chunks('meals.html');
 
 # output the main 'mealPage' chunk.  name information
 # is supplied with static text.  the 'meals' data element
 # is handled by the 'outputMeals' routine.
 
 $engine->output('mealPage', {
   firstName => 'Homer',
   lastName => 'Simpson',
   meals => \&outputMeals
 });
 
 # our first data element routine
 
 sub outputMeals
 {
   my ($engine, $element) = @_;
 
   # normally you would read this from a database but
   # this is easier for an example.
   
   my @meals = (
     [ '2001-09-09 08:15', 'One dozen assorted donuts' ],
     [ '2001-09-09 11:45', 'One giant sub sandwich' ],
     [ '2001-09-09 14:22', 'One bag of gummy worms' ],
     [ '2001-09-09 18:34', 'Bucket of BBQ' ]
   );
 
   # we output each meal using the 'meal' chunk.  simple.
   
   foreach my $meal (@meals)
   {
     $engine->output('meal', {
       date => $meal->[0],
       food => $meal->[1]
     });
   }
 }

=head1 SEE ALSO

For the adventurous, there is L<HTML::Chunks::Super>, a subclass of
HTML::Chunks with enhanced features.

=head1 CREDITS

Created, developed and maintained by Mark W Blythe and Dave Balmer, Jr.
Contact dbalmer@cpan.org or mblythe@cpan.org for comments or questions.

=head1 LICENSE

(C)2001-2009 Mark W Blythe and Dave Balmer Jr, all rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
