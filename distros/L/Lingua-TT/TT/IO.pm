## -*- Mode: CPerl -*-
## File: Lingua::TT::IO.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: TT I/O: file I/O object


package Lingua::TT::IO;
use Lingua::TT::Token;
use Lingua::TT::Sentence;
use Lingua::TT::Document;

use IO::Handle;
use IO::File;
use Carp;
use Encode qw(encode decode);

use strict;

##==============================================================================
## Globals & Constants

#==============================================================================
## Constructors etc.

## $io = CLASS_OR_OBJECT->new(%opts)
## + $io: HASH-ref
##    (
##     encoding => $encoding,  ##-- I/O encoding (default: undef)
##                             ##   + uses perlio :encoding($encoding) layer
##                             ##   + undef (default) uses perl default (locale?)
##                             ##   + undef gives fastest I/O, since no translation is required
##                             ##   + pseudo-encoding 'raw' sets ':raw' layer
##                             ##   + false encodings (0,'') set no perlIO flags at all
##     fh       => $fh,        ##-- underlying filehandle (default: none)
##     name     => $name,      ##-- source name to use for error reporting (defualt: none)
##    )
sub new {
  my $that = shift;
  return bless({
		encoding => undef,
		fh       => undef,
		name     => undef,
		@_,
	       }, ref($that)||$that);
}

#x undef = $io->DESTROY()
#x  + destructor implicitly calls close()
#sub DESTROY {
#  $_[0]->close();
#}

##==============================================================================
## Methods: I/O: Generic

## $io = $io->close()
##  + closes $io object, if open
sub close {
  my $io = shift;
  return $io if (!ref($io));
  $io->{fh}->close if (defined($io->{fh}));
  delete(@$io{qw(fh name)});
  return $io;
}

## $io = CLASS_OR_OBJECT->open($mode,$src,%opts)
##  + opens $io with $mode on $src
##  + %opts: clobbers %$io (e.g. encoding=>$encoding)
sub open {
  my ($io,$mode,$src,%opts) = @_;
  $io = $io->new if (!ref($io));
  $io->close();
  @$io{'name',keys(%opts)} = ($src,values(%opts));
  if (ref($src)) {
    $mode .= '&' if (UNIVERSAL::isa($src,'IO::Handle') && $mode !~ /\&/);
    $io->{fh} = IO::Handle->new() if (!defined($io->{fh}));
    CORE::open($io->{fh},$mode,$src)
	or confess(ref($io)."::open(): open failed with mode '$mode' for '$io->{name}': $!");
  } else {
    $io->{fh} = IO::File->new($mode.$src)
      or confess(ref($io)."::open(): open failed with mode '$mode' for file '$src': $!");
  }
  if ($io->{encoding}) {
    if ($io->{encoding} eq 'raw') {
      binmode($io->{fh}, ':raw');
    }
    elsif ($io->{encoding} eq 'utf8' || $io->{encoding} eq 'UTF-8') {
      binmode($io->{fh}, ':utf8');
    }
    else {
      binmode($io->{fh},":encoding($io->{encoding})");
    }
  }
  return $io;
}

## $bool = $io->opened()
##  + returns true iff $io is opened
sub opened {
  return defined($_[0]{fh});
}

## $bool = $io->eof()
##  + returns true iff $io->{fh} is at eof (or closed)
sub eof {
  return !defined($_[0]{fh}) || CORE::eof($_[0]{fh});
}

##----------------------------------------------------------------------
## Methods: I/O: Generic: Input

