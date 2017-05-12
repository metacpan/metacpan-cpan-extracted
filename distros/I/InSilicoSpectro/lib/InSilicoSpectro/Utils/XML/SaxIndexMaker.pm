use strict;

package InSilicoSpectro::Utils::XML::SaxIndexMaker;
require Exporter;

=head1 NAME

InSilicoSpectro::Utils::XML::SaxIndexMaker

=head1 DESCRIPTION

A handler to be used with XML::Parser::PerlSax. The goal is to read an indexMaker (xmlIndexMaker) file, stating which elements sould be indexed from a (large) source xml file. Then this source file is parsed, indexed element are saved into an index (xmlIndex) file.

=head1 METHODS

=head2 my $sim=InSilicoSpectro::Utils::XML::SaxIndexMaker->new();

Instanciate a new SaxIndexMaker

=head2 $sim->readXmlIndexMaker($file)

=head2 $sim->readXmlIndexMaker(file=>$file)

=head2 $sim->readXmlIndexMaker(contents=>$xmlcontents)

Read what is to be caught and put into the index. xmlIndexMaker files follows the format

=begin text

<?xml version="1.0" encoding="ISO-8859-1"?>
<xmlIndexMaker>
  <elementToIndex path="/some/path/name1">   <!-- the path for the element to be indexed -->
    <!-- then 0 or more keys (attribute(s) or childValue to be stored in the index)
    <key type="attribute" name="oneatt"/>   <!-- we want to save attribute "onneatt" into the index -->
    <key type="attribute" name="otheratt"/> <!-- we want to save attribute "otheratt" into the index -->
    <key type="contents"/>                  <!-- save the contents value>
  </elementToIndex>
  <elementToIndex path="/some/other/name1/name2">
    <key type="contents"/>
  </elementToIndex>
  <elementToIndex path="/some/other/name3">
    <key type="attribute" value="someatt"/>
  </elementToIndex>
</xmlIndexMaker>

=end text

=head2 $sim->makeIndex($sourceFile, [$indexFile, [\%args]])

Opens $sourceFile and writes the index into $indexFile. $sourceFile is a normal valid xml.

$indexFile will look like the following example

%args can contain

=over 4

=item origSrc=file 

So that the origSrc is saved instead of the given $sourceFile (think that the $sourceFile may bonly be a temporary gunziped file)

=back

=begin text

<?xml version="1.0" encoding="ISO-8859-1"?>
<xmlIndex>
  <source>
    <origFile>my/file/location</origFile>
    <MD5>123456</MD5>
  </source>
  <processed>
    <date>2005-03-12</date>
    <time>15:12:40</time>
  </processed>
  <indexedElements>
    <oneIndexedElement path="/some/path/name1" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <attr name="oneatt" value="someval"/>
      <attr name="otheratt" value="someval"/>
    </oneIndexedElement>
    <oneIndexedElement path="/some/other/name1/name2" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <contents><![CDATA[someContents]]></contents>
    </oneIndexedElement>
    <oneIndexedElement path="/some/other/name1/name2" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <contents><![CDATA[someContents]]></contents>
    </oneIndexedElement>
    <oneIndexedElement path="/some/other/name1/name2" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <contents><![CDATA[someContents]]></contents>
    </oneIndexedElement>
    <oneIndexedElement path="/some/path/name1" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <attr name="oneatt" value="someval"/>
      <attr name="otheratt" value="someval"/>
    </oneIndexedElement>
    <oneIndexedElement path="/some/other/name1/name2" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <contents>someContents</contents>
    </oneIndexedElement>
    <oneIndexedElement path="/some/path/name1" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <attr name="oneatt" value="someval"/>
      <attr name="otheratt" value="someval"/>
    </oneIndexedElement>
    <oneIndexedElement path="/some/other/name3" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <child name="someatt">someval</child>
    </oneIndexedElement>
    <oneIndexedElement path="/some/other/name3" id="someid" parentid="someid">
      <pos lineNumber="int" columnNumber="int" startByte="int" lengthByte="int"/>
      <child name="someatt">someval</child>
    </oneIndexedElement>
  </indexedElements>
</xmlIndex>

=end text

=head2 printIndex([$out])

Print the index in a text format

=head1 FUNCTIONS

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

Nicolas Budin, www.genebio.com

=cut

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = ();

use InSilicoSpectro::Utils::io;

sub new{
  my ($pkg, $h)=@_;

  my $sim={};
  bless $sim, $pkg;

  my $dvar={};
  bless $dvar, $pkg;

  foreach (keys %$h){
    $sim->set($_, $h->{$_});
  }
  return $sim;
}

