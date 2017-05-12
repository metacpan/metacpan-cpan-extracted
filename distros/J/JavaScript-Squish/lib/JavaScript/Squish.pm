
package JavaScript::Squish;

=head1 NAME

JavaScript::Squish - Reduce/Compact JavaScript code to as few characters as possible.

=head1 SYNOPSIS

use JavaScript::Squish;
 my $compacted = JavaScript::Squish->squish(
                     $javascript,
                     remove_comments_exceptions => qr/copyright/i )
                     or die $JavaScript::Squish::err_msg;

# OR, to just do a few steps #

 my $c = JavaScript::Squish->new();
 $c->data( $javascript );
 $c->extract_strings_and_comments();
 $c->replace_white_space();
 my $new = $c->data();

=head1 DESCRIPTION

This module provides methods to compact javascript source down to just what is needed. It can remove all comments, put everything on one line (semi-)safely, and remove extra whitespace.

Any one of the various compacting techniques can be applied individually, or with in any group.

It also provides a means by which to extract all text literals or comments in separate arrays in the order they appear.

Since JavaScript eats up bandwidth, this can be very helpful, and you can then be free to properly comment your JavaScript without fear of burning up too much bandwidth.

=head2 EXPORT

None by default.

"squish" may be exported via "use JavaScript::Squish qw(squish);"

=head1 METHODS

=head2 B<JavaScript::Squish-E<gt>squish($js [, %options] )>

Class method. This is a wrapper around all methods in here, to allow you to do all compacting operations in one call.

     my $squished = JavaScript::Squish->squish( $javascript );

Current supported options:

=over

=item remove_comments_exceptions : array ref of regexp's

 B<JavaScript::Squish-E<gt>squish($js, remove_comments_exceptions =E<gt> [ qr/copyright/i ] )>

Any comment strings matching any of the supplied regexp's will not be removed. This is the recommended way to retain copyright notices, while still compacting out all other comments.

=back

=head2 B<JavaScript::Squish-E<gt>new()>

Constructor. Currently takes no options. Returns JavaScript::Squish object.

NOTE: if you want to specify a "remove_comments_exceptions" option via one of these object, you must do so directly against the C<remove_comments()> method (SEE BELOW).

=head2 B<$djc-E<gt>data($js)>

If the option C<$js> is passed in, this sets the javascript that will be worked on.

If not passed in, this returns the javascript in whatever state it happens to be in (so you can step through, and pull the data out at any time).

=head2 B<$djc-E<gt>strings()>

