#
# $Id$
#
# Copyright (c)1999 Alligator Descartes <descarte@arcana.co.uk>
#
# $Log$
#
package HTML::RefMunger;

use HTML::TokeParser;
use Getopt::Long;
require Exporter;
@ISA = Exporter;
@EXPORT = qw( refmunger );
use Cwd;
$VERSION = '0.01';

use Carp;

use strict;

=head1 NAME

HTML::RefMunger - module to mangle HREF links within HTML files

=head1 SYNOPSIS

    use HTML::RefMunger;
    refmunger( [options] );

=head1 DESCRIPTION

=head1 ARGUMENTS

HTML::RefMunger takes the following arguments:

=over 4

=item help

    --help

Displays the usage message.

=item infile

    --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item outdir

    --outdir=name

Specify the output directory to stash the munged HTML files in. Defaults
to ``.'' ( the current working directory )

=item outfile

    --convention=[UNIX,MSDOS,MacOS]

Specify the filename remapping convention to use. Current supported formats
are UNIX ( 14-character, such as Xenix ), MSDOS ( 8.3 format ) and MacOS
( 32 character ).

=item verbose

    --verbose

Display progress messages.

=back

=head1 EXAMPLE

    refmunger( "refmunger", "--infile=foo.html", 
               "--convention=MacOS" );

=head1 AUTHOR

Alligator Descartes E<lt>descarte@arcana.co.ukE<gt>

=head1 BUGS

=head1 LIMITATIONS

=over 4

=item *

Passing directories as the --infile current doesn't work. It I<should>
recursively translate everything in that directory downwards, but it
doesn't.

=item *

There should be some sort of funky file renaming thing that happens to
referenced links, I guess. At the moment, you also need to translate those
links I<via> C<HTML::RefMunger> to generate the correct name.

=back

=head1 SEE ALSO

L<refmunger>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

### The HTML file we're parsing
my $htmlfile = "index.html";

### The output directory to dump the converted files to
my $outdir = ".";

### The remapping convention to use
my $MSDOS = 1;
my $MACOS = 2;
my $UNIX = 3;
my $convention = $MACOS;

### Do we chatter a lot about progress?
my $verbose = 1;

### The filename lookup cache
my %cache = ();

### Should the cache be wiped?
my $wipeCache = 0;

### Global sequence for unique name generation
my $nameSequence = "0000";

### Workaround for a problem with HTML::Parser
my $fileEnded = 0;

### Usage message
my $USAGE = <<END_OF_USAGE;
Usage:  $0 --help --infile=<name> --convention=<convention> 
                --verbose --wipe-cache

  --help       - prints this message
  --infile     - filename for the HTML to convert ( input taken from stdin
                 by default )
  --outdir     - The output directory that munged files are written to
  --convention - convention for converting filenames and HREFs. Valid options
                 are MacOS ( default ), UNIX and MSDOS.
  --wipe-cache - Wipes clean any caches prior to conversion
  --verbose    - self-explanatory

END_OF_USAGE

