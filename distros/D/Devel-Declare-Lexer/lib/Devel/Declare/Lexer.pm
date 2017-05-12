package Devel::Declare::Lexer;

use strict;
use warnings;
use v5;

our $VERSION = '0.014';

use Data::Dumper;
use Devel::Declare;
use Devel::Declare::Lexer::Stream;
use Devel::Declare::Lexer::Token;
use Devel::Declare::Lexer::Token::Bareword;
use Devel::Declare::Lexer::Token::Declarator;
use Devel::Declare::Lexer::Token::EndOfStatement;
use Devel::Declare::Lexer::Token::Heredoc;
use Devel::Declare::Lexer::Token::LeftBracket;
use Devel::Declare::Lexer::Token::Newline;
use Devel::Declare::Lexer::Token::Operator;
use Devel::Declare::Lexer::Token::RightBracket;
use Devel::Declare::Lexer::Token::String;
use Devel::Declare::Lexer::Token::Variable;
use Devel::Declare::Lexer::Token::Whitespace;

use vars qw/ @ISA $DEBUG $SHOWTRANSLATE /;
@ISA = ();
$DEBUG = 0;
$SHOWTRANSLATE = 0;

sub import
{
    my $class = shift;
    my $caller = caller;

    import_for($caller, @_);
}

sub import_for
{
    my ($caller, @args) = @_;
    my $class = shift;

    no strict 'refs';

    my %subinject = ();
    if(ref($args[0]) =~ /HASH/) {
        $DEBUG and print STDERR "Using hash for import\n";
        %subinject = %{$args[0]};
        @args = keys %subinject;
    }

    my @consts;

    my %tags = map { $_ => 1 } @args;
    if($tags{":debug"}) {
        $DEBUG = 1;
    }
    if($tags{":lexer_test"}) {
        $DEBUG and print STDERR "Adding 'lexer_test' to keyword list\n";

        push @consts, "lexer_test";
    }

    my @names = @args;
    for my $name (@names) {
        next if $name =~ /:/;
        $DEBUG and print STDERR "Adding '$name' to keyword list\n";

        push @consts, $name;
    }

    for my $word (@consts) {
        $DEBUG and print STDERR "Injecting '$word' into '$caller'\n";
        Devel::Declare->setup_for(
            $caller,
            {
                $word => { const => \&lexer }
            }
        );
        if($subinject{$word}) {
            $DEBUG and print STDERR "- Using sub provided in import\n";
            *{$caller.'::'.$word} = $subinject{$word};
        } else {
            $DEBUG and print STDERR "- Using default sub\n";
            *{$caller.'::'.$word} = sub () { 1; };
        }
    }
}

my %named_lexed_stack = ();
sub lexed
{
    my ($key, $callback) = @_;
    $DEBUG and print STDERR "Registered callback for keyword '$key'\n";
    $named_lexed_stack{$key} = $callback;
}

sub call_lexed
{
    my ($name, $stream) = @_;

    $DEBUG and print STDERR "Checking for callbacks for keyword '$name'\n";
    $DEBUG and print STDERR Dumper($stream) . "\n";

    my $callback = $named_lexed_stack{$name};
    if($callback) {
        $DEBUG and print STDERR "Found callback '$callback' for keyword '$name'\n";
        $stream = &$callback($stream);
    }

    $DEBUG and print STDERR Dumper($stream) . "\n";

    return $stream;
}

