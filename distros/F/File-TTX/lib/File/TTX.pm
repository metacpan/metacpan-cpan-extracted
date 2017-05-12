package File::TTX;

use warnings;
use strict;
use XML::Snap;
use POSIX qw/strftime/;

=head1 NAME

File::TTX - Utilities for dealing with TRADOS TTX files

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

TRADOS has been more or less the definitive set of translation tools for over a decade; more to the point, they're the
tools I use most.  There are two basic modes used by TRADOS to interact with documents.  The first is in Word documents, which
is not addressed in this module.  The second is with TagEditor, which has TTX files as its native file format.  TTX files are
a breed of XML, so they're actually pretty easy to work with.

    use File::TTX;

    my $foo = File::TTX->load('myfile.ttx');
    ... do stuff with it ...
    $foo->write();
    
Each TTX consists of a header and body text.  The header contains various information about the file you can read and write;
the text is, well, the text of the document.  Before translation, the text consists of just plain text, but as you work TagEditor
I<segments> the file into segments, each of which is translated in isolation.  (The paradigm here is that if you re-encounter a
segment or something similar to one you've already done, the translation memory will provide you with the translation, either
automatically writing it if it's identical, or at least presenting it to you to speed things up if it's just similar.)

A common mode is to read things with a script, build a TTX, and write it out for translation with TagEditor.  Here's the kind
of functions you'd use for that:

   use File::TTX;

   my $ttx = File::TTX->new();

   $ttx->append_text("This is a sentence.\n");
   $ttx->append_mark("test mark");
   $ttx->append_text("\n");
   $ttx->append_text("This is another sentence.\n");

   $ttx->write ("my.ttx");
   
After translation, you can use the marks to find out where you are in the file (they'll be skipped during translation without
being removed from the file).

There are two basic modes for content extraction; either you want to scan all content, or you're just interested in the segments
so you can toss them into an Excel spreadsheet or something.  These work pretty much the same; to scan all elements, you use
C<content_elements> as follows; it returns a list of C<File::TTX::Content> elements, documented below, which are really just 
C<XML::Snap> elements with a little extra sugar for convenience.

   use File::TTX;
   my $ttx = File::TTX->load('myfile.ttx');
   
   foreach my $piece ($ttx->content_elements) {
      if ($piece->type eq 'mark') {
         # something
      } else {
         print $piece->translated . "\n";
      }
   }
   
To do a more data-oriented extraction, you'd want the C<segments> function, and the loop would look more like this:

   foreach my $s ($ttx->segments) {
      print $s->source . " - " . $s->translated . "\n";
   }
   
Clear?  Sure it is.

Here's another example: a filter to strip all pre-translated content out of a TTX in case you want a new, un-pre-translated copy.

   use File::TTX;

   my $in = $ARGV[0];
   my $outf = $in;
   $outf =~ s/\.xls\.ttx$/-stripped.xls.ttx/;

   my $ttx = File::TTX->load($in);
   my $out = File::TTX->new(from=>$ttx);

   foreach my $piece ($ttx->content_elements) {
      $out->append_copy ($piece->source_xml);
   }
   
   $out->write($outf);

It should be easy to see how you can expand that filter idea into nearly anything you need.

There are still plenty of gaps in this API! I plan to extend it as I run into new use cases. I'd be overjoyed to hear about yours.

=head1 CREATING A TTX OBJECT

=head2 new()

