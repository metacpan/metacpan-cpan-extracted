package Decl::Tok;

use 5.006;
use strict;
use warnings;

use parent 'Iterator::Records';
use Iterator::Records::Lines;
use Carp;

=head1 NAME

Decl::Tok - Given a line iterator, returns a token stream that tokenizes the lines as first-pass Decl

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Decl can be parsed at different levels of detail. The tokenizer simply takes a line iterator and skims it to extract the bare minimum of the line shape in order
to facilitate indexing or support some other parsing, such as building an in-memory data structure. This token stream is pretty minimal; for instance, the contents
of brackets are not parsed at all, just identified and passed through as a kind of quoted string. The next stage in processing has to identify any internal structure
in bracketed line parameters.

=head1 CREATING A TOKENIZER

Essentially, C<skim> is currently the beginning and end of tokenization at the stream level. A parameter tokenizer could be added as a second level of processing,
but I currently don't plan to do that, instead breaking out bracketed data in the data structure parser.

=head2 skim (source, type)

Given either a line stream or a string, sets up a first-line token stream drawing from the source. If a line stream, it must have the fields ['type', 'lno', 'indent', 'len', 'text'],
and 'type' must be either 'line' or 'blank'.

The output of this tokenizer is a stream with the same fields (which means that a line stream is actually a token stream); the types are many and varied.

The C<type> parameter to the skimmer determines the basic text type to be expected - must be one of text, para, block, tag, or textplus. The default is tag.

=cut

sub _make_debug_out {
   my $d = shift;
   return sub { } unless $d;
   return $d if ref $d;
   print STDERR "\n";
   sub {
      print STDERR shift . "\n";
   };
}

