#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Dita::PCD - Implementation of the Please Change Dita Language.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
#podDocumentation
package Dita::PCD;
our $VERSION = 20190811;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Edit::Xml;
use Data::Table::Text qw(:all);

#D1 Please Change Dita                                                          # Edit L<Dita> using directives written in  L<pcd>. An introduction to l<pcd> can be found at: L<pcdLang>.

sub compilePcdFile($)                                                           #E Compile the specified L<pcd> directives B<$file> specifying changes to be made to L<dita> files.
 {my ($if) = @_;                                                                # Input file
  my @l = readFile($if);
  my @blocks;
  for my $i(keys @l)                                                            # Each line of a pcd file
   {my $l = $l[$i];
    next if $l =~ m(\A\s*#|\A\s*\Z);                                            # Comment line or empty line
    if ($l =~ m(\A\S)s)                                                         # Change description
     {push @blocks, [[trim($l), $i+1, $if], []];
     }
    else                                                                        # Change command block
     {if (my ($cmd, @keys) = split m/\s+/, trim($l))                            # Parse command
       {if (isSubInPackage(q(Data::Edit::Xml), $cmd))                           # Validate command
         {my $e = q($o->).$cmd.q/(/.join(', ', dump(@keys)).q/);/;              # Create matching Perl expression for command
          push @{$blocks[-1][1]}, [$e, $i+1, $if];                              # Save generated code
         }
        else                                                                    # Report wrong command
         {my $n = $i + 1;
          confess "No such command: =$cmd= at $if line $n\n";
         }
       }
      else                                                                      # Report wrong command
       {my $n = $i + 1;
        confess "Please specify a command  at $if line $n\n";
       }
     }
   }
  @blocks
 }

sub compilePcdFiles(@)                                                          #E Locate and compile the L<dita> files in the specified folder B<@in>.
 {my (@in) = @_;                                                                # Input folders
  my @blocks;                                                                   # Blocks of changes
  my @i = searchDirectoryTreesForMatchingFiles(@in, q(.pcd));                   # Pcd source files
  for my $f(@i)                                                                 # Each pcd file
   {push @blocks, compilePcdFile($f);
   }
  [@blocks]
 }

sub transformDitaWithPcd($$;$)                                                  #E Transform the specified parse tree B<$x> by applying the specified L<pcd> directive B<$blocks> optionally tracing the transformations applied if B<$trace> is true.
 {my ($x, $blocks, $trace) = @_;                                                # Parse tree, change blocks, trace block execution if true

  $x->by(sub                                                                    # Traverse parse tree applying each block to each node
   {my ($node) = @_;

    for my $block(@$blocks)                                                     # Each block of commands
     {my ($description, $commands) = @$block;

      sub                                                                       # Execute the command block against the current node of the parse tree
       {my ($d, $di, $df) = @$description;
        my $o = $node;
        &Data::Edit::Xml::clearSavedNodes;                                      # Clear any saved values

        for my $command(@$commands)                                             # Each command in the block
         {my ($c, $ci, $cf) = @$command;                                        # Command

          my $r = eval $c;                                                      # Evaluate command

          if ($@)                                                               # Report any errors
           {say STDERR "Error at $cf line $ci\n$@\n";
            return;
           }

          return unless $r;                                                     # Return on undef

          if (!ref($r))                                                         # Print string result
           {chomp($r);
            my $l = "  at $cf line $ci";
            if ($r =~ m(\n)s)
             {$r =~ s(\n) ($l\n)s;
             }
            else
             {$r ="$r$l";
             }
            say STDERR timeStamp, " $r";
           }
          else                                                                  # Continue the block with the new value
           {$o = $r;
           }
         }

        say STDERR timeStamp, " $d at $df line $di" if $trace;
       }->();

     }
   });
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
     optional=><<'END',
Do not complain if there are no .pcd files present.
END
     trace=><<'END',
Trace blocks executed
END
    });

  my $in  = $options{in};                                                       # Input folder
  my $out = $options{out};                                                      # Output folder

  my $blocks = compilePcdFiles($in);                                            # Blocks of changes
  return undef if $options{optional} and !@$blocks;                             # No files to process and optional specified
  @$blocks or confess "No .pcd files found in $in\n";                           # No source files

  my @dita = searchDirectoryTreesForMatchingFiles($in, qw(.dita .ditamap));     # The dita files to be converted

  for my $if(@dita)                                                             # Process each dita file against each change file
   {my $x = Data::Edit::Xml::new($if);

    transformDitaWithPcd($x, $blocks, $options{trace});                         # Transform the parse tree with the compiled blocks tracing if required

    my $o = swapFilePrefix($if, $in, $out);                                     # Print the results
    if ($x->ditaRoot)
     {owf($o, $x->ditaPrettyPrintWithHeaders);
     }
    else
     {owf($o, -p $x);
     }
   }
 } # pleaseChangeDita

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
pleaseChangeDita
transformDitaWithPcd
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

