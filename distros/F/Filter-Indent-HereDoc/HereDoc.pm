package Filter::Indent::HereDoc;

use strict;
use warnings;
use Filter::Simple;

our $VERSION = '1.01';
our %options = ();
our @buffer;            # Temporary storage of current here document
our @termstring;        # FIFO list of here document terminating strings

sub import {
  %options = ();
  $options{$_}++ foreach (@_);
}

FILTER_ONLY
  executable => sub {
    my @code = split /\n/;
    $_ = join '',(map &process_line($_),@code);
  };

sub process_line {
  my $line = shift;
  if (@termstring) {
    # At this point we are in a here document, so all lines of code
    # are buffered until the end of the heredoc is detected
    push @buffer,$line;
    
    # 2 scenarios - terminator is a blank line, or terminator contains non-
    # whitespace. If blank line, then look for same whitespace at start of
    # each line in buffer. Otherwise take the whitespace that precedes the
    # terminator and match this against each line in the buffer.
    #
    # By default, we accept terminator strings in the Perl6 RFC111 format,
    # i.e. whitespace, ';', and comments following the terminator are
    # allowed. The only exception is if the terminator is a blank line,
    # in this case then only whitespace is allowed.
    
    my $termregex;
    unless ($options{strict_terminators}) {
      if ($termstring[0] =~ /\S/) {
        $termregex = qr/^(\s*)($termstring[0])(\s*;{0,1}\s*(?:#.*){0,1})$/;
      } else {
        $termregex = qr/^\s*$/;
      }
    } else {
      if ($termstring[0] =~ /\S/) {
        $termregex = qr/^(\s*)($termstring[0])$/;
      } else {
        $termregex = qr/^$/;
      }
    }
    
    my ($whitespace,$terminator,$extras);
    if ($line =~ $termregex) {
      ($whitespace,$terminator,$extras) = ($1,$2,$3);
      if ($termstring[0] =~ /\S/) {
        foreach (@buffer) {
          return unless (/^$whitespace/);
        }      
      } else {
        # Terminator string is a blank line
        undef $whitespace;
        foreach (@buffer) {
          if (/^(\s+)\S/) {
            $whitespace = $1 unless ($whitespace and /^$whitespace\s*/);
          }
        }
      }
      # End of heredoc - strip the required amount of whitespace
      map s/^$whitespace//,@buffer;
      
      # If we found extra characters after the terminator (Perl6 RFC111
      # style), move them onto a new line to be compatible with Perl5
      if ($extras) {
        pop @buffer;
        push @buffer,$terminator;
        push @buffer,$extras;
      }
      
      # Return captured heredoc back to Perl and reset the buffer
      $line   = join "\n",@buffer;
      @buffer = ();
      shift @termstring;
      return "$line\n";
    }
  } else {
    # Perl6 RFC111 states that whitespace after the terminator
    # should be ingored
    unless ($options{strict_terminators}) {
      $line =~ s/(?<!<)<<(?!<)\s+/<</g;
    }

    # Can we find the start of any here documents?
    MATCH: while ($line =~ m/(?<!<)<<(?!<)/g) {
      if ($line =~ m/\G(\w+)/) {
        push @termstring,$1;
        next MATCH;
      }

      if ($line =~ m/\G(?:\s*(['"`]))(.*?)(?<!\\)\1/) {
        my ($quote,$string) = ($1,$2);
        $string =~ s/\\$quote/$quote/g;
        push @termstring,$string;
        next MATCH;
      }
      
      # Use of bare << to mean <<"" is depreciated
      # ...but still works so the module needs to support it!
      push @termstring,'';
    }
    return "$line\n";    
  }
}

1;
__END__

=head1 NAME

Filter::Indent::HereDoc - allows here documents to be indented within code blocks

=head1 SYNOPSIS

  use Filter::Indent::HereDoc;
  {
    {
      print <<EOT;
      Hello, World!
      EOT
    }
  }
  # This will print "Hello, World!" and stop at EOT
  # even though the termination string is indented.

=head1 DESCRIPTION

When a 'here document' is used, the document text and the termination
string must be flush with the left margin, even if the rest of the code
block is indented. 

Filter::Indent::HereDoc removes this restriction, and acts in a more DWIM kind 
of way - that if the terminator string is indented then that level of 
indent will apply to the whole document.

If there is no terminator string (so the here document stops at the first
blank line), then enough whitespace will be stripped out so that the 
leftmost character of the document will be flush with the left margin, e.g.

  print <<;
       Hello,
      World!
  
  # This will print:
   Hello,
  World!

=head2 Changes to terminator strings

In addition to allowing indented here documents, Filter::Indent::HereDoc
also provides support for a more permissive style of terminator string,
as specified in Perl6 RFC111. The changes are:

=over 4

=item *

Whitespace is allowed between '<<' and an unquoted terminator string when
the heredoc is defined

=item *

At the end of the heredoc, whitespace, a single semicolon, and comments are 
all allowed after the terminator, however other code statements are not

=back

You can force the module to revert to the standard Perl5 style of
terminator string by specifying 'strict_terminators' when the module
is C<use>'d, e.g.

 use Filter::Indent::HereDoc;
 print << EOT
 Hello, World!
 EOT ;             # this will work
 
 use Filter::Indent::HereDoc 'strict_terminators';
 print << EOT
 Hello, World!
 EOT ;             # this will generate an error

=head1 CAVEATS

=over 4

=item *

At present, Filter::Indent::HereDoc does not attempt to parse any of the Perl
code, it just searches for the '<<' string to locate the start of a 
here document. Therefore if you need to write '<<' without starting a
here document, you must first use C<no Filter::Indent::HereDoc;> to stop the
code from being filtered, e.g.

  use Filter::Indent::HereDoc;
  print <<EOT;
  This is a here document
  EOT
  
  no Filter::Indent::HereDoc;
  print "<<EOT";  # This will be printed as normal

=item *

Due to the way in which whitespace is removed, Filter::Indent::HereDoc can 
become confused if your editor replaces groups of spaces with tab
characters. Different text editors use different tab stops, so for 
portability reasons it is probably best to avoid this feature.

=back

=head1 SEE ALSO

L<Filter::Simple>, L<http://perl.jonallen.info/modules>, L<perlfaq4>, 
Perl6 RFC111

=head1 AUTHOR

Jon Allen, E<lt>jj@jonallen.infoE<gt>

=head1 THANKS TO

Michael Schwern for the suggestions about Perl6 RFC111

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jon Allen

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
