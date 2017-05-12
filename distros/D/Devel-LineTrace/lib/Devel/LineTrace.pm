package Devel::LineTrace;

use strict;
use warnings;

require 5.006;

use vars (qw($VERSION));
$VERSION = '0.1.9';

package DB;


my (%files);
sub BEGIN
{
    my $filename = $ENV{'PERL5DB_LT'} || "perl-line-traces.txt";
    open my $in_fh, "<", $filename
        or return;
    my $line;
    $line = <$in_fh>;
    MAIN:
    while ($line)
    {
        chomp $line;
        if (($line =~ /^\s+/) || ($line =~ /^#/))
        {
            $line = <$in_fh>;
            next MAIN;
        }
        $line =~ /^(.+):(\d+)$/;
        my $filename = $1;
        my $line_num = $2;
        my $callback = "";
        CALLBACK:
        while ($line = <$in_fh>)
        {
            if ($line =~ /^\s/)
            {
                $callback .= $line;
            }
            else
            {
                last CALLBACK;
            }
        }
        $files{$filename}{$line_num} = $callback;
    }
    close ($in_fh);

    return;
}

use vars qw(@saved $package $filename $line $usercontext);

sub DB
{
    local @saved = ($@, $!, $^E, $,, $/, $\, $^W);
    local($package, $filename, $line) = caller;
    local $usercontext = '($@, $!, $^E, $,, $/, $\, $^W) = @saved;' .
      "package $package;";	# this won't let them modify, alas
    if (exists($files{$filename}{$line}))
    {
        eval $usercontext . " " . $files{$filename}{$line};
    }
}

1;

=head1 NAME

Devel::LineTrace - Apply traces to individual lines.

=head1 SYNPOSIS

    perl -d:LineTrace myscript.pl [args ...]

=head1 DESCRIPTION

This is a class that enables assigning Perl code callbacks to certain
lines in the original code B<without modifying it>.

To do so prepare a file with the following syntax:

    [source_filename]:[line]
        [CODE]
        [CODE]
        [CODE]
    [source_filename]:[line]
        [CODE]
        [CODE]
        [CODE]

Which will assign the [CODE] blocks to the filename and line combinations.
The [CODE] sections are indented from the main blocks. To temporarily cancel
a callback put a pound-sign (#) right at the start of the line (without
whitespace beforehand).

The location of the file should be specified by the PERL5DB_LT environment
variable (or else it defaults to C<perl-line-traces.txt>.)

Then invoke the perl interpreter like this:

    perl -d:LineTrace myprogram.pl

=head1 SEE ALSO

L<Devel::Trace>, L<Debug::Trace>

=head1 COPYRIGHT & LICENSE

Copyright 2011 by Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHORS

Shlomi Fish ( L<http://www.shlomifish.org/> ).

=cut