Applying the L<PCD Language|https://philiprbrenan.github.io/data_edit_xml_edit_commands.html> file B<test.pcd>:

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

The L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> commands available are those documented in: L<Data::Edit::Xml|https://metacpan.org/pod/Data::Edit::Xml>.

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


Version 20190811.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Please Change Dita

Edit L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> using directives written in  L<Dita::PCD|https://metacpan.org/pod/Dita::PCD>. An introduction to L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> can be found at: L<PCD Language|https://philiprbrenan.github.io/data_edit_xml_edit_commands.html>.

=head2 compilePcdFile($)

Compile the specified L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

     Parameter  Description
  1  $if        Input file

B<Example:>


  if (1) {                                                                          
   my $blocks =
  [[["Change d under c under b to D", 1, "test.pcd"],
   [["\$o->change((\"D\", \"d\", \"c\", \"b\"));",  2, "test.pcd"]]],
   [["Change B to b", 4, "test.pcd"],
   [["\$o->change((\"b\", \"B\"));", 5, "test.pcd"]]],
   [["Merge two adjacent b", 7, "test.pcd"],
   [["\$o->mlp(\"b\");", 8, "test.pcd"]],
  ]];
  
    is_deeply [eval(dump(𝗰𝗼𝗺𝗽𝗶𝗹𝗲𝗣𝗰𝗱𝗙𝗶𝗹𝗲($inFile)) =~ s($in) ()gsr)], $blocks;
    is_deeply  eval(dump(compilePcdFiles($in))    =~ s($in) ()gsr),  $blocks;
  
    ok -p transformDitaWithPcd(Data::Edit::Xml::new(<<END), $blocks) eq <<END;
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
  
  }
  clearFolder($_, 1e2) for $in, $out;
  
  done_testing;
  

This method can be imported via:

  use Dita::PCD qw(compilePcdFile)


=head2 compilePcdFiles(@)

Locate and compile the L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files in the specified folder B<@in>.

     Parameter  Description
  1  @in        Input folders

B<Example:>


  if (1) {                                                                          
   my $blocks =
  [[["Change d under c under b to D", 1, "test.pcd"],
   [["\$o->change((\"D\", \"d\", \"c\", \"b\"));",  2, "test.pcd"]]],
   [["Change B to b", 4, "test.pcd"],
   [["\$o->change((\"b\", \"B\"));", 5, "test.pcd"]]],
   [["Merge two adjacent b", 7, "test.pcd"],
   [["\$o->mlp(\"b\");", 8, "test.pcd"]],
  ]];
  
    is_deeply [eval(dump(compilePcdFile($inFile)) =~ s($in) ()gsr)], $blocks;
    is_deeply  eval(dump(𝗰𝗼𝗺𝗽𝗶𝗹𝗲𝗣𝗰𝗱𝗙𝗶𝗹𝗲𝘀($in))    =~ s($in) ()gsr),  $blocks;
  
    ok -p transformDitaWithPcd(Data::Edit::Xml::new(<<END), $blocks) eq <<END;
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
  
  }
  clearFolder($_, 1e2) for $in, $out;
  
  done_testing;
  

This method can be imported via:

  use Dita::PCD qw(compilePcdFiles)


=head2 transformDitaWithPcd($$$)

Transform the specified parse tree B<$x> by applying the specified L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> directive B<$blocks> optionally tracing the transformations applied if B<$trace> is true.

     Parameter  Description
  1  $x         Parse tree
  2  $blocks    Change blocks
  3  $trace     Trace block execution if true