sub skim {
   my $class = shift;

   my $self = bless ({}, $class);
   $self->{input} = shift;
   
   # If the source is a string, define a line iterator on it. If it's code, then we're transmogrifying an existing token stream. 
   # If the source is already a line iterator, use it directly. Otherwise, croak.
   if (not ref ($self->{input})) {
      $self->{input_mode} = 'string';
      $self->{source} = Iterator::Records::Lines->new ('string', $self->{input});
   } elsif (ref ($self->{input}) eq 'CODE') {
      # This is a transmogrification of a line iterator, so keep the class intact but initialize like a vanilla itrecs.
      # Transmogrification creates a new itrecs of the parent's class because the parent might have custom transmogrifiers. (See thread on 2019-02-23.)
      $self->{input_mode} = 'transmog';
      $self->{gen} = $self->{input_type};
      $self->{f} = shift;
      $self->{id} = '*';
      return $self;
   } elsif ($self->{input}->can('iter')) {
      $self->{input_mode} = 'lines';
      $self->{source} = $self->{input};
   } else {
      croak "Can't use this input type";
   }

   $self->{input_type} = shift || 'tag';
   
   my $debug_out = _make_debug_out(shift);
   
   # As we're a tokenizer, we know our fields.
   $self->{f} = ['type', 'lno', 'indent', 'len', 'text'];
   $self->{id} = '*';

   $self->{gen} = sub {
      # Set up our state.
      # The following are the settings for 'tag'; for other input types, see 'if's below.
      my $stop_on_blank = 0;
      my $check_barewords = 1;
      my $check_quotes = 1;
      my $check_brackets = 1;
      my $check_sigils = 1;
      my $check_plus = 0;
      my $force_sigil_space = 1;
      my $tokens_found = 0;
      my $in_text_block = 0;
      
      my $qindent = 0;
      my $qindmin = 0;
      my $lastlno = 0;
      my $blanks = 0;
      my $closer = 0;
      my $blanks_before = 0;
      my $plus_quoted = 0;
      my $plus_indent = 0;
      
      my $starting_quote = 0;
      my $quoting = 0;
      my $glom = 0;
      my $glom_until = undef;
      my $first_line = 1;
      my $first = 0;
      
      my $line_continues = 0;
      my $line_continued = 0;

      my @token_buffer = ();
      my $yield_token = sub {
         my $tok = shift;
         return unless $tok;
         unshift @token_buffer, $tok;
      };
      
      my @indentation_stack = ();
      
      my $pop_frame = sub { # This weird style is because I'm porting from a Racket generator. This seems most natural as a translation; sorry for the accent.
         my $correction = shift;
         #$debug_out->("Asked to pop frame from stack of " . scalar (@indentation_stack));
         return unless scalar @indentation_stack;
         my $ret = ['end', $lastlno - $blanks_before - $correction, $qindmin, 0, '']; # This is the token that will be returned by the caller.
         $qindmin = pop @indentation_stack;
         $debug_out->("Indentation stack popped, now " . scalar (@indentation_stack) . " with q $qindmin");
         $closer = 1;
         $first_line = 1;
         if (not @indentation_stack and $self->{input_type} eq 'textplus') {
            $check_barewords = 0;
            $check_quotes = 0;
            $check_brackets = 0;
            $check_plus = 1;
            $plus_quoted = 0;
            $first_line = 1;
            $quoting = 0;
            $starting_quote = 0;
            $stop_on_blank = 1;
         }
         return $ret;
      };
      my $pop_frames_to_indent = sub {
         my $indent = shift;
         #print STDERR "Asked to pop stack of " . scalar(@indentation_stack) . " to indent $indent; q $qindmin\n" if $debug;
         while (@indentation_stack and $indent < $qindmin) {
            #print STDERR "Popping frame " . scalar(@indentation_stack) . " because i $indent > q $qindmin\n" if $debug;
            $yield_token->($pop_frame->( $indent == -1 ? 0 : 1 ));
         }
      };
      
      if ($self->{input_type} eq 'text') {
         $quoting = 1;
         $glom = 1;
      }
      if ($self->{input_type} eq 'para') {
         $stop_on_blank = 1;
      }
      if ($self->{input_type} eq 'block') {
         $check_barewords = 0;
         $check_quotes = 0;
         $check_brackets = 0;
         $force_sigil_space = 1;
         $stop_on_blank = 1;
      }
      if ($self->{input_type} eq 'textplus') {
         $check_barewords = 0;
         $check_quotes = 0;
         $check_brackets = 0;
         $check_plus = 1;
         $force_sigil_space = 1;
         $stop_on_blank = 1;
      }
      
      my $done = 0;
      
      my $line_iter = $self->{source}->iter;
      
      sub {
         YIELD:
         #print STDERR "Yield @ line $lastlno\n" if $debug;
         if (@token_buffer) {
            #print STDERR "Popping token buffer\n" if $debug;
            my $tok = pop @token_buffer;
            my ($t, $l, $n, $len, $tt) = @$tok;
            $debug_out->( " --> ['$t', $l, $n, $len, '$tt']" );
            return $tok;
         }
         if ($done) {
            #print STDERR "Done and glom is $glom and bb $blanks\n" if $debug;
            if ($glom and $blanks) {
               while ($blanks) {
                  $lastlno += 1;
                  $yield_token->(['text', $lastlno, 0, 0, '']);
                  $blanks -= 1;
               }
            }
            if (@indentation_stack) {
               #print STDERR scalar @indentation_stack;
               #print STDERR " Done, so popping stack\n";
               $pop_frames_to_indent->(-1);
               goto YIELD;
            }
            return undef;
         }
         
         # Get a line and quit if there aren't any more.
         my $line = $line_iter->();
         if (not $line) {
            $done = 1;
            goto YIELD;
         }
         
         $line_continued = $line_continues;
         $line_continues = 0;
         
         # We have a line to process.
         my ($type, $lno, $indent, $len, $text) = @$line;
         $debug_out->( "LINE $lno: $type $indent $len $text" );
         my $advance_cursor = sub {
            my $tlen = shift; # Token length to advance by
            $indent = $indent + $tlen;
            $len = $len - $tlen;
            $text = substr ($text, $tlen);
         };
         
         $first = 1;
         $tokens_found = 0;
         my $non_name = 0;
         my $textrest = 0;

         if ($line_continued) {
            $first = 0;
            $non_name = 1;
         }
         
         my $push_frame = sub {
            my $indmin = shift;
            #print STDERR "Pushing $indmin on stack\n";
            push @indentation_stack, $qindmin;
            $qindmin = $indmin;
         };
         my $push_frame_on_plus = sub {
            my $indent = shift;
            $pop_frames_to_indent->($indent);
            $push_frame->($indent + 1);
            $yield_token->(['start', $lno, $indent, 0, '']);
         };
         my $push_frame_if_first = sub {
            my $indent = shift;
            if ($first) {
               $first = 0;
               if ($plus_quoted) { # The *first* tag quoted in the textplus + block shouldn't start a frame, but then that flag should turn off
                  $plus_quoted = 0;
               } elsif (not $plus_quoted) {
                  $pop_frames_to_indent->($indent);
                  $push_frame->($indent + 1);
                  $yield_token->(['start', $lno, $indent, 0, '']);
               }
            }
         };

         if ($type eq 'blank') { # Our line iterator just gave us a blank line.
            $first_line = 1;
            if ($stop_on_blank and not $quoting and not $plus_quoted) {
               $blanks += 1;
               $in_text_block = 0;
               $debug_out->( "Popping frame at ll# $lastlno bb $blanks_before corr 0" );
               $yield_token->($pop_frame->(0));
            }
            $blanks += 1 if ($glom or $self->{input_type} eq 'text');
            goto YIELD;
         }
         
         $blanks_before = $blanks;
         $blanks = 0;
         $lastlno = $lno;
         
         if ($self->{input_type} eq 'para') {
            if ($first_line) {
               $yield_token->(['tstart', $lno, 0, 0, '']);
               $push_frame->(0);
            }
            $first_line = 0;
            $yield_token->(['text', $lno, $indent, $len, $text]);
            goto YIELD;
         } 
         
         if ($plus_quoted and $indent < $plus_indent) {
            $pop_frames_to_indent->($indent);
         }
         
         NEXT_TOKEN:
         $debug_out->( "Advancing token $lno $indent $len" );
         my $probe;
         
         $probe = match_white ($text);
         if ($probe) {
            my ($tlen, $ttxt) = @$probe;
            $advance_cursor->($tlen);
            goto NEXT_TOKEN;
         }
         
         if ($textrest) {
            $yield_token->(['text', $lno, $indent, $len, $text]);
            goto YIELD;
         }
         
         if ($starting_quote) {
            $push_frame->($indent);
            $yield_token->(['qstart', $lno, $indent, 0, '']);
            $quoting = 1;
            $starting_quote = 0;
         }
         
         if ($quoting or $self->{input_type} eq 'text' or $self->{input_type} eq 'para') {
            $debug_out->("Quoting or reading text");
            if ($glom) {
               if ($glom_until) {
                  if ($text eq $glom_until) {
                     $glom = 0;
                     $glom_until = undef;
                     while ($blanks_before) {
                        $yield_token->(['text', $lno - $blanks_before, 0, 0, '']);
                        $blanks_before -= 1;
                     }
                     $yield_token->(['closer', $lno, $indent, $len, $text]);
                     $yield_token->(['end', $lno, $indent, 0, '']);
                     $pop_frame->(1);
                     goto YIELD;
                  }
               }
               $debug_out->( "Glomming with $blanks_before blanks" );
               while ($blanks_before) {
                  $yield_token->(['text', $lno - $blanks_before, 0, 0, '']);
                  $blanks_before -= 1;
               }
               $yield_token->(['text', $lno, $indent, $len, $text]);
               goto YIELD;
            }
          
            $debug_out->( "Not glomming, i $indent q $qindmin" );
            if ($indent < $qindmin) { # !differs: wrong paren indentation in Racket
               $debug_out->( "This line is too far back already; quoted text done" );
               if ($closer) {
                  if ($closer eq $text) {
                     $yield_token->(['closer', $lno, $indent - $qindmin, $len, $text]); # The indentation of the closer is *negative*.
                     $pop_frames_to_indent->($indent);
                     $quoting = 0;
                     goto YIELD; # We used up this line with the closer.
                  }
               }
               
               $pop_frames_to_indent->($indent); # We're done with the quoted text and have to buffer the appropriate tokens, but this line
                                                     # still needs to be processed.
               $quoting = 0;
            } else {
               while ($blanks_before) {
                  $yield_token->(['text', $lno - $blanks_before, 0, 0, '']);
                  $blanks_before -= 1;
               }
               $yield_token->(['text', $lno, $indent - $qindmin, $len, $text]);
               goto YIELD;
            }
         }
         
         if ($check_plus) {
            $probe = match_plus ($text);
            if ($probe and not $line_continued) {
               my ($tlen, $ttxt) = @$probe;
               if ($in_text_block) {
                  $debug_out->( "Encountered plus tag in text block; popping frame" );
                  $pop_frame->(1);
                  $yield_token->(['end', $lno, $indent, 0, '']);
                  $in_text_block = 0;
               }
               
               $push_frame_on_plus->($indent);
               $yield_token->(['plus', $lno, $indent, $tlen, $ttxt]);
               $advance_cursor->($tlen);
               $check_barewords = 1; # Simulate 'tag' mode until the stack pops off
               $check_quotes = 1;
               $check_brackets = 1;
               $check_plus = 0;
               $plus_quoted = 1;
               $plus_indent = $indent;
               $tokens_found = 1;
               goto NEXT_TOKEN;
            }
         }
         
         if ($check_barewords) {
            $probe = match_bareword ($text);
            if ($probe) {
               my ($tlen, $ttxt) = @$probe;
               my $ttype = $first    ? 'tag' :
                            $non_name ? 'word' :
                            'name';
               $push_frame_if_first->($indent) unless $line_continued;
               $yield_token->([$ttype, $lno, $indent, $tlen, $ttxt]);
               $advance_cursor->($tlen);
               $tokens_found = 1;
               goto NEXT_TOKEN;
            }
         }
         
         if ($check_brackets) {
            $probe = match_brackets ($text);
            if ($probe) {
               my ($tlen, $ttxt) = @$probe;
               $push_frame_if_first->($indent) unless $line_continued;
               $yield_token->(['bracket', $lno, $indent, $tlen, $ttxt]);
               $advance_cursor->($tlen);
               $non_name = 1;
               $tokens_found = 1;
               goto NEXT_TOKEN;
            }
         }
         
         if ($check_quotes) {
            $probe = match_quoted ($text);
            if ($probe) {
               my ($tlen, $ttxt) = @$probe;
               $push_frame_if_first->($indent) unless $line_continued;
               $yield_token->(['quote', $lno, $indent, $tlen, $ttxt]);
               $advance_cursor->($tlen);
               $non_name = 1;
               $tokens_found = 1;
               goto NEXT_TOKEN;
            }
         }
         
         if ($check_sigils) {
            $debug_out->( "Checking for sigil on $text" );
            $probe = match_sigil ($text);
            if ($probe) {
               my ($tlen, $ttxt) = @$probe;
               $debug_out->( "Sigil $ttxt" );
               $tokens_found = 1;
               if ($in_text_block) {
                  $debug_out->( "Encountered sigil in text block; popping frame" );
                  $pop_frame->(1);
                  $yield_token->(['end', $lno, $indent, 0, '']);
                  $in_text_block = 0;
               }
               my $line_cont = $ttxt eq '|';
               my $ttype = $line_cont ? 'cont' : 'sigil';
               $debug_out->( "f $first fss $force_sigil_space mw " . (match_white(substr($text, $tlen)) ? 1 : 0));
               if (not $first or not $force_sigil_space or ($tlen eq $len) or match_white(substr($text, $tlen))) { # !differs: substr(...) instead of ttxt
                  #                                             ^^^^^^^^^^^^^^^ - this feels arbitrary for dash-alone corner case
                  $push_frame_if_first->($indent) unless $line_continued;
                  $yield_token->([$ttype, $lno, $indent, $tlen, $ttxt]);
                  $advance_cursor->($tlen);
                  $non_name = 1;
                  $textrest = $line_cont;
                  $debug_out->( " - sigil is $ttxt" );
                  $closer = _closing_bracket ($ttxt);
                  $debug_out->( " - closer is " . ($closer ? $closer : '(none)') );
                  
                  if ($ttxt =~ /<<(.*)$/) { # Special <<< or <<EOF quote-inclusion
                     $len = 0;
                     $glom = 1;
                     if ($1 eq '') {
                        $glom_until = 'EOF';
                     } elsif ($1 ne '<') {
                        $glom_until = $1;
                     } else {
                        $glom_until = undef; # This gloms to the end of the line iterator.
                     }
                  }
                  
                  if (not $line_cont) {
                     $debug_out->( "Starting quoted text next line" );
                     $starting_quote = 1;
                     $blanks_before = 0;
                     if (not $len) {
                        goto YIELD;
                     }
                  }
                  $line_continues = 1 if $line_cont;
                  #goto YIELD; # !differs: fall through instead of NEXT_TOKEN
               }
            }
         }
         
         # We have a line, but it didn't get tokenized up until here because the matchers are disabled - meaning it's a text line in  a text mode.
         # So here we just pretend we're in 'para' mode, except we need to dump any starting whitespace.
         $probe = match_white($text);
         if ($probe) {
            $advance_cursor->($probe->[0]);
         }
         if ($len) {
            if ($tokens_found) {
               $debug_out->( "There is extra text on this line." );
               if ($first_line) {
                  $first_line = 0;
                  $yield_token->(['qstart', $lno, $indent, 0, '']); # !differs: 'tstart' in Racket
                  $push_frame->($indent);
                  $quoting = 1; # !differs
                  $starting_quote = 0; # !differs
                  $debug_out->( "qindmin now $qindmin" );
               }
            } else {
               $debug_out->( "This line is text but not quoted." );
               if ($first_line) {
                  $first_line = 0;
                  $yield_token->(['tstart', $lno, $indent, 0, '']);
                  $push_frame->($indent);
                  $in_text_block = 1;
               }
            }
            $yield_token->(['text', $lno, $indent - $qindmin, $len, $text]); # Note: indent will always be 0
         }
         
         goto YIELD;
      }
   };

   $self;
}