###
# refmunger(): Handles the actual file munging
#
sub refmunger {
    my ( @ARGV ) = @_;

    ### Process the command-line options
    &parse_command_line();

    ### Process the cache, if it exists
    &readCache( "." );

    ### Test to see if the input file is a directory or a file
    if ( -d $htmlfile ) {
        warn "Input file is a directory!\n" if $verbose;
        ### Recurse through the directory and sub-directories and convert each file
      } else {
        warn "Input file is a file!\n" if $verbose;
        ### Convert the given file
        my $parser = new HTML::TokeParser( $htmlfile );
        $parser->parse_file( $htmlfile );

        ### Open the output file
        my $newFileName = &calculateLink( $htmlfile );
        open OUTFILE, ">$outdir/$newFileName";

        ### Enter the main tag parse loop
        while ( ( my $token = $parser->get_token() ) && ( !$fileEnded ) ) {
            warn "Token: $token->[0]\n" if $verbose;
            SWITCH: {
                if ( $token->[0] eq "S" ) {
                    warn "\tTag: $token->[1]\n" if $verbose;
                    print OUTFILE "<$token->[1] ";
                    foreach my $attr ( keys %{ $token->[2] } ) {
                        warn "\t\tTag Attribute: $attr\t$token->[2]{$attr}\n" if $verbose;
                        if ( $attr eq "href" || $attr eq "img" ) {
                            ### Test to see whether this is, or isn't, a
                            ### mungeable filename
                            if ( $token->[2]{$attr} !~ /^#/ &&
                                 $token->[2]{$attr} !~ /^http:/ &&
                                 $token->[2]{$attr} !~ /^ftp:/ &&
                                 $token->[2]{$attr} !~ /^mailto:/ &&
                                 $token->[2]{$attr} !~ /^gopher:/ &&
                                 $token->[2]{$attr} !~ /^news:/ ) {
                                warn "\t\tLocal document found!\n" if $verbose;
                                ### Split the link name up
                                my $cacheFile = &calculateLink( $token->[2]{$attr} );
                                print OUTFILE $attr . "=" . "\"$cacheFile\"";
                              } else {
                                print OUTFILE "$attr=\"$token->[2]{$attr}\" ";
                              }
                          } else {
                            print OUTFILE "$attr=\"$token->[2]{$attr}\" ";
                          }
                      }
                    print OUTFILE ">";
                    last SWITCH;
                  }
                if ( $token->[0] eq "E" ) {
                    warn "\tTag End: $token->[1]\n" if $verbose;
                    print OUTFILE "</$token->[1]>";
                    ### Assume the file has ended with the </HTML> tag
                    if ( $token->[1] eq "html" ) {
                        $fileEnded = 1;
                      }
                    last SWITCH;
                  }
                if ( $token->[0] eq "T" ) {
                    warn "\tText: $token->[1]\n" if $verbose;
                    print OUTFILE "$token->[1]";
                    last SWITCH;
                  }
                if ( $token->[0] eq "C" ) {
                    warn "\tComment: $token->[1]\n" if $verbose;
                    print OUTFILE "<!-- $token->[1] -->";
                    last SWITCH;
                  }
                if ( $token->[0] eq "D" ) {
                    warn "\tDeclaration: $token->[1]" if $verbose;
                    print OUTFILE "$token->[1]";
                    last SWITCH;
                  }
              }
          }
        close OUTFILE;
      }

    ### Write out the cache
    &writeCache( "." );

    warn "Exiting HTML::RefMunger\n" if $verbose;
  }

###
# readCache(): Reads the cached filename conversions
#
sub readCache {
    my ( $directory ) = @_;

    ### Check to see if a cache exists in the given directory
    my $id = open CACHE, "$directory/.mungcach";
    if ( !defined $id ) {
        %cache = ();
      } else {
        if ( $wipeCache ) {
            ### Clear the memory cache...
            %cache = ();
            close CACHE;
            ### ...and wipe the file...
            unlink "$directory/.mungcach";
          } else {
            ### Read the cache in...
            while ( <CACHE> ) {
                my ( $origlink, $newlink ) = split( '\t', $_ );
                $newlink =~ s/(\n|\r)//g;
                $cache{$origlink} = $newlink;
              }
            close CACHE;

            ### Dump the cache for sanity's sake
            if ( $verbose ) {
                foreach my $key ( keys %cache ) {
                    print "Cache Key *$key* -> *$cache{$key}*\n";
                  }
              }
          }
      }
  }

###
# writeCache(): Writes out the cached filename conversions
#
sub writeCache {
    my ( $directory ) = @_;

    my $id = open CACHE, ">$directory/.mungcach";
    if ( !defined $id ) {
        die "Cannot open cache $directory/.mungcach for writing: $!\n";
      } else {
        ### Write the cache entries out to file
        foreach my $centry ( keys %cache ) {
            print CACHE "$centry\t$cache{$centry}\n";
          }

        ### Close the output file
        close CACHE;
      }
  }