B<Example:>


  if (1) {                                                                          
   my $blocks =
  [[["Change d under c under b to D", 1, "test.pcd"],
   [["\$o->change((\"D\", \"d\", \"c\", \"b\"));",  2, "test.pcd"]]],
   [["Change B to b", 4, "test.pcd"],
   [["\$o->change((\"b\", \"B\"));", 5, "test.pcd"]]],
   [["Merge two adjacent b", 7, "test.pcd"],
   [["\$o->mlp(\"b\");", 8, "test.pcd"]],
  ]];
  
    is_deeply [eval(dump(compilePcdFile($inFile)) =~ s($in) ()gsr)], $blocks;
    is_deeply  eval(dump(compilePcdFiles($in))    =~ s($in) ()gsr),  $blocks;
  
    ok -p 𝘁𝗿𝗮𝗻𝘀𝗳𝗼𝗿𝗺𝗗𝗶𝘁𝗮𝗪𝗶𝘁𝗵𝗣𝗰𝗱(Data::Edit::Xml::new(<<END), $blocks) eq <<END;
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
  
  }
  clearFolder($_, 1e2) for $in, $out;
  
  done_testing;
  

This method can be imported via:

  use Dita::PCD qw(transformDitaWithPcd)


=head2 pleaseChangeDita(%)

Transform L[dita] files as specified by the directives in L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> files.

     Parameter  Description
  1  %options   Execution options

B<Example:>


  𝗽𝗹𝗲𝗮𝘀𝗲𝗖𝗵𝗮𝗻𝗴𝗲𝗗𝗶𝘁𝗮(in=>$in, out=>$out, trace=>1);                                 
  

This method can be imported via:

  use Dita::PCD qw(pleaseChangeDita)



=head1 Index


1 L<compilePcdFile|/compilePcdFile> - Compile the specified L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> directives B<$file> specifying changes to be made to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files.

2 L<compilePcdFiles|/compilePcdFiles> - Locate and compile the L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> files in the specified folder B<@in>.

3 L<pleaseChangeDita|/pleaseChangeDita> - Transform L[dita] files as specified by the directives in L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> files.

4 L<transformDitaWithPcd|/transformDitaWithPcd> - Transform the specified parse tree B<$x> by applying the specified L<Dita::PCD|https://metacpan.org/pod/Dita::PCD> directive B<$blocks> optionally tracing the transformations applied if B<$trace> is true.



=head1 Exports

All of the following methods can be imported via:

  use Dita::PCD qw(:all);

Or individually via:

  use Dita::PCD qw(<method>);



1 L<compilePcdFile|/compilePcdFile>

2 L<compilePcdFiles|/compilePcdFiles>

3 L<pleaseChangeDita|/pleaseChangeDita>

4 L<transformDitaWithPcd|/transformDitaWithPcd>

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
use Test::More;
use warnings FATAL=>qw(all);
use strict;
use Data::Table::Text qw(:all);

makeDieConfess;

if ($^O !~ m(bsd|linux)i)
 {plan skip_all => 'Not supported';
 }

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Dita::PCD') eq "Dita::PCD";


my $in  = temporaryFolder;
my $out = temporaryFolder;

writeFile(fpe($in, qw(1 dita)), <<END);
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

my $inFile = writeFile(fpe($in, qw(test pcd)), <<END);
Change d under c under b to D
  change D d c b

Change B to b
  change b B

Merge two adjacent b
  mlp b
END

pleaseChangeDita(in=>$in, out=>$out, trace=>1);                                 #TpleaseChangeDita

ok readFile(fpe($out, qw(1 dita))) eq <<END;
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

if (1) {                                                                        #TtransformDitaWithPcd #TcompilePcdFile #TcompilePcdFiles
 my $blocks =
[[["Change d under c under b to D", 1, "test.pcd"],
 [["\$o->change((\"D\", \"d\", \"c\", \"b\"));",  2, "test.pcd"]]],
 [["Change B to b", 4, "test.pcd"],
 [["\$o->change((\"b\", \"B\"));", 5, "test.pcd"]]],
 [["Merge two adjacent b", 7, "test.pcd"],
 [["\$o->mlp(\"b\");", 8, "test.pcd"]],
]];

  is_deeply [eval(dump(compilePcdFile($inFile)) =~ s($in) ()gsr)], $blocks;
  is_deeply  eval(dump(compilePcdFiles($in))    =~ s($in) ()gsr),  $blocks;

  ok -p transformDitaWithPcd(Data::Edit::Xml::new(<<END), $blocks) eq <<END;
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

}
clearFolder($_, 1e2) for $in, $out;

done_testing;