sub lexer
{
    my ($symbol, $offset) = @_;

    $DEBUG and print "=" x 80, "\n";

    my $linestr = Devel::Declare::get_linestr;
    my $original_linestr = $linestr;
    my $original_offset = $offset;
    $DEBUG and print STDERR "Starting with linestr '$linestr'\n";

    my @tokens = ();
    tie @tokens, "Devel::Declare::Lexer::Stream";
    my ($len, $tok);
    my $eoleos = 0;
    my $line = 1;

    # Skip the declarator
    $offset += Devel::Declare::toke_move_past_token($offset);
    push @tokens, new Devel::Declare::Lexer::Token::Declarator( value => $symbol );
    $DEBUG and print STDERR "Skipped declarator '$symbol'\n";

    my %lineoffsets = ( 1 => $offset );

    # We call this from a few places inside the loop
    my $skipspace = sub {
        # Move past any whitespace
        $len = Devel::Declare::toke_skipspace($offset);
        if($len > 0) {
            $tok = substr($linestr, $offset, $len);
            $DEBUG and print STDERR "Skipped whitespace '$tok', length [$len]\n";
            push @tokens, new Devel::Declare::Lexer::Token::Whitespace( value => $tok );
            $offset += $len;

            if($tok =~ /\n/) {
                # its odd that this works without handling any line numbering
                # I think we end up here when an end of line is found after a bareword (e.g. print\n"something")
                # It probably still needs some work on line numbering, but everything just seems to work! 
                $DEBUG and print STDERR "Got end of line in skipspace, probable bareword preceeding EOL\n";
                Devel::Declare::clear_lex_stuff;

                # We've got a new line so we need to refresh our linestr
                $linestr = Devel::Declare::get_linestr;
                $original_linestr = $linestr;

                $DEBUG and print STDERR "Refreshed linestr [$linestr]\n";
            }
        } elsif ($len < 0) {
            # Again, its odd that we don't handle any line numbering here, and a $len of < 0 is a definite EOL
            $DEBUG and print STDERR "Got end of line in skipspace\n";
        } elsif ($len == 0) {
            $DEBUG and print STDERR "No whitespace skipped\n";
        }
        return $len;
    };

    # Capture the tokens
    $DEBUG and print STDERR "Linestr length [", length $linestr, "]\n";
    my $heredoc = undef;
    my $heredoc_end_re = undef;
    my $heredoc_end_re2 = undef;
    my $nest = 0; # nested bracket tracking, just in case we get ; inside a block
    while($offset < length $linestr) {
        $DEBUG and print STDERR Dumper(\%lineoffsets) . "\n";
        if($heredoc && !(substr($linestr, $offset, 2) eq "\n")) {
            my $c = substr($linestr, $offset, 1);
            $DEBUG and print STDERR "Consuming char from heredoc: '$c'\n";
            $offset += 1;
            if($c =~ /\n/) {
                $DEBUG and print STDERR "Newline found in heredoc (current line $line)\n";
                #$line++;
                #$lineoffsets{$line} = $offset;
            } else {
                $heredoc->{value} .= $c;
            }
            $DEBUG and print STDERR "New heredoc value: " . $heredoc->{value} . "\n";
            my $heredoc_name = $heredoc->{name};
            if($heredoc->{value} =~ /$heredoc_end_re/) {
                $heredoc->{value} =~ s/$heredoc_end_re2//;
                $DEBUG and print STDERR "Consumed heredoc, name [$heredoc_name]:\n" . $heredoc->{value} . "\n";
                push @tokens, $heredoc;
                $heredoc = undef;
                $heredoc_end_re = undef;
                $heredoc_end_re2 = undef;
            }
            next;
        }

        $DEBUG and print STDERR "Offset[$offset], nest [$nest], Remaining[", substr($linestr, $offset), "]\n";

        if(substr($linestr, $offset, 1) eq ';') {
            $DEBUG and print STDERR "Got end of statement\n";
            push @tokens, new Devel::Declare::Lexer::Token::EndOfStatement;
            $offset += 1;
            $eoleos = 1;
            last unless $nest;
            next;
        }

        if(substr($linestr, $offset, 2) eq "\n") {
            if($heredoc) {
                $DEBUG and print STDERR "Got end of line in heredoc\n";
                $heredoc->{value} .= "\n";
            }

            if(!$heredoc) {
                $DEBUG and print STDERR "Got end of line in loop (current line $line)\n";
                push @tokens, new Devel::Declare::Lexer::Token::Newline;
                $offset += 1;
            }

            # this lets us capture a newline directly after a semicolon
            # and immediately exit the loop - otherwise we might start
            # consuming code that doesn't belong to us
            last if $eoleos && !$nest;
            $eoleos = 0;

            # If we're here, it's just a new line inside the statement that 
            # we do want to consume

            # We don't use skipspace here - it does too much!
            #&$skipspace;
            $len = Devel::Declare::toke_skipspace($offset);
            if($len != 0) {
                # TODO it seems odd that we don't add $len to the
                # offset... this might come back to bite us later!
                #$offset += $len - 6;
                $DEBUG and print STDERR "Skipped $len whitespace following EOL, not added to \$offset\n";
            }

            Devel::Declare::clear_lex_stuff;

            # Got a new line, so we need to refresh linestr
            $linestr = Devel::Declare::get_linestr;
            # It's not the next line, its everything upto and including the next line
            # so really our original_linestr is wrong!
            $original_linestr = $linestr;

            # Record some offsets for later - we start on line 1 and the first $line++ is 2
            # so we make a special case for recording line 1's offset
            if($line == 1) {
                $lineoffsets{1} = (length $symbol) + 1;
            };
            $line++;
            $lineoffsets{$line} = $heredoc ? $offset + 1 : $offset;

            $DEBUG and print STDERR "Refreshed linestr [$linestr], added lineoffset for line $line, offset $offset\n";
            next;
        }

        # FIXME Does this ever happen?
        if(&$skipspace < 0) {
            $DEBUG and print STDERR "Got skipspace < 0\n";
            last;
        }

        # Check if its a opening bracket
        if(substr($linestr, $offset, 1) =~ /(\{|\[|\()/) {
            my $b = substr($linestr, $offset, 1);
            push @tokens, new Devel::Declare::Lexer::Token::LeftBracket( value => $b );
            $nest++;
            $DEBUG and print STDERR "Got left bracket '$b', nest[$nest]\n";
            $offset += 1;
            next;
        }
        # Check if its a closing bracket
        if(substr($linestr, $offset, 1) =~ /(\}|\]|\))/) {
            my $b = substr($linestr, $offset, 1);
            push @tokens, new Devel::Declare::Lexer::Token::RightBracket( value => $b );
            $nest--;
            $DEBUG and print STDERR "Got right bracket '$b', nest[$nest]\n";
            $offset += 1;
            next;
        }
        # Check for a reference
        if(substr($linestr, $offset, 1) =~ /\\/) {
            $tok = substr($linestr, $offset, 1);
            $DEBUG and print STDERR "Got reference operator '$tok'\n";
            push @tokens, new Devel::Declare::Lexer::Token::Operator( value => $tok);
            $offset += 1;
            next;
        }
        # Check for variable
        if(substr($linestr, $offset, 1) =~ /(\$|\%|\@|\*)/) {
            # get the sign
            # TODO the variable name is captured later - it should probably be done here
            $tok = substr($linestr, $offset, 1);
            $DEBUG and print STDERR "Got variable '$tok'\n";
            push @tokens, new Devel::Declare::Lexer::Token::Variable( value => $tok );
            $offset += 1;
            next;
        }
        # Check for string
        if(substr($linestr, $offset, 1) =~ /^(q|\"|\')/) {
            # FIXME need to determine string type properly
            my $strstype = substr($linestr, $offset, 1);

            my $allow_string = 1;

            if($strstype eq 'q') {
                if(substr($linestr, $offset + 1, 1) !~ /\|\{\[\(\#/) {
                    $DEBUG and print STDERR "This 'q' isnt a string type\n";
                    $allow_string = 0;
                }
            }

            if($allow_string) {
                my $stretype = $strstype;
                if($strstype =~ /q/) {
                    if(substr($linestr, $offset, 2) =~ /qq/) {
                        $strstype = substr($linestr, $offset, 3);
                        $offset += 2;
                    } else {
                        $strstype = substr($linestr, $offset, 2);
                        $offset += 1;
                    }
                    $stretype = substr($linestr, $offset, 1);
                    $stretype =~ tr/\(/)/;
                    $len = Devel::Declare::toke_scan_str($offset);
                } else {
                    $len = Devel::Declare::toke_scan_str($offset);
                }
                $DEBUG and print STDERR "Got string type '$strstype', end type '$stretype'\n";
                $tok = Devel::Declare::get_lex_stuff;
                Devel::Declare::clear_lex_stuff;
                $DEBUG and print STDERR "Got string '$tok'\n";
                push @tokens, new Devel::Declare::Lexer::Token::String( start => $strstype, end => $stretype, value => $tok );
                # get a new linestr - we might have captured multiple lines
                $linestr = Devel::Declare::get_linestr;
                $offset += $len;

                # If we do have multiple lines, we'll fix line numbering at the end

                next;
            }
        }
        # Check for heredoc
        if(substr($linestr, $offset)=~ /^(<<\s*([\w\d]+)\s*\n)/) {
            # Heredocs are weird - we'll just remember we're in a heredoc until we get the end token
            $DEBUG and print STDERR "Got a heredoc with name '$2'\n";
            $heredoc = new Devel::Declare::Lexer::Token::Heredoc( name => $2, value => '' );
            $heredoc_end_re = qr/\n$2\n$/;
            $heredoc_end_re2 = qr/$2\n$/;
            $DEBUG and print STDERR "Created regex $heredoc_end_re and $heredoc_end_re2\n";

            # get a new linestr - we might have captured multiple lines
            $offset += 2 + (length $1);
    
            $len = Devel::Declare::toke_skipspace($offset);
            $linestr = Devel::Declare::get_linestr;
            $offset += $len;
            $DEBUG and print STDERR "Skipped $len whitespace at start of heredoc, got new linestr[$linestr]\n";

            $line++;
            $lineoffsets{$line} = $offset;

            # If we do have multiple lines, we'll fix line numbering at the end

            next;
        }
        # Check for operator after strings (so heredocs <<NAME work)
        if(substr($linestr, $offset, 1) =~ /[!\+\-\*\/\.><=,|&\?:]/) {
            $tok = substr($linestr, $offset, 1);
            $DEBUG and print STDERR "Got operator '$tok'\n";
            push @tokens, new Devel::Declare::Lexer::Token::Operator( value => $tok );
            $offset += 1;
            next;
        }
        # Check for bareword
        $len = Devel::Declare::toke_scan_word($offset, 1);
        if($len) {
            $tok = substr($linestr, $offset, $len);
            $DEBUG and print STDERR "Got bareword '$tok'\n";
            push @tokens, new Devel::Declare::Lexer::Token::Bareword( value => $tok );
            $offset += $len;
            next;
        }

    }

    # Callback (AT COMPILE TIME) to allow manipulation of the token stream before injection
    $DEBUG and print STDERR Dumper(\@tokens) . "\n";
    @tokens = @{call_lexed($symbol, \@tokens)};

    my $stmt = "";
    for my $token (@tokens) {
        $stmt .= $token->get;
    }

    $DEBUG and print "=" x 80, "\n";

    if($symbol =~ /^lexer_test$/) {
        $DEBUG and print STDERR "Escaping statement for variable assignment\n";
        $stmt =~ s/\\/\\\\/g;
        $stmt =~ s/\"/\\"/g;
        $stmt =~ s/\$/\\\$/g;
        $stmt =~ s/\n/\\n/g;
        chomp $stmt;
        $stmt = substr($stmt, 0, (length $stmt)); # strip the final \\n
    } else {
        $stmt =~ s/\n//g; # remove multiline on final statement
        chomp $stmt;
    }
    $DEBUG and print STDERR "Final statement: [$stmt]\n";

    # FIXME line numbering is broken if a \n appears inside a block, e.g. keyword { print "\n"; }
    #my @lcnt = split /[^\\]\\n/, $stmt;
    my @lcnt = split /\\n/, $stmt;
    my $lc = scalar @lcnt;
    $DEBUG and print STDERR "Lines:\n", Dumper(\@lcnt) . "\n";
    my $lineadjust = $lc - $line;
    $DEBUG and print STDERR "Linecount[$lc] lines[$line] - missing $lineadjust lines\n";

    # we've got a new linestr, we need to re-fix all our offsets
    $DEBUG and print STDERR "\n\nStarted with linestr [$linestr]\n";
    use Data::Dumper;
    $DEBUG and print STDERR Dumper(\%lineoffsets) . "\n";

    for my $l (sort keys %lineoffsets) {
        my $sol = $lineoffsets{$l};
        last if !defined $lineoffsets{$l+1}; # don't mess with the current line, yet!
        my $eol = $lineoffsets{$l + 1} - 1;
        my $diff = $eol - $sol;
        my $substr = substr($linestr, $sol, $diff);
        $DEBUG and print STDERR "\nLine $l, sol[$sol], eol[$eol], diff[$diff], linestr[$linestr], substr[$substr]\n";
        substr($linestr, $sol, $diff) = " " x $diff;
    }

    # now clear up the last line
    $DEBUG and print STDERR "Still got linestr[$linestr]\n";
    my $sol = $line == 1 ? (length $symbol) + 1 + $original_offset : $lineoffsets{$line};
    my $eol = (length $linestr) - 1;
    my $diff = $eol - $sol;
    my $substr = substr($linestr, $sol, $diff);
    $DEBUG and print STDERR "Got substr[$substr] sol[$sol] eol[$eol] diff[$diff]\n";

    my $newline = "\n" x $lineadjust;
    if($symbol =~ /^lexer_test$/) {
        $newline .= "and \$lexed = \"$stmt\";";
    } else {
        $newline .= " and " . substr($stmt, length $symbol);
    }

    substr($linestr, $sol, (length $linestr) - $sol - 1) = $newline; # put the rest of the statement in

    ($DEBUG || $SHOWTRANSLATE) and print STDERR "Got new linestr[$linestr] from original_linestr[$original_linestr]\n";

    $DEBUG and print "=" x 80, "\n";
    Devel::Declare::set_linestr($linestr);
}

1;

=encoding utf8

=head1 NAME

Devel::Declare::Lexer - Easier than Devel::Declare

=head1 SYNOPSIS

    # Add :debug tag to enable debugging
    # Add :lexer_test to enable variable assignment
    # Anything not starting with : becomes a keyword
    use Devel::Declare::Lexer qw/ keyword /;

    BEGIN {
        # Create a callback for the keyword (inside a BEGIN block!)
        Devel::Declare::Lexer::lexed(keyword => sub {
            # Get the stream out (given as an arrayref)
            my ($stream_r) = @_;
            my @stream = @$stream_r;

            my $str = $stream[2]; # in the example below, the string is the 3rd token

            # Create a new stream (we could manipulate the existing one though)
            my @ns = ();
            tie @ns, "Devel::Declare::Lexer::Stream";

            # Add a few tokens to print the string 
            push @ns, (
                # You need this (for now)
                new Devel::Declare::Lexer::Token::Declarator( value => 'keyword' ),
                new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),

                # Everything else is your own custom code
                new Devel::Declare::Lexer::Token( value => 'print' ),
                new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
                $string,
                new Devel::Declare::Lexer::Token::EndOfStatement,
                new Devel::Declare::Lexer::Token::Newline,
            );

            # Stream now contains:
            # keyword and print "This is a string";
            # keyword evaluates to 1, everything after the and gets executed

            # Return an arrayref
            return \@ns;
        });
    }

    # Use the keyword anywhere in this package
    keyword "This is a string";

=head1 DESCRIPTION

L<Devel::Declare::Lexer> makes it easier to parse code using L<Devel::Declare>
by generating a token stream from the statement and providing a callback for
you to manipulate it before its parsed by Perl.

The example in the synopsis creates a keyword named 'keyword', which accepts
a string and prints it.

Although this simple example could be done using print, say or any other simple
subroutine, L<Devel::Declare::Lexer> supports much more flexible syntax.

For example, it could be used to auto-expand subroutine declarations, e.g.
    method MethodName ( $a, @b ) {
        ... 
    }
into
    sub MethodName ($@) {
        my ($self, $a, @b) = @_;
        ...
    }

Unlike L<Devel::Declare>, there's no need to worry about parsing text and
taking care of multiline strings or code blocks - it's all done for you.

=head1 ADVANCED USAGE

L<Devel::Declare::Lexer>'s standard behaviour is to inject a sub into the
calling package which returns a 1. Because your statement typically gets
transformed into something like
    keyword and [your statement here];
the fact keyword evaluates to 1 means everything following the and will always
be executed.

You can extend this by using a different import syntax when loading L<Devel::Declare::Lexer>
    use Devel::Declare::Lexer { keyword => sub { $Some::Package::variable } };
which will cause the provided sub to be injected instead of the default sub.

=head1 SEE ALSO

Some examples can be found in the source download.

For more information about how L<Devel::Declare::Lexer> works, read the 
documentation for L<Devel::Declare>.

=head1 AUTHORS

Ian Kent - L<iankent@cpan.org> - original author

http://www.iankent.co.uk/

=head1 COPYRIGHT AND LICENSE

This library is free software under the same terms as perl itself

Copyright (c) 2013 Ian Kent

Devel::Declare::Lexer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the license for more details.

=cut