## $io = CLASS_OR_OBJECT->fromFile($filename_or_fh,%opts)
##  + opens $io for read from $filename_or_fh
sub fromFile {
  return $_[0]->open('<&',@_[1..$#_]) if (ref($_[1]));
  return $_[0]->open('<', @_[1..$#_]);
}

## $io = CLASS_OR_OBJECT->fromFh($fh,%opts)
##  + opens $io for read from dup of $fh
sub fromFh {
  return $_[0]->open('<&',@_[1..$#_]);
}

## $io = CLASS_OR_OBJECT->fromString(\$string,%opts)
##  + opens $io for read from string $string
sub fromString {
  return $_[0]->open('<',@_[1..$#_]);
}

##----------------------------------------------------------------------
## Methods: I/O: Generic: Output

## $io = CLASS_OR_OBJECT->toFile($filename_or_fh,%opts)
##  + opens $io for write (clobbering) to $filename_or_fh
sub toFile {
  return $_[0]->open('>&',@_[1..$#_]) if (ref($_[1]));
  return $_[0]->open('>', @_[1..$#_]);
}

## $io = CLASS_OR_OBJECT->toFh($fh,%opts)
##  + opens $io for write to dup of $fh
sub toFh {
  return $_[0]->open('>&',@_[1..$#_]);
}

## $io = CLASS_OR_OBJECT->toString(\$string,%opts)
##  + opens $io for write (clobbering) to string $string
sub toString {
  return $_[0]->open('>',@_[1..$#_]);
}

##==============================================================================
## Methods: I/O: Input

## $tok_or_undef = $io->getToken()
##  + gets next (possibly empty) token from input stream
##  + returns undef of EOF
sub getToken {
  my $io = shift;
  return undef if ($io->eof);
  return bless([split(/[\n\r]*[\t\n\r][\n\r]*/,$io->{fh}->getline)], 'Lingua::TT::Token');
}

## $sent_or_undef = $io->getSentence()
##  + gets next (possibly empty) sentence from input stream
##  + returns undef of EOF
sub getSentence {
  my $io = shift;
  return undef if ($io->eof);
  my $sent = bless([],'Lingua::TT::Sentence');
  my ($line);
  while (defined($line=$io->{fh}->getline)) {
    last if ($line =~ /^\r?$/);
    push(@$sent, bless([split(/[\n\r]*[\t\n\r][\n\r]*/,$line)], 'Lingua::TT::Token'));
  }
  return $sent;
}

## $doc_or_undef = $io->getDocument()
##  + gets all remaining data from input stream as a Lingua::TT:Document
##  + returns undef of EOF
sub getDocument {
  my $io = shift;
  return undef if ($io->eof);
  my $fh = $io->{fh};
  my ($buf);
  {
    local $/ = undef;
    $buf = <$fh>;
  }
  my $doc = bless([],'Lingua::TT::Document');
  @$doc = map {
    bless([
	   map {
	     bless([split(/[\n\r]*[\t\n\r][\n\r]*/,$_)], 'Lingua::TT::Token')
	   } split(/[\r\n]+/,$_)
	  ],
	  'Lingua::TT::Sentence')
  } split(/(?:\r?\n){2}/, $buf);

  return $doc;
}

## $line = $io->getLine();
##  + gets a single line from input stream, or undef on eof
##  + basically just a wrapper for the <> operator
sub getLine {
  my $fh = $_[0]{fh};
  return scalar(<$fh>);
}

## \@lines = $io->getLines();   ##-- scalar context
##  @lines = $io->getLines();   ##-- array context
##  + gets all remaining data from input stream as a flat list of (decoded) strings
##  + returns undef of EOF
sub getLines {
  my $io = shift;
  return undef if ($io->eof);
  my $fh = $io->{fh};
  my ($buf);
  {
    local $/ = undef;
    $buf = scalar(<$fh>);
  }
  my $lines = [split(/\r?\n/, $buf)];
  return wantarray ? @$lines : $lines;
}


##==============================================================================
## Methods: I/O: Output

## $io = $io->putToken($tok)
##  + writes $tok to output stream
sub putToken {
  $_[0]{fh}->print(join("\t", @{$_[1]})."\n");
}

## $io = $io->putSentence($sent)
##  + writes $sent to output stream
sub putSentence {
  $_[0]{fh}->print(join("\n", map {join("\t",@$_)} @{$_[1]})."\n\n");
}

## $io = $io->putDocument($doc)
##  + writes $doc to output stream
sub putDocument {
  $_[0]{fh}->print(map { join("\n",map {join("\t",@$_)} @$_)."\n\n" } @{$_[1]});
}

## undef = $io->print(@data)
##  + wrapper for $io->{fh}->print(@data)
sub print {
  $_[0]{fh}->print(@_[1..$#_]);
}

## $io = $io->putLines(@lines);
## $io = $io->putLines(\@lines);
##  + dumps @lines to output handle, adding terminating newline
sub putLines {
  my $io = shift;
  $io->{fh}->print(map {/\R\z/ ? $_ : "$_\n"} (ref($_[0]) ? @{$_[0]} : @_));
  return $io;
}


##==============================================================================
## Footer
1;

__END__