The C<new> function creates a blank TTX so you can build whatever you want and write it out.  If you've already got an XML::Snap
structure (that's the library used internally for XML representation here) then you can pass it in and it will be broken down
into useful structural components for the element access functions.

=cut

sub new {
   my ($class, %input) = @_;
   my $self = bless {}, $class;
   if ($input{'xml'}) {
      $self->{xml} = $input{'xml'};
   } else {
      $self->{xml} = XML::Snap->parse ('<TRADOStag Version="2.0"><FrontMatter><ToolSettings/><UserSettings/></FrontMatter><Body><Raw></Raw></Body></TRADOStag>');
   }
   $self->{file} = $input{'file'};
   $self->{'frontmatter'} = $self->{xml}->first ('FrontMatter');
   $self->{'toolsettings'} = $self->{frontmatter}->first ('ToolSettings');
   $self->{'usersettings'} = $self->{frontmatter}->first ('UserSettings');
   $self->{'body'} = $self->{xml}->first ('Raw');
   
   if ($input{'from'}) {
      $self->copy_header ($input{'from'});
      return $self;
   }

   my $lookup = sub {
      my ($field, $where, $default) = @_;
      return $input{$field} if $input{$field};
      return $self->{$where}->get ($field, $default);
   };
   
   $self->{toolsettings}->set ('CreationTool',        $lookup->('CreationTool',        'toolsettings', 'perl with File::TTX'));
   $self->{toolsettings}->set ('CreationDate',        $lookup->('CreationDate',        'toolsettings', $self->date_now));
   $self->{toolsettings}->set ('CreationToolVersion', $lookup->('CreationToolVersion', 'toolsettings', $VERSION));
   
   $self->{usersettings}->set ('SourceDocumentPath',  $lookup->('SourceDocumentPath',  'usersettings', ''));
   $self->{usersettings}->set ('O-Encoding',          $lookup->('O-Encoding',          'usersettings', 'windows-1252'));
   $self->{usersettings}->set ('TargetLanguage',      $lookup->('TargetLanguage',      'usersettings', 'EN-US'));
   $self->{usersettings}->set ('PlugInInfo',          $lookup->('PlugInInfo',          'usersettings', ''));
   $self->{usersettings}->set ('SourceLanguage',      $lookup->('SourceLanguage',      'usersettings', 'DE-DE'));
   $self->{usersettings}->set ('SettingsPath',        $lookup->('SettingsPath',        'usersettings', ''));
   $self->{usersettings}->set ('SettingsRelativePath',$lookup->('SettingsRelativePath','usersettings', ''));
   $self->{usersettings}->set ('DataType',            $lookup->('DataType',            'usersettings', 'RTF'));
   $self->{usersettings}->set ('SettingsName',        $lookup->('SettingsName',        'usersettings', ''));
   $self->{usersettings}->set ('TargetDefaultFont',   $lookup->('TargetDefaultFont',   'usersettings', ''));
   
   return $self;
}

=head2 load()

The C<load> function loads an existing TTX.  Said file will remember where it came from, so you don't have to give the
filename again when you write it (assuming you write it, of course).

TRADOS is nice enough to provide us with TTX that is illegal XML sometimes, so load() has to load your entire file into memory to 
sanitize it of illegal characters before the XML parser sees it.  This will unfortunately cause File::TTX to work from a different input
from TRADOS native tools, but as long as your TTX isn't generated from a Word document with soft hyphens in it, you ought to be OK.

=cut

sub load {
   my ($class, $file) = @_;
   my $xml = XML::Snap->load($file);
   $xml->bless_text;
   return $class->new(xml => $xml, file=>$file);
}

=head1 FILE MANIPULATION

=head2 write($file)

Writes a TTX out to disk; the C<$file> can be omitted if you used C<load> to make the object and you want the file to write
to the same place.

=cut

sub write {
   my ($self, $fname) = @_;
   $fname = $self->{file} unless $fname;
   
   my $file;
   open $file, ">:raw:encoding(UCS-2LE):crlf:utf8", $fname or croak $!;
   print $file "\x{FEFF}";  # This is the byte order marker; Perl would do this for us, apparently, if we hadn't
                            # explicitly specified the UCS-2LE encoding.
   print $file "<?xml version='1.0'?>\n";
   $self->{xml}->writestream($file);

   #$self->{xml}->write_UCS2LE($file);
}



=head1 HEADER ACCESS

Here are a bunch of functions to access and/or modify different things in the header.  Pass any of them a value to set that
value.

=head2 CreationTool(), CreationDate(), CreationToolVersion()

These are in the ToolSettings part of the header.  Mostly you don't care about them.

=cut

sub CreationTool        { $_[0]->{toolsettings}->set ('CreationTool',        $_[1]) }
sub CreationDate        { $_[0]->{toolsettings}->set ('CreationDate',        $_[1]) }
sub CreationToolVersion { $_[0]->{toolsettings}->set ('CreationToolVersion', $_[1]) }

=head2 SourceDocumentPath(), OEncoding(), TargetLanguage(), PlugInInfo(), SourceLanguage(), SettingsPath(), SettingsRelativePath(), DataType(), SettingsName(), TargetDefaultFont()

These are in the UserSettings part of the header.  Frankly, mostly you don't care about these either, but here we're getting
into the reason for this module, like writing a quick script to read or change the source and target languages of TTX files.

=cut

sub SourceDocumentPath   { $_[0]->{usersettings}->set ('SourceDocumentPath',   $_[1]) }
sub OEncoding            { $_[0]->{usersettings}->set ('O-Encoding',           $_[1]) }
sub TargetLanguage       { $_[0]->{usersettings}->set ('TargetLanguage',       $_[1]) }
sub PlugInInfo           { $_[0]->{usersettings}->set ('PlugInInfo',           $_[1]) }
sub SourceLanguage       { $_[0]->{usersettings}->set ('SourceLanguage',       $_[1]) }
sub SettingsPath         { $_[0]->{usersettings}->set ('SettingsPath',         $_[1]) }
sub SettingsRelativePath { $_[0]->{usersettings}->set ('SettingsRelativePath', $_[1]) }
sub DataType             { $_[0]->{usersettings}->set ('DataType',             $_[1]) }
sub SettingsName         { $_[0]->{usersettings}->set ('SettingsName',         $_[1]) }
sub TargetDefaultFont    { $_[0]->{usersettings}->set ('TargetDefaultFont',    $_[1]) }

=head2 copy_header ($source)

Copies the header information from another TTX into this one.

=cut
sub copy_header {
   my ($self, $source) = @_;
 
   $self->CreationTool         ($source->CreationTool);
   $self->CreationDate         ($source->CreationDate);
   $self->CreationToolVersion  ($source->CreationToolVersion);

   $self->SourceDocumentPath   ($source->SourceDocumentPath);
   $self->OEncoding            ($source->OEncoding);
   $self->TargetLanguage       ($source->TargetLanguage);
   $self->PlugInInfo           ($source->PlugInInfo);
   $self->SourceLanguage       ($source->SourceLanguage);
   $self->SettingsPath         ($source->SettingsPath);
   $self->SettingsRelativePath ($source->SettingsRelativePath);
   $self->DataType             ($source->DataType);
   $self->SettingsName         ($source->SettingsName);
   $self->TargetDefaultFont    ($source->TargetDefaultFont);
}

=head2 slang(), tlang()

These are quicker versions of SourceLanguage and TargetLanguage; they cache the values for repeated use (and they do get used
repeatedly).  The drawback is they're actually slower for files without a source or target language defined, but this actually
doesn't happen all that often.  At least I hope not.

=cut

sub slang {
   my ($self, $l) = @_;
   if (defined $l) {
      $self->{slang} = $self->SourceLanguage($l);
      return $self->{slang};
   }
   return $self->{slang} if $self->{slang};
   $self->{slang} = $self->SourceLanguage();
   $self->{slang};
}
sub tlang {
   my ($self, $l) = @_;
   if (defined $l) {
      $self->{tlang} = $self->TargetLanguage($l);
      return $self->{tlang};
   }
   return $self->{tlang} if $self->{tlang};
   $self->{tlang} = $self->TargetLanguage();
   $self->{tlang};
}

=head1 WRITING TO THE BODY

=head2 append_text($string)

Append a string to the end of the body.  It's the caller's responsibility to terminate the line.

=cut

sub append_text {
   my ($self, $str) = @_;
   $self->{body}->add (\$str);
}

=head2 append_segment($source, $target, $match, $slang, $tlang, $origin)

Appends a segment to the body.  Only C<$source> and C<$target> are required; C<$match> defaults to 0, and defaults for C<$slang>
and C<$tlang> (the source and target languages) default to the master values in the header.  Note that TagEditor I<really> doesn't
like you to mix languages, but who am I to stand in your way in this matter?  Finally, C<$origin> defaults to unspecified.
TagEditor sets it to "manual"; probably "Align" is another value, but I haven't verified that.

If the header doesn't actually have a source or target language, and you specify one or the other here, it will be written to
the header as the default source or target language.

=cut

sub append_segment {
   my ($self, $source, $target, $match, $slang, $tlang, $origin) = @_;
   
   $match = 0 unless $match;
   
   if ($slang) {
      my $lang = $self->slang;
      $self->slang($slang) unless $lang;
   } else {
      $slang = $self->slang;
   }
   if ($tlang) {
      my $lang = $self->tlang;
      $self->tlang($tlang) unless $lang;
   } else {
      $tlang = $self->tlang;
   }
   
   $source = XML::Snap->escape ($source);
   $target = XML::Snap->escape ($target);
   my $tu = XML::Snap->parse ("<Tu MatchPercent=\"$match\"/>");
   $tu->set ('origin', $origin) if defined $origin;
   $tu->append (XML::Snap->parse ("<Tuv Lang=\"$slang\">$source</Tuv>"));
   $tu->append (XML::Snap->parse ("<Tuv Lang=\"$tlang\">$target</Tuv>"));
   
   $self->{body}->add ($tu);
}

=head2 append_mark($string, $tag)

Appends a non-opening, non-closing tag to the body.  (External style, e.g. text in Word that doesn't get translated.)
This is useful for setting marks for script coordination, which is why I call it append_mark.

The default appearance is "text", but you can add C<$tag> if you want something else.

=cut

sub append_mark {
   my ($self, $text, $tag) = @_;
   $tag = 'text' unless $tag;
   $text = XML::Snap->escape($text);
   my $mark = XML::Snap->parse ("<ut DisplayText=\"$tag\" Style=\"external\">$text</ut>");
   $self->{body}->add($mark);
}

=head2 append_open_tag($string, $tag), append_close_tag ($string, $tag)

Appends a opening or closing tag.  Here, the C<$tag> is required.  (Well, it will default to 'cf' if you screw up.  But don't.)

=cut

sub append_open_tag {
   my ($self, $text, $tag) = @_;
   $tag = 'cf' unless $tag;
   $text = XML::Snap->escape($text);
   my $mark = XML::Snap->parse ("<ut RightEdge=\"angle\" Style=\"external\" DisplayText=\"$tag\" Type=\"start\">$text</ut>");
   $self->{body}->add($mark);
}
sub append_close_tag {
   my ($self, $text, $tag) = @_;
   $tag = '/cf' unless $tag;
   $text = XML::Snap->escape($text);
   my $mark = XML::Snap->parse ("<ut LeftEdge=\"angle\" Style=\"external\" DisplayText=\"$tag\" Type=\"end\">$text</ut>");
   $self->{body}->add($mark);
}

=head2 append_copy, copy_all

If you have an XML piece from another TTX, you can append a copy of it directly into this TTX.  Note that the "XML piece" from C<source> and
C<translated> of a segment may actually be a list (because a segment may contain tags and text).
The C<copy_all> method copies the contents of another TTX's body tag into the current TTX, and can filter along the way.

=cut

sub append_copy {
   my $self = shift;
   foreach my $piece (@_) {
      $self->{body}->add($piece); # This adds a copy of the piece if it's an XML node
   }
}

sub copy_all {
   my $self = shift;
   my $other = shift;
   $self->{body}->copy_from($other->{body}, @_);
}

=head1 READING FROM THE BODY

Since a TTX is structured data, not just text, reading from it consists of iterating across its child elements.  These elements
are L<XML::Snap> elements due to the underlying XML nature of the TTX file.  I suppose some convenience functions might be a
good idea, but frankly it's so easy to use the XML::Snap functions (well, I did write XML::Snap) that I haven't needed any
so far.  This might be a place to watch for further details.

=head2 content_elements()

Returns all the top-level content elements in a list.  Depending on the structure of the TTX and the tool used to build it,
this level may not include all segments (I've had segmented TTX with the segments embedded in top-level formatting elements).

=cut
sub content_elements {
   my ($self) = @_;
   my @returns = $self->{body}->children;
   foreach (@returns) {
      File::TTX::Content->rebless($_);
   }
   @returns;
}

=head2 segments()

Returns a list of just the segments in the body.  Useful for data extraction.

=cut

sub segments {
   my $self = shift;
   my @returns = $self->{body}->all('Tu');
   foreach (@returns) {
      File::TTX::Content->rebless($_);
   }
   @returns;
}


=head1 MISCELLANEOUS STUFF

=head2 date_now()

Formats the current time the way TTX likes it.

=cut

sub date_now { strftime ('%Y%m%dT%H%M%SZ', localtime); }


=head1 File::TTX::Content

This helper class wraps the L<XML::Snap> parts returned by C<content_elements>, providing a little more comfort when working
with them.

=cut

package File::TTX::Content;

use base qw(XML::Snap);
use warnings;
use strict;

=head2 rebless($xml)

Called on an XML::Snap element to rebless it as a File::TTX::Content element.  This is a class method.

=cut

sub rebless {
   my ($class, $xml) = @_;
   bless $xml, $class;
}

=head2 type()

Returns the type of content piece.  The possible answers are 'text', 'open', 'close', 'segment', and 'mark'.

=cut

sub type {
   my $self = shift;
   
   return 'text' if $self->istext;
   return 'segment' if $self->is('Tu');
   if ($self->is('ut')) {
      return 'open'  if $self->get('Type', '') eq 'start';
      return 'close' if $self->get('Type', '') eq 'end';
      return 'mark';
   }
   return 'unknown';
}

=head2 tag()

Returns (or sets) the tag or mark text of a tag or mark.

=cut

sub tag {
   my $self = shift;
   my $type = $self->type;
   return '' if $type eq 'text';
   return '' if $type eq 'segment';
   return $self->set("DisplayText", shift);
}

=head2 translated(), translated_xml()

Returns the translated content of a segment, or just the content for anything else.  Use with care.  The C<_xml> variant returns the underlying
XML object - use with even more care.

=cut

sub translated_xml {
   my $self = shift;
   my $type = $self->type;
   return $self unless $type eq 'segment';
   my @t = $self->elements();
   return $t[1]->children if defined $t[1];
   return $t[0]->children;
}
sub translated {
   my $self = shift;
   my $type = $self->type;
   return $self->rawcontent unless $type eq 'segment';
   my @t = $self->elements();
   return $t[1]->rawcontent if defined $t[1];
   return $t[0]->rawcontent;
}

=head2 write_translated($thing)

If not called on a segment, does nothing at all.  Eventually, of course, it will have to be possible to identify a text area and segment it,
but this is not that function.

If called on a segment with a string, deletes whatever may be in the segment's translated half, creates an XML::Snap text object from the string,
and inserts said object.  If called on a segment with an XML::Snap object, insert it.  If called with a list of things, inserts one after the
other with the same rules.

=cut

sub write_translated {
   my $self = shift;
   my $type = $self->type;
   return unless $type eq 'segment';
   my @t = $self->elements();
   return unless defined $t[1]; # Not sure if this can actually happen, but it's best to play it safe.
   my $t = $t[1];
   $$t{children} = []; # Cheating a little here, because I know this is an XML::Snap object underneath.
   for my $element (@_) {
      $t->add($element);
   }
}

=head2 source(), source_xml()

Returns the source content of a segment, or just the content for anything else.  The C<_xml> variant returns the xml object, so you get the tag
structure if it's a complex source segment.

=cut

sub source_xml {
   my $self = shift;
   my $type = $self->type;
   return $self unless $type eq 'segment';
   $self->first('Tuv')->children;
}
sub source {
   my $self = shift;
   my $type = $self->type;
   return $self->rawcontent unless $type eq 'segment';
   my $t = $self->first('Tuv');
   return $t->rawcontent;
}

=head2 write_source($thing)

Works I<just like write_translated>, except on the source, which Trados tools won't let you do.  Use with care.

=cut

sub write_source {
   my $self = shift;
   my $type = $self->type;
   return unless $type eq 'segment';
   my @t = $self->elements();
   return unless defined $t[0]; # Not sure if this can actually happen, but it's best to play it safe.
   my $t = $t[0];
   $$t{children} = []; # Cheating a little here, because I know this is an XML::Snap object underneath.
   for my $element (@_) {
      $t->add($element);
   }
}

=head2 match()

Returns and/or sets the recorded match percent of a segment (or 0 if it's not a segment).

=cut

sub match {
   my $self = shift;
   my $type = $self->type;
   return 0 unless $type eq 'segment';
   $self->set('MatchPercent', shift);
}

=head2 source_lang(), translated_lang()

Returns and/or sets the source or target language of a segment (or nothing if it's not a segment).

=cut

sub source_lang {
   my $self = shift;
   return unless $self->type eq 'segment';
   my $xml = $self->search_first('Tuv');
   $xml->set('Lang', shift) if $xml;
}
sub translated_lang {
   my $self = shift;
   return unless $self->type eq 'segment';
   my @t = $self->elements();
   my $xml = $t[1] if defined $t[1];
   $xml->set('Lang', shift) if $xml;
}

=head2 Other things we'll want

The XML::Snap doesn't support the full range of XML manipulation in its current incarnation, so I'll need to revisit it, and
also I don't need all this functionality today, but here's what the content handler should be able to do:

 - Segment non-segmented text, replacing a chunk or series of chunks (in case neighboring text chunks don't cover a full segment)
   with a segment or a segment-plus-extra-text.
 - Translate a segment, i.e. replace the translated content.
 - Modify the source of a segment (just in case).
 
If you are actually using Perl to access TTX files and would like to do these things, then by all means drop me a line and tell me
to get the lead out.

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-ttx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-TTX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::TTX


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-TTX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-TTX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-TTX>

=item * Search CPAN

L<http://search.cpan.org/dist/File-TTX/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::TTX
