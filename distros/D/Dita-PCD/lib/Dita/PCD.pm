#!/usr/bin/perl -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Dita::PCD - Implementation of the Please Change Dita Language.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
#podDocumentation
# cd /home/phil/perl/cpan/DitaPCD/; perl Build.PL && perl Build test && sudo perl Build install
# initial - 0.1296. checkout: 0.083, optimized: 0.064 with each command a sub

package Dita::PCD;
our $VERSION = 20201103;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);

sub padLength {8}                                                               # Padding length for editor fields

#D1 Please Change Dita                                                          # Edit L<Dita> using directives written in  L<pcd>. An introduction to l<pcd> can be found at: L<pcdLang>.

sub ditaPcdBase($)                                                              #P Base of various objects used by the editor
 {my ($rowType) = @_;                                                           # Row type
   (action       => q(),                                                        # Action to be applied to the comment
    actionError  => q(),                                                        # Error in chosen action if true
    rowType      => $rowType,                                                   # Row type
    rowTypeError => q(),                                                        # Error in chosen row type if true
   );
 }

sub newDitaPcdComment(%)                                                        #P Create a new comment
 {my (%options) = @_;                                                           # Attributes
  my $h =
    genHash(q(DitaPcdComment),                                                  # Description of a comment
      ditaPcdBase(q(comment)),                                                  # Common row start
      comment   => q(),                                                         # Comment text
    );
  loadHash($h, %options)
 }

sub newDitaPcdDescription(%)                                                    #P Create a new description
 {my (%options) = @_;                                                           # Attributes
  my $h =
    genHash(q(DitaPcdDescription),                                              # Description
      ditaPcdBase(q(description)),                                              # Common row start
      description => q(),                                                       # Description text
    );
  loadHash($h, %options)
 }

sub newDitaPcdMethod(%)                                                         #P Create a new Method
 {my (%options) = @_;                                                           # Attributes
  my $h =
    genHash(q(DitaPcdMethod),
      ditaPcdBase(q(method)),                                                   # Common row start
      context       => [],                                                      # Context for this method call
      contextErrors => {},                                                      # Errors in chosen context if entries present
      methodError   => q(),                                                     # Error in chosen method if true
      method        => q(),                                                     # Method name - a unitary method in Data::Edit::Xml
    );
  loadHash($h, %options)
 }

sub newDitaPcdParseTree(%)                                                      #P Create a new Parse Tree
 {my (%options) = @_;                                                           # Attributes
  my $h =
    genHash(q(DitaPCDParseTree),
      inputFile => q(),
      errors    => [],
      rows      => [],
    );
  loadHash($h, %options)
 }