########

use XML::Twig;
use File::Spec;
sub readXmlIndexMaker{
  my $this=shift;
  my %hprms;
  my $file;
  if(scalar(@_)==1){
    $hprms{file}=shift;
    $file=$hprms{file};
  }else{
    %hprms=@_;
  }
  use File::Temp qw(tempfile);
  if($hprms{contents}){
    my ($fh, $tempfile)=tempfile("indexmaker-XXXXXX", DIR=> File::Spec->tmpdir(), UNLINK=>1);
    $file=$tempfile;
    print $fh $hprms{contents};
    close $fh;
  }

  $this->{source}{indexMaker}=$file;
  #delete the prvious element paths to record
  $this->{recordPaths}={};
  my $twig=XML::Twig->new(twig_handlers=>{
					  'elementToIndex'=>sub {twig_addElementToIndex($this, $_[0], $_[1])},
					  pretty_print=>'indented'
					 }
			 );
  $twig->parsefile($file) or InSilicoSpectro::Utils::io::croakIt "cannot parse [$file]: $!";
  
}

sub twig_addElementToIndex{
  my ($this, $twig, $el)=@_;

  my $path=$el->atts->{path};
  my %h=(attributes=>[],
	);
  #records all attributes to be recorded
  foreach ($el->get_xpath('key[@type="attribute"]')){
    push @{$h{attributes}}, $_->atts->{name};
  }
  #set a flag if we must also record the contents
  if ($el->first_child('key[@type="contents"]')){
    $h{contents}=1;
  }
  $this->{recordPaths}{$path}=\%h;
}

######## PerlSAX
use XML::Parser::PerlSAX;
use File::Basename;
use SelectSaver;
sub makeIndex{
  my ($this, $sourceFile, $indexFile, $h)=@_;

  my $saver= (new SelectSaver(InSilicoSpectro::Utils::io->getFD(">$indexFile") or InSilicoSpectro::Utils::io::croakIt "cannot open [>$indexFile]: $!")) if defined $indexFile;

  my $parser = XML::Parser::PerlSAX->new( Handler => $this );

  #auto append -gz if needed
  $sourceFile.=".gz" if ((! -f $sourceFile) && (-f "$sourceFile.gz"));
  $this->{source}{file}=($h and $h->{origSrc}) || $sourceFile;
  $this->{source}{fileMD5}=InSilicoSpectro::Utils::io::getMD5($sourceFile);

  #saves the parser, to later access expat info (byteposition...
  $this->{parser}=\$parser;

  #string (could be a stack) where the path is built and unbuilt
  $this->{path}='';
  #the depth into the xml tree
  $this->{depth}=0;
  #stack to remember the parent id
  $this->{idStack}=[];
  #a global counter for assigning an incemreneted new id to each needed tag
  $this->{idCpt}=0;
  #contains all the indexed
  $this->{indexEl}=[];
  #catchEnPos[2] contains (evenutally the point to the index for which for should catch the end position, et level 2
  $this->{catchEndPos}=[];

  #launches the parsing process
  open FD, "<$sourceFile" or CORE::die "cannot open for reading [$sourceFile]: $!";
  binmode FD;
  $parser->parse(Source => { ByteStream => \*FD});

  #print the index
  $this->printIndexXml();

}

use Data::Dumper;

#the next sub are sax callbacks

#this one is just to instanciate the {expat} element (that will handle byteposition)
sub start_document{
}

sub start_element {
  my ($this, $element) = @_;

  $this->saveEndPos();

  $this->{path}.="/$element->{Name}";
  $this->{level}++;

  my $path=$this->{path};
  #print "$path ?\n";
  my $id;
  if(defined $this->{recordPaths}{$path}){
    $id=$this->{idCpt}++;
    my $parentId=((scalar @{$this->{idStack}})>0)?$this->{idStack}[-1]:undef;
    #print "$path [$id] [$parentId]\n";
    my $loc=${$this->{parser}}->location;
    my $index={id=>$id,
	       parentId=>$parentId,
	       path=>$path,
	       pos=>{
		     startByte=>$loc->{BytePosition},
		     lineNumber=>$loc->{LineNumber},
		     columnNumber=>$loc->{ColumnNumber},
		    },
	       atts=>{},
		    };
    #add this $index to the list of all
    push @{$this->{index}}, $index;

    #record the requested attributes info
    foreach (@{$this->{recordPaths}{$path}{attributes}}){
      $index->{atts}{$_}=$element->{Attributes}{$_};
    }
    #if it is requested to catch the contents, we must setup a flags so that the characters sub saves it
    if($this->{recordPaths}{$path}{contents}){
      $index->{contents}='';
      $this->{saveContents}[$this->{level}]=\$index->{contents};
    }

    #we have to cath the end of this tag, i.e. the next end of a tag at the dirname $path level
    $this->{catchEndPos}[$this->{level}-1]=$index;
  }
  push @{$this->{idStack}}, $id;
}

