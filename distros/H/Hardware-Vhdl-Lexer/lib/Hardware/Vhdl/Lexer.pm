package Hardware::Vhdl::Lexer;

use Class::Std;
use Carp;
use Readonly;
use strict;
use warnings;
#use diagnostics;

=for To do:
'use charnames' instead of \012 and \015
test get_nhistory and get_linesource
use regexp-generating module for number-matching regexps

=cut

our $VERSION = "1.00";

# Create storage for object attributes...
my %nhistory    :ATTR( :default<1>       :get<nhistory>   :init_arg<nhistory> );
my %linesource  :ATTR( :default<undef>   :get<linesource>  );
my %line        :ATTR( :default<q{}>                     );
my %source_func :ATTR;
my %history     :ATTR;

sub START {
    my ($self, $obj_ID, $arg_ref) = @_;
    my $class = ref($self);
    
    # check that a linesource was specified
    croak "$class constructor requires a linesource to be specified"
        if !defined $arg_ref->{linesource};

    {
        my $sourcetype = ref $arg_ref->{linesource};
	# store the source of lines as a subroutine reference
	$source_func{$obj_ID} = 
        $sourcetype eq q{}      ? croak "${class}->new 'linesource' parameter is not of a valid type (it is not a reference)" :
        $sourcetype eq 'GLOB'   ? sub { readline( $arg_ref->{linesource} ) }  :
        $sourcetype eq 'ARRAY'  ? _arrayref_to_sub($arg_ref->{linesource})      :
        $sourcetype eq 'SCALAR' ? _scalarref_to_sub($arg_ref->{linesource})     :
        $sourcetype eq 'CODE'   ?  $arg_ref->{linesource}                       :
        #~ $sourcetype ne 'REF' &&
        eval "$sourcetype->can('get_next_line')"
                                ? sub { $arg_ref->{linesource}->get_next_line } :
                                  croak "${class}->new 'linesource' parameter is not of a valid type (type is '$sourcetype')";

    }

    # set up initial history values
    for my $i ( 1 .. $self->get_nhistory ) { $history{$obj_ID}->[ $i - 1 ] = q{} }
    #@{ $history{$obj_ID} } = q{} x $self->get_nhistory;

    pos($line{$obj_ID}) = 0;

    return $self;
}

sub _arrayref_to_sub {
    # given an array ref, return a ref to a sub which returns the lines in sequence and then returns undef
    my $array_ref = shift;
    my $i = 0; 
    return sub {
        return $array_ref->[ $i++ ];
    };
}

sub _scalarref_to_sub {
    # given a scalar ref, return a ref to a sub which returns the line and then returns undef
    my $scalar_ref = shift;
    my $i = 0; 
    return sub {
        return $i++ == 0 ? ${ $scalar_ref } : undef;
    };
}

# after use charnames qw( :full );
#  \N{CR} is character 13 = 015
#  \N{LF} is character 10 = 012
#my $NEW_LINE           = qr/ \N{CR}\N{LF}? | \N{LF}\N{CR}? /xms;
my Readonly $NEW_LINE           = qr/ \015\012? | \012\015? /xms;
my Readonly $WHITESPACE         = qr/ [^\S\012\015]+ /xms;
my Readonly $COMMENT            = qr/ -- [^\015\012]* /xms;
my Readonly $BIT_VECTOR_LITERAL = qr/ [BOX] ".+?" /xms;
my Readonly $BASED_NUMBER       = qr/ 
                             (?: [23456789] | 1[0123456] ) # the base (2-16)
                             \# [\d_A-F]+ \#               # the number
                           /xmsi;