Returns all strings extracted by either C<extract_literal_strings()> or C<extract_strings_and_comments()> (NOTE: be sure to call one of the aforementioned extract methods prior to C<strings()>, or you won't get anything back).

=head2 B<$djc-E<gt>comments()>

Returns all comments extracted by either C<extract_comments()> or C<extract_strings_and_comments()> (NOTE: be sure to call one of the aforementioned extract methods prior to C<strings()>, or you won't get anything back).

=head2 B<$djc-E<gt>determine_line_ending()>

Method to automatically determine the line ending character in the source data.

=head2 B<$djc-E<gt>eol_char("\n")>

Method to set/override the line ending character which will be used to parse/join lines. Set to "\r\n" if you are working on a DOS / Windows formatted file.

=head2 B<$djc-E<gt>extract_strings_and_comments()>

Finds all string literals (eg. things in quotes) and comments (// or /*...*/) and replaces them with tokens of the form "\0\0N\0\0"  and "\0\0_N_\0\0" respectively, where N is the occurrance number in the file, and \0 is the null byte. The strings are stored inside the object so they may be resotred later.

After calling this, you may retrieve a list of all extracted strings or comments using the C<strings()> or C<comments()> methods.

=head2 B<$djc-E<gt>extract_literal_strings()>

This is a wrapper around C<extract_strings_and_comments()>, which will restore all comments afterwards (if they had not been stripped prior to its call).

NOTE: sets C<$djc-E<gt>strings()>

=head2 B<$djc-E<gt>extract_comments()>

This is a wrapper around C<extract_strings_and_comments()>, which will restore all literal strings afterwards (if they had not been stripped prior to its call).

NOTE: sets C<$djc-E<gt>comments()>

=head2 B<$djc-E<gt>replace_white_space()>

Per each line:

=over

=item * Removes all begining of line whitespace.

=item * Removes all end of line whitespace.

=item * Combined all series of whitespace into one space character (eg. s/\s+/ /g)

=back

Comments and string literals (if still embeded) are untouched.

=head2 B<$djc-E<gt>remove_blank_lines()>

...does what it says.

Comments and string literals (if still embeded) are untouched.

=head2 B<$djc-E<gt>combine_concats()>

Removes any string literal concatenations. Eg.

    "bob and " +   "sam " + someVar;

Becomes:

    "bob and sam " + someVar

Comments (if still embeded) are untouched.

=head2 B<$djc-E<gt>join_all()>

Puts everything on one line.

Coments begining with "//", if still embeded, are the exception, as they require a new line character at the end of the comment.

=head2 B<$djc-E<gt>replace_extra_whitespace()>

This removes any excess whitespace. Eg.

    if (someVar = "foo") {

Becomes:

    if(someVar="foo"){

Comments and string literals (if still embeded) are untouched.

=head2 B<$djc-E<gt>remove_comments(%options)>

Current supported options:

=over

=item exceptions : array ref of regexp's

 B<$djc-E<gt>remove_comments( exceptions =E<gt> [ qr/copyright/i ] )>

Any comment strings matching any of the supplied regexp's will not be removed. This is the recommended way to retain copyright notices, while still compacting out all other comments.

=back

NOTE: this is destructive (ie. you cannot restore comments after this has been called).

=head2 B<$djc-E<gt>restore_comments()>

All comments that were extracted with C<$djc-E<gt>extract_strings_and_comments()> or C<$djc-E<gt>extract_comments()> are restored. Comments retain all spacing and extra lines and such.

=head2 B<$djc-E<gt>restore_literal_strings()>

All string literals that were extracted with C<$djc-E<gt>extract_strings_and_comments()> or C<$djc-E<gt>extract_comments()> are restored. String literals retain all spacing and extra lines and such.

=head2 B<$djc-E<gt>replace_final_eol()>

Prior to this being called, the end of line may not terminated with a new line character (especially after some of the steps above). This assures the data ends in at least one of whatever is set in C<$djc-E<gt>eol_char()>.

=head1 NOTES

The following should only cause an issue in rare and odd situations... If the input file is in dos format (line termination with "\r\n" (ie. CR LF / Carriage return Line feed)), we'll attempt to make the output the same. If you have a mixture of embeded "\r\n" and "\n" characters (not escaped, those are still safe) then this script may get confused and make them all conform to whatever is first seen in the file.

The line-feed stripping isn't as thorough as it could be. It matches the behavior of JSMIN, and goes one step better with replace_extra_whitespace(), but I'm certain there are edge cases that could be optimised further. This shouldn't cause a noticable increase in size though.

=head1 TODO

Function and variable renaming, and other more dangerous compating techniques.

Currently, JavaScript::Squish::err_msg never gets set, as we die on any real errors. We should look into returning proper error codes and setting this if needed.

Fix Bugs :-)

=head1 BUGS

There are a few bugs, which may rear their head in some minor situations.

=over

=item Statements not terminated by semi-colon.

These should be ok now - leaving a note here because this hasn't been thoroughly tested (I don't have any javascript to test with that meets this criteria).

This would affect statements like the following:

    i = 5.4
    j = 42

This used to become "i=5.4 j=42", and would generate an error along the lines of "expected ';' before statement".

The linebreak should be retained now. Please let me know if you see otherwise.

=item Ambiguous operator precidence

Operator precidence may get screwed up in ambiguous statements. Eg. "x = y + ++b;" will be compacted into "x=y+++b;", which means something different.

=back

Still looking for them. If you find some, let us know.

=head1 SEE ALSO

=over

=item Latest releases, bugzilla, cvs repository, etc:

https://developer.berlios.de/projects/jscompactor/

=item Simlar projects:

    http://crockford.com/javascript/jsmin
    http://search.cpan.org/%7Epmichaux/JavaScript-Minifier/lib/JavaScript/Minifier.pm
    http://dojotoolkit.org/docs/shrinksafe
    http://dean.edwards.name/packer/

=back

=head1 AUTHOR

Joshua I. Miller <jmiller@puriifeddata.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by CallTech Communications, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.00503;
use strict;
use Carp qw(croak carp);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw( squish ) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( );

$VERSION = '0.07';

sub squish
{
    my $this = shift;

    # squish() can be used as a class method or instance method
    unless (ref $this)
    {
        $this = $this->new();
    }

    {
        my $data = (ref($_[0]) eq 'SCALAR') ? ${(shift)} : shift;
        $this->data($data);
    }
    my %opts = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

    # determine line ending
    print STDERR "Determining line ending format (LF || CRLF)...\n" if $opts{DEBUG};
    $this->determine_line_ending();

    # extract literal strings and comments
    print STDERR "Replacing literal strings and comments...\n" if $opts{DEBUG};
    $this->extract_strings_and_comments();

    # remove comments
    print STDERR "Removing comments...\n" if $opts{DEBUG};
    my %rc_opts = ();
    $rc_opts{exceptions} = $opts{remove_comments_exceptions} if $opts{remove_comments_exceptions};
    $this->remove_comments(%rc_opts);

    # replace white space
    print STDERR "Replacing white space...\n" if $opts{DEBUG};
    $this->replace_white_space();

    # remove blank lines
    print STDERR "Removing blank lines...\n" if $opts{DEBUG};
    $this->remove_blank_lines();

    # combine literal string concatenators
    print STDERR "Combining literal string concatenators...\n" if $opts{DEBUG};
    $this->combine_concats();

    # join all lines
    print STDERR "Joining all lines...\n" if $opts{DEBUG};
    $this->join_all();

    # replace extra extra whitespace
    print STDERR "Replacing extra extra whitespace...\n" if $opts{DEBUG};
    $this->replace_extra_whitespace();

    # restore literals
    print STDERR "Restoring all literal strings...\n" if $opts{DEBUG};
    $this->restore_literal_strings();

    # replace final EOL
    print STDERR "Replace final EOL...\n" if $opts{DEBUG};
    $this->replace_final_eol();

    return $this->data;
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $this = {
        data    => '',
        strings => [ ],
        comments => [ ],
        eol     => "\n",
        _strings_extracted  => 0, # status var
        _comments_extracted  => 0, # status var
        };
    bless $this, $class;

    return $this;
}

sub data
{
    my $this = shift;
    if ($_[0]) {
        my $data = (ref($_[0]) eq 'SCALAR') ? ${$_[0]} : $_[0];
        $this->{data} = $_[0];
    } else {
        return $this->{data};
    }
}

sub strings
{
    my $this = shift;
    if ($_[0]) {
        $this->{strings} = $_[0];
    } else {
        return $this->{strings};
    }
}

sub comments
{
    my $this = shift;
    if ($_[0]) {
        $this->{comments} = $_[0];
    } else {
        return $this->{comments};
    }
}

sub eol_char
{
    my $this = shift;
    if ($_[0]) {
        $this->{eol} = $_[0];
    } else {
        return $this->{eol};
    }
}

sub determine_line_ending
{
    my $this = shift;

    # Where is the first LF character?
    my $lf_position = index($this->data, "\n");
    if ($lf_position == -1)
    {   # not found, set to default, cause it won't (shouldn't) matter
        $this->eol_char("\n");
    } else {
        if ($lf_position == 0)
        {   # found at first char, so there is no prior character to observe
            $this->eol_char("\n");
        } else {
            # Is the character immediately before it a CR?
            my $test_cr = substr($this->data, ($lf_position -1),1);
            if ($test_cr eq "\r")
            {
                $this->eol_char("\r\n");
            } else {
                $this->eol_char("\n");
            }
        }
    }
}

# extract_literal_strings() - wrapper around extract_strings_and_comments
sub extract_literal_strings
{
    my $this = shift;

    # don't do it twice...
    return if $this->{_strings_extracted};

    # save state of comments
    my $comment_state = $this->{_comments_extracted};

    $this->extract_strings_and_comments();
    # only restore comments if they weren't extraced when we started
    $this->restore_comments() unless $comment_state;
}

# extract_comments() - wrapper around extract_strings_and_comments
sub extract_comments
{
    my $this = shift;

    # don't do it twice...
    return if $this->{_comments_extracted};

    # save state of strings
    my $string_state = $this->{_strings_extracted};

    $this->extract_strings_and_comments();
    # only restore strings if they weren't extraced when we started
    $this->restore_literal_strings() unless $string_state;
}

sub extract_strings_and_comments
{
    my $this = shift;

    # SAFETY CHECKS
    # Can't extract strings twice, as the keep the
    # quotes in the original when we extract them
    if ($this->{_strings_extracted}) {
        $this->restore_literal_strings();
    }
    # Restore comments, so that we still get them
    # in the cache (this could be optimized out)
    # NOTE: if they had called remove_comments(), then we'll
    #       officially lose all our history of comments here.
    if ($this->{_comments_extracted}) {
        $this->restore_comments();
    }

    # reset the instance variables caching strings and comments:
    $this->strings([]);
    $this->comments([]);
    # where we'll store the literals
    my $strings = $this->strings();
    # where we'll store the comments
    my $comments = $this->comments();

    my ($escaped, $quoteChar, $inQuote);

    my $lastnws = ''; # last non-whitespace character
    my $literal = ""; # literal strings we're building
    my $t = "";       # replacement text

    my @lines = split(/\r?\n/, $this->data); # dos or unix... output is unix
    # step through each line
    LINE: for (my $i=0; $i<@lines; $i++)
    {
        # step through each character
        LINE_CHAR: for (my $j=0; $j<length($lines[$i]); $j++)
        {
            my $c  = substr($lines[$i],$j,1);
            my $c2 = substr($lines[$i],$j,2);
            # look for start of string (if not in one)
            if (! $inQuote)
            {
                # double-slash comments
                if ($c2 eq "//") {
                    my $comment = substr($lines[$i],$j);
                    my $key_num = scalar(@{$comments});
                    $t .= "\0\0".'_'.$key_num.'_'."\0\0";
                    $t .= $this->eol_char();
                    push(@{$comments}, $comment);
                    next LINE;

                # slash-star comments
                } elsif ($c2 eq "/*") {
                    my $comment = "/*";
                    my $comstart = $j+2;
                    my $found_end = 0;
                    COMM_SEARCH1: for (my $k=($j+2); $k<length($lines[$i]); $k++)
                    {
                        my $end = substr($lines[$i],$k,2);
                        if ($end eq "*/") {
                            $comment .= substr($lines[$i],$comstart,($k+2 - $comstart));
                            $j = $k+1;
                            $found_end = 1;
                            #next LINE_CHAR;
                            last COMM_SEARCH1;
                        }
                    }

                    if (! $found_end)
                    {
                        $comment .= substr($lines[$i],$comstart).$this->eol_char();
                        COMM_SEARCH2: for (my $l=($i+1); $l<@lines; $l++)
                        {
                            for (my $k=0; $k<length($lines[$l]); $k++)
                            {
                                my $end = substr($lines[$l],$k,2);
                                if ($end eq "*/") {
                                    $comment .= substr($lines[$l],0,$k+2);
                                    $i = $l;
                                    $j = $k+1;
                                    $found_end = 1;
                                    #next LINE_CHAR;
                                    last COMM_SEARCH2;
                                }
                            }
                            $comment .= $lines[$l].$this->eol_char();
                        }
                    }
                    if (! $found_end)
                    {
                        die "Unterminated /* */ style comment found around line[$i]\n";
                    } else {
                        my $key_num = scalar(@{$comments});
                        $t .= "\0\0".'_'.$key_num.'_'."\0\0";
                        #$t .= $this->eol_char();
                        push(@{$comments}, $comment);
                        next LINE_CHAR;
                    }

                # standard quoted strings, and bare regex's
                # "/" is considered division if it's preceeded by: )._$\ or alphanum
                } elsif ( $c eq '"' || $c eq "'" ||
                          ($c eq '/' && $lastnws !~ /[\)\.a-zA-Z0-9_\$\\]/) ) {
                    $inQuote = 1;
                    $escaped = 0;
                    $quoteChar = $c;
                    $t .= $c;
                    $literal = '';
                    $lastnws = $c unless $c =~ /\s/;

                # standard code
                } else {
                    $t .= $c;
                    $lastnws = $c unless $c =~ /\s/;
                }

            # else we're in a quote
            } else {
                if ($c eq $quoteChar && !$escaped)
                {
                    $inQuote = 0;
                    my $key_num = scalar(@{$strings});
                    $t .= "\0\0".$key_num."\0\0";
                    $t .= $c;
                    push(@{$strings}, $literal);
                    $lastnws = $c unless $c =~ /\s/;

                } elsif ($c eq "\\" && !$escaped) {
                    $escaped = 1;
                    $literal .= $c;
                    $lastnws = $c unless $c =~ /\s/;
                } else {
                    $escaped = 0;
                    $literal .= $c;
                    $lastnws = $c unless $c =~ /\s/;
                }
            }
        }
        if ($inQuote) {
            $literal .= $this->eol_char();
        } else {
            $t .= $this->eol_char();
        }
    }

    $this->{_comments_extracted} = 1;
    $this->{_strings_extracted} = 1;
    $this->comments($comments);
    $this->strings($strings);
    $this->data($t);
}

sub replace_white_space
{
    my $this = shift;

    # can't do this if literal strings are still in the thing.
    my $string_state = $this->{_strings_extracted};
    my $comment_state = $this->{_comments_extracted};
    unless ($this->{_strings_extracted} && $this->{_comments_extracted}) {
        $this->extract_strings_and_comments();
    }

    my @lines = split(/\r?\n/, $this->data);

    # condense white space
    foreach (@lines)
    {
        s/\s+/\ /g;
        s/^\s//;
        s/\s$//;
    }

    $this->data( join($this->eol_char(), @lines) );

    # restore strings/comments if needed
    unless ($string_state) {
        $this->restore_literal_strings();
    }
    unless ($comment_state) {
        $this->restore_comments();
    }
}

sub remove_blank_lines
{
    my $this = shift;

    # can't do this if literal strings are still in the thing.
    my $string_state = $this->{_strings_extracted};
    my $comment_state = $this->{_comments_extracted};
    unless ($this->{_strings_extracted} && $this->{_comments_extracted}) {
        $this->extract_strings_and_comments();
    }

    my @lines = split(/\r?\n/, $this->data);
    my @new_lines = ();
    foreach (@lines)
    {
        next if /^\s*$/;
        push(@new_lines,$_);

    }

    $this->data( join($this->eol_char(), @new_lines) );

    # restore strings/comments if needed
    unless ($string_state) {
        $this->restore_literal_strings();
    }
    unless ($comment_state) {
        $this->restore_comments();
    }
}

sub combine_concats
{
    my $this = shift;

    # can't do this if literal strings are still in the thing.
    my $string_state = $this->{_strings_extracted};
    my $comment_state = $this->{_comments_extracted};
    unless ($this->{_strings_extracted} && $this->{_comments_extracted}) {
        $this->extract_strings_and_comments();
    }

    my $data = $this->data;
    # TODO: currently, we only concat two literals if 
    #       they both use the same quote style. Eg.
    #           this: "foo " + "bar" == "foo bar"
    #           not : "foo " + 'bar' == "foo "+'bar'
    # this just makes things easier to do w/ a regexp, but we should be
    # able to do the second form as well (can't w/out lookahead and
    # lookbehind searches).
    $data =~ s/(['"])\s?\+\s?\1//g;
    $this->data($data);

    # restore strings/comments if needed
    unless ($string_state) {
        $this->restore_literal_strings();
    }
    unless ($comment_state) {
        $this->restore_comments();
    }
}

sub join_all
{
    my $this = shift;

    # we can't join lines that contain "//" comments
    # and we can't process unless strings are not there

    my $string_state = $this->{_strings_extracted};
    my $comment_state = $this->{_comments_extracted};
    unless ($this->{_strings_extracted} && $this->{_comments_extracted}) {
        $this->extract_strings_and_comments();
    }

    my $last_eol;
    my $newdata;
    foreach my $line (split(/\r?\n/, $this->data))
    {
        # if we have a linebreak between these charsets (not counting spaces/other-newlines)
        # we retain it so we don't break any code.
        my ($first_char) = ($line =~ /^\s*(\S)/);
        if (defined($last_eol) &&
                ($last_eol =~ /[a-zA-Z0-9\\\$_}\])+\-"']/ || ord($last_eol) > 126) &&
                ($first_char =~ /[a-zA-Z0-9\\\$_{[(+\-]/  || ord($first_char) > 126)    )
        {
            $newdata .= "\n";
        } elsif (defined $last_eol) {
            $newdata .= " ";
        }

        $newdata .= $line;

        if ($line =~ /(\S)\s*$/) {
            $last_eol = $1;
        }
    }
    $newdata =~ s/\ $//;
    $this->data($newdata);

    # restore comments if they're supposed to be in here
    unless ($comment_state) {
        $this->restore_comments();
    }

    # restore strings/comments if needed
    unless ($string_state) {
        $this->restore_literal_strings();
    }
}

sub replace_extra_whitespace
{
    my $this = shift;

    # can't do this if literal strings are still in the thing.
    my $string_state = $this->{_strings_extracted};
    my $comment_state = $this->{_comments_extracted};
    unless ($this->{_strings_extracted} && $this->{_comments_extracted}) {
        $this->extract_strings_and_comments();
    }

    my $data = $this->data;
    # remove unneccessary white space around operators, braces, parenthesis
    $data =~ s/\s([\x21\x25\x26\x28\x29\x2a\x2b\x2c\x2d\x2f\x3a\x3b\x3c\x3d\x3e\x3f\x5b\x5d\x5c\x7b\x7c\x7d\x7e])/$1/g;
    $data =~ s/([\x21\x25\x26\x28\x29\x2a\x2b\x2c\x2d\x2f\x3a\x3b\x3c\x3d\x3e\x3f\x5b\x5d\x5c\x7b\x7c\x7d\x7e])\s/$1/g;
    $this->data($data);

    # restore strings/comments if needed
    unless ($string_state) {
        $this->restore_literal_strings();
    }
    unless ($comment_state) {
        $this->restore_comments();
    }
}

sub remove_comments
{
    my $this = shift;
    my %opts = @_;
    my @exceptions;
    if (ref($opts{exceptions}) eq 'ARRAY') {
        @exceptions = @{$opts{exceptions}};
    } elsif ( ((ref($opts{exceptions}) eq 'Regexp') || (! ref($opts{exceptions})))
              && $opts{exceptions} ) {
        @exceptions = ( $opts{exceptions} );
    }

    # can't do this if literal strings are still in the thing.
    my $string_state = $this->{_strings_extracted};
    my $comment_state = $this->{_comments_extracted};
    unless ($this->{_strings_extracted} && $this->{_comments_extracted}) {
        $this->extract_strings_and_comments();
    }

    my $comments = $this->comments();

    my $data = $this->data;
    my $exception_caught = 0;
    # replace each of the comments
    for (my $i=0; $i<@{$comments}; $i++)
    {
        my $comment = $comments->[$i];
        if (grep { $comment =~ /$_/ } @exceptions)
        {
            $exception_caught++;
            $data =~ s/\0\0\_($i)\_\0\0/$comment/g;
        } else {
            $data =~ s/\0\0\_($i)\_\0\0//g;
        }
    }
    $this->{_comments_extracted} = 0 if $exception_caught;
    $this->data($data);

    # restore strings if needed
    unless ($string_state) {
        $this->restore_literal_strings();
    }
}

sub restore_comments
{
    my $this = shift;

    return unless $this->{_comments_extracted};

    my $comments = $this->comments();

    my $data = $this->data;
    # replace each of the comments
    for (my $i=0; $i<@{$comments}; $i++)
    {
        my $comment = $comments->[$i];
        $data =~ s/\0\0\_($i)\_\0\0/$comment/g;
    }
    $this->{_comments_extracted} = 0;
    $this->data($data);
}

sub restore_literal_strings
{
    my $this = shift;

    return unless $this->{_strings_extracted};

    my $strings = $this->strings();

    my $data = $this->data;
    # replace each of the strings
    for (my $i=0; $i<@{$strings}; $i++)
    {
        my $string = $strings->[$i];
        $data =~ s/\0\0($i)\0\0/$string/g;
    }
    $this->{_strings_extracted} = 0;
    $this->data($data);
}

sub replace_final_eol
{
    my $this = shift;

    my $eol  = $this->eol_char();
    my $data = $this->data;
    if ($data =~ /\r?\n$/) {
        $data =~ s/\r?\n$/$eol/;
    } else {
        $data .= $eol;
    }
    $this->data($data);
}



1;
