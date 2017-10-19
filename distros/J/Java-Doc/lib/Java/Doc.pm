#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Extract documentation from Java source code.
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
# Override when we click on the method it should go to the overridden method and the comment can then be shortened
# Method should use a hash of fields, it currently uses an array
# returns in title should link to definition of that item
# class in title should link to definition of that class
package Java::Doc;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

our $VERSION = '20171014';

genLValueHashMethods(qw(parse));                                                # Combined parse tree of all the input files read
genLValueHashMethods(qw(classes));                                              # Classes encountered in all the input files read

my %veryWellKnownClassesHash = map {$_=>1} split /\n/, &veryWellKnownClasses;   # Urls describing some well known Java classes

sub urlIfKnown($$)                                                              # Replace a well known type with an informative url
 {my ($javaDoc, $type)  = @_;                                                   # Java doc builder, type to replace with an informative url
  for my $url(keys %veryWellKnownClassesHash, @{$javaDoc->wellKnownClasses})
   {my $i = index($url, "/$type.html");
    if ($i >= 0)
     {return qq(<a target="_blank" href="$url">$type</a>);
     }
   }
  $type
 }

sub getAttributes($)                                                            # Get the attributes from a method type: public, private, final, static etc
  {my ($type) = @_;                                                             # Type as parsed out
   my $t = qq( $type );                                                         # Blank pad
   $t =~ s(\A\s*[\(\{]) ( )gs;                                                  # Replace leading open bracket with space
   my @attributes;                                                              # Method attributes
   for(qw(public private protected abstract final static))
    {push @attributes, $_ if $t =~ m($_)s;
     $t =~ s($_) ( )gs;
    }
   $t =~ s(\s+) ( )gs;                                                          # Remove excess white space
   (trim($t), @attributes)
  }
#say STDERR dump([getAttributes("  (final  public static  float  ")]);  exit;

sub parseJavaFile($$)                                                           # Parse java file for package, class, method, parameters
 {my ($javaDoc, $fileOrString)  = @_;                                           # Java doc builder, Parse tree, java file or string of java to process
  my $parse = $javaDoc->parse;                                                  # Parse tree

  my $snf = $fileOrString =~ m(\n)s;                                            # String not file
  my $s = $fileOrString =~ m(\n)s ? $fileOrString : readFile($fileOrString);    # Source
  say STDERR $fileOrString unless $snf;

  my $package;                                                                  # Package we are in
  my @class;                                                                    # Containing classes as array
  my $class;                                                                    # Containing classes as a.b.c
  my $method;                                                                   # Method we are in
  my $state = 0;                                                                # 0 - outer, 1 - parameters to last method

  my $line = 0;                                                                 # Line numbers
  for(split /\n/, $s)
   {++$line;

    my $at = sub                                                                # Position
     {return "at line: $line\n$_\n" if $snf;
      "at line $line in file/string:\n$fileOrString\n$_\n";
     }->();

    if ($state == 0)
     {if (m(\A\s*package\s+((\w+|\.)+)))                                        # 'package' package ;
       {#say STDERR "Package = $1";
        $package = $1;
       }
      elsif (m(\A.*?class\s+(\S+)\s*\{?\s*//C\s+(.*?)\s*\Z))                    # Class with optional '{' //C
       {push @class, $1;                                                        # Save containing class
        $class = join '.', @class;
        #say STDERR "Class $class = $1 = $2";
        $javaDoc->classes->{$class} = $parse->{$package}{$class}{comment} = $2; # Record the last encountered class as the class to link to - could be improved!
       }
      elsif (m(\A\s*}\s*//C\s+(\S+)))                                           # '}' '//C' className - close class className
       {#say STDERR "Class = $1 End";
        if (!@class)
         {warn "Closing class $1 but no class to close $at";
         }
        elsif ($1 ne $class[-1])
         {warn "Closing class $1 but in class $class $at";
         }
        else
         {$parse->{$package}{$class}{methods} =
           [sort
             {my $r = $b->{res}     cmp $a->{res};     return $r if $r;
              my $n = $a->{name}    cmp $b->{name};    return $n if $n;
              my $c = $a->{comment} cmp $b->{comment}; return $c;
             }
            @{$parse->{$package}{$class}{methods}}];

          pop @class;
          $class = join '.', @class;
         }
       }
      elsif                                                                     # Method with either '()' meaning no parameters or optional '(' followed by //M for method, //c for constructor, //O=package.method for override of the named method. If () is specified  then {} can follow to indicate an empty method
            (m(\A\s*(.*?)
                 \s+(\w+)
                 \s*(\x28\s*\x29\s*(?:\x7b\s*\x7d)?)?
                 \s*\x28?\s*
                 //(M|c|O=\S+)\s+(.*?)\s*\Z)x)                                  # Comment
       {my ($empty, $res, $comment) = ($3, $4, $5);
        $method = $2;

        my ($type, @attributes) = getAttributes($1);                            # Method attributes

        my $override;                                                           # Method is an override
        if ($res =~ m(\Ac\Z)s)                                                  # In summa it is a constructor
         {push @attributes, q(constructor);                                     # Constructor
          if ($package and $class)
           {$type = qq(<a href="#$package.$class.$method">$method</a>);         # Type for a constructor is the constructor name
           }
          elsif (!$package)
           {warn "Ignoring method $method because no package specified $at";
           }
          elsif (!$class)
           {warn "Ignoring method $method because no containing class $at";
           }
         }
        elsif ($res =~ m(\AO=(.+?)\Z)s)                                         # Override
         {$override = $1;
          my $dot = $comment =~ m(\.\Z)s ? '' : '.';
          $comment  = qq($comment$dot Overrides: <a href="#$override">$override</a>);
         }

        if ($package and $class)                                                # Save method details is possible
         {#say STDERR "Method = $method == $type == $comment ";

          push @{$parse->{$package}{$class}{methods}},
                {type=>$javaDoc->urlIfKnown($type), name=>$method, res=>$res,
                 comment=>$comment, attributes=>[@attributes], line=>$line};
          $state = 1 if !$empty and !$override;                                 # Get parameters next if method has parameters and is not an override
         }
        else
         {my $m = qq(Ignoring method $method as no preceding);
          warn "$m package $at" unless $package;
          warn "$m class $at"   unless $class;
         }
       }
     }
    elsif ($state == 1)
     {if (m(\A.\s*(.+?)\s+(\w+)\s*[,\)\{]*\s*//P\s+(.*?)\s*\Z))                 # type name, optional ',){', //P
       {#say STDERR "Parameter =$1=$2=$3";
        my ($type, $parameter, $comment) = ($1, $2, $3);
        my ($t, @attributes) = getAttributes($type);
        push @{$parse->{$package}{$class}{methods}[-1]{parameters}},
             [$javaDoc->urlIfKnown($t), $parameter, $comment, [@attributes],
              $line];
       }
      else                                                                      # End of parameters if the line does not match
       {$state = 0;
        if ($package and $class and $method)
         {my $m = $parse->{$package}{$class}{methods}[-1];
          if (my $p = $m->{parameters})
           {if (my @p = @$p)
             {$m->{nameSig} = join ', ', map {$_->[1]} @p;
              $m->{typeSig} = join ', ', map {$_->[0]} @p;
             }
           }
         }
        elsif (!$package)
         {warn "Ignoring method $method because no package specified $at";
         }
        elsif (!$class)
         {warn "Ignoring method $method because no containing class $at";
         }
       }
     }
   }
  if (0 and @class)
   {if ($snf)
     {warn "Classes still to close at end of string: ".join(' ', @class);
     }
    else
     {warn "Classes still to close: ".join(' ', @class). "\n".
           "At end of file:\n$fileOrString";
     }
   }
  $parse
 }

sub parseJavaFiles($)                                                           # Parse all the input files into one parse tree
 {my ($javaDoc)  = @_;                                                          # Java doc processor
  for(sort @{$javaDoc->source})                                                 # Extend the parse tree with the parse of each source file
   {$javaDoc->parseJavaFile($_);
   }
 }

sub htmlJavaFiles($)                                                            # Create documentation using html for all java files from combined parse tree
 {my ($javaDoc)  = @_;                                                          # Java doc processor, combined parse tree
  my $parse = $javaDoc->parse;                                                  # Parse tree
  my $indent = $javaDoc->indent // 0;                                           # Indentation per level
  my @c = @{$javaDoc->colors};                                                  # Back ground colours
     @c = 'white' unless @c;
  my $d;                                                                        # Current background colour - start
  my $D = q(</div>);                                                            # Current background colour - end
  my $swapColours = sub                                                         # Swap background colour
   {my ($margin) = @_;
    my $m = $margin * $indent;
    push @c, my $c = shift @c;
    $d = qq(<div style="background-color: $c; margin-left: $m">);
   };
  &$swapColours(0);                                                             # Swap background colour

  my @h = <<END;
$d
<head>
 <meta charset="UTF-8">
</head>
<body>
<h1>Packages</h1>
<table border="1" cellspacing="20">
END
  for my $package(sort keys %$parse)
   {push @h, qq(<tr><td><a href="#$package">$package</a></tr>);
   }
  push @h, <<END;
</table>
$D
END

  for my $package(sort keys %$parse)
   {my %package = %{$parse->{$package}};
    &$swapColours(1);
    push @h, <<END;
<a name="$package"/>
$d
<h2>Package: <big>$package</big></h2>
<table border="1" cellspacing="20">
<tr><th>Class<th>Description</tr>
END
    for my $class(sort keys %package)
     {my %class = %{$package{$class}};
      my $classComment = $class{comment};
      push @h, <<"END";
<tr><td><a href="#$package/$class">$class</a>
    <td>$classComment
</tr>
END
     }
    push @h, <<END;
</table>
$D
END
    for my $class(sort keys %package)
     {my %class = %{$package{$class}};
      my $classComment = $class{comment};
      &$swapColours(2);
      push @h, <<END;
$d
<a name="$package/$class"/>
<h3>Class: <big>$class</big>, package: $package</h3>
<p>$classComment
<table border="1" cellspacing="20">
<tr><th>Returns<th>Method<th>Signature<th>Attributes<th>Line<th>Description</tr>
END
      for my $method(@{$class{methods}})
       {my %method  = %{$method};
        my $attr    = join ' ', @{$method{attributes}//[]};
        my $type    = $method{type};
        my $name    = $method{name};
        my $comment = $method{comment};
        my $line    = $method{line};
        my $sig     = $method{typeSig} // 'void';
        push @h, <<END;
<tr><td>$type
    <td><a href="#$package/$class/$name">$name</a>
    <td>$sig
    <td>$attr
    <td>$line
    <td>$comment
</tr>
END
       }
      push @h, <<END;
</table>
$D
END
      for my $method(@{$class{methods}})
       {my %method = %{$method};
        my $type = $method{type};
        my $name = $method{name};
        my $comment = $method{comment};
        my $sig     = $method{typeSig} // '';
        &$swapColours(3);
        push @h, <<END;
$d
<a name="$package/$class/$name"/>
<h4><big>$name($sig)</big> returns <big>$type</big>   <small>in class $class</small></h4>
<p>$comment</p>
END

        if (my $parameters = $method{parameters})
         {my @parameters = @$parameters;
          push @h, <<END;
<table border="1" cellspacing="20">
<tr><th>Name<th>Type<th>Line<th>Description</tr>
END
          for my $parameter(@parameters)
           {my ($type, $name, $comment, $attributes, $line) = @$parameter;
            my $attr    = join ' ', @{$attributes//[]};
            push @h, qq(<tr><td>$name<td>$type<td>$line<td>$comment</tr>);
           }
          push @h, <<END;
</table>
END
         }
        push @h, <<END;
$D
</body>
END
       }
     }
   }

  s(L<(.+?)>) (<a href="#$1">$1</a>)gs for @h;

  @h
 }

sub veryWellKnownClasses {<<'END'}
https://developer.android.com/reference/android/app/Activity.html
https://developer.android.com/reference/android/content/Context.html
https://developer.android.com/reference/android/graphics/BitmapFactory.html
https://developer.android.com/reference/android/graphics/Bitmap.html
https://developer.android.com/reference/android/graphics/Canvas.html
https://developer.android.com/reference/android/graphics/drawable/BitmapDrawable.html
https://developer.android.com/reference/android/graphics/drawable/Drawable.html
https://developer.android.com/reference/android/graphics/Matrix.html
https://developer.android.com/reference/android/graphics/Paint.html
https://developer.android.com/reference/android/graphics/Path.html
https://developer.android.com/reference/android/graphics/PorterDuff.Mode.html
https://developer.android.com/reference/android/graphics/RectF.html
https://developer.android.com/reference/android/media/MediaPlayer.html
https://developer.android.com/reference/android/util/DisplayMetrics.html
https://developer.android.com/reference/java/io/ByteArrayOutputStream.html
https://developer.android.com/reference/java/io/DataInputStream.html
https://developer.android.com/reference/java/io/DataOutputStream.html
https://developer.android.com/reference/java/io/File.html
https://developer.android.com/reference/java/io/FileOutputStream.html
https://developer.android.com/reference/java/lang/String.html
https://developer.android.com/reference/java/lang/Thread.html
https://developer.android.com/reference/java/util/Stack.html
https://developer.android.com/reference/java/util/TreeMap.html
https://developer.android.com/reference/java/util/TreeSet.html
https://developer.android.com/studio/command-line/adb.html
END

#1 Attributes                                                                   # Attributes that can be set or retrieved by assignment

if (1) {                                                                        # Parameters that can be set by the caller
  genLValueArrayMethods(qw(source));                                            # A reference to an array of Java source files that contain documentation as well as java
  genLValueScalarMethods(qw(target));                                           # Name of the file to contain the generated documentation
  genLValueArrayMethods(qw(wellKnownClasses));                                  # A reference to an array of urls that contain the class name of well known Java classes such as: L<TreeMap|/https://developer.android.com/reference/java/util/TreeMap.html> which will be used in place of the class name to make it possible to locate definitions of these other classes.
  genLValueScalarMethods(qw(indent));                                           # Indentation for methods vs classes and classes vs packages - defaults to 0
  genLValueArrayMethods(qw(colors));                                            # A reference to an array of colours expressed in html format - defaults to B<white> - the background applied to each output section is cycled through these colours to individuate each section.
 }

#1 Methods                                                                      # Methods available

sub new                                                                         # Create a new java doc processor
 {bless {};                                                                     # Java doc processor
 }

sub html($)                                                                     # Create documentation using html as the output format. Write the generated html to the file specified by L<target|/target> if any and return the generated html as an array of lines.
 {my ($javaDoc)  = @_;                                                          # Java doc processor
  $javaDoc->parseJavaFiles;                                                     # Parse the input files
  my @h = $javaDoc->htmlJavaFiles;                                              # Write as html

  if (my $file = $javaDoc->target)
   {my $h = @h;
    writeFile($file, join "\n", @h);
    say STDERR "$h lines of documentation written to:\n$file";
   }
  @h                                                                            # Return the generated html
 }

# podDocumentation

=encoding utf-8

=head1 Name

Java::Doc - Extract L<documentation|https://metacpan.org/source/PRBRENAN/Java-Doc-20171012/examples/documentation.html>
from L<Java source code|https://metacpan.org/source/PRBRENAN/Java-Doc-20171012/examples/documentation.java>

=head1 Synopsis

  use Java::Doc;

  my $j = Java::Doc::new;                                # New document builder

  $j->source = [qw(~/java/layoutText/LayoutText.java)];  # Source files
  $j->target =  qq(~/java/documentation.html);           # Output html
  $j->indent = 20;                                       # Indentation
  $j->colors = [map {"#$_"} qw(ccFFFF FFccFF FFFFcc),    # Background colours
                            qw(CCccFF FFCCcc ccFFCC)];
  $j->html;                                              # Create html

Each source file is parsed for documentation information which is then
collated into a colorful cross referenced html file.

Documentation is extracted for L<packages|/Packages>, L<classes|/Classes>,
L<methods|/Methods>.

=head2 Packages

Lines matching

  package packageName ;

are assumed to define packages.

=head2 Classes

Lines with comments B<//C> are assumed to define classes:

  class className    //C <comment>

with the text of the comment being the definition of the class.

Classes are terminated with:

 } //C className

which allows class document definitions to be nested.

=head2 Methods

Methods are specified by lines with comments matching B<//M>:

  methodName ()  //M <comment>

  methodName     //M <comment>

with the description of the method contained in the text of the comment
extending to the end of the line.

Constructors should be marked with comments matching B<//c> as in:

  methodName     //c <comment>

Methods that are overridden should be noted with a comment as in:

  methodName     //O=package.class.method <comment>

=head2 Parameters

Methods that are not overrides and that do have parameters should place the
parameters declarations one per line on succeeding lines marked with comments
B<//P> as in:

  parameterName //P <comment>

=head2 Example

The following fragment of java code provides an example of documentation held as
comments that can be processed by this module:

 package com.appaapps;

 public class Outer        //C Layout text on a canvas
  {public static void draw //M Draw text to fill a fractional area of the canvas
    (final Canvas canvas)  //P Canvas to draw on
    {}

   class Inner              //C Inner class
    {InnerText()            //c Constructor
      {}
    } //C Inner
  } //C Outer

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Attributes

Attributes that can be set or retrieved by assignment

=head2 source :lvalue

A reference to an array of Java source files that contain documentation as well as java


=head2 target :lvalue

Name of the file to contain the generated documentation


=head2 wellKnownClasses :lvalue

A reference to an array of urls that contain the class name of well known Java classes such as: L<TreeMap|/https://developer.android.com/reference/java/util/TreeMap.html> which will be used in place of the class name to make it possible to locate definitions of these other classes.


=head2 indent :lvalue

Indentation for methods vs classes and classes vs packages - defaults to 0


=head2 colors :lvalue

A reference to an array of colours expressed in html format - defaults to B<white> - the background applied to each output section is cycled through these colours to individuate each section.


=head1 Methods

Methods available

=head2 new()

Create a new java doc processor


=head2 html($)

Create documentation using html as the output format. Write the generated html to the file specified by L<target|/target> if any and return the generated html as an array of lines.

  1  $javaDoc  Java doc processor


=head1 Index


1 L<colors|/colors>

2 L<html|/html>

3 L<indent|/indent>

4 L<new|/new>

5 L<source|/source>

6 L<target|/target>

7 L<wellKnownClasses|/wellKnownClasses>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

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
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 1;

my $j = Java::Doc::new;
$j->source = [<<END];
package com.appaapps;

public class LayoutText                                                         //C Draw text to fill a fractional area of a canvas, justifying remaining space
 {
  public void draw                                                              //M Draw text to fill a fractional area of a canvas, justifying remaining space
   (final Canvas canvas,                                                        //P Canvas to draw on
    final String text,                                                          //P Text to draw
    final float x,                                                              //P Area to draw text in expressed as fractions of the canvas: left   x
   )
   {say("Different text sizes");
   }

  public class Inner                                                            //C Draw text to fill a fractional area of a canvas, justifying remaining space
   {public void shade                                                           //M Scribble on canvas
     (final Canvas canvas,                                                      //P Canvas to draw on
      final String text,                                                        //P Text to draw
      final float x,                                                            //P Area to draw text in expressed as fractions of the canvas: left   x
     )
     {say("Different text sizes");
     }
   } // class Inner

  public void scribble                                                          //M Scribble on canvas
   (final Canvas canvas,                                                        //P Canvas to draw on
    final String text,                                                          //P Text to draw
    final float x,                                                              //P Area to draw text in expressed as fractions of the canvas: left   x
   )
   {say("Different text sizes");
   }
 }
END
$j->colors = [map {"#$_"} qw(ccFFFF FFccFF FFFFcc),                             # Colours
                          qw(CCccFF FFCCcc ccFFCC)];

my @h = $j->html;

#writeFile("out.html", join "\n", @h);

#say STDERR "AAAA ", scalar(@h);

ok 35 == @h;