my Readonly $BASE10_REAL        = qr/ -? \d [\d_]* (?: \. \d*)? (?: E -? \d+)? /xmsi;
my Readonly $IDENTIFIER         = qr/ (?: \\ [^\\]+ \\) | (?: \w+ ) /xms;
my Readonly $PUNCTUATION        = qr{
                              [:<>/]= | => | <> | \*\* # 2-character punctuations
                              | [ \.\,\+\-\*\=\:\;\&\'\(\)\<\>\|\/ ] 
                            }xms;
my Readonly $DBL_QUOTED         = qr/
                              "          # opening quote
                              .*?        # contents of the quotes
                              (?<!\\)    # not preceded by a backslash:
                              (?:\\\\)*  # an even number of backslashes
                              "          # closing quote
                           /xms;
my Readonly $CHAR_LITERAL       = qr/
    '.'              # a character in single-quotes
    (?=              # followed by...
        (?: .'.' )*  # any number of following character literals
        (?! .'   )   # without leaving us with an unmatched single-quote 
        .*           # and anything that follows
    ) 
  /xms;

sub _as_str :STRINGIFY {
    my $self = shift;
    return scalar $self->get_next_token();
}

sub get_next_token {
    my $self = shift;
    my $obj_ID = ident $self;
    
    # get another line from the line-source if needed
    if ( defined $line{$obj_ID} && pos($line{$obj_ID}) >= length $line{$obj_ID} ) {
        $line{$obj_ID} = &{ $source_func{$obj_ID} };
        pos($line{$obj_ID}) = 0 if defined $line{$obj_ID};
    }
    # an undef line means the end of the VHDL source - no more tokens
    return if !defined $line{$obj_ID};

    my ($token, $match) =
        $line{$obj_ID} =~ m/\G ($NEW_LINE)           /gcxms ? ($1, 'wn') : # newline
        $line{$obj_ID} =~ m/\G ($WHITESPACE)         /gcxms ? ($1, 'ws') : # whitespace
        substr( $line{$obj_ID}, pos($line{$obj_ID}), 1 ) eq q{"} 
                                      ? ($self->_dquoted_string(), 'cs') : # string literal
        $line{$obj_ID} =~ m/\G ($COMMENT)            /gcxms ? ($1, 'r' ) : # comment
        $line{$obj_ID} =~ m/\G ($CHAR_LITERAL)       /gcxms ? ($1, 'cc') : # single-character literal
        $line{$obj_ID} =~ m/\G ($BIT_VECTOR_LITERAL) /gcxms ? ($1, 'cb') : # bit_vector literal
        $line{$obj_ID} =~ m/\G ($BASED_NUMBER)       /gcxms ? ($1, 'cn') : # specified-base integer numeric literal
        $line{$obj_ID} =~ m/\G ($BASE10_REAL)        /gcxms ? ($1, 'cn') : # base-10 numeric literal
        $line{$obj_ID} =~ m/\G ($IDENTIFIER)         /gcxms ? ($1, 'ci') : # extended identifier or keyword
        $line{$obj_ID} =~ m/\G ($PUNCTUATION)        /gcxms ? ($1, 'cp') : # punctuation
        $line{$obj_ID} =~ m/\G (.)                   /gcxms ? ($1, 'cu') : # unexpected character
                    croak "Internal error (token failed to match anything): "
                        . "Please file a bug report, showing what input caused this error\n";
    
    if ( substr( $match, 0, 1 ) eq 'c' ) {

        # not whitespace or comment, so add it to the code history
        push @{ $history{$obj_ID} }, $token;
        while ( @{ $history{$obj_ID} } > $self->get_nhistory ) {
            shift @{ $history{$obj_ID} };
        }
    }

    return wantarray ? ( $token, $match ) : $token;
}

sub _dquoted_string {
    my $self = shift;
    my $obj_ID = ident $self;
    # this method should only be called when we already know we have an open-quote at the match-start point of $line{$obj_ID}
    while (1) {
        if ( $line{$obj_ID} =~ /\G ($DBL_QUOTED) /gcxms ) {
            return $1;
        }

        # can't match a closing quote - get another line from the source
        my $nextline = &{ $source_func{$obj_ID} };
        if ( !defined $nextline ) {
            # reached EOF without finding closing quote: we're done
            my $start_pos = pos $line{$obj_ID};
            pos $line{$obj_ID} = length $line{$obj_ID};
            return substr $line{$obj_ID}, $start_pos;
        }
        $line{$obj_ID} .= $nextline;
    }
}

sub history {
    my $self = shift;
    my $age  = shift;
    my $obj_ID = ident $self;

    croak "more (" . ( $age + 1 ),
        ") history requested than has been stored ("
        . ( $nhistory{$obj_ID} ) . ")"
        if $age >= @{ $history{$obj_ID} };
    return $history{$obj_ID}->[ -1 - $age ];
}

1;    # End of Hardware::Vhdl::Lexer

__END__
perl p:\bin\pod2html.bat --infile=Lexer.pm --outfile=C:/t/Lexer.html

=head1 NAME

Hardware::Vhdl::Lexer - Split VHDL code into lexical tokens

=head1 SYNOPSIS

    use Hardware::Vhdl::Lexer;
    
    # Open the file to get the VHDL code from
    my $fh;
    open $fh, '<', 'device_behav.vhd' || die $!
    
    # Create the Lexer object
    my $lexer = Hardware::Vhdl::Lexer->new({ linesource => $fh });
    
    # Dump all the tokens
    my ($token, $type);
    while( (($token, $type) = $lexer->get_next_token) && defined $token) {
        print "# type = '$type' token='$token'\n";
    }

=head1 DESCRIPTION

C<Hardware::Vhdl::Lexer> splits VHDL code into lexical tokens.  To use it, you need to first create a lexer object, passing in
something which will supply chunks of VHDL code to the lexer.  Repeated calls to the C<get_next_token> method of
the lexer will then return VHDL tokens (in scalar context) or a token type code and the token (in list context).  C<get_next_token>
returns undef when there are no more tokens to be read.

NB: in this documentation I refer to "lines" of VHDL code and "line" sources 
etc., but in fact the chunks of code don't have to be broken up at
line-ends - they can be broken anywhere that isn't in the middle of a
token.  New-line characters just happen to be a simple and safe way to split
up a file.  You don't even have to split up the VHDL at all, you can
pass in the whole thing as the first and only "line".

=head1 CONSTRUCTOR

	new({ linesource => <source> [, nhistory => N] })

Note that from version 1.0 of this module the arguments must now be given as a hash reference rather than a hash, so the curly 
brackets above are required.

The linesource argument is required: it defines where the VHDL source code will be taken from (see below).

The optional nhistory argument sets 
how many "code" tokens (see the C<get_next_token> method) will be remembered for access by the C<history> method.

=over 4

=item new({ linesource => $filehandle_reference [, nhistory => N] })

To read from a file, pass in the filehandle reference like this:

    use Hardware::Vhdl::Lexer;
    my $fh;
    open $fh, '<', $filename || die $!;
    my $lexer = Hardware::Vhdl::Lexer->new({ linesource => $fh });

=item new({ linesource => \@array_of_lines [, nhistory => N] })

=item new({ linesource => \$scalar_containing_vhdl [, nhistory => N] })

To read VHDL source that is already in program memory, the linesource argument can be a reference to either an array of lines
or a single string which can have embedded newlines.

=item new({ linesource => $object_with_get_next_line_method [, nhistory => N] })

The linesource argument can be an object with a C<get_next_line> method.  
This method must return undef when there are no more lines to read.

=item new({ linesource => \&subroutine_that_returns_lines [, nhistory => N] })

If none of the above input methods suits your needs, you can give a subroutine reference and wrap whatever code you
need to get the VHDL source.  When called, this subroutine must return each line of source code in turn, and then return
undef when there are no more lines.

=back

=head1 METHODS

=over 4

=item get_linesource()

Returns the linesource argument passed into the constructor.  Before version 1.0 of this module, this method was called C<linesource()>.

=item C<get_next_token()>

In scalar context, returns the next VHDL token.

In list context, returns a token type code and the token

Nothing is removed from the source code: if you concatenate all the tokens returned by C<get_next_token()>, you will get the same
result as if you concatenate all the strings returned by the linesource object.

The token type codes are 1 or 2-character strings.  When the codes are 2 characters, the first character gives the general class of the
token and the second indicates its type more specifically.  The first character will be 'w' for whitespace, 'r' for comments (remarks) 
or 'c' for code.  It should be possible to remove all comment tokens, and change whitespace tokens for different whitespace, and 
always end up with functionally equivalent code.

The token type codes are:

=over 4

=item wn

Whitespace:Newline.  This could be any of \012, \015, \015\012 or \012\015.

=item ws

Whitespace:Spaces.  A group of whitespace characters which match the /s regexp pattern but which do not include any carriage-return
or linefeed characters.

=item r

Remark.  The token will start with two dashes and include the remainder of the source code line, not including any newline characters.  
The next token will either be a newline or undef.

=item cs

Code:String literal.  The lexer accepts multi-line strings, even though the VHDL specification does not allow them.

=item cc

Code:Character literal.

=item cb

Code:Bit_vector literal.  For example, C<B"001_1010"> or C<O"7720"> or C<H"A7_DEAD">.

=item cn

Code:Numeric literal.  This could be a specified-base literal like C<8#7720#> or a simple integer or floating-point value.

=item ci

Code:Identifier or keyword.  For example, C<package> or C<my_signal_23> or C</extended identifier$%!/>..

=item cp

Code:Punctuation.  A 1 or 2-character group of punctuation symbols that is part of VHDL syntax.  For example,
'<=' is returned as a single 'cp' token, as is '&', but '#' would be returned as an unexpected character
(see below).

=item cu

Unexpected character.  Any character in the source that does not match any of the above definitions, and
cannot be part of valid VHDL code.  Note that prior to version 1.0 of this module, these would be returned
with the 'cp' token type code.

=back 

=item history(N)

Returns previous code tokens.  N must not be larger than the nhistory argument passed to the constructor.  C<history(0)> will 
return the text of the last token returned by C<get_next_token> whose type started with a 'c',
C<history(1)> will return the code token before that, and so on.

=back

=head1 AUTHOR

Michael Attenborough, C<< <michael.attenborough at physics.org> >>

=head1 DEPENDENCIES

This module requires the following modules to be available:

=over 4

Carp: any version
Class::Std: any version
Readonly: version 1.03 or later

=back

=head1 ERRORS AND WARNINGS

=over 4

=item "Argument to Hardware::Vhdl::Lexer->new() must be hash reference"

Have you remembered to put curly brackets around the argument list?  Pre-1.0 
versions of this module used to take the arguments to new() as a direct hash,
but version 1.0 onwards need a hash reference.  This means that the curly
brackets need to be added when migrating from pre-1.0 to 1.0 or later.

    # Old style (argument list is hash) - doesn't work any more
    my $lexer = Hardware::Vhdl::Lexer->new( linesource => $fh );

    # New style (argument is a hash ref) - do it this way now
    my $lexer = Hardware::Vhdl::Lexer->new({ linesource => $fh });

=item "Hardware::Vhdl::Lexer constructor requires a linesource to be specified"

The 'linesource' argument to Hardware::Vhdl::Lexer->new() is required, and
it is a fatal error not to provide one.

=item "Hardware::Vhdl::Lexer->new 'linesource' parameter is not of a valid type (it is not a reference)"

The linesource parameter needs to be a reference to something.
If your VHDL code to be passed is in a scalar string, you need to pass
in a reference to the string, not the string itself.

=item "Hardware::Vhdl::Lexer->new 'linesource' parameter is not of a valid type (type is '<type>')"

The linesource parameter that you have passed to new() does not appear to be
a reference to a scalar, a list, a filehandle, a subroutine or an object with 
a get_next_line method.  You have passed a reference to something (otherwise 
you would see the previous message) and the error message will tell you what
it appears to be a reference to.

=item "Internal error (token failed to match anything)"

This is a "this should never happen" type of error, and is a sign that I have included a bug.
If you ever see this error, I would appreciate a bug report describing how to reproduce the
error.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-hardware-vhdl-lexer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hardware-Vhdl-Lexer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hardware::Vhdl::Lexer

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hardware-Vhdl-Lexer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hardware-Vhdl-Lexer>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hardware-Vhdl-Lexer>

=item * Search CPAN

L<http://search.cpan.org/dist/Hardware-Vhdl-Lexer>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Michael Attenborough, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

