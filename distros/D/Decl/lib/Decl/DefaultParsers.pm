package Decl::DefaultParsers;

use warnings;
use strict;
use Decl::Parser;
use Decl::Util;
use Decl::Node;
use Data::Dumper;


=head1 NAME

Decl::DefaultParsers - implements the default parsers for the Declarative language.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This isn't really an object module; it's just a convenient place to stash the default parsers we use, in order to make it easier to work with the Decl code.

=head2 init_default_line_parser(), init_default_body_parser(), init_locator_parser(), including locally defined is_blank, is_blank_or_comment, and line_indentation

These are called by C<init_parsers> to initialize our various sublanguage parsers.  You don't need to call them.

=cut

sub init_default_line_parser {
   my ($self) = @_;
   
   # Default line parser.
   my $p = Decl::Parser->new();
   
   $p->add_tokenizer ('CODEBLOCK'); # TODO: parameterizable, perhaps.
   $p->add_tokenizer ('STRING', "'(?:\\.|[^'])*'|\"(?:\\.|[^\"])*\"",
                      sub {
                         my $s = shift;
                         $s =~ s/.//;
                         $s =~ s/.$//;
                         $s =~ s/\\(['"])/$1/g;
                         $s =~ s/\\\\/\\/g;
                         $s =~ s/\\n/\n/g;
                         $s =~ s/\\t/\t/g;
                         ['STRING', $s]
                      }); # TODO: this should be globally available.
   $p->add_tokenizer ('BRACKET', '{.*');
   $p->add_tokenizer ('COMMENT', '#.*');
   $p->add_tokenizer ('WHITESPACE*', '\s+');
   $p->add_tokenizer ('EQUALS',  '=');
   $p->add_tokenizer ('COMMA',   ',');
   $p->add_tokenizer ('LPAREN',  '\(');
   $p->add_tokenizer ('RPAREN',  '\)');
   $p->add_tokenizer ('LBRACK',  '\[');
   $p->add_tokenizer ('RBRACK',  '\]');
   $p->add_tokenizer ('LT',      '<');
   
   $p->add_rule ('line',       'p_and(optional(<name>), optional(<parmlist>), optional(<optionlist>), optional (<label>), optional(<parser>), optional(<code>), optional(<bracket>), optional(<comment>), \&end_of_input)');
   $p->add_rule ('name',       'one_or_more(\&word)');
   $p->add_rule ('parmlist',   'p_and(token_silent(["LPAREN"]), list_of(<parm>, "COMMA*"), token_silent(["RPAREN"]))');
   $p->add_rule ('parm',       'p_or(<parmval>, one_or_more(\&word))');
   $p->add_rule ('parmval',    'p_and(\&word, token_silent(["EQUALS"]), <value>)');
   $p->add_rule ('value',      'p_or(\&word, token(["STRING"]))');
   $p->add_rule ('optionlist', 'p_and(token_silent(["LBRACK"]), list_of(<parm>, "COMMA*"), token_silent(["RBRACK"]))');
   $p->add_rule ('label',      'token(["STRING"])');
   $p->add_rule ('parser',     'p_and(\&word, token_silent(["LT"]))');
   $p->add_rule ('code',       'token(["CODEBLOCK"])');
   $p->add_rule ('bracket',    'token(["BRACKET"])');
   $p->add_rule ('comment',    'token(["COMMENT"])');
   
   $p->action ('input', sub {
      my ($parser, $node, $input) = @_;
      if (not ref $node) {
         $node = 'tag' unless defined $node;
         $node = Decl::Node->new($node);
      }
      $parser->{user}->{node} = $node;
      $input = $node->line() unless $input;
   });
   $p->action ('output', sub {
      my ($parse_result, $parser) = @_;
      my $node = $parser->{user}->{node};
      if (defined $parse_result and car($parse_result) eq 'line') {
         foreach my $piece (@{$parse_result->[1]}) {
            if      (car($piece) eq 'name') {
               my @names = map { cdr $_ } @{cdr($piece)};
               $node->{name} = $names[0];
               $node->{namelist} = \@names;
            } elsif (car($piece) eq 'parmlist') {
               my @parmlist = ();
               foreach my $parm (@{cdr($piece)}) {
                  my $value = cdr($parm);
                  if (car($value) eq 'parmval') {
                     my $parameter = cdr(car(cdr($value)));
                     my $val = cdr(cdr(cdr(cdr($value))));
                     push @parmlist, $parameter;
                     $node->{parameters}->{$parameter} = $val;
                  } else {
                     my @words = map { cdr $_ } @$value;
                     my $parameter = join ' ', @words;
                     push @parmlist, $parameter;
                     $node->{parameters}->{$parameter} = 'yes';
                  }
               }
               $node->{parmlist} = \@parmlist;
            } elsif (car($piece) eq 'optionlist') {
               my @parmlist = ();
               foreach my $parm (@{cdr($piece)}) {
                  my $value = cdr($parm);
                  if (car($value) eq 'parmval') {
                     my $parameter = cdr(car(cdr($value)));
                     my $val = cdr(cdr(cdr(cdr($value))));
                     push @parmlist, $parameter;
                     $node->{options}->{$parameter} = $val;
                  } else {
                     my @words = map { cdr $_ } @$value;
                     my $parameter = join ' ', @words;
                     push @parmlist, $parameter;
                     $node->{options}->{$parameter} = 'yes';
                  }
               }
               $node->{optionlist} = \@parmlist;
            } elsif (car($piece) eq 'parser') {
               $node->{parser} = cdr car cdr $piece;
            } else {
               $node->{car($piece)} = cdr(cdr($piece));  # Elegance!  We likes it, precioussss.
            }
         }
      }
      return $node;
   });
   
   $p->build();
   return $p;
}

sub init_default_body_parser {
   my ($self) = @_;
   
   # Default body parser.
   my $p = Decl::Parser->new();
   
   $p->add_tokenizer ('BLANKLINE', '\n\n+');
   $p->add_tokenizer ('NEWLINE*', '\n');
   $p->add_rule ('body', 'series(p_or(\&word, token("BLANKLINE")))');
   $p->action ('input', sub {
      my ($parser, $context, $parent, $input) = @_;
      $input
   });
   $p->action ('output', sub {
      my ($parse_result, $parser, $context, $parent, $input) = @_;
      my @results = ();
      my @nodes_made = ();
      my $root = $parent->root();
      return () unless popcar($parse_result) eq 'body';
      my $indent = 0;
      my $lineindent = 0;
      my $thisindent = 0;
      my $curtext = '';
      my $tag = '';
      my $blanks = '';
      my $firstcode = '';
      my $rest;
      my $spaces = '';
      my $bracket = '';
      
      my $starttag = sub {
         my ($line) = @_;
         if ($line =~ /^(\s+)/) {
            $lineindent = length ($1);
            $line =~ s/^\s*//; # Discard any indentation before the tag line
         } else {
            $lineindent = 0;
         }
         if ($curtext) {
            push @results, $curtext;
         }
         $curtext = $line . "\n";
         ($tag, $rest) = split /\s+/, $line, 2;
         $indent = 0;
      };
      
      my $concludetag = sub {
         # print STDERR "---- concludetag: $tag\n";
         my $newnode = $context->makenode($parent, $tag, $curtext);
         $newnode->{parent} = $parent;
         push @results, $newnode;
         push @nodes_made, $newnode;
         $tag = '';
         $curtext = '';
         $indent = 0;
      };
      sub is_blank { $_[0] =~ /^(\s|\n)*$/ };
      sub is_blank_or_comment {
         $_ = shift;
         /^\s*#/ || is_blank ($_)
      };
      sub line_indentation {
         if ($_[0] =~ /^(\s+)/) {
            length($1)
         } else {
            0
         }
      }
      
      # print STDERR "\n\n----- Starting " . $parent->tag . " with:\n$input-----------------------\n";
      foreach (@$parse_result) {
         my ($type, $line) = splitcar ($_);
         my $testline = $line;
         $testline =~ s/\n/\\n/g;
         # print STDERR "$testline : ";
         $line =~ s/\n*// if $type;  # If we have a BLANKLINE token, there are one too many \n's in there.
         if (not $tag) {   # We're in a blank-and-comment stretch
            if (is_blank_or_comment($line)) {
               # print STDERR "blank-or-comment\n";
               $curtext .= $line . "\n";
            } else {
               # print STDERR "start tag\n";
               $starttag->($line);
            }
         } else {   # We're in a tag
            if (not $indent) {    # We just started it, though.
               $indent = line_indentation($line);
               if ($indent <= $lineindent) {   # And the first line after the starting line is already back-indented!
                  if (is_blank($line)) {  # This is a blank line, though, so it may not count as indented.
                     # print STDERR "blank line at start of tag\n";
                     $blanks .= $line;    # We'll stash it and try again.
                     $indent = 0;
                  } else {  # It's not a blank; it's either a new tag, or a comment.
                     $concludetag->();
                     if (is_blank_or_comment($line)) {
                        # print STDERR "blank-or-comment\n";
                        $curtext = $blanks . $line . "\n";
                        $blanks = '';
                     } else {
                        if ($blanks) {
                           # print STDERR "(had some leftover blanks) ";
                           push @results, $blanks;
                           $blanks = '';
                        }
                        # print STDERR ("starting new tag\n");
                        $starttag->($line);
                     }
                  }
               } elsif (is_blank ($line)) {
                  # print STDERR "blank line at start of tag with longer indent\n";
                  $blanks .= $line; # Stash it and keep going.
                  $indent = $lineindent; # 2010-07-24 - and don't let 'indent' get updated
               } else {   # This is the first line of the body, because it's indented further than the opening line.
                  $spaces = ' ' x $indent;
                  $line =~ s/^$spaces//;
                  if ($blanks) {
                     # print STDERR "(had blanks) ";
                     $curtext .= $blanks;
                     $blanks = '';
                  }
                  # print STDERR "first line of body\n";
                  $curtext .= $line . "\n";
               }
            } else {
               if (line_indentation ($line) < $indent) { # A new back-indentation!
                  if (is_blank($line)) { # If this is blank, we don't add it to the body until there's more to add.
                     # print STDERR ("stash blank line\n");
                     $blanks .= $line . "\n";
                  } elsif ($line =~ /^\s*}/) { # Closing bracket; we don't check for matching brackets; the closing bracket is really just a sort of comment.
                     # print STDERR ("closing bracket\n");
                     $concludetag->();
                  } elsif (is_blank_or_comment($line)) { # Comment; this by definition belongs to the parent.
                     # print STDERR ("back-indented comment, denoting end of last tag\n");
                     $concludetag->();
                     $curtext = $blanks . $line . "\n";
                     $blanks = '';
                  } else {  # Next tag line.
                     $concludetag->();
                     if ($blanks) {
                        # print STDERR "(had some blanks) ";
                        push @results, $blanks;
                        $blanks = '';
                     }
                     # print STDERR "starting tag!\n";
                     $starttag->($line);
                  }
               } elsif (is_blank ($line)) { # This blank line may fall between nodes, or be part of the current one.
                  # print STDERR "stash blank line within body\n";
                  $blanks .= $line . "\n";
               } else { # Normal body line; toss it into the mix.
                  $line =~ s/^$spaces//;
                  if ($blanks) {   # If we've stashed some blanks, add them back.
                     # print STDERR "(had some blanks) ";
                     $curtext .= $blanks;
                     $blanks = '';
                  }
                  # print STDERR "body line >> $line\n";
                  $curtext .= $line . "\n";
               }
            }
         }
      }
      if ($curtext) {
         if ($tag) {
            # print STDERR "FINAL: had a tag\n";
            $concludetag->();
         } else {
            # print STDERR "FINAL: extra text\n";
            push @results, $curtext;
         }
      }
      if ($blanks) {
         # print STDERR "FINAL: extra blanks\n";
         push @results, $blanks;
      }
      $parent->{elements} = [$parent->elements, @results];
      @nodes_made
   });
   
   $p->build();   # Forgetting this cost me several hours of debugging...
   return $p;
}

sub init_locator_parser {
   my ($self) = @_;
   
   my $p = Decl::Parser->new();
   
   $p->add_tokenizer ('STRING', "'(?:\\.|[^'])*'|\"(?:\\.|[^\"])*\"",
                      sub {
                         my $s = shift;
                         $s =~ s/.//;
                         $s =~ s/.$//;
                         $s =~ s/\\(['"])/$1/g;
                         $s =~ s/\\\\/\\/g;
                         $s =~ s/\\n/\\n/g;
                         $s =~ s/\\t/\\t/g;
                         ['STRING', $s]
                      });
   $p->add_tokenizer ('WHITESPACE*', '\s+');
   $p->add_tokenizer ('MATCHES',   '=~');
   $p->add_tokenizer ('EQUALS',    '=');
   $p->add_tokenizer ('SEPARATOR', '[.:/]');
   $p->add_tokenizer ('LPAREN',    '\(');
   $p->add_tokenizer ('RPAREN',    '\)');
   $p->add_tokenizer ('LBRACK',    '\[');
   $p->add_tokenizer ('RBRACK',    '\]');
   
   $p->add_rule ('locator',    'list_of(<tag>, "SEPARATOR*")');
   $p->add_rule ('tag',        'p_and(\&word, p_or (<attribute>, <match>, <offset>, <name>, \&nothing))');
   $p->add_rule ('name',       'p_and(token_silent(["LBRACK"]), one_or_more(\&word), token_silent(["RBRACK"]))');
   $p->add_rule ('attribute',  'p_and(token_silent(["LBRACK"]), \&word, token_silent(["EQUALS"]), p_or(\&word, token (["STRING"])), token_silent(["RBRACK"]))');
   $p->add_rule ('match',      'p_and(token_silent(["LBRACK"]), \&word, token_silent(["MATCHES"]), p_or(\&word, token (["STRING"])), token_silent(["RBRACK"]))');
   $p->add_rule ('offset',     'p_and(token_silent(["LPAREN"]), \&word, token_silent(["RPAREN"]))');
   
   $p->action ('output', sub {
      my ($parse_result, $parser) = @_;
      my $list = cdr $parse_result;
      my @pieces = ();
      foreach (@$list) {
         my $t = cdr $_;
         my $tag = cdr car $t;
         my $rest = cdr $t;
         if (defined $rest) {
            my ($type, $spec) = @$rest;
            if ($type eq 'name') {
               my @names = map { cdr $_ } @$spec;
               push @pieces, [$tag, @names];
            } elsif ($type eq 'attribute') {
               push @pieces, [$tag, ['a', cdr car $spec, cdr cdr $spec]];
            } elsif ($type eq 'match') {
               push @pieces, [$tag, ['m', cdr car $spec, cdr cdr $spec]];
            } elsif ($type eq 'offset') {
               push @pieces, [$tag, ['o', cdr car $spec]];
            }
         } else {
            push @pieces, $tag;
         }
      }
      return \@pieces;
   });
   
   $p->build();
   return $p;
}
=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::DefaultParsers