sub parsePcdString($)                                                           #P Parse the specified L<pcd> directives B<$string> specifying changes to be made to L<dita> files.
 {my ($string) = @_;                                                            # String of PCD directives

  my $ditaTags = &pcdDitaTags;                                                  # Dita tag names
  my @i = split /\n/, $string;
  my @p;                                                                        # Parse tree

  for my $i(keys @i)                                                            # Each line==row of a pcd file
   {my $l = $i[$i];                                                             # Row to process
    my $j = $i + 1;                                                             # Current row number

    next unless $l =~ m(\S);                                                    # Ignore empty rows

    if ($l =~ m(\A\s*#\s*(.*?)\s*\Z))                                           # Comment
     {push @p, newDitaPcdComment(comment=>trim($1));
     }
    elsif ($l =~ m(\A\S))                                                       # Description
     {push @p, newDitaPcdDescription(description=>$l);
     }
    else                                                                        # Method
     {if (my ($method, @context) = split m/\s+/, trim($l))                      # Parse command string invoking method
       {push @p, newDitaPcdMethod(method=>$method, context=>[@context]);
       }
     }
   }

  newDitaPcdParseTree(rows => \@p)                                              # Parse tree
 } # parsePcdString

sub parsePcdFile($)                                                             #P Parse the specified L<pcd> directives B<$file> specifying changes to be made to L<dita> files.
 {my ($if) = @_;                                                                # Input file
  my $p = parsePcdString(readFile($if));                                        # Read and parse file
  $p->inputFile = $if;                                                          # Add input file detail
  $p                                                                            # Return parse tree
 } # parsePcdFile

sub editPcdParseTree($)                                                         #P Validate a B<$parseTree>
 {my ($parseTree) = @_;                                                         # Parse tree

  my $ditaTags   = {map {$_=>1} &pcdDitaTags};                                  # Dita tag names
  my $rowActions = {map {$_=>1} &pcdRowActions};                                # Row actions
  my $rowTypes   = {map {$_=>1} &pcdRowTypes};                                  # Row types

  my @l = @{$parseTree->rows};                                                  # Rows in parse tree
  my @errors;
  my @delete;
  my @repeat;
  my @source;
  my @target;

  for my $l(@l)                                                                 # Each line==row of a pcd file
   {if (my $action = $l->action)                                                # Validate action
     {if ($action =~ m(\A(after|before)\Z)i)
       {push @target, $l;
       }
      elsif ($action =~ m(\A(copy|move)\Z)i)
       {push @source, $l;
       }
      elsif ($action =~ m(\Adelete\Z)i)
       {push @delete, $l;
       }
      elsif ($action =~ m(\Arepeat\Z)i)
       {push @repeat, $l;
       }
      elsif (!$$rowActions{$action})
       {$l->actionError = "No such action";
#       push @errors, $l;
       }
     }

    if (my $rowType = $l->rowType)                                              # Validate row type
     {if (!$$rowTypes{$rowType})
       {$l->methodError = q(No such row type);
#       push @errors, $l;
       }
     }

    if (ref($l) =~ m(method)i and my $method = $l->method)                      # Validate method
     {if (!isSubInPackage(q(Data::Edit::Xml), $method))
       {$l->methodError = q(No such method);
#       push @errors, $l;
       }

      if (my $context = $l->context)                                            # Validate context of method
       {for my $c(@$context)
         {if (!$$ditaTags{$c})
           {$l->contextErrors->{$c}++;
#           push @errors, $l;
           }
         }
       }
     }
   }

  if (@target == 0 and @source == 1)                                            # Paste required if copy or move
   {for my $l(@source)
     {$l->actionError = "At least one after or before required";
      push @errors, $l;
     }
   }

  if (@source > 1)                                                              # Only one copy or move allowed
   {for my $l(@source)
     {$l->actionError = "More than one copy and/or move";
      push @errors, $l;
     }
   }

  if (!@errors and @repeat || @delete)                                          # Perform delete or repeat
   {my @e;
    for my $l(@{$parseTree->rows})
     {if    ($l->action =~ m(\Adelete\Z)i) {}
      elsif ($l->action =~ m(\Arepeat\Z)i) {push @e, $l, $l}
      else                                 {push @e, $l}
     }
    $parseTree->rows = \@e;
   }

  if (!@errors and @source and @target)                                         # Perform copy|move after|before
   {for my $source(@source)
     {my @e;
      for my $l(@{$parseTree->rows})
       {if ($l == $source)
         {if ($l->action =~ m(\Acopy\Z)i)
           {push @e, $l;
           }
         }
        else
         {sub
           {for my $target(@target)
             {if ($l == $target)
               {if ($target->action =~ m(\Abefore\Z)i)
                 {push @e, $source, $l;
                 }
                else
                 {push @e, $l, $source;
                 }
                return;
               }
             }
            push @e, $l;
           }->();
         }
       }

      $parseTree->rows = @e ? \@e : newDitaPcdComment(comment=>q());            # Make sure there is at least one row in the parse tree otherwise it will be difficult to edit it
     }
   }

  if (!@errors)                                                                 # Remove actions now they have been successfully performed
   {for my $l(@{$parseTree->rows})
     {$l->action = q();
     }
   }

  $parseTree->errors = \@errors;                                                # List of rows with errors

  $parseTree                                                                    # Return parse tree
 } # editPcdParseTree

sub makeDataList($@)                                                            #P Create a data list
 {my ($name, @values) = @_;                                                     # Name, values
  join " ", qq(<datalist id="$name">), (map {qq(<option value="$_">)} sort @values), q(</datalist>);
 }

sub representPcdParseTreeAsHtml($)                                              #P Parse the specified L<pcd> directives B<$file> specifying changes to be made to L<dita> files.
 {my ($parseTree) = @_;                                                         # Parse tree

  editPcdParseTree $parseTree;                                                  # Annotate with any errors and return

  my $ditaTags = map {$_=>1} &pcdDitaTags;                                      # Dita tag names

  my @h;                                                                        # Generated html
  push @h, qq(<form class="editor" name="editor">);
  push @h, qq(<div oninput="expandInputField(event)" class="editor" name="editor">);
  push @h, q(<table border="0" cellpadding="10" cellspacing="10">);
  my @l = @{$parseTree->rows};
  for my $i(keys @l)                                                            # Show each row
   {my $I = $i + 1;
    my $R = sprintf("%08d_", $I);                                               # Unlikely to be this many rows in a PCD
    my $l = $l[$i];
    my $a = $l->action;
    my $t = lc ref($l) =~ s(\ADitaPcd) ()ir;

    my $n = $l->rowType = sub
     {return q(comment)     if ref($l) =~ m(comment)i;
      return q(description) if ref($l) =~ m(description)i;
      return q(method)      if ref($l) =~ m(method)i;
      confess "Unknown row type: ".ref($l);
     }->();

    my $d = $l->{$n}; my $D = length(pad($d, padLength));
    my $ae = $l->actionError  ? q(actionError)  : q();
    my $me = $n =~ m(method) && $l->methodError ? q(methodError) : q();
    my $te = $l->rowTypeError ? q(rowTypeError) : q();

    push @h,
      qq(<tr><td>),
      qq(<div class="row">),
      qq(<span class="rowNumber">$I</span>),
      qq(<input class="action  $ae" name="${R}action"   list="actions"  size="10" type="text"   value="$a">),
      qq(<input                     name="${R}rowType1"                           type="hidden" value="$t">),
      qq(<input class="rowType $te" name="${R}rowType2" list="rowTypes" size="12" type="text"   value="$n">),
      qq(<input class="method  $me" name="${R}method"   list="methods"  size="$D" type="text"   value="$d">);

    if (my $context = $l->{context})                                            # Show contexts chosen with a spare field at the end for additional context
     {pop  @$context while @$context and $$context[-1] !~ m(\S)s;
      push @$context, q();
      for my $j(keys @$context)
       {my $J  = $j + 1;
        my $c  = $$context[$j];
        my $e  = $c && $l->contextErrors->{$c} ? q(contextError) : q();
        my $lc = length(pad($c, padLength));
        push @h, qq(<input class="context $e" name="${R}context_$J" list="contexts" size="$lc" type="text" value="$c">);
       }
     }
    push @h, qq(</div>);
   }

  push @h, makeDataList q(actions),  sort &pcdRowActions;
  push @h, makeDataList q(rowTypes), sort &pcdRowTypes;
  push @h, makeDataList q(methods),  sort &pcdUnitaryMethods;
  push @h, makeDataList q(contexts), sort &pcdDitaTags;
  push @h, <<'END';
<script>
function expandInputField(event) {
  const target = event.target;
  const value = target.value;
  target.setAttribute("size", value.length + 4);
  if (target.classList.contains("action")) {
    if      (value.match(/^a$/i))  {target.value = "after"}
    else if (value.match(/^b$/i))  {target.value = "before"}
    else if (value.match(/^c$/i))  {target.value = "copy"}
    else if (value.match(/^d$/i))  {target.value = "delete"}
    else if (value.match(/^m$/i))  {target.value = "move"}
    else if (value.match(/^r$/i))  {target.value = "repeat"}
  }
}
</script>
END
  push @h, qq(</table></div><p><input class="editButton" name="submit" value="Edit" type="submit"></form>);
  join "\n", @h
 } # representPcdParseTreeAsHtml

sub printPcdHtml($)                                                             #P Print a PCD using L<html>
 {my ($string) = @_;                                                            # Pcd as a string

  my $p = parsePcdString($string);                                              # Create a parse tree for the pcd
  push my @h, qq(<div class="pcds">);

  for my $l($p->rows->@*)                                                       # Show each row
   {my $n = $l->rowType = sub
     {return q(comment)     if ref($l) =~ m(comment)i;
      return q(description) if ref($l) =~ m(description)i;
      return q(method)      if ref($l) =~ m(method)i;
      confess "Unknown row type: ".ref($l);
     }->();

    if    ($n =~ m(comment)i)
     {push @h, qq(<div class="pcdComment">).$l->{$n}.qq(</div>);
     }
    elsif ($n =~ m(description)i)
     {push @h, qq(<div class="pcdDescription">).$l->{$n}.qq(</div>);
     }
    elsif ($n =~ m(method)i)
     {push my @s, join '', qq(<div class="pcdMethodLine">),
       qq(<span class="pcdIndent">&nbsp;&nbsp;&nbsp;&nbsp;</span>),
       qq(<span class="pcdMethod">).$l->{$n}.qq(</span>);
      if (my $context = $l->{context})                                          # Show contexts chosen with a spare field at the end for additional context
       {for my $context(@$context)
         {push @s, qq(<span class="pcdContext">$context</span>);
         }
        push @h, join '&nbsp;', @s;
       }
      push @h, qq(</div>);
     }
   }
  push @h, qq(</div>);
  join "\n", @h
 } # printPcdHtml

sub parseUrlRepresentationOfPcd($)                                              #E Parse the url representation of a parse tree.
 {my ($url) = @_;                                                               # Url

  my @l;
  for my $key(sort keys %$url)                                                  # Go vertical
   {my $value = $$url{$key};
       $value =~ s(\+) ( )gs;                                                   # Remove url encoding
    if ($key =~ m(\A(\d+)_(.*)\Z)s)
     {my $row   = $1;
      my $field = $2;
      if ($key =~ m(\A\d+_context_(\d+)\Z)s)
       {my $context = $1;
        $l[$row-1]{context}[$context-1] = $value;
       }
      else
       {$l[$row-1]{$field} = $value;
       }
     }
   }

  my @p;                                                                        # Reconstruct parse tree
  for my $l(@l)                                                                 # Each row of the parse tree
   {my @action = $l->{action} ? (action => $l->{action}) : ();                  # Action specification
    my $method = $l->{method};                                                  # Method

    if (my $rowType = $l->{rowType1})                                           # Comment
     {if    ($rowType =~ m(comment)i)
       {push @p, newDitaPcdComment    (@action, comment=>$method);
       }
      elsif ($rowType =~ m(description)i)                                       # Description
       {push @p, newDitaPcdDescription(@action, description=>$method);
       }
      elsif ($rowType =~ m(method)i)                                            # Method
       {my $context = join ' ', @{$l->{context}//[]};                           # Join context string so it can be resplit
        push @p, newDitaPcdMethod
         (@action, method=>$method, context=>[split /\s+/, $context]);
       }
      else                                                                      # Unknown row type
       {confess "Unknown row type $rowType";
       }
     }
    else                                                                        # Missing row type
     {confess "No row type";
     }
   }

  newDitaPcdParseTree(rows=>\@p);
 } # parseUrlRepresentationOfPcd

sub representPcdParseTreeAsText($)                                              #P Print a parse tree as text
 {my ($parseTree) = @_;                                                         # Parse tree

  my @l = @{$parseTree->rows};                                                  # Rows of parse tree
  my @t;
  for my $l(@l)                                                                 # Each row
   {if (my $rowType = ref($l))                                                  # Type of row
     {if    ($rowType =~ m(comment)i)                                           # Comment
       {push @t, q(# ).$l->comment;
       }
      elsif ($rowType =~ m(description)i)                                       # Description
       {push @t, q(), $l->{description};
       }
      elsif ($rowType =~ m(method)i)                                            # Method
       {my $context = join ' ', @{$l->{context}//[]};                           # Join context string so it can be resplit allowing the user to use a single field to enter several context entries
        push @t, q(  ).join ' ', $l->{method}, @{$l->{context}//[]}
       }
      else                                                                      # Unknown row type
       {confess "Unknown row type $rowType";
       }
     }
    else                                                                        # Missing row type
     {confess "No row type";
     }
   }

  join "\n", @t, '';
 } # representPcdParseTreeAsText

sub compilePcdString($;$)                                                       #P Compile the specified L<pcd> directives in the supplied B<$string> optionally associated with B<$file>.
 {my ($string, $file) = @_;                                                     # Input string, optional name of file associated with string
  my $if = $file // q();                                                        # Nominal file

  my @l = split m/\n/, $string;

  my @blocks;
  for my $i(keys @l)                                                            # Each line==row a pcd file
   {my $l = $l[$i];
    my $j = $i + 1;

    next if $l =~ m(\A\s*#|\A\s*\Z);                                            # Comment

    if ($l =~ m(\A\S)s)                                                         # Change description
     {push @blocks, [[trim($l), $i+1, $if], []];
     }
    else                                                                        # Change command block
     {if (my ($cmd, @Keys) = split m/\s+/, trim($l))                            # Parse command
       {my @keys;

        for my $key(@Keys)                                                      # Transforms keys into Perl strings
         {if    ($key =~ m(undef))       {push @keys, "undef"}                  # Undef for anything
          elsif ($key =~ m/\Aqr(.*)\Z/s) {push @keys, $key}                     # Words wrapped with qr(.*) are regular expressions
          elsif ($key =~ m(\|)s)         {push @keys, "qr(\\A($key)\\Z)"}       # Words separated by | are a regular expression indicating choice of tags
          else                           {push @keys,      "q($key)"}
         }

        if (isSubInPackage(q(Data::Edit::Xml), $cmd))                           # Validate command
         {my $p = join(', ', @keys);                                            # Parameter list
          my $e = qq(sub {Data::Edit::Xml::$cmd(\$_, $p)});                     # Create matching Perl expression for command
          my $r = eval $e;                                                      # Evaluate command
          die "Error at $if line $j;\n$@\n" if $@;                              # Report any errors
          push @blocks, [] unless @blocks;                                      # Vivify blocks
          push @{$blocks[-1][1]}, [$r, $j, $if];                                # Save generated code
         }
        else                                                                    # Report wrong command
         {die "No such command: $cmd at $if line $j\n";
         }
       }
      else                                                                      # Request command
       {die "Please specify a command at $if line $j\n";
       }
     }
   }
  \@blocks
 } # compilePcdString

sub compilePcdFile($)                                                           #E Compile the specified L<pcd> directives B<$file> specifying changes to be made to L<dita> files.
 {my ($if) = @_;                                                                # Input file
  my $l = readFile($if);
  compilePcdString($l, $if);
 }

sub compilePcdFiles(@)                                                          #E Locate and compile the L<dita> files in the specified folder B<@in>.
 {my (@in) = @_;                                                                # Input folders
  my @blocks;                                                                   # Blocks of changes
  my @i = searchDirectoryTreesForMatchingFiles(@in, q(.pcd));                   # Pcd source files
  for my $f(@i)                                                                 # Each pcd file
   {push @blocks, @{compilePcdFile($f)};
   }
  \@blocks
 }

sub transformDitaWithPcd($$$)                                                   #E Transform the contents of file B<$if> represented as a parse tree B<$x> by applying the specified L<pcd> directives in B<$blocks>.
 {my ($if, $x, $blocks) = @_;                                                   # Input file, parse tree, change blocks

  my %stats;                                                                    # Statistics

  for my $block(@$blocks)                                                       # Each block of commands
   {my ($description, $commands) = @$block;

    $x->by(sub                                                                  # Traverse parse tree applying each block to each node
     {my ($node) = @_;

      sub                                                                       # Execute the command block against the current node of the parse tree
       {my ($d, $di, $df) = @$description;
        %Data::Edit::Xml::savedNodes = @Data::Edit::Xml::saveLastCutOut = ();   # Clear state from DEX expeditiously

        my $o = $node;                                                          # Start each block at the current node
        for my $command(@$commands)                                             # Each command in the block
         {my ($c, $ci, $cf) = @$command;                                        # Command

          local $_ = $o; my $r = &$c;                                           # Transform current node

          unless(defined $r)                                                    # Return on undef
           {my $ml  = $stats{failed}    {$df}{$di};
            my $mlf = $stats{failedFile}{$df}{$di}{$if};
            $stats{failed}    {$df}{$di}      = $ci if !$ml  or $ci > $ml;
            $stats{failedFile}{$df}{$di}{$if} = $ci if !$mlf or $ci > $mlf;
            return;
           }

          if (!ref($r))                                                         # Print string result
           {chomp($r);
            my $l = " in $if at $cf line $ci";
            if ($r =~ m(\n)s)
             {$r =~ s(\n) ($l\n)s;
             }
            else
             {$r ="$r$l";
             }
            #lll $r;
           }
          else                                                                  # Continue the block with the new value
           {$o = $r;
           }
         }

# lll "$d in $if at $df line $di";
        $stats{passed}{$df}{$di}++;
        $stats{passedFile}{$df}{$di}{$if}++;
       }->();
     });
   }

  \%stats
 }

sub transformDitaWithPcdOptimized($$$)                                          #E Transform the specified parse tree B<$x> by applying the specified L<pcd> directive B<$blocks> without any reporting to speed up execution.
 {my ($if, $x, $blocks) = @_;                                                   # Input file, parse tree, change blocks

  my %stats;                                                                    # Statistics

  for my $block(@$blocks)                                                       # Each block of commands
   {my ($description, $commands) = @$block;
    my ($d, $di, $df)            = @$description;

    $x->by(sub                                                                  # Traverse parse tree applying each block to each node
     {my ($node) = @_;

      %Data::Edit::Xml::savedNodes = @Data::Edit::Xml::saveLastCutOut = ();     # Clear state from DEX expeditiously

      my $o = $node;                                                            # Start each block at the current node
      for my $command(@$commands)                                               # Each command in the block
       {my $c = $$command[0];                                                   # Command
        local $_ = $o; my $r = &$c;                                             # Transform current node
        return unless defined $r;                                               # Return unless we got a response
        $o = $r if ref $r;                                                      # Move on to next node
       }
      $stats{passedFile}{$df}{$di}{$if}++;                                      # Record completion of block
     });
   }

  \%stats                                                                       # Return statistics
 }

sub pleaseChangeDita(%)                                                         #E Transform L[dita] files as specified by the directives in L<pcd> files.
 {my (%options) = @_;                                                           # Execution options

  checkKeys(\%options,                                                          # Check report options
    {in=><<'END',
The input folder containing .dita files to be changed and .pcd files describing
the changes.
END
     out=><<'END',
The output folder containing transformed copies of the input dita files.
END
     reports=><<'END',
The output folder containing reports on the changes made.
END
     optional=><<'END',
Do not complain if there are no .pcd files present.
END
    });

  my $in      = $options{in};                                                   # Input folder
  my $out     = $options{out};                                                  # Output folder
  my $reports = $options{reports};                                              # Reports folder

  my $blocks = compilePcdFiles($in);                                            # Blocks of changes
  return undef if $options{optional} and !@$blocks;                             # No files to process and optional specified
  @$blocks or confess "No .pcd files found in $in\n";                           # No source files

  my @dita = searchDirectoryTreesForMatchingFiles($in);                         # The dita files to be converted

  for my $if(@dita)                                                             # Process each dita file against each change file
   {next if fe($if) =~ m(\A(directory|pcd)\Z)i;                                 # Skip files that are obviously not xml files

    my $x = Data::Edit::Xml::new($if);

    my $stats = transformDitaWithPcd($if, $x, $blocks);                         # Transform the parse tree with the compiled blocks tracing if required
#   lll "File: $if\n", dump($stats);

    my $o = swapFilePrefix($if, $in, $out);                                     # Print the results
    if ($x->ditaRoot)
     {owf($o, $x->ditaPrettyPrintWithHeaders);
     }
    else
     {owf($o, -p $x);
     }
   }
 } # pleaseChangeDita

sub pleaseChangeDitaString($$%)                                                 #E Apply a pcd string to an xml string and return the resulting string
 {my ($xml, $pcd, %options) = @_;                                               # Xml, pcd options, options

  my $blocks = compilePcdString($pcd);                                          # Compiled Pcd
  my $x = Data::Edit::Xml::new($xml);                                           # Parse tree to transform

  transformDitaWithPcd($options{file}//q(), $x, $blocks);                       # Transform the parse tree with the compiled pcd blocks

  $x
 } # pleaseChangeDitaString

sub pcdDitaTags
 {qw(abstract alt anchorref annotation-xml apiname apply area author b bind body   bodydiv brand bvar category cause cerror change-completed change-historylist   change-item change-organization change-person change-request-id   change-request-reference change-request-system change-revisionid   change-started change-summary chdesc chdeschd chhead choice choices   choicetable choption choptionhd chrow ci cite closereqs cmd cmdname cn   codeblock codeph component conbody conbodydiv concept condition consequence   context coords copyrholder copyright critdates csymbol data data-about dd   ddhd declare degree delim desc dita ditavalmeta ditavalref div dl dlentry   dlhead domainofapplication draft-comment dt dthd dvrKeyscopePrefix   dvrKeyscopeSuffix dvrResourcePrefix dvrResourceSuffix entry equation-block   equation-figure equation-inline equation-number example exportanchors featnum   fig figgroup filepath fn foreign fragment fragref glossAbbreviation   glossAcronym glossAlt glossBody glossdef glossentry glossgroup glossProperty   glossref glossScopeNote glossShortForm glossSurfaceForm glossSymbol   glossSynonym glossterm glossUsage groupchoice groupcomp groupseq   hazardstatement hazardsymbol howtoavoid i image imagemap index-base index-see   index-see-also index-sort-as indexterm info interval itemgroup keydef keyword   keywords kwd lambda li line-through lines link linkinfo linklist linkpool   linktext list logbase lowlimit lq maction map mapref markupname math mathml   matrix matrixrow menclose menucascade merror messagepanel metadata mfenced   mfrac mi mlabeledtr mlongdiv mmultiscripts mn mo momentabout mover mpadded   mphantom mroot mrow ms mscarries mscarry msgblock msgnum msgph msgroup msqrt   msrow mstack mstyle msub msubsup msup mtable mtd mtext mtr munder munderover navtitle note numcharref object ol oper option otherwise overline p parameterentity parml parmname pd ph piece piecewise platform plentry postreq pre prelreqs prereq prodinfo prodname prognum prolog propdesc propdeschd properties property prophead proptype proptypehd propvalue propvaluehd pt   publisher q refbody refbodydiv reference refsyn related-links relcell   relcolspec relheader reln relrow reltable remedy repsep reqconds reqpers   required-cleanup resourceid responsibleParty result row safety screen   searchtitle section sectiondiv semantics sep series set shape shortcut   shortdesc simpletable sl sli sort-as source spares sparesli stentry step   stepresult steps steps-informal steps-unordered stepsection   steptroubleshooting stepxmp sthead strow sub substep substeps sup supeqli   supequip supplies supplyli svg-container synblk synnote synph syntaxdiagram   systemoutput table task taskbody tasktroubleshooting tbody term text   textentity tgroup thead title titlealts tm topic topicgroup topichead   topicmeta topicref topicset topicsetref troublebody troubleshooting   troubleSolution tt tutorialinfo typeofhazard u uicontrol ul unknown uplimit   userinput var varname vector vrmlist wintitle xmlatt xmlelement xmlnsname  xmlpi xref)}

sub pcdUnitaryMethods{qw(addAttr addFirst addFirstAsText addLabels addLast addLastAsText addNext addNextAsText addPrev addPrevAsText addSingleChild addWrapWith an ancestry ap apn approxLocation at atOrBelow atStringContentMatches atText atTop attrAt attrCount attrValueAt attrsNone bitsNodeTextBlank breakIn breakInBackwards breakInForwards breakOut breakOutChild c cText change changeAttr changeAttrValue changeAttributeValue changeKids changeOrDeleteAttr changeOrDeleteAttrValue changeText changeTextToSpace checkParentage checkParser closestLocation concatenateSiblings containsSingleText contentAfter contentAfterAsTags contentAfterAsTags2 contentAsTags contentAsTags2 contentBefore contentBeforeAsTags contentBeforeAsTags2 context copyAttrsFromParent copyAttrsToParent count countAttrNames countAttrNamesAndValues countAttrNamesOnTagExcluding countAttrValues countLabels countNonEmptyTags countOutputClasses countReport countTagNames countTags countTexts countWords createGuidId cut cutFirst cutIfEmpty cutLast cutNext cutPrev deleteAttr deleteAttrs deleteAttrsInTree deleteContent deleteLabels depth depthProfile ditaAddColSpecToTGroup ditaAddPadEntriesToTGroupRows ditaConvertConceptToReference ditaConvertConceptToSection ditaConvertConceptToTask ditaConvertDlToUl ditaConvertFromHtmlDl ditaConvertOlToSubSteps ditaConvertReferenceToConcept ditaConvertReferenceToTask ditaConvertSectionToConcept ditaConvertSectionToReference ditaConvertSectionToTask ditaConvertSimpleTableToTable ditaConvertSubStepsToSteps ditaConvertTopicToTask ditaConvertUlToSubSteps ditaCouldConvertConceptToTask ditaCutTopicmetaFromAClassificationMap ditaExpandAllConRefs ditaFixTGroupColSpec ditaListToChoices ditaListToSteps ditaListToStepsUnordered ditaListToSubSteps ditaListToTable ditaMaximumNumberOfEntriesInATGroupRow ditaMergeLists ditaMergeListsOnce ditaNumberOfColumnsInRow ditaObviousChanges ditaParagraphToNote ditaPrettyPrintWithHeaders ditaRemoveTGroupTrailingEmptyEntries ditaReplaceAnyConref ditaReplaceAnyConrefIdeallyWithMatchingTag ditaReplaceAnyConrefInContext ditaRoot ditaStepsToChoices ditaStepsToList ditaSyntaxDiagramFromDocBookCmdSynopsis ditaSyntaxDiagramToBasicRepresentation ditaTGroupStatistics ditaTopicHeaders ditaWrapWithPUnderConbody ditaXrefs divideHtmlDocumentIntoSections downWhileFirst downWhileHasSingleChild downWhileLast dupPutNext dupPutNextN dupPutPrev expandIncludes extendSectionToNextSection findByForestNumber findById findByNumber findByNumbers first firstBy firstContextOf firstDown firstIn firstInIndex firstIs firstNot firstOf firstSibling firstText firstTextMatches firstUntil firstUntilText firstWhile firstn fixEntryColSpan fixEntryRowSpan fixTGroup fixTable forestNumberTrees formatOxygenMessage getLabels getNodeAs getSectionHeadingLevel giveEveryIdAGuid go goFish hasContent hasSingleChild hasSingleChildText hasSingleChildToDepth height help howFar howFarAbove howFarBelow howFirst howLast howOnlyChild htmlHeadersToSections htmlTableToDita index indexIds invert invertFirst invertLast isADitaMap isAllBlankText isBlankText isEmpty isFirst isFirstN isFirstText isFirstToDepth isLast isLastN isLastText isLastToDepth isNotFirst isNotLast isOnlyChild isOnlyChildBlankText isOnlyChildN isOnlyChildText isOnlyChildToDepth isText joinWithText jsonString labelsInTree last lastBy lastContextOf lastDown lastIn lastInIndex lastIs lastNot lastOf lastSibling lastText lastTextMatches lastUntil lastUntilText lastWhile lastn lineLocation location matchNodesByRepresentation matchTree matchesFirst matchesLast matchesNext matchesPrev matchesText mergeDuplicateChildWithParent mergeLikeElements mergeLikeNext mergeLikePrev mergeOnlyChildLikeNext mergeOnlyChildLikePrev mergeOnlyChildLikePrevLast moveEndLast moveFirst moveLast moveSelectionAfter moveSelectionBefore moveSelectionFirst moveSelectionLast moveStartFirst next nextIn nextIs nextN nextOn nextText nextTextMatches nextUntil nextWhile nextn not numberNode numberTree numberTreesJustIds over over2 overAllTags overFirstTags overLastTags parentage path pathString position present prettyString prettyStringCDATA prettyStringContent prettyStringContentNumbered prettyStringDitaHeaders prettyStringEnd prettyStringNumbered prev prevIn prevIs prevN prevOn prevText prevTextMatches prevUntil prevWhile prevn printAttributes printAttributesExtendingIdsWithLabels printAttributesHtml printAttributesReplacingIdsWithLabels printNode printNodeAsSingleton printStack propagate putContentAfter putContentBefore putCutOutFirst putCutOutLast putCutOutNext putCutOutPrev putFirstAsComment putFirstAsText putFirstRequiredCleanUp putLastAsComment putLastAsText putLastRequiredCleanUp putNextAsComment putNextAsText putNextFirstCut putNextFirstCut2 putNextRequiredCleanUp putNodeAs putPrevAsComment putPrevAsText putPrevLastCut putPrevLastCut2 putPrevRequiredCleanUp putSiblingsAfterParent putSiblingsBeforeParent putSiblingsFirst putSiblingsLast putTextFirst putTextLast putTextNext putTextPrev putUpNextCut putUpNextCut2 putUpPrevCut putUpPrevCut2 renameAttr renameAttrValue renameAttrXtr reorder replaceContentWithText replaceWithBlank replaceWithRequiredCleanUp replaceWithText reportNode reportNodeAttributes reportNodeContext requiredCleanUp set setAttr setDepthProfile setRepresentationAsTagsAndText setRepresentationAsText setSelectionEnd setSelectionStart splitAfter splitAndWrapFromStart splitAndWrapToEnd splitBefore splitParentAfter splitParentBefore sss string stringAsMd5Sum stringContent stringContentOrText stringNode stringQuoted stringTagsAndText stringText structureAdjacentSectionsByLevel swapFirstSibling swapLastSibling swapNext swapPrev swapTagWithParent tocNumbers top unwrap unwrapContentsKeepingText unwrapOnlyChild unwrapParentOfOnlyChild unwrapParentsWithSingleChild unwrapSingleParentsOfSection up upThru upUntil upUntilFirst upUntilIsOnlyChild upUntilLast upWhile upWhileFirst upWhileIsOnlyChild upWhileLast upn wordStyles wrapContentWith wrapContentWithDup wrapDown wrapFirstN wrapFromFirst wrapFromFirstOrLastIn wrapLastN wrapNext wrapNextN wrapPrev wrapPrevN wrapRuns wrapSiblingsAfter wrapSiblingsBefore wrapToLast wrapToLastOrFirstIn wrapUp wrapWith wrapWithAll wrapWithDup wrapWithN writeCompressedFile zipDown zipDownOnce)}

sub pcdRowActions
 {qw(delete repeat copy cut after before)
 }

sub pcdRowTypes
 {qw(comment description method)
 }

sub formatHtml($)                                                               #P Replace <> by &lt; &gt; to make example html displayable
 {my ($string) = @_;                                                            # String
  $string =~ s(<) (&lt;)gs;
  $string =~ s(>) (&gt;)gs;
  join "\n", q(<pre>), $string, q(</pre>);
 }

sub printPcdExamplesHtml($;$)                                                   #P Print the PCD examples found in the module description of Data::Edit::Xml.
 {my ($mod, $formatter) = @_;                                                   # Module description of Data::Edit::Xml, optional sub to format xml

  my @h;                                                                        # Html table showing before, pcd, after

  my %m = $mod->methods->%*;                                                    # Module description

  for my $m(sort keys %m)
   {if (my $e = $m{$m}{example})
     {my $i = join "\n", $e->before->@*;                                        # Input Xml
      my $b = $i =~ m(<(concept|reference|task)) ? $i : qq(<a>$i</a>);          # Wrap input xml if no root tag supplied
      my $c = join "\n", qq(Test:), map{qq(    $_)} $e->code->@*;               # Pcd

      my $d = $e->doc;                                                          # Doc

      my $braceable = sub                                                       # Demonstrates a braceable string
       {my $u = $m{$m}{userFlags};
        $u and $u =~ m(b)                                                       # Braceable marker
       }->();

      push @h, <<END;                                                           # Format PCD
<tr id="a$m"                         onclick="clickTitle(event, '$m')"><td class="bold">$m<td>$d

<tr id="b$m" class="hide pcdExample" onclick="clickExample(event)">
<td><td><table cellspacing="10" cellpadding="10" border="0">
END

      if ($braceable && $formatter)                                             # Braceable and we have a formatter to interpret it
       {my $B = formatHtml $b;
        my $A = formatHtml $formatter->($b);                                    # Format input xml

        push @h, <<END;
<tr><th>Input l[xml]<th><th>Output l[xml]
<tr><td>$B<td>Press <b>Save</b><td>$A
END
       }
      else
       {my $B = sub                                                             # Format input xml
         {my $x = eval {Data::Edit::Xml::new($b)};
          if ($@)
           {return qq(<h2>Error</h2><p>$b <p>$@) if $@;
           }
          $x->prettyStringHtml;
         }->();

        my $A = sub                                                             # Format output xml
         {my $x = eval {pleaseChangeDitaString($b, $c, file=>$m)};
          return qq(<h2>Error</h2><p>$c<p>$@) if $@;
          $x->prettyStringHtml
         }->();

        my $C = printPcdHtml($c);

        push @h, <<END;
<tr><th>Input l[xml]<th>L[pcd]<th>Output l[xml]
<tr><td>$B<td>$C<td>$A
END
       }

      push @h, <<END;                                                           # Format PCD
</table>
</tr>
END
     }
   }

  join "\n", <<END,                                                             # Table of examples
<script>
function clickTitle(event, method)                                              // Click on title to show or dismiss example
 {const next = document.getElementById('b'+method);                             // Example associated with title

  const examples = document.getElementsByClassName("pcdExample");               // Hide all examples except the current example
  for(var i = 0; i < examples.length; ++i)
   {const e = examples[i];
    if (e != next) e.classList.add("hide");
   }

  next.classList.toggle("hide");                                                // Toggle the current example
 }

function clickExample(event)                                                    // Click on example to dismiss it
 {const examples = document.getElementsByClassName("pcdExample");
  for(var i = 0; i < examples.length; ++i)
   {examples[i].classList.add("hide");
   }
 }
</script>

<style>
.xmlTag    {color: red}
.xmlAttr   {color: blue}
.xmlValue  {color: green}
.xmlText   {color: brown}
.xmlEquals, .xmlGt, .xmlLt, .xmlSlashGt, .xmlLtSlash {color: darkBlue; font-weight: bold;}

.pcdComment     {color: darkOrange}
.pcdDescription {color: darkGreen}
.pcdMethod      {color: darkBlue}
.pcdContext     {color: darkRed}

td
 {padding: 10px;
  vertical-align: top;
 }

th
 {text-align: left;
 }

table.pcdExamples tr:nth-child(even)
 {background-color: #f0fff0;
 }
table.pcdExamples tr:nth-child(odd)
 {background-color: #fff0ff;
 }
table.pcdExamples
 {border-spacing: 10px 10px;
 }
tr.hide
 {display: none;
 }
</style>
<p>Click on a l[dex] method description below to see the associated example.


<table class="pcdExamples" cellspacing="10" cellpadding="10">
<tr><th>Method<th>Description
END
  @h, <<END;
</table>

<p>In the method names above <b>next</b> and <b>prev</b> meaning <i>next</i>
and <i>previous</i> can always be interchanged as can <b>first</b> and
<b>last</b> meaning the <i>first</i> or the <i>last</i> child of a parent to
generate new and valid method names from the ones listed.
END
 }

#Doff

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
compilePcdFile
compilePcdFiles
editPcdParseTree
parsePcdFile
parsePcdString
parseUrlRepresentationOfPcd
pcdDitaTags
pcdRowActions
pcdRowTypes
pcdUnitaryMethods
pleaseChangeDita
pleaseChangeDitaString
printPcdExamplesHtml
representPcdParseTreeAsHtml
representPcdParseTreeAsText
transformDitaWithPcd
transformDitaWithPcdOptimized
);

%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

my $documentationSynopsis = <<END;

Applying the L<pcdLang> file B<test.pcd>:

  # Sample pcd file
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B
    rn BBBB

  Merge two adjacent b
    mergeLikePrev b

To a sample L<xml> file B<1.dita>:

  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>

Produces the following messages:

  Change d under c under b to D at test.pcd line 2
  BBBB  at test.pcd line 8
  <b>
    <c>
      <d/>
    </c>
  </b>
  Change B to b at test.pcd line 6
  Merge two adjacent b at test.pcd line 10

And the following output L<XML> in B<out/1.dita>:

  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>

The L<PCD> commands available are those documented in: L<dex>.

Each block of commands is applied to each node of the parse tree produced by
L<dex>. If the block completes successfully the description line at the head of
the block is printed.  Execution of a block is halted if one of the commands in
the block returns a false value. Any changes made to the parse tree before a
block halts are retained so it is sensible to put as many tests as might be
necessary at the start of the block to ensure that all the conditions are met
to allow the block to complete successfully or to halt the block before the
block starts making changes to the parse tree.

END

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Dita::PCD - Implementation of the Please Change Dita Language.

=head1 Synopsis

Applying the L<PCD|https://philiprbrenan.github.io/data_edit_xml_edit_commands.html> file B<test.pcd>:

  # Sample pcd file
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B
    rn BBBB

  Merge two adjacent b
    mergeLikePrev b

To a sample L<Xml|https://en.wikipedia.org/wiki/XML> file B<1.dita>:

  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>

Produces the following messages:

  Change d under c under b to D at test.pcd line 2
  BBBB  at test.pcd line 8
  <b>
    <c>
      <d/>
    </c>
  </b>
  Change B to b at test.pcd line 6
  Merge two adjacent b at test.pcd line 10

And the following output L<Xml|https://en.wikipedia.org/wiki/XML> in B<out/1.dita>:

  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>

The L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> commands available are those documented in: L<Data::Edit::Xml|https://metacpan.org/pod/Data::Edit::Xml>.

Each block of commands is applied to each node of the parse tree produced by
L<Data::Edit::Xml|https://metacpan.org/pod/Data::Edit::Xml>. If the block completes successfully the description line at the head of
the block is printed.  Execution of a block is halted if one of the commands in
the block returns a false value. Any changes made to the parse tree before a
block halts are retained so it is sensible to put as many tests as might be
necessary at the start of the block to ensure that all the conditions are met
to allow the block to complete successfully or to halt the block before the
block starts making changes to the parse tree.

=head1 Description

Implementation of the Please Change Dita Language.


Version 20201030.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Please Change Dita

Edit L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> using directives written in  L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD>. An introduction to L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> can be found at: L<PCD|https://philiprbrenan.github.io/data_edit_xml_edit_commands.html>.

=head2 parseUrlRepresentationOfPcd($url)

Parse the url representation of a parse tree.

     Parameter  Description
  1  $url       Url

B<Example:>


  if (1)
   {my $testUrl =
     {q(001_action)    => q(),
      q(001_rowType1)  => q(comment),
      q(001_rowType2)  => q(comment),
      q(001_method)    => q(Sample+Pcd+file),
      q(002_action)    => q(),
      q(002_rowType1)  => q(description),
      q(002_rowType2)  => q(description),
      q(002_method)    => q(sf-111+unwrap+ph+under+title),
      q(003_action)    => q(),
      q(003_rowType1)  => q(method),
      q(003_rowType2)  => q(method),
      q(003_method)    => q(unwrap),
      q(003_context_1) => q(ph),
      q(003_context_2) => q(title),
      q(003_context_3) => q()};


    my $parseTree = parseUrlRepresentationOfPcd($testUrl);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok representPcdParseTreeAsText($parseTree) eq <<END;
  # Sample Pcd file

  sf-111 unwrap ph under title
    unwrap ph title
  END
   }


This method can be imported via:

  use Dita::PCD qw(parseUrlRepresentationOfPcd)


=head2 compilePcdFile($if)

Compile the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

     Parameter  Description
  1  $if        Input file

B<Example:>


      my $in  = temporaryFolder;
      my $out = temporaryFolder;

      my $inXml = <<END;
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>
  END

      my $outXml = <<END;
  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END

      writeFile(fpe($in, qw(1 dita)), $inXml);

      my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B

  Merge two adjacent b
    mlp b
  END

      pleaseChangeDita(in=>$in, out=>$out);

      ok readFile(fpe($out, qw(1 dita))) eq $outXml;


      my $blocks = compilePcdFile($inFile);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      ok dump(compilePcdFiles($in)) eq dump($blocks);

      for(1..1)
       {my $x = Data::Edit::Xml::new($inXml);

        transformDitaWithPcdOptimized(q(), $x, $blocks);

        ok -p $x eq $outXml;
       }

      clearFolder($_, 1e2) for $in, $out;

    my $in = temporaryFolder;

    my $f = owf(fpe($in, qw(test pcd)), <<END);
  # Sample Pcd file
  sf-111 unwrap ph under title
    unwrap2 ph2 title
  END

    my $p = parsePcdFile($f);
    delete $p->{inputFile};

    is_deeply $p, bless({
    errors => [],
    rows   => [
                bless({
                  action       => "",
                  actionError  => "",
                  comment      => "Sample Pcd file",
                  rowType      => "comment",
                  rowTypeError => "",
                }, "DitaPcdComment"),
                bless({
                  action       => "",
                  actionError  => "",
                  description  => "sf-111 unwrap ph under title",
                  rowType      => "description",
                  rowTypeError => "",
                }, "DitaPcdDescription"),
                bless({
                  action        => "",
                  actionError   => "",
                  context       => ["ph2", "title"],
                  contextErrors => {},
                  method        => "unwrap2",
                  methodError   => "",
                  rowType       => "method",
                  rowTypeError  => "",
                }, "DitaPcdMethod"),
              ],
     }, "DitaPCDParseTree");


This method can be imported via:

  use Dita::PCD qw(compilePcdFile)


=head2 compilePcdFiles(@in)

Locate and compile the L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files in the specified folder B<@in>.

     Parameter  Description
  1  @in        Input folders

B<Example:>


      my $in  = temporaryFolder;
      my $out = temporaryFolder;

      my $inXml = <<END;
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>
  END

      my $outXml = <<END;
  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END

      writeFile(fpe($in, qw(1 dita)), $inXml);

      my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B

  Merge two adjacent b
    mlp b
  END

      pleaseChangeDita(in=>$in, out=>$out);

      ok readFile(fpe($out, qw(1 dita))) eq $outXml;

      my $blocks = compilePcdFile($inFile);


      ok dump(compilePcdFiles($in)) eq dump($blocks);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      for(1..1)
       {my $x = Data::Edit::Xml::new($inXml);

        transformDitaWithPcdOptimized(q(), $x, $blocks);

        ok -p $x eq $outXml;
       }

      clearFolder($_, 1e2) for $in, $out;

    my $in = temporaryFolder;

    my $f = owf(fpe($in, qw(test pcd)), <<END);
  # Sample Pcd file
  sf-111 unwrap ph under title
    unwrap2 ph2 title
  END

    my $p = parsePcdFile($f);
    delete $p->{inputFile};

    is_deeply $p, bless({
    errors => [],
    rows   => [
                bless({
                  action       => "",
                  actionError  => "",
                  comment      => "Sample Pcd file",
                  rowType      => "comment",
                  rowTypeError => "",
                }, "DitaPcdComment"),
                bless({
                  action       => "",
                  actionError  => "",
                  description  => "sf-111 unwrap ph under title",
                  rowType      => "description",
                  rowTypeError => "",
                }, "DitaPcdDescription"),
                bless({
                  action        => "",
                  actionError   => "",
                  context       => ["ph2", "title"],
                  contextErrors => {},
                  method        => "unwrap2",
                  methodError   => "",
                  rowType       => "method",
                  rowTypeError  => "",
                }, "DitaPcdMethod"),
              ],
     }, "DitaPCDParseTree");


This method can be imported via:

  use Dita::PCD qw(compilePcdFiles)


=head2 transformDitaWithPcd($if, $x, $blocks)

Transform the contents of file B<$if> represented as a parse tree B<$x> by applying the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives in B<$blocks>.

     Parameter  Description
  1  $if        Input file
  2  $x         Parse tree
  3  $blocks    Change blocks

B<Example:>


      my $in  = temporaryFolder;
      my $out = temporaryFolder;

      my $inXml = <<END;
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>
  END

      my $outXml = <<END;
  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END

      writeFile(fpe($in, qw(1 dita)), $inXml);

      my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B

  Merge two adjacent b
    mlp b
  END

      pleaseChangeDita(in=>$in, out=>$out);

      ok readFile(fpe($out, qw(1 dita))) eq $outXml;

      my $blocks = compilePcdFile($inFile);

      ok dump(compilePcdFiles($in)) eq dump($blocks);

      for(1..1)
       {my $x = Data::Edit::Xml::new($inXml);

        transformDitaWithPcdOptimized(q(), $x, $blocks);

        ok -p $x eq $outXml;
       }

      clearFolder($_, 1e2) for $in, $out;

    my $in = temporaryFolder;

    my $f = owf(fpe($in, qw(test pcd)), <<END);
  # Sample Pcd file
  sf-111 unwrap ph under title
    unwrap2 ph2 title
  END

    my $p = parsePcdFile($f);
    delete $p->{inputFile};

    is_deeply $p, bless({
    errors => [],
    rows   => [
                bless({
                  action       => "",
                  actionError  => "",
                  comment      => "Sample Pcd file",
                  rowType      => "comment",
                  rowTypeError => "",
                }, "DitaPcdComment"),
                bless({
                  action       => "",
                  actionError  => "",
                  description  => "sf-111 unwrap ph under title",
                  rowType      => "description",
                  rowTypeError => "",
                }, "DitaPcdDescription"),
                bless({
                  action        => "",
                  actionError   => "",
                  context       => ["ph2", "title"],
                  contextErrors => {},
                  method        => "unwrap2",
                  methodError   => "",
                  rowType       => "method",
                  rowTypeError  => "",
                }, "DitaPcdMethod"),
              ],
     }, "DitaPCDParseTree");


This method can be imported via:

  use Dita::PCD qw(transformDitaWithPcd)


=head2 transformDitaWithPcdOptimized($if, $x, $blocks)

Transform the specified parse tree B<$x> by applying the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directive B<$blocks> without any reporting to speed up execution.

     Parameter  Description
  1  $if        Input file
  2  $x         Parse tree
  3  $blocks    Change blocks

B<Example:>


      my $in  = temporaryFolder;
      my $out = temporaryFolder;

      my $inXml = <<END;
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>
  END

      my $outXml = <<END;
  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END

      writeFile(fpe($in, qw(1 dita)), $inXml);

      my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B

  Merge two adjacent b
    mlp b
  END

      pleaseChangeDita(in=>$in, out=>$out);

      ok readFile(fpe($out, qw(1 dita))) eq $outXml;

      my $blocks = compilePcdFile($inFile);

      ok dump(compilePcdFiles($in)) eq dump($blocks);

      for(1..1)
       {my $x = Data::Edit::Xml::new($inXml);


        transformDitaWithPcdOptimized(q(), $x, $blocks);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


        ok -p $x eq $outXml;
       }

      clearFolder($_, 1e2) for $in, $out;


This method can be imported via:

  use Dita::PCD qw(transformDitaWithPcdOptimized)


=head2 pleaseChangeDita(%options)

Transform L[dita] files as specified by the directives in L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> files.

     Parameter  Description
  1  %options   Execution options

B<Example:>


      my $in  = temporaryFolder;
      my $out = temporaryFolder;

      my $inXml = <<END;
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <B>
      <c>
        <d/>
      </c>
    </B>
  </a>
  END

      my $outXml = <<END;
  <a>
    <b>
      <c>
        <D/>
      </c>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END

      writeFile(fpe($in, qw(1 dita)), $inXml);

      my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
  Change d under c under b to D
    change D d c b

  Change B to b
    change b B

  Merge two adjacent b
    mlp b
  END


      pleaseChangeDita(in=>$in, out=>$out);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      ok readFile(fpe($out, qw(1 dita))) eq $outXml;

      my $blocks = compilePcdFile($inFile);

      ok dump(compilePcdFiles($in)) eq dump($blocks);

      for(1..1)
       {my $x = Data::Edit::Xml::new($inXml);

        transformDitaWithPcdOptimized(q(), $x, $blocks);

        ok -p $x eq $outXml;
       }

      clearFolder($_, 1e2) for $in, $out;

    my $in = temporaryFolder;

    my $f = owf(fpe($in, qw(test pcd)), <<END);
  # Sample Pcd file
  sf-111 unwrap ph under title
    unwrap2 ph2 title
  END

    my $p = parsePcdFile($f);
    delete $p->{inputFile};

    is_deeply $p, bless({
    errors => [],
    rows   => [
                bless({
                  action       => "",
                  actionError  => "",
                  comment      => "Sample Pcd file",
                  rowType      => "comment",
                  rowTypeError => "",
                }, "DitaPcdComment"),
                bless({
                  action       => "",
                  actionError  => "",
                  description  => "sf-111 unwrap ph under title",
                  rowType      => "description",
                  rowTypeError => "",
                }, "DitaPcdDescription"),
                bless({
                  action        => "",
                  actionError   => "",
                  context       => ["ph2", "title"],
                  contextErrors => {},
                  method        => "unwrap2",
                  methodError   => "",
                  rowType       => "method",
                  rowTypeError  => "",
                }, "DitaPcdMethod"),
              ],
     }, "DitaPCDParseTree");


This method can be imported via:

  use Dita::PCD qw(pleaseChangeDita)


=head2 pleaseChangeDitaString($xml, $pcd, %options)

Apply a pcd string to an xml string and return the resulting string

     Parameter  Description
  1  $xml       Xml
  2  $pcd       Pcd options
  3  %options   Options

B<Example:>



  ok pleaseChangeDitaString(q(<a><b>C</b></a>), qq(Unwrap
  unwrap b))->string eq qq(<a>C</a>);    # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



This method can be imported via:

  use Dita::PCD qw(pleaseChangeDitaString)



=head2 DitaPcdComment Definition


Description of a comment




=head3 Output fields


=head4 comment

Comment text



=head2 DitaPcdDescription Definition


Description




=head3 Output fields


=head4 description

Description text



=head1 Private Methods

=head2 ditaPcdBase($rowType)

Base of various objects used by the editor

     Parameter  Description
  1  $rowType   Row type

=head2 newDitaPcdComment(%options)

Create a new comment

     Parameter  Description
  1  %options   Attributes

=head2 newDitaPcdDescription(%options)

Create a new description

     Parameter  Description
  1  %options   Attributes

=head2 newDitaPcdMethod(%options)

Create a new Method

     Parameter  Description
  1  %options   Attributes

=head2 newDitaPcdParseTree(%options)

Create a new Parse Tree

     Parameter  Description
  1  %options   Attributes

=head2 parsePcdString($string)

Parse the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$string> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

     Parameter  Description
  1  $string    String of PCD directives

=head2 parsePcdFile($if)

Parse the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

     Parameter  Description
  1  $if        Input file

=head2 editPcdParseTree($parseTree)

Validate a B<$parseTree>

     Parameter   Description
  1  $parseTree  Parse tree

=head2 makeDataList($name, @values)

Create a data list

     Parameter  Description
  1  $name      Name
  2  @values    Values

=head2 representPcdParseTreeAsHtml($parseTree)

Parse the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

     Parameter   Description
  1  $parseTree  Parse tree

=head2 printPcdHtml($string)

Print a PCD using L<HTML|https://en.wikipedia.org/wiki/HTML>

     Parameter  Description
  1  $string    Pcd as a string

=head2 representPcdParseTreeAsText($parseTree)

Print a parse tree as text

     Parameter   Description
  1  $parseTree  Parse tree

=head2 compilePcdString($string, $file)

Compile the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives in the supplied B<$string> optionally associated with B<$file>.

     Parameter  Description
  1  $string    Input string
  2  $file      Optional name of file associated with string

=head2 formatHtml($string)

Replace <> by &lt; &gt; to make example html displayable

     Parameter  Description
  1  $string    String

=head2 printPcdExamplesHtml($mod, $formatter)

Print the PCD examples found in the module description of Data::Edit::Xml.

     Parameter   Description
  1  $mod        Module description of Data::Edit::Xml
  2  $formatter  Optional sub to format xml


=head1 Index


1 L<compilePcdFile|/compilePcdFile> - Compile the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

2 L<compilePcdFiles|/compilePcdFiles> - Locate and compile the L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files in the specified folder B<@in>.

3 L<compilePcdString|/compilePcdString> - Compile the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives in the supplied B<$string> optionally associated with B<$file>.

4 L<ditaPcdBase|/ditaPcdBase> - Base of various objects used by the editor

5 L<editPcdParseTree|/editPcdParseTree> - Validate a B<$parseTree>

6 L<formatHtml|/formatHtml> - Replace <> by &lt; &gt; to make example html displayable

7 L<makeDataList|/makeDataList> - Create a data list

8 L<newDitaPcdComment|/newDitaPcdComment> - Create a new comment

9 L<newDitaPcdDescription|/newDitaPcdDescription> - Create a new description

10 L<newDitaPcdMethod|/newDitaPcdMethod> - Create a new Method

11 L<newDitaPcdParseTree|/newDitaPcdParseTree> - Create a new Parse Tree

12 L<parsePcdFile|/parsePcdFile> - Parse the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

13 L<parsePcdString|/parsePcdString> - Parse the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$string> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

14 L<parseUrlRepresentationOfPcd|/parseUrlRepresentationOfPcd> - Parse the url representation of a parse tree.

15 L<pleaseChangeDita|/pleaseChangeDita> - Transform L[dita] files as specified by the directives in L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> files.

16 L<pleaseChangeDitaString|/pleaseChangeDitaString> - Apply a pcd string to an xml string and return the resulting string

17 L<printPcdExamplesHtml|/printPcdExamplesHtml> - Print the PCD examples found in the module description of Data::Edit::Xml.

18 L<printPcdHtml|/printPcdHtml> - Print a PCD using L<HTML|https://en.wikipedia.org/wiki/HTML>

19 L<representPcdParseTreeAsHtml|/representPcdParseTreeAsHtml> - Parse the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

20 L<representPcdParseTreeAsText|/representPcdParseTreeAsText> - Print a parse tree as text

21 L<transformDitaWithPcd|/transformDitaWithPcd> - Transform the contents of file B<$if> represented as a parse tree B<$x> by applying the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directives in B<$blocks>.

22 L<transformDitaWithPcdOptimized|/transformDitaWithPcdOptimized> - Transform the specified parse tree B<$x> by applying the specified L<Dita::Pcd|https://metacpan.org/pod/Dita::PCD> directive B<$blocks> without any reporting to speed up execution.



=head1 Exports

All of the following methods can be imported via:

  use Dita::PCD qw(:all);

Or individually via:

  use Dita::PCD qw(<method>);



1 L<compilePcdFile|/compilePcdFile>

2 L<compilePcdFiles|/compilePcdFiles>

3 L<parseUrlRepresentationOfPcd|/parseUrlRepresentationOfPcd>

4 L<pleaseChangeDita|/pleaseChangeDita>

5 L<pleaseChangeDitaString|/pleaseChangeDitaString>

6 L<transformDitaWithPcd|/transformDitaWithPcd>

7 L<transformDitaWithPcdOptimized|/transformDitaWithPcdOptimized>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Dita::PCD

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More qw(no_plan);
use warnings FATAL=>qw(all);
use strict;
use Data::Table::Text qw(:all);
use Time::HiRes qw(time);

makeDieConfess;

#goto latestTest;

if ($^O !~ m(bsd|linux)i)
 {plan skip_all => 'Not supported';
 }

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Dita::PCD') eq "Dita::PCD";

if (1)
 {my $startTime = time;

  if (1) {                                                                      #TpleaseChangeDita #TtransformDitaWithPcd #TcompilePcdFile #TcompilePcdFiles #TtransformDitaWithPcdOptimized
    my $in  = temporaryFolder;
    my $out = temporaryFolder;

    my $inXml = <<END;
<a>
  <b>
    <c>
      <d/>
    </c>
  </b>
  <B>
    <c>
      <d/>
    </c>
  </B>
</a>
END

    my $outXml = <<END;
<a>
  <b>
    <c>
      <D/>
    </c>
    <c>
      <d/>
    </c>
  </b>
</a>
END

    writeFile(fpe($in, qw(1 dita)), $inXml);

    my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
Change d under c under b to D
  change D d c b

Change B to b
  change b B

Merge two adjacent b
  mlp b
END

    pleaseChangeDita(in=>$in, out=>$out);

    ok readFile(fpe($out, qw(1 dita))) eq $outXml;

    my $blocks = compilePcdFile($inFile);

    ok dump(compilePcdFiles($in)) eq dump($blocks);

    for(1..1)
     {my $x = Data::Edit::Xml::new($inXml);

      transformDitaWithPcdOptimized(q(), $x, $blocks);

      ok -p $x eq $outXml;
     }

    clearFolder($_, 1e2) for $in, $out;
   }

  lll "Finished in", (time() - $startTime), "seconds";
 }

if (1) {                                                                        #TpleaseChangeDita #TtransformDitaWithPcd #TcompilePcdFile #TcompilePcdFiles
  my $in = temporaryFolder;

  my $f = owf(fpe($in, qw(test pcd)), <<END);
# Sample Pcd file
sf-111 unwrap ph under title
  unwrap2 ph2 title
END

  my $p = parsePcdFile($f);
  delete $p->{inputFile};

  is_deeply $p, bless({
  errors => [],
  rows   => [
              bless({
                action       => "",
                actionError  => "",
                comment      => "Sample Pcd file",
                rowType      => "comment",
                rowTypeError => "",
              }, "DitaPcdComment"),
              bless({
                action       => "",
                actionError  => "",
                description  => "sf-111 unwrap ph under title",
                rowType      => "description",
                rowTypeError => "",
              }, "DitaPcdDescription"),
              bless({
                action        => "",
                actionError   => "",
                context       => ["ph2", "title"],
                contextErrors => {},
                method        => "unwrap2",
                methodError   => "",
                rowType       => "method",
                rowTypeError  => "",
              }, "DitaPcdMethod"),
            ],
   }, "DitaPCDParseTree");
 }

if (1)                                                                          #TparseUrlRepresentationOfPcd
 {my $testUrl =
   {q(001_action)    => q(),
    q(001_rowType1)  => q(comment),
    q(001_rowType2)  => q(comment),
    q(001_method)    => q(Sample+Pcd+file),
    q(002_action)    => q(),
    q(002_rowType1)  => q(description),
    q(002_rowType2)  => q(description),
    q(002_method)    => q(sf-111+unwrap+ph+under+title),
    q(003_action)    => q(),
    q(003_rowType1)  => q(method),
    q(003_rowType2)  => q(method),
    q(003_method)    => q(unwrap),
    q(003_context_1) => q(ph),
    q(003_context_2) => q(title),
    q(003_context_3) => q()};

  my $parseTree = parseUrlRepresentationOfPcd($testUrl);

  ok representPcdParseTreeAsText($parseTree) eq <<END;
# Sample Pcd file

sf-111 unwrap ph under title
  unwrap ph title
END
 }

sub testParseTreeEdit($$)                                                       #P Test a parse tree edits
 {my ($p, $r) = @_;                                                             # Parse tree, expected results
  editPcdParseTree($p);
  ok $r eq join ' ', map {$p->rows->[$_]->comment} 0..scalar($p->rows->@*)-1;
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
END
  $p->rows->[0]->action = q(delete);
  testParseTreeEdit($p, q());
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
END
  $p->rows->[0]->action = q(repeat);
  testParseTreeEdit($p, q(0 0));
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
# 1
END
  $p->rows->[0]->action = q(cut);
  $p->rows->[1]->action = q(before);
  testParseTreeEdit($p, q(0 1));
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
# 1
END
  $p->rows->[0]->action = q(move);
  $p->rows->[1]->action = q(after);
  testParseTreeEdit($p, q(1 0));
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
# 1
END
  $p->rows->[0]->action = q(copy);
  $p->rows->[1]->action = q(before);
  testParseTreeEdit($p, q(0 0 1));
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
# 1
END
  $p->rows->[0]->action = q(copy);
  $p->rows->[1]->action = q(after);
  testParseTreeEdit($p, q(0 1 0));
 }

if (1)
 {my $p = parsePcdString <<END;
# 0
# 1
# 2
# 3
END
  $p->rows->[0]->action = q(delete);
  $p->rows->[1]->action = q(repeat);
  $p->rows->[2]->action = q(copy);
  $p->rows->[3]->action = q(after);
  testParseTreeEdit($p, q(1 1 2 3 2));
 }

if (1)
 {my $f = writeFile(undef, <<END);
  addAttr a
END
   my $p = compilePcdFile($f);
   unlink $f;
 }

ok pleaseChangeDitaString(q(<a><b>C</b></a>), qq(Unwrap\n  unwrap b))->string eq qq(<a>C</a>);  #TpleaseChangeDitaString

if (0)
 {my $f = q(/home/phil/r/www/html/help/);
  my $e = q(/home/phil/.config/help/Data::Edit::Xml.txt);
  if (-d $f and -f $e)
   {owf(fpe($f, qw(examples html)), printPcdExamplesHtml(evalFile($e)))
   }
 }


ok pleaseChangeDitaString(q(<a><b id="b"/><b id="c"/></a>), qq(Unwrap c\n  attrValueAt id qr(c)\n unwrap), file=>q(attrValueAt))->string eq q(<a><b id="b"/></a>);

latestTest:;

if (1) {
  my $in = temporaryFolder;
  owf(my $source = fpe($in, qw(source xml)), <<END);
<concept id="source">
  <title>
    Source file
  </title>
  <prolog/>
  <conbody>
    <p><ph conref="target.xml#target/topic-title"/></p>
    <p><ph conref="target.xml#target/topic-title"/></p>
    <p><ph conref="target.xml#target/topic-title"/></p>
    <p><ph conref="target.xml#target/topic-title"/></p>
    <p><ph conref="target.xml#target/topic-title"/></p>
  </conbody>
</concept>
END
  owf(fpe($in, qw(target xml)), <<END);
<concept id="target">
  <title id="topic-title">
    Target file
  </title>
  <prolog/>
  <conbody>
    <p>Health Cloud</p>
  </conbody>
</concept>
END
  owf(fpe($in, qw(test pcd)), <<END);
Expand topic-title conrefs
  attrValueAt conref qr(topic-title\\Z)
  ditaReplaceAnyConref
  unwrap title
END
  my $out = temporaryFolder;

  pleaseChangeDita(in=>$in, out=>$out);

  if (0)
   {my $r = readFiles($out);
    for my $f(sort keys %$r)
     {lll "File: $f\n", $$r{$f};
     }
   }
  clearFolder($_, 1e1) for $in, $out;
 }

clearFolder(q(zzzParseErrors/), 10);

done_testing;
