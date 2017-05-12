# Java::Makefile
# Version 1.0
# Copyright (C) 2015 David Helkowski
# License CC-BY-SA ( http://creativecommons.org/licenses/by-sa/4.0/ )

# This program generates Makefiles that can build Java programs as a jar containing other Jar dependencies
# It utilizes the Eclipse "jarinjarloader" to accomplish this
#   The source for it is included and built automatically as well
#   The source is licensed under the Eclipse Public License.
# A custom Manifest is needed for the "jarinjarloader" to function properly, and is generated along with the Makefile

=head1 NAME

Java::Makefile - Script to generate Makefile for building Java projects into a single standalone jar

=head1 VERSION

1.00

=cut

package Java::Makefile;
use warnings;
use strict;
use vars qw/$VERSION/;
$VERSION = "1.00";
use XML::Bare qw/xval forcearray/;

sub new {
  my $class = shift;
  my %ops = ( @_ );
  my $self = bless { jar_set => [] }, $class;
  if( $ops{'config_file'} ) {
    $self->read_configuration( $ops{'config_file'} );
  }
  return $self;
}

sub read_configuration {
  my ( $self, $config_file ) = @_;
  my ( $ob, $xml ) = XML::Bare->simple( file => $config_file );
  $xml = $xml->{'xml'};

  $self->{'classes'} = forcearray( $xml->{'class'} );
  $self->{'jars'}    = forcearray( $xml->{'classpath'}{'jar'} );
  
  $self->{'manifest_filename'} = $xml->{'manifest'} || "Manifest.txt";
  $self->{'output_jar_filename'} = $xml->{'output_jar'} or die "Output jar not specified";
  $self->{'source_folder'} = $xml->{'source_folder'} or die "Source folder not specified";
}

sub read_jars {
  my ( $self, $jars ) = @_;
  my $jarlines = '';
  my $jarfolders = '';
  my $jarextra = '';
  my %folder_hash;
  
  my $all_jars = [];
  
  my $jar_set = $self->{'jar_set'};
  my $j_lines = [];
  for my $jarspec ( @$jars ) {
    my $usemacro = 0;
    if( ref( $jarspec ) && $jarspec->{'usemacro'} ) {
      $jarspec = $jarspec->{'content'};
      $usemacro = 1;
    }
    my $fulljarspec = $jarspec;
    $jarspec =~ m|(.+)/([^/]+)$|;
    my $folder = $1;
    $folder_hash{ $folder } = 1;
    my $jarspec = $2;
    
    my $jar_arr = [];
    if( $jarspec =~ m/\*/ ) {
      $jarspec =~ s/\./\\\./g;
      $jarspec =~ s/\*/\.+/;
      $jar_arr = files_matching( $folder, $jarspec );
      push( @$jar_set, @$jar_arr );
      
      if( $usemacro ) {
        my $basevar = $folder;
        $basevar =~ s/[^A-Za-z]//g;
        my $var = "JAR_LINES_$basevar";
        my $raw = "JAR_LINES_RAW_$basevar";
        $jarextra .= "\n\n$raw = \$(wildcard $fulljarspec)\n";
        $jarextra .= "$var = \$(subst $folder/,-C $folder ,\$($raw))";
        push( @$j_lines, "\t\$($var) \\" );
      }
      else {
        for my $j ( @$jar_arr ) {
          push( @$j_lines, "\t-C $folder $j \\" );
        }
      }
    }
    else {
      push( @$jar_set, $jarspec );
      push( @$j_lines, "\t-C $folder $jarspec \\" );
    }
  }
  
  my $jf_lines = [];
  for my $jf ( keys %folder_hash ) {
    push( @$jf_lines, "\t$jf/* \\" );
  }
  $jarfolders = join( "\n", @$jf_lines );
  $jarlines   = join( "\n", @$j_lines  );
  
  $jarfolders = substr( $jarfolders, 0, -2 );
  $jarlines   = substr( $jarlines  , 0, -2 );
  
  return ( $jarlines, $jarfolders, $jarextra );
}

sub files_matching {
  my ( $dir, $re ) = @_;
  opendir( my $dh, $dir ) or die "Cannot open dir $dir";
  my @files = readdir( $dh );
  closedir( $dh );
  
  my @match;
  for my $file ( @files ) {
    next if( $file =~ m/^\.+$/ );
    if( $file =~ m/^$re$/ ) {
      push( @match, $file );
    }
  }
  return \@match;
}

sub read_classes {
  my ( $self, $classes ) = @_;
  my $classlines  = '';
  my $dep_classes = '';
  
  my $src_folder = $self->{'source_folder'};
  
  for my $class ( @$classes ) {
    my $name = $class->{'name'};
    my $path = $class->{'path'};
    my $use_node = $class->{'use'};
    
    my $java = $path ? "$path.java" : "$src_folder/$name.java";
    
    if( $use_node ) {
      # we have a dependent class
      my $uses = forcearray( $use_node );
      
      my $source_arr = [ $java ];
      for my $use ( @$uses ) {
        my $uc = $use->{'class'};
        my $usepath;
        if( $uc =~ m|/| ) {
          $usepath = "$uc.java";
        }
        else {
          $usepath = "$src_folder/$uc.java";
        }
        push( @$source_arr, $usepath );
      }
      my $cls;
      if( $path ) {
        $cls = "$path.class";
      }
      else {
        $cls = "$src_folder/$name.class";
      }
      $dep_classes .= "$cls: $java\n";
      my $sources = join(' ',@$source_arr);
      $dep_classes .= "\t\$(JC) \$(JFLAGS) -classpath \$(CLASSPATH) $sources\n\n";
    }
    $classlines .= "\t$java \\\n";
  }
  
  setup_jarinjar();
  #my $jarinjar = "$path/com/codechild/jarinjarloader";
  #$classlines .= "\t$jarinjar/JarRsrcLoader.java \\\n";
  #$classlines .= "\t$jarinjar/JIJConstants.java \\\n";
  #$classlines .= "\t$jarinjar/RsrcURLConnection.java \\\n";
  #$classlines .= "\t$jarinjar/RsrcURLStreamHandler.java \\\n";
  #$classlines .= "\t$jarinjar/RsrcURLStreamHandlerFactory.java \\\n";
  
  $classlines = substr( $classlines, 0, -3 );
  $dep_classes = substr( $dep_classes, 0, -2 );
  
  return ( $classlines, $dep_classes );
}