###
# calculateLink(): Calculates the link name
#
sub calculateLink {
    my ( $link ) = @_;

    ### Return value
    my $rv = $link;

    ### Split the link name up
    my $suffix = $link;
    my $prefix = $link;
    my $sublink = $link;
    $sublink =~ /(.*)(\#.*)$/;
    $sublink = $2;
    $suffix =~ s/(\#.*)$//g;
    $suffix =~ /(.*)\.(\w+)$/g;
    $prefix = $1;
    $suffix = $2;
    warn "\t\t\tOriginal Link: $link\n" if $verbose;
    warn "\t\t\tPrefix: $prefix\tSuffix: $suffix\tSublink: $sublink\n" if $verbose;
    my $cacheLink = $prefix . "." . $suffix;
    ### Check to see whether or not this
    ### document needs mangling according to
    ### the file naming convention
    SWITCH: {
        if ( $convention eq $MSDOS ) {
            if ( length( $link ) >= 12 ) {
                warn "\t\t\t$link needs formatting for MS-DOS\n" if $verbose;
                ### Truncate the suffix to 3 characters
                $suffix = substr( $suffix, 0, 3 );
                $rv = &getLinkFromCache( 11, $cacheLink, $prefix, $suffix );
              }
            last SWITCH;
          }
        if ( $convention eq $MACOS ) {
            if ( length( $link ) >= 32 ) {
                warn "\t\t\t$link needs formatting for MacOS\n" if $verbose;
                $rv = &getLinkFromCache( 32, $cacheLink, $prefix, $suffix );
              }
            last SWITCH;
          }
        if ( $convention eq $UNIX ) {
            if ( length( $link ) >= 14 ) {
                warn "\t\t\t$link needs formatting for UNIX\n" if $verbose;
                $rv = &getLinkFromCache( 14, $cacheLink, $prefix, $suffix );
              }
            last SWITCH;
          }
      }
    return $rv;
  }

###
# getLinkFromCache(): Retrieves an existing link or generates a new one
#                     from the cache
#
sub getLinkFromCache {

    my ( $limit, $cacheLink, $prefix, $suffix ) = @_;
    my $rv = "";

    if ( exists $cache{$cacheLink} ) {
        warn "\t\t\tLocated $cacheLink in cache as " . $cache{$cacheLink} . "!\n" if $verbose;
        print OUTFILE "href=\"" . $cache{$cacheLink} . "\" ";
        $rv = $cache{$cacheLink};
      } else {
        warn "\t\t\tFailed to locate $cacheLink in cache!\n" if $verbose;
        ### Truncate the prefix
        my $ok = 0;
        while ( !$ok ) {
            my @prefix = split( / */, $prefix );
            my $tmpfile = 
                join( '', 
                      @prefix[0 .. ( $limit - ( length( $suffix ) + 1 + 4 ) )] ) . $nameSequence++ . "." . $suffix;
            warn "\t\t\tFile: $tmpfile\n" if $verbose;
            my $found = 0;
            foreach my $elem ( values %cache ) {
                if ( $elem eq $tmpfile ) {
                    $found = 1;
                  }
              }
            if ( !$found ) {
                $cache{$cacheLink} = $tmpfile;
                warn "\t\t\tAdded $cacheLink to cache!\n" if $verbose;
                $rv = $tmpfile;
                $ok = 1;
              } else {
                warn "\t\t\t$cacheLink already in cache!\n" if $verbose;
                $ok = 0;
              }
          }
      }
    return $rv;
  }

###
# usage(): Prints out a usage message if the program has been wrongly invoked
#
sub usage {
    my $htmlf = shift;
    warn "$0: $htmlf: @_\n" if @_;
    die $USAGE;
}

###
# parse_command_line(): Parses the command line options
#
sub parse_command_line {
    my ( $opt_help, $opt_infile, $opt_outdir, $opt_convention, 
         $opt_verbose, $opt_wipecache );
    my $result = GetOptions(
                'help'       => \$opt_help,
                'infile=s'   => \$opt_infile,
                'outdir=s'   => \$opt_outdir,
                'convention=s'  => \$opt_convention,
                'verbose'    => \$opt_verbose,
                'wipe-cache' => \$opt_wipecache,
               );
    usage("-", "invalid parameters") if not $result;

    usage("-") if defined $opt_help;    # see if the user asked for help
    $opt_help = "";                     # just to make -w shut-up.

    ### Name of the HTML file or directory of HTML files to process
    $htmlfile  = $opt_infile if defined $opt_infile;
    $outdir = $opt_outdir if defined $opt_outdir;

    ### Process the file naming convention
    $convention = $opt_convention if defined $opt_convention;
    if ( defined $opt_convention ) {
        if ( ( $opt_convention !~ /UNIX/ ) && ( $opt_convention !~ /MacOS/ ) && 
             ( $opt_convention !~ /MSDOS/ ) ) {
            &usage( "-", "invalid --convention option" );
          }
      }
    SWITCH: {
        if ( $convention =~ /UNIX/ ) {
            $convention = $UNIX;
            last SWITCH;
          }
        if ( $convention =~ /MacOS/ ) {
            $convention = $MACOS;
            last SWITCH;
          }
        if ( $convention =~ /MSDOS/ ) {
            $convention = $MSDOS;
            last SWITCH;
          }
      }

    ### Wipe the cache?
    $wipeCache = $opt_wipecache if defined $opt_wipecache;

    $verbose  = defined $opt_verbose ? 1 : 0;
  }

1;
