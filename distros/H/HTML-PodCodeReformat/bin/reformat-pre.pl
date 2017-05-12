#!/usr/bin/perl

###########################################################################
# Copyright 2011 Emanuele Zeppieri                                        #
#                                                                         #
# This program is free software; you can redistribute it and/or modify it #
# under the terms of either: the GNU General Public License as published  #
# by the Free Software Foundation, or the Artistic License.               #
#                                                                         #
# See http://dev.perl.org/licenses/ for more information.                 #
###########################################################################

use strict;
use warnings;

use File::Copy;
use HTML::PodCodeReformat;

our $VERSION = $HTML::PodCodeReformat::VERSION;

use Getopt::Long;
Getopt::Long::Configure qw(
    auto_help auto_version bundling require_order gnu_compat
);
use Pod::Usage;

### Options ###

my $man;
my $help;

my $extension;
my $squash_blank_lines;
my $line_numbers;

GetOptions(
    'help|h|?' => \$help,
    'man'      => \$man,
    
    'squash-blank-lines|squash|s!' => \$squash_blank_lines,
    'line-numbers|l!'              => \$line_numbers,
    
    'backup|b:s'                   => \$extension
) or pod2usage(2);

pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;
pod2usage(2) if $help;

my $f = HTML::PodCodeReformat->new(
    squash_blank_lines => $squash_blank_lines,
    line_numbers       => $line_numbers
);

$| = 1;

if ( @ARGV ) {
    while ( my $in_filename = shift @ARGV ) {
        my $fixed_html;
        
        if ( $in_filename eq '-' ) {
            $fixed_html = $f->reformat_pre( \*STDIN );
            select STDOUT
        } else {
            $fixed_html = $f->reformat_pre( $in_filename );
            
            if ( defined $extension ) {
                if ( $extension ne '' ) {
                    my $backup_filename;
                    if ( $extension !~ /\*/ ) {
                        $backup_filename = $in_filename . $extension
                    } else {
                        ( $backup_filename = $extension ) =~ s/\*/$in_filename/g
                    }
                    move( $in_filename, $backup_filename ) or die
                    qq[Can't rename "$in_filename" to "$backup_filename": $!]
                }
                
                open my $output, '>', $in_filename
                    or die qq[Can't create file "$in_filename": $!];
                select $output
            }
        }
        
        print $fixed_html
    }
} else {
    print $f->reformat_pre( \*STDIN )
}

__END__

=head1 NAME

reformat-pre.pl - Command line utility to reformat <pre> blocks in HTML files rendered from pods

=head1 VERSION

version 0.20000

=head1 SYNOPSIS

    reformat-pre.pl [ OPTIONS ] [ FILE(S) ]
    reformat-pre.pl --man

=head1 DESCRIPTION

This program reformats the html file(s) rendered from pods, by removing the
extra leading spaces in the lines inside
C<< <pre>...</pre> >> blocks (corresponding to Pod I<verbatim paragraphs>).
Other transformations can be applied as well (see below).

The given files are read and modified one by one, and the resulting content is
printed to the standard output, unless the C<backup> option is used (see below).

If no file is given, or if one of the file names is a C<-> (dash), the HTML code
is read from STDIN, so that this program can be used as a I<filter> or even
interactively.

=head1 OPTIONS

=head2 -b [ I<extension> ] | --backup [ [=] I<extension> ]

If given, the files are modified I<in-place> (and no output is sent to the
standard output).

An I<extension> can optionally be provided, which will cause a backup copy
of every input file to be created.

The extension works exactly as with the perl C<-i> switch, that is:
if the extension does not contain a C<*>, then it is appended to the end of the
current filename as a suffix;
if the extension does contain one or more C<*> characters, then each C<*>
is replaced with the current filename.

If no extension is supplied, no backup is made and the current file is
overwritten.

=head2 -s | --squash-blank-lines

It causes every line composed solely of
spaces (C<\s>) in a C<pre> block, to be I<squashed> to an empty string
(the newline is left untouched).

Otherwise by default the I<blank lines> in a
C<pre> block will be treated as I<normal> lines, that is, they will be
stripped only of the extra leading whitespaces, as any other line.

=head2 -l | --line-numbers

It causes every line in a C<pre> text
to be wrapped in C<< <li>...</li> >> tags, and the whole text to be wrapped in
C<< <ol>...</ol> >> tags (so that a line number is prepended to every line in
the C<pre> text, when the HTML document is viewed in a browser).

In this case the original newlines in the C<pre> text are removed, to not add
extra empty lines when the HTML document is rendered.

=head2 -h | -? | --help

It prints a brief help message and exits.

=head2 --man

It shows the full man page.

=head2 --version

It prints the program version and exits.

=head1 COOKBOOK

=head2 Convert a pod through Pod::Simple and reformat it in one fell swoop

    perl -MPod::Simple::HTML -e Pod::Simple::HTML::go MyModule.pm | reformat-pre.pl > MyModule.pm.html

=head2 Reformat all the HTML files in a directory and make a backup of each of them

    reformat-pre.pl --backup=.orig /path/to/dir/*.html

=head1 SEE ALSO

=over 4

=item *

L<HTML::PodCodeReformat> (perldoc HTML::PodCodeReformat)

=item *

L<perlpodspec>

=item *

L<Pod::Simple>

=back

=head1 COPYRIGHT

Copyright 2011 I<Emanuele Zeppieri> E<lt>emazep@cpan.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 NO WARRANTY

This program comes with NO WARRANTIES of any kind. It not only may cause loss of
data and hardware damaging, but it may also cause several bad diseases to nearby
people, including, but not limited to, diarrhoea, gonorrhoea and dysmenorrhoea
(and anything else ending in I<rhoea>).
Don't say you haven't been warned.

=cut