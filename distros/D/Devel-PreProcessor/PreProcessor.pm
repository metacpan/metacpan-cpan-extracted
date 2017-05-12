#!/usr/local/bin/perl -s

package Devel::PreProcessor;

$VERSION = 2003.1128;

use strict;
use IO::File;

# Option flags, defaulting to off
use vars qw( $Includes $Conditionals $StripComments $StripPods $ShowFileBoundaries $StripBlankLines );

# %psuedo_INC - hash of filenames included so far
# @psuedo_INC - directories to search for modules
use vars qw( %psuedo_INC @psuedo_INC );

# %Importers - maps file inclusion keywords to their import methods
use vars qw( %Importers );
%Importers = (
  'require' => '',
  'use' => 'import',
  'no' => 'unimport',
);

# Devel::PreProcessor->import( 'StripPods', 'Conditionals', ... );
sub import {
  my $package = shift;
  foreach ( @_ ) {
    if ( m/Conditionals/i ) {
      $Conditionals = 1;
    } elsif ( m/Includes/i ) {
      $Includes = 1;
    } elsif ( m/StripComments/i ) {
      $StripComments = 1;
    } elsif ( m/ShowFileBoundaries/i ) {
      $ShowFileBoundaries = 1;
    } elsif ( m/StripBlankLines/i ) {
      $StripBlankLines = 1;
    } elsif ( m/StripPods/i ) {
      $StripPods = 1;
    } elsif ( m/LibPath:(.*)/i ) {
      @INC = split(/\:/, $1);
    } else {
      die "unkown import";
    }
  }
}

@psuedo_INC = @INC;
%psuedo_INC = ();

# If we're being run directly, expand the first file on the command line.
unless ( caller ) {
  $Includes ||= $main::Includes;
  $Conditionals ||= $main::Conditionals;
  $StripComments ||= $main::StripComments;
  $StripBlankLines ||= $main::StripBlankLines;
  $StripPods ||= $main::StripPods;
  $ShowFileBoundaries ||= $main::ShowFileBoundaries;
  my $source = shift @ARGV;
  if ( scalar @ARGV ) {
    @psuedo_INC = @ARGV;
 }
  parse_file( $source, 'outermost_file'=>1 );
}

### File Processing