sub _closing_bracket {
   my $bracket = shift;
   return '}' if $bracket eq '{';
   return ')' if $bracket eq '(';
   return '>' if $bracket eq '<';
   return ']' if $bracket eq ']';
}

=head1 MATCHING INDIVIDUAL TOKENS

The different classes of tokens each have a matcher that can be called on a given string. If the string begins with the relevant type of token, the caller gets back the length
that matched and the matched token as an arrayref. If not, it gets an undef.

=head2 match_white

Matches whitespace.

=cut

sub match_white {
   if ($_[0] =~ /^(\s+)/) {
      return [length ($1), $1]
   }
   return undef;
}

=head2 match_bareword

Given a string, checks whether it starts with a Decl bareword. A bareword is pretty liberal in comparison with most languages; mostly we just have to make sure we don't
collide with sigils.

=cut

sub match_bareword {
   my $string = shift;

   if ($string =~ /^([[:alnum:]_](:*[[:alnum:]!@#$%\^&*=\-+~_.,;\|\(\)\[\]\?<>{}])*)(.*)/) {
      my ($bareword, $rest) = ($1, $2);
      # The above regex grabs colon-punctuation sigils where it shouldn't, so let's split those off now.
      # (I actually worked this out in, and brought the tests over from, Racket tok.rkt.)
      if ($bareword =~ /^(.*):[[:punct:]]+$/) {
         $bareword = $1;
      }
      # One slight weirdness that is best handled in a separate stage: a sigil of the form ...<<EOF will match the above regex and be counted as a single bareword.
      if ($bareword =~ /([[:punct:]]*<<([[:alnum:]\-]*))$/) {
         $bareword = substr ($bareword, 0, length($bareword) - length($1));
      }
      return [length ($bareword), $bareword];
   }
   return undef;
}

=head2 match_quoted

=cut

sub match_quoted {
   my $string = shift;
   
   # Do we have a single-quoted string?   
   if ($string =~ /^'((?:\\.|[^'])*)'(.*)/) {
      my ($content, $rest) = ($1, $2);
      return [length($content)+2, substr($string, 0, length($content)+2)];
   }

   # How about a double-quoted string?
   if ($string =~ /^"((?:\\.|[^"])*)"(.*)/) {
      my ($content, $rest) = ($1, $2);
      return [length($content)+2, substr($string, 0, length($content)+2)];
   }
   return undef;
}