# Copy the source of the jarinjarloader locally and then compile it so it can be included
sub setup_jarinjar {
  my $path = $INC{'Java/Makefile.pm'};
  #print "Path: $path\n";
  $path =~ s|/Makefile\.pm$||;
  #print "Path: $path\n";
  if( ! -d 'com' ) { mkdir 'com'; }
  if( ! -d 'com/codechild' ) { mkdir 'com/codechild'; }
  if( ! -d 'com/codechild/jarinjarloader' ) { mkdir 'com/codechild/jarinjarloader'; }
  `cp $path/com.codechild.jarinjarloader/* com/codechild/jarinjarloader`;
  `cd com/codechild/jarinjarloader; javac *.java 2> /dev/null`;
}

sub write_manifest {
  my ( $self, $file ) = @_;
  $file ||= $self->{'manifest_filename'};
  
  my $src_folder = $self->{'source_folder'};
  my $jar_set = $self->{'jar_set'};
  
  open( my $fh, ">$file" );
  print $fh "Manifest-Version: 1.0\nCreated-By: CPAN Java::Makefile v1.0\n";
  my $long = "Rsrc-Class-Path: ./ " . join( ' ', @$jar_set ) . "\n";
  print $fh split72( $long );
  print $fh "Class-Path: .\nRsrc-Main-Class: $src_folder.Main\nMain-Class: com.codechild.jarinjarloader.JarRsrcLoader\n";
  close( $fh );
}

sub split72 {
    my $str = shift;
    my $chr1 = substr( $str, 0, 1 );
    $str = substr( $str, 1 );
    $str =~ s/(.{69})/[$1]\n/g;
    $str =~ s/\[(.+)\]\n/ $1\n/g;
    $str =~ s/([^\n]+)\n$/ $1\n/;
    return $chr1 . substr( $str, 1 );
}

sub write_makefile {
  my ( $self, $loc ) = @_;
  
  $loc ||= "Makefile";
  my ( $classlines, $dependent_classes     ) = $self->read_classes( $self->{'classes'} );
  my ( $jarlines  , $jarfolders, $jarextra ) = $self->read_jars( $self->{'jars'} );
  
  my $mfile = $self->{'manifest_filename'} || 'Manifest.txt';
  
  $self->write_manifest();
  
  my $output_jar_filename = $self->{'output_jar_filename'};
  my $src_folder = $self->{'source_folder'};
  
  open( my $fh, ">$loc" ) or die "Cannot open $loc for writing";
  print $fh 
"# This Makefile was generated by CPAN Java::Makefile Version 1.0
JFLAGS = -g
JC = javac
.SUFFIXES: .java .class
.java.class:
\t\$(JC) \$(JFLAGS) -classpath \$(CLASSPATH) \$*.java

all: classes jar

jar: classes
\tjar cfm $output_jar_filename $mfile \$(CLASSFILES) \$(CLASSPATHJAR) com/codechild/jarinjarloader/*.class

$src_folder/Main.class: $src_folder/Main.java \$(CLASSES)
\t\$(JC) \$(JFLAGS) -classpath \$(CLASSPATH) \$*.java \$(CLASSES)

$dependent_classes$jarextra

CLASSPATHJAR = \\
$jarlines

CLASSPATHX = \\
$jarfolders

empty =
space = \$(empty) \$(empty)
CLASSPATH = \$(subst \$(space),:,\$(CLASSPATHX))

CLASSFILES = \$(subst .java,.class,\$(CLASSES))

CLASSES = \\
$classlines

default: classes

classes: \$(CLASSES:.java=.class)

clean:
\t\$(RM) $src_folder/*.class $output_jar_filename Manifest.txt";

  close( $fh );
}

1;

__END__

=head1 SYNOPSIS

This is the Git repository for the Perl CPAN module Java::Makefile.

It is designed to be a quick and painless way to create standalone Jar files for Java projects from some simple XML declaring the classes in the project and the jars that are depended upon.

Jars are injected directly into the build jar file, and their contents are accessible to the built Java project by way of the "jarinjarloader".

=head1 DESCRIPTION

=head2 Basic Example

=head3 generate_makefile.pl

    #!/usr/bin/perl -w
    use Java::Makefile;
    
    my $jm = Java::Makefile->new( config_file => 'makefile_specs.xml' );
    $jm->write_makefile();

=head3 makefile_spec.xml

    <xml>
      <output_jar>test_project.jar</output_jar>
      <source_folder>test_project</source_folder>
      
      <class name="Main" />
      
      <classpath>
        <jar>libraries/some_jar_you_need.jar</jar>
      </classpath>
    </xml>

=head1 LICENSE

    Copyright (C) 2015 David Helkowski
    Licensed under CC-BY-SA 4.0
    jarinjarloader licensed under EPL 1.0
    See LICENSE file for full details

=cut