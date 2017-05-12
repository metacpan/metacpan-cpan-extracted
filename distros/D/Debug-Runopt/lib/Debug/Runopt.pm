package Debug::Runopt;

use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '1.01';
our $RCFileLoc;

sub init {
  my ($opts) = @_;

  ## Source file for debug commands, if provided
  my $src = ($opts && $opts->{src})?$opts->{src}:undef;

  ## Get the command line - basically to check if already running under debugger
  my @cmdLine = `ps -o args $$`;

  ## Invoke debugger only when not already running under one
  if ($cmdLine[1] !~ /-d/) {
      my $rcFile;

      unless((open $rcFile, ">.perldb") && do {$RCFileLoc = '.perldb';}) {
          (open $rcFile, ">$ENV{HOME}/.perldb") && do {$RCFileLoc = "$ENV{HOME}/.perldb";} 
                        || croak "Could not open .perldb for writing";
      }

      setParseOptions($rcFile,$opts);

      if ($src) {
          my $srcFile;
          open $srcFile, "<$src" || croak "Could not open $src for writing";

          setSourceFile($rcFile, $srcFile);

          close $srcFile;
      }
   
      close($rcFile);

      ## All settings done, run with debugger now 
      exec "$^X -d $0 @ARGV";
  }
}

## Set parse_options parameters in rc file.
## Can be used for writing free form debug customizations also
sub setParseOptions {
    my ($rc, $opt) = @_;

    ## All the rc file content provided as free form text
    if ($opt && defined $opt->{freecontent}) {
        print $rc $opt->{freecontent};
    }
    else {
        ## parse_options string provided verbatim
        if ($opt && defined $opt->{parseoptions}) {
            print $rc "parse_options($$opt{parseoptions});\n";
        }
        else {
            ## User specified or default
            my $interActive = ($opt && defined $opt->{interactive})?$opt->{interactive}:1;
            my $outputFile  = ($opt && defined $opt->{outputfile})?$opt->{outputfile}:'db.out';
            my $autoTrace   = ($opt && defined $opt->{autotrace})?$opt->{autotrace}:1;
            my $frame       = ($opt && defined $opt->{frame})?$opt->{frame}:6;

            print "Info :: Debug outputs can be obtained in $outputFile\n";

            print $rc "parse_options(\"NonStop=$interActive LineInfo=$outputFile AutoTrace=$autoTrace frame=$frame\");","\n";
        }
    }
}

## Sets debug commands to a file
## to be fed to debugger while running
sub setSourceFile {
    my ($rc, $src) = @_;

    ## Read from source file line by line
    my $srcCmdStr;
    while (my $line = <$src>) {
        chomp $line;
        $srcCmdStr .= "'$line',";
    }

    ## RC file directive to feed to @DB::typeahead
    if($srcCmdStr) {
        $srcCmdStr =~ s/,$//;
        print $rc "sub afterinit { push \@DB::typeahead,$srcCmdStr;}","\n";
    }
}

## Call this if you want to clean up the rc files
sub end {
    ## Clean up of RC files - call end() optionally
    foreach my $rcFile ("$ENV{HOME}/.perldb",".perldb") {
        if (-f $rcFile) {
            print "Warning :: Removing $rcFile\n";
            unlink $rcFile || croak "Error :: Could not remove $rcFile\n";
        }
    }
}

1;

=head1 NAME

Debug::Runopt - Customize how to run debugger
                Specify configurable debug options as part of rc file ie .perldb or ~/.perldb under Unix.
                Specify runtime debug commands into a file and source to debugger 
                - works for interactive/non interactive both modes
                       
=head1 SYNOPSIS

  use Debug::Runopt;

  Debug::Runopt::init();

      - Initializes debugger with a few default parse options eg.
        NonStop=1 LineInfo=db.out AutoTrace=1 frame=6
        No source command file given, debugger goes through normal execution flow.

  Debug::Runopt::init({'src'=>'tmp.cmd'});

      - Default parameters for parse_options, commands read from tmp.cmd

  Debug::Runopt::init({'src'=>'tmp.cmd', 'interactive' => 0, 'outputfile' => 'debug.out',
                     'autotrace' => 0, 'frame' => 2});

      - Sets parse_options as NonStop=0 LineInfo=debug.out AutoTrace=0 frame=2

  Debug::Runopt::init({'src'=>'tmp.cmd','parseoptions' => 'blah blah'});

      - Sets parse_options("blah blah");

  Debug::Runopt::init({'freecontent' => 'free form text blah blah....'});
   
      - Writes 'free form text blah blah' to rc file as is.
        Care should be taken while passing content like this.

  Debug::Runopt::end();

      - This can be optionally called at the end of the debuuged program
        if rc files created needs to be cleaned up                
  
=head1 ABSTRACT

  This module tries to make debugging easy by letting user specify configurable
  options particulary when running in non-interactive mode.

  Apart from the configurable options, a source can be created on the run with user
  specified contents and run with debugger.

=head1 METHODS

  init() :: public

      - Initializes configurable options and rc file if any.

  end() :: public

      - Cleans up rc files created during execution if any.

  setParseOptions :: private

      - Sets up parse_options and other configurable directives.

  setSourceFile :: private

      - Creates rc file if required.

=head1 CAVEATS

  It works only for a few versions of Unix/Linux.
  Further improvement plan involves avoiding creating of rc file and using debug hooks. 

=head1 Similar Modules

  Debug::Simple

=head1 SUPPORT

  debashish@cpan.org

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Debashish Parasar, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
 
