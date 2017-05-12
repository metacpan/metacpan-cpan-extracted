package Gimp::ScriptFu::Client;

our $VERSION = '1.01';

use strict;
use warnings;
use Cwd;
use IO::Socket;
use Getopt::Long;
use Text::Template;
use Filter::Simple;

FILTER {
    my $script = $_;
    $script =~ s/\r\n/\n/g if $^O =~ /win32/i;

    # defaults
    my $peer_host = "localhost";
    my $peer_port = 10008;         # Gimp default
    my $verbose   = 0;
    my $syntax    = 0;
    my $include   = '';

    Getopt::Long::Configure("bundling");
    GetOptions( "server|s=s" => \$peer_host,    # alternate server
                "port|p=i"   => \$peer_port,    #  and/or port
                "verbose|v"  => \$verbose,      # display Scheme before sending request
                "check|c"    => \$syntax,       # generate Scheme for syntax check and exit
                "include=s"  => \$include,      # return for inclusion in parent Scheme/Perl file
                                                #  for internal use
              );

    # preprocess Scheme code using Perl
    my $scheme = Text::Template::fill_in_string(
        $script,
        PACKAGE    => 'PERL_FRAGMENTS',
        BROKEN_ARG => $include || $0,
        BROKEN     => sub {
            my %args = @_;
            $args{error} =~ s/at template line/at $args{arg} line/;
            print STDERR "ERROR: Perl fragment: ", $args{error};
            exit 1;                     # instead of 'die' in case include is being eval'd
        }
    );
    if ($include) {
        unshift @ARGV, $scheme;
        return;
    }
    print $scheme if $verbose;
    my $length = length($scheme);
    die "ERROR: script is too long for one server request: $length > 65535\n" if $length > 65535;
    if ($syntax) {
        print STDERR "$0 syntax check done\n";
        exit 0;
    }

    # connect to the Gimp ScriptFu server
    my $gimp = IO::Socket::INET->new( Proto    => "tcp",
                                      PeerHost => $peer_host,
                                      PeerPort => $peer_port,
                                    ) or die "ERROR: can't connect to server at $peer_host:$peer_port\n";

    # request
    my $header = pack( 'an', 'G', $length );
    syswrite( $gimp, $_ ) for ( $header, $scheme );

    # wait for response
    my $rin = '';
    vec( $rin, fileno($gimp), 1 ) = 1;
    select( $rin,  undef, undef, undef );    # wait (forever) for response start
    select( undef, undef, undef, .1 );       # wait a bit for response to finish
                                             #  increase wait if INVALID/INCOMPLETE RESPONSE occurs

    # response
    $length = sysread( $gimp, $header, 4 ) or die "INVALID RESPONSE: empty response\n";
    ( $length == 4 and $header =~ /^G/ ) or die "INVALID RESPONSE: bad header\n";
    my $status;
    ( $status, $length ) = unpack( 'xCn', $header );
    my $response;
    ( sysread( $gimp, $response, $length ) == $length ) or die "INCOMPLETE RESPONSE: $response\n";

    # convert user generated "Success" message to no error status
    if ( $status and $response =~ /^Error: Success\n/i ) {
        $response =~ s/^Error: Success\n//i;
        $status = 0;
    }
    print $response;
    exit $status;

    package PERL_FRAGMENTS;

    # helper functions

    # make Scheme expression from a quoted Perl list
    sub sexp_from_list {
        "(" . join( " ", map { qq("$_") } @_ ) . ")";
    }

    # make set! expression for Scheme variable argv = Perl @ARGV
    sub set_argv {
        "(set! argv '" . sexp_from_list(@ARGV) . ")";
    }

    # expand a Perl list of filenames/patterns by globbing patterns
    #  and adding full pathnames. Dies on a non-existant filename.
    sub expand_files {
        my @pats = @_;
        @pats = map { /^[^"].* / ? "\"$_\"" : $_ } @pats
          if $^O =~ /win32/i;    # re-quote names w/spaces
        return map { $_ = Cwd::realpath($_); s|\\|/|g if $^O =~ /win32/i; $_ } glob "@pats";
    }

    # include another Scheme/Perl script into this one, processing any
    #  Perl first. @ARGV in the current script is preserved and arguments
    #  for the included script are placed in its @ARGV
    sub include_script {
        my @save_argv = @ARGV;
        my $file      = shift;
        @ARGV = ( '--include', $file, '--', @_ );
        do $file;
        my $included = shift @ARGV;
        @ARGV = @save_argv;
        return $included;
    }
}
__END__

=head1 NAME

Gimp::ScriptFu::Client - Client for the GNU Image Manipulation Program

=head1 SYNOPSIS

Makes a mixed Scheme and Perl script into a client application
for the Gimp Script-Fu server.

=head1 VERSION

Version 1.01, Feb 6, 2007

=head1 DESCRIPTION

Gimp::ScriptFu::Client acts as a source filter in a Scheme
script that uses Text::Template to preprocess any embedded
Perl fragments contained between { } brackets before sending
the resulting Scheme to a Gimp Script-Fu server. Each Perl
fragment may or may not produce a Scheme fragment.

The Scheme script becomes a standalone client application.

This permits using Perl for getting parameters from the real world or
for generating complex Scheme expressions, that would be more difficult or
impossible with plain Scheme.

It also makes it possible to do Perlish things with Gimp if you can't do the
compiler stuff for Gimp/Gimp::Fu for your OS. All recent Gimp versions include
the Script-Fu server.

=head2 Starting the Gimp server

Run Gimp with something like:

    gimp-x.x -b "(plug-in-script-fu-server 1 10008 \"\")"

or start Gimp and start the server from the menu Xtns/Script-Fu/Start Server.

=head2 Usage

Include this module at the beginning of the script:

    use Gimp::ScriptFu::Client;

Everything after that is Scheme or embedded Perl fragments.

Command line options for the Client are:

    --server   -s   # alternate server address
    --port     -p   # alternate server port
    --verbose  -v   # display Scheme before sending request
    --check    -c   # generate Scheme for syntax check and exit

Options C<-v> and C<-c> may be bundled as C<-vc> or C<-cv>.

The rest of the file after the C<use Gimp::ScriptFu::Client> line is
preprocessed by C<Text::Template> for embedded Perl - anything between curly
brackets. Perl variables persist from fragment to fragment in a file. The
resulting Scheme is displayed and/or sent to the Gimp Script-Fu server and the
result displayed.

The result may be 'Success', an Error message, or a user success message (see
the end of B<demo.pl> shown below).

=head2 Helper functions

The Client module provides several helper functions that can be used in Perl
fragments:

=over 4

=item sexp_from_list()

This function takes a Perl list as an argument and returns a string which is
a Scheme expression for that list.

=item set_argv()

This function takes no arguments and returns a string which is a Scheme
expression setting the Scheme variable I<argv> to the Perl array @ARGV.

=item expand_files()

This function takes a Perl list of filenames or file patterns and expands it to
a Perl list of filenames with full real pathnames. On a Win32 system , it will
convert backslashes to forward slashes for Gimp use. Gimp needs full paths
because the server is running in another directory. This function will
C<die> if a filename is not found.

=item include_script()

This function takes the name of another Scheme/Perl Client script plus any
arguments for that script. The arguments are passed to that script in @ARGV.
The Scheme output of the included script is returned by its Client code and
included in the parent script. The original @ARGV in the parent is preserved.
Includes may be nested.

The Client command line option C<--include> is used internally as the first
argument to the included script.

=back

=head2 Example command lines

Using the example Scheme/Perl script B<demo.pl>, shown below:

    demo *.jpg *.raw                        # quietly send Scheme to Gimp
    demo --verbose test.jpg                 # display Scheme and send to Gimp
    demo --check *.jpg *.bmp                # generate Scheme for error messages and quit
    demo -vc *.jpg                          # display Scheme and/or errors and quit
    demo -s 192.168.1.1 -p 10020 some.jpg   # use a different server
    demo                                    # demo uses file dialog to get file names

Client options are processed by Getopt::Long. To pass options to the script use --

    demo --verbose -- --ext=jpg --scale=.5 *jpg   # pass --ext and --scale thru to demo
                                                  #  --verbose eaten by Client

Included scripts have C<--> prepended to the argument list automatically, since the Client
options are only needed for the parent script.

Syntax errors will report line numbers for the template, not the file. The line after
C<use Gimp::ScriptFu::Client;> is line 1 of the template.

=head2 Example script 'demo.pl'

    #!perl -w
    use Gimp::ScriptFu::Client;
    {use Getopt::Long;
     $ext = 'png';
     $scale = .1;
     GetOptions( "ext=s"   => \$ext,   # thumbnail extension
                 "scale=f" => \$scale, # thumbnail scale
               );

     # This helper function expands all patterns,
     #  adds needed paths and converts Win32 backslashes
     @ARGV = expand_files( @ARGV );
     die "No files selected\n" if !@ARGV;

     # no Scheme output from this Perl fragment
     ''; }

    ; Server only executes one expression per request - use 'begin' wrapper
    (begin (let ( (argv '()) (argc 0) (outfiles '()) (scale 0) )
    ; Gimp >= 2.13.13 is TinyScheme, requires all variables defined before first use

    ; This helper function puts the
    ; contents of @ARGV into the
    ; Scheme variable, argv.
    {set_argv}
    (set! argc {scalar @ARGV})

    ; include another file here
    { include_script('included_script.pl', qw(--mode special a b c)) }
    ; original @ARGV is still = ({ "@ARGV" })

    ; This uses Perl's regexes to create
    ; filenames for the thumbnails.
    (set!
        outfiles '{
            sexp_from_list(
                map { s/\..*$/-thumbnail.$ext/; $_ } @ARGV)})

    ; configure your scaling factor
    (set! scale { $scale })

    ; This is a function for resizing an image
    (define (resize filename)
        (let*
        (
            (image     (car (gimp-file-load 1 filename filename)))
            (drawable  nil)
            (wd        (car (gimp-image-width image)))
            (hi        (car (gimp-image-height image)))
            (_wd       (* wd scale))
            (_hi       (* hi scale))
            (new-filename nil)
        )
        (gimp-image-scale image _wd _hi)
        (set! drawable      (car (gimp-image-flatten image)))
        (set! new-filename  (car outfiles))
        (set! outfiles      (cdr outfiles))
        (gimp-file-save 1 image drawable new-filename new-filename)
        (gimp-image-delete image)
        )
    )

    ; Finally, make a thumbnail out of every file in argv
    (while (car argv)
        (resize (car argv))
        (set! argv (cdr argv))
        )

    ; Use an error message to return a string. If Client receives an error message
    ; starting with "Success\n", that is stripped and the exit status is changed
    ; to zero (no error).
    ; Otherwise, no error returns the string "Success".
    (error  (string-append "Success\nThumbnails created: " (number->string argc)))
    ))

=head2 File 'included_script.pl' included in 'demo.pl'

    #!perl -w
    use Gimp::ScriptFu::Client;
    { use Getopt::Long; }
    ; stuff from 'included_script.pl' to test nested 'use' and @ARGV
    ; included @ARGV = ({ "@ARGV" })
    ; mode is { my $mode = 'normal'; GetOptions( "mode=s" => \$mode ); $mode }
    ; after GetOptions, @ARGV = ({ "@ARGV" })

=head1 AUTHOR

Alan Stewart <astewart1@cox.net>

=head1 BUGS?

Tested with Gimp 2.13.12 and Gimp 2.13.14, compiled with MinGW
on Win XP, Perl 5.8.8
Feb 20, 2007

=head1 COPYRIGHT

Copyright (c) 2007 Alan Stewart. All rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLDGEMENTS

Derived from an article and script by John Beppu <beppu@cpan.org> in
Linux Magazine Feb 15, 2002.

=head1 SEE ALSO

    Filter::Simple
    Text::Template

=cut