# parse_file( $filename, %options );
sub parse_file {
  my $filename = shift;
  my $fh = IO::File->new($filename);
  
  my $line_number = 0;
  my %module_info = @_;
  
  LINE: while( defined ($_ = $fh->getline) ) {
    $line_number ++;
    
    # Handle use, no, and require statements
    if ( $Includes and /^\s*(use|no)\s+([^\s\(\;]+)\b(?:\s*(\S.*))?;/ ) {
      my($mode, $mod_name, $import_list) = ( $1, $2, $3 );
      $module_info{'isa_AutoLoader'} = 1 if ($mod_name =~ /AutoLoader/);
      handle_include($mode, $mod_name, $import_list) or print $_;
      next LINE;
    } elsif ( $Includes and /^\s*require\s+([^\$]+?)\s*?;/ ) {
      my $mod_name = $1;
      $module_info{'isa_AutoLoader'} = 1 if ($mod_name =~ /AutoLoader/);
      handle_include( 'require', $mod_name, '' ) or print $_;
      next LINE;
    } elsif ( $Includes and /^__END__/ ){
      next LINE if $module_info{'isa_AutoLoader'}; # parse unsplit source
      last LINE;
    } elsif ( $Includes and /^__DATA__/ ){
      if ( $module_info{'outermost_file'} ) {
	# blindly include everything up to end of file
	do { print $_; ++ $line_number; $_ = $fh->getline } while (defined $_); 
      } else {
	# we're going to loose anything they might have in the __DATA__ handle
	# warn "Unable to include __DATA__ contents.\n";
      }
      last LINE;
    }
    
    # Handle embedded POD 
    elsif ( /^=(pod|head[12])/i ){
      if ( $StripPods ) {
	do {++ $line_number; $_ = $fh->getline } 
	    while ( $_ !~ /^=cut/i ); # discard everything up to '=cut'
      } else {
	do { print $_; ++ $line_number; $_ = $fh->getline } 
	    while ( $_ !~ /^=cut/i ); # blindly include everything up to '=cut'
	print $_;
      }
      next LINE;
    }
    
    # Optionally exclude blank or whitespace-only lines
    elsif ( $StripBlankLines and /^\s*$/){
      next LINE;
    }
    
    # Optionally exclude lines that begin with the comment character
    elsif ( $StripComments and /^\s*\#/){
      print $_ if ( $line_number < 2 and /^\#\!/ ); # never discard shbang line
      next LINE;
    }
    
    # Support a minimal conditional inclusion mechanism with Perl test syntax
    elsif ( $Conditionals and /^\s*#__CONDITIONAL__\s?(.*)$/i ) {
      my $conditional = $1;
      if ( $conditional =~ s/^if //i ) {
	my $rc = eval "package main;\n$conditional";
	unless ( $rc and ! $@ ) {	    # if expr isn't true, skip to end
	  do { print "\n"; ++ $line_number; $_ = $fh->getline } 
	      while ( $_ !~ /^\s*\#__CONDITIONAL__ endif/i );
	}
      } elsif ( $conditional =~ /endif/i ){
	next LINE;			    # skip conditional end
      } else {
	print $conditional;		    # remove conditional null branches
	next LINE;
      }
    } 
    
    else {
      print $_;
    }
  }
}

# $handled_flag = handle_include( $mode, $mod_name, $import_list );
sub handle_include {
  my ( $mode, $mod_name, $import_list ) = @_;
  
  $import_list = '' unless defined $import_list;
  my $importer = $Importers{ $mode };
  # warn "    Include statement: $mode $mod_name ($import_list)\n";
  
  ## Special cases
  
  # Perl version requirements are not linked to a module file
  if ( $mod_name =~ /^[\.\_\d]+/ ) {
    return 0;	# include in output for check at exection time 
  }
  
  # Problems with scoping of use/no strict in single-file context
  # if ( $importer and $mod_name eq 'strict' ) {
  #   return 1;	# do not include in output
  # }
  
  # Manipulate library search path at preprocessor include time
  if ($mode eq 'use' and $mod_name eq 'lib') {
    my @paths = eval "$import_list";
    push @psuedo_INC, @paths unless $@;
    # return 1; # Perhaps we don't actually want this to happen at run-time?
  }
  
  ## Locate file to be included
  
  # Convert package name to partial file name
  my $mod_file = $mod_name;
  unless ( $mod_file =~ s/^(['"])(.*)\1\Z/$2/ ) {
    $mod_file =~ s#::#/#g;
    $mod_file .= '.pm';
  }
  
  my $mod_path;
  if ( $psuedo_INC{ $mod_file } ) {
    # If we've already included this file, all we need to do is the import.
    $mod_path = -1; 
  } else {
    $mod_path = $psuedo_INC{ $mod_file } = search_path( $mod_file );
    return unless $mod_path; # not found -- leave in output for later use
  }
  
  ## Generate output
  
  if ( $importer ) {
    # use and no statements should be executed as soon as they're parsed
    print "BEGIN { \n";
  }
  
  if ( $mod_path and $mod_path ne '-1' ) {
    warn "  Including $mod_path\n";
    
    print "### Start of inlined library $mod_name.\n" if $ShowFileBoundaries;
    
    print "\$INC{'$mod_file'} = '$mod_path';\n";
    print "{\n"; 
    print "  BEGIN { strict::unimport('strict') }\n" 
	if ( exists $psuedo_INC{'strict.pm'} and $mod_file ne 'strict.pm' );
    parse_file($mod_path);
    print "\n};\n";
    
    print "### End of inlined library $mod_name.\n" if $ShowFileBoundaries;
  }
  
  # Call import or unimport, but don't use the OOP notation for pragma modules
  if ( $importer ) {
    if ( $mod_name =~ /\A[a-z]+\Z/ ) {
      print $mod_name . '::' . $importer . "('$mod_name', $import_list);\n";
    } else {
      print $mod_name . '->' . $importer . "($import_list);\n";
    }
    
    # end BEGIN block
    print "}\n";
  }
  
  return 1;
}

# $mod_path = search_path($mod_file);
sub search_path {
  my $mod_file = shift;
  
  my $dir;
  foreach $dir (@psuedo_INC) {
    my $match = $dir . "/" . $mod_file;
    return $match if ( -e $match );
  }
  
  warn "Unable to find $mod_file\n";
  return;
}

1;

__END__

=head1 NAME

Devel::PreProcessor - Module inlining and other Perl source manipulations


=head1 SYNOPSIS

From a command line,

    sh> perl Devel/PreProcessor.pm -Flags sourcefile > targetfile

Or in a Perl script,

    use Devel::PreProcessor qw( Flags );

    select(OUTPUTFH);
    Devel::PreProcessor::parse_file( $source_pathname );


=head1 DESCRIPTION

This package processes Perl source files and outputs a modified version
acording to several user-setable option flags, as detailed below.

Each of the flag names listed below can be used as above, with a hyphen on
the command line, or as one of the arguments in an import statement. Each
of these flags are mapped to the scalar package variable of the same name.

=over 4

=item Includes

If true, parse_file will attempt to replace C<require>, C<use> and C<no>
statements with inline declarations containg the source of the relevant
library found in the current @INC. The resulting script should operate
identically and no longer be dependant on external libraries (but see
compatibility note below).

If the corresponding file can not be located, the statements are left
unchanged in the source; numeric perl version requirements are handled
the same way.

If a C<use libs ...> statement is encountered in the source, the library
path arguments are evaluated and pushed onto @INC at run-time to enable
inclusion of libraries from these paths.

Unless the file explicitly C<use>'s or C<require>'s AutoLoader,
information after C<__END__> is not included in the resultant
file. Information after C<__DATA__> is also discarded, except for the
first, outermost source file.

=item ShowFileBoundaries

If true, comment lines will be inserted delimiting the start and end of
each inlined file.

=item StripPods

If true, parse_file will not include POD from the source files. All
groups of lines resembling the following will be discarded:

    =(pod|head1|head2) 
    ...  
    =cut

=item StripBlankLines

If true, parse_file will skip lines that are empty, or that contain
only whitespace.

=item StripComments

If true, parse_file will not include full-line comments from the
source files. Only lines that start with a pound sign are discarded;
this behaviour might not match Perl's parsing rules in some cases,
such as multiline strings.

=item Conditionals

If true, parse_file will utilize a simple conditional inclusion scheme,
as follows.

    #__CONDITIONAL__ if expr
    ...		
    #__CONDITIONAL__ endif

The provided Perl expression is evaluated, and unless it is true,
everything up to the next endif declaration is replaced with empty
lines. In order to allow the default behavour to be provided when
running the raw files, comment out lines in non-default branches with
the following:

    #__CONDITIONAL__ ...

Empty lines are used  in place of skipped blocks to make line numbers
come out evenly, but conditional use or require statements will throw
the count off, as we don't pad by the size of the file that would have
been in-lined.

The conditional functionality can be combined with Perl's C<-s> switch,
which allows you to set flags on the command line, such as:

    perl -s Devel/PreProcessor.pm -Conditionals -Switch filter.test

You can use any name for your switch, and the matching scalar variable
will be set true; the following code will only be used if you supply
the argument as shown below.

    #__CONDITIONAL__ if $Switch
    #__CONDITIONAL__   print "you hit the switch!\n";
    #__CONDITIONAL__ endif

=back

=head1 EXAMPLES

To inline all used modules:

    perl -s Devel/PreProcessor.pm -Includes foo.pl > foo_complete.pl

To count the lines of Perl source in a file, run the preprocessor from
a shell with the following options

    perl -s Devel/PreProcessor.pm -StripComments -StripPods \
    -StripBlankLines foo.pl | wc -l


=head1 BUGS AND SUPPORT

=head2 Release Status

This is a maintenance release of Devel::PreProcessor. 

This module has been tested in several environments and no major
problems have been discovered, but those tests have been somewhat
limited and you are advised to try it in your environment to confirm
it works as expected.

=head2 Known Problems

=over 4

=item To Do: Improved Test Suite

The current test suite is quite limited, and only addresses the
Includes functionality. Additional tests that exercise the other
capabilities would be nice.

=item Compatibility: Includes

Libraries inlined with Includes may not be appropriate on another system;
for example, if Config is inlined, the script may fail if run on a platform
other than that on which it was built. This problem can be minimized
by adjusting the search path to not include modules in the version- or
architecture-specific library trees, but you will then need to ensure
that those modules are available on the execution platform.

=item Bug: Multi-line use statements not handled

Should support newline in import blocks for multiline use statements.

=item Limitation: Module __DATA__ contents lost

Few modules place anything other than POD in a __DATA__ section, much
less ever try to read from it, so this hasn't been a priority to fix.

=item Limitation: binary files not included

There's not much we can do about XSub/SO/PLL files.

=back

=head2 Support

If you have questions or feedback about this module, please feel
free to contact the author at the below address. Although there is
no formal support program, I do attempt to answer email promptly. 

Bug reports that contain a failing test case are greatly appreciated,
and suggested patches will be promptly considered for inclusion in
future releases.

To report bugs via the CPAN web tracking system, go to 
C<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-PreProcessor> or send mail 
to C<Dist=Devel-PreProcessor#rt.cpan.org>, replacing C<#> with C<@>.

=head2 Community

If you've found this module useful or have feedback about your
experience with it, consider sharing your opinion with other Perl
users by posting your comment to CPAN's ratings system:

=over 2

=item *

http://cpanratings.perl.org/rate/?distribution=Devel-PreProcessor

=back

For more general discussion, you may wish to post a message on PerlMonks or the comp.lang.perl.misc newsgroup:

=over 2

=item *

http://www.perlmonks.org/index.pl?node=Seekers%20of%20Perl%20Wisdom

=item *

http://groups.google.com/groups?group=comp.lang.perl.misc

=back


=head1 DISTRIBUTION AND INSTALLATION

=head2 Version

This is Devel::PreProcessor version 2003.1128.

This module's CPAN registration should read:

  Name            DSLIP  Description
  --------------  -----  ---------------------------------------------
  Devel::
  ::PreProcessor  rdpfp  Module inlining and other Perl source manipulations

=head2 Prerequisites

In general, this module should work with Perl 5.003 or later,
without requring any modules beyond the core Perl distribution.

=head2 Installation

You should be able to install this module using the CPAN shell interface:

  perl -MCPAN -e 'install Devel::PreProcessor'

Alternately, you may retrieve this package from CPAN or from the author's site:

=over 2

=item *

http://search.cpan.org/~evo/

=item *

http://www.cpan.org/modules/by-authors/id/E/EV/EVO

=item *

http://www.evoscript.org/Devel-PreProcessor/dist/

=back

After downloading the distribution, follow the normal procedure to unpack and install it, using the commands shown below or their local equivalents on your system:

  tar -xzf Devel-PreProcessor-*.tar.gz
  cd Devel-PreProcessor-*
  perl Makefile.PL
  make test && sudo make install

=head2 Tested Platforms

This release has been tested succesfully on the following platforms:

  5.6.1 on darwin

You may also review the current test results from CPAN-Testers:

=over 2

=item *

http://testers.cpan.org/show/Devel-PreProcessor.html

=back

=head1 CREDITS AND COPYRIGHT

=head2 Developed By

Developed by Matthew Simon Cavalletto at Evolution Softworks. 
You may contact the author directly at C<simonm@cavalletto.org>.
More free Perl software is available at C<www.evoscript.org>.

=head2 Contributors 

  Del Merritt
  Randy Roy, Win32 debugging assistance

=head2 Copyright

Copyright 2003 Matthew Cavalletto. 

Portions copyright 1998, 1999 Evolution Online Systems, Inc.

Derived from filter.pl, as provided by ActiveWare
E<lt>www.activestate.comE<gt>.

=head2 License

You may use, modify, and distribute this software under the same terms as Perl.

=cut  