=head2 match_brackets

=cut

sub match_brackets {
   my $string = shift;
   my $bracket = substr ($string, 0, 1);
   return undef unless $bracket eq '[' or $bracket eq '{' or $bracket eq '(' or $bracket eq '<';
   my $closer = $bracket;
   $closer =~ tr/\(\[<{/)]>}/;
   
   my $copy = substr ($string, 1);
   
   # First, eliminate all quoted strings.
   while ($copy =~ /('(?:\\.|[^'])*'|\"(?:\\.|[^\"])*\")/) {
      my $match = $1;
      my $rep = ' ' x length($match);
      $copy =~ s/\Q$match\E/$rep/g;
   }
   # Now, eliminate all bracket pairs.
   while ($copy =~ /(\Q$bracket\E(?:\\.|[^$bracket$closer])*\Q$closer\E)/) {
      my $match = $1;
      my $rep = ' ' x length($match);
      $copy =~ s/\Q$match\E/$rep/g;
   }
   # Is there a closer on the line?
   if ($copy =~ /^(.*)\Q$closer\E(.*)/) {
      return [length($1) + 2, substr($string, 0, length($1) + 2)];
   }
   return undef;
}

=head2 match_sigil

=cut

sub match_sigil {
   my $string = shift;
   if ($string =~ /^([[:punct:]]+)([[:alnum:]\-]*)/) {
      my ($p, $tag) = ($1, $2);
      $p .= $tag if $p =~ /<<$/;
      return [length ($p), $p];
   }
   return undef;
}

=head2 match_plus

=cut

sub match_plus {
   if ($_[0] =~ /^\+/) {
      return [1, '+']
   }
   return undef;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl-tok at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl-Tok>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Decl::Tok


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Decl-Tok>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Decl-Tok>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Decl-Tok>

=item * Search CPAN

L<http://search.cpan.org/dist/Decl-Tok/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2021 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Decl::Tok