sub end_element {
  my ($this, $element) = @_;

  $this->saveEndPos();

  undef $this->{saveContents}[$this->{level}];

  my $id=pop @{$this->{idStack}};
  $this->{path}=~s/\/[^\/]+$//;
  $this->{level}--;

}

sub characters{
  my ($this, $el) = @_;
  $this->saveEndPos();
  if (defined $this->{saveContents}[$this->{level}]){
    ${$this->{saveContents}[$this->{level}]}.=$el->{Data};
  }
}

#the end_element is called before the final tag, and we'd like to savethe end position after this tag
#one solution is to save that position the next time a ((start|end)_element|character) sub is called
sub saveEndPos{
  my ($this) = @_;
  my $path=$this->{path};
  #print "saveEndPos  $path\n";
  if(defined $this->{catchEndPos}[$this->{level}]){
    my $loc=${$this->{parser}}->location;
    my $indel=$this->{catchEndPos}[$this->{level}];
    $indel->{pos}{lengthByte}=$loc->{BytePosition}-$indel->{pos}{startByte};
    my $pos=$indel->{pos};
    #print "$pos->{lineNumber} $pos->{columnNumber} $pos->{startByte} $pos->{lengthByte} $indel->{path}\n";
    undef $this->{catchEndPos}[$this->{level}];
  }
}

######## END PerlSAX

######## output

sub printIndex{
  my ($this, $out)=@_;
  my $fdOut=(defined $out)?(new SelectSaver(InSilicoSpectro::Utils::io->getFD($out) or CORE::die "cannot open [$out]: $!")):\*STDOUT;

  foreach my $indel(@{$this->{index}}){
    print<<TAG;
$indel->{path}
  id $indel->{id}\t($indel->{parentId})
  line:$indel->{pos}{lineNumber}\tcol:$indel->{pos}{columnNumber}\tbyte:$indel->{pos}{startByte}\tlen:$indel->{pos}{lengthByte}
TAG
    foreach(sort (keys %{$indel->{atts}})){
      print "    $_ => '$indel->{atts}{$_}'\n";
    }
    print "    contents: $indel->{contents}\n" if defined $indel->{contents};
  }

}

use Time::localtime;
sub printIndexXml{
  my ($this, $out)=@_;
  my $save=(defined $out)?(new SelectSaver(InSilicoSpectro::Utils::io->getFD($out) or CORE::die "cannot open [$out]: $!")):\*STDOUT;

  my $date=sprintf("%4d-%2.2d-%2.2d",localtime->year()+1900, localtime->mon()+1, localtime->mday());
  my $time=sprintf("%2.2d:%2.2d:%2.2d", localtime->hour(), localtime->min(), localtime->sec());
print <<TAG;
<?xml version="1.0" encoding="ISO-8859-1"?>
<xmlIndex>
  <source>
    <file>$this->{source}{file}</file>
    <MD5 type="base_64">$this->{source}{fileMD5}</MD5>
    <indexMaker>$this->{source}{indexMaker}</indexMaker>
  </source>
  <processed>
    <date>$date</date>
    <time>$time</time>
  </processed>
  <indexedElements>
TAG
  foreach my $indel(@{$this->{index}}){
    my $pidatt= " parentId=\"$indel->{parentId}\"" if defined $indel->{parentId};

    print <<TAG;
    <oneIndexedElement path="$indel->{path}" id="$indel->{id}"$pidatt>
      <pos lineNumber="$indel->{pos}{lineNumber}" columnNumber="$indel->{pos}{columnNumber}" startByte="$indel->{pos}{startByte}" lengthByte="$indel->{pos}{lengthByte}"/>
TAG
    foreach(sort (keys %{$indel->{atts}})){
      print "      <attr name=\"$_\" value=\"$indel->{atts}{$_}\"/>\n";
    }
    print "      <contents><![CDATA[$indel->{contents}]]></contents>\n" if defined $indel->{contents};
    print "    </oneIndexedElement>\n";
}
  print <<TAG;
  </indexedElements>
</xmlIndex>
TAG
}

1;
