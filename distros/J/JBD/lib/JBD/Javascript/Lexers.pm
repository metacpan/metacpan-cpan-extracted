package JBD::Javascript::Lexers;
# ABSTRACT: Javascript lexers
our $VERSION = '0.04'; # VERSION

# Javascript Lexers.
# @author Joel Dalley
# @version 2014/Apr/13

use JBD::Core::Exporter;
use JBD::Parser::DSL;

our @EXPORT = qw(
    SourceCharacter WhiteSpace LineTerminator LineTerminatorSequence
    MultiLineNotForwardSlashOrAsteriskChar PostAsteriskCommentChars
    MultiLineNotAsteriskChar MultiLineCommentChars MultiLineComment
    SingleLineCommentChar SingleLineCommentChars SingleLineComment
    Comment Infinity HexDigit HexIntegerLiteral DecimalDigit NonZeroDigit
    DecimalDigits DecimalIntegerLiteral DecimalLiteral NumericLiteral
    BooleanLiteral NullLiteral StringLiteral RegularExpressionFirstChar
    RegularExpressionChar RegularExpressionTags RegularExpressionBody
    RegularExpressionLiteral Literal SignedInteger ExponentIndicator
    ExponentPart Punctuator UnicodeDigit UnicodeLetter UnicodeCombiningMark
    UnicodeConnectorPunctuation IdentifierStart IdentifierPart IdentifierName
    Identifier Keyword FutureReservedWord ReservedWord Token DivPunctuator
    InputElementDiv InputElementRegExp
    );

sub SourceCharacter {
    bless sub {
        my $chars = shift;
        return unless defined $chars && length $chars;
        substr $chars, 0, 1;
    }, 'SourceCharacter';
}

sub WhiteSpace { bless sub { Space->(shift) }, 'WhiteSpace' }

sub LineTerminator { 
    bless sub { shift =~ m{^(\v+)}o; $1 }, 'LineTerminator' 
}

sub LineTerminatorSequence { 
    bless sub { 
        LineTerminator->(shift) 
    }, 'LineTerminatorSequence'
}

sub MultiLineNotForwardSlashOrAsteriskChar {
    bless sub {
        my $chars = shift or return;
        return if $chars =~ m{^(/|\*)}o;
        SourceCharacter->($chars);
    }, 'MultiLineNotForwardSlashOrAsteriskChar';
}

sub PostAsteriskCommentChars {
    bless sub {
        my $chars = shift or return;

        my $not = MultiLineNotForwardSlashOrAsteriskChar->($chars);
        if ($not) {
            return $not unless length($chars) - length($not) > 0;
            my $remain = substr $chars, length $not;
            my $multi = &MultiLineCommentChars->($remain);
            return $not . ($multi ? $multi : '');
        }
        elsif ($chars && $chars =~ m{^\*}o) {
            my $return = '*';
            $chars = substr $chars, 0, 1;
            while (my $next = &PostAsteriskCommentChars->($chars)) {
                $return .= $next;
                last unless length($chars) - length($next) > 0;
                $chars = substr $chars, length $next;
            }
            return $return;
        }

        undef;
    }, 'PostAsteriskCommentChars';
}

sub MultiLineNotAsteriskChar {
    bless sub {
        my $chars = shift or return;
        return if $chars && $chars =~ m{^\*}o;
        SourceCharacter->($chars);
    }, 'MultiLineNotAsteriskChar';
}

sub MultiLineCommentChars {
    bless sub {
        my $chars = shift or return;

        my $not = MultiLineNotAsteriskChar->($chars);
        if ($not) {
            my $multi;
            return $not unless length($chars) - length($not) > 0;
            $chars = substr $chars, length $not;
            while (my $next = &MultiLineCommentChars->($chars)) {
                $multi .= $next;
                last unless length($chars) - length($next) >= 0;
                $chars = substr $chars, length $next;
            }
            return $not . ($multi ? $multi : '');
        }
        elsif ($chars && $chars =~ m{^\*}o) {
            my $post = &PostAsteriskCommentChars->(substr $chars, 1);
            return '*' . ($post ? $post : '');
        }

        undef;
    }, 'MultiLineCommentChars';
}

sub MultiLineComment {
    bless sub {
        my $chars = shift;
        return unless $chars && $chars =~ m{^(/\*)}o;

        $chars  = substr $chars, 2;
        my $pos = index($chars, '*/');
        return unless $pos > 0;
        $chars = substr $chars, 0, $pos-1;

        my $multi = MultiLineCommentChars->($chars);
        '/*' . ($multi ? $multi : '') . '*/';
    }, 'MultiLineComment';
}

sub SingleLineCommentChar {
    bless sub {
        my $chars = shift;
        return if LineTerminator->($chars);
        SourceCharacter->($chars);
    }, 'SingleLineCommentChar';
}

sub SingleLineCommentChars {
    bless sub {
        my $chars = shift;
          
        my $first = SingleLineCommentChar->($chars);
        return unless $first;

        my $return = $first;
        $chars = substr $chars, length $first;

        while (my $next = SingleLineCommentChar->($chars)) {
            $return .= $next;
            last unless length($chars) - length($next) >= 0;
            $chars = substr $chars, length $next;
        }
        $return;
    }, 'SingleLineCommentChars';
}

sub SingleLineComment {
    bless sub {
        my $chars = shift;
        return unless $chars
            && length $chars > 1
            && $chars =~ m{^//}o;
        my $single = SingleLineCommentChars->(substr $chars, 2);
        '//' . ($single ? $single : '');
    }, 'SingleLineComment';
}

sub Comment {
    bless sub {
        my $chars = shift;
        MultiLineComment->($chars) 
        || SingleLineComment->($chars);
    }, 'Comment';
}

sub Infinity {
    bless sub { 
        shift =~ /^(\+|-)Infinity/o or return;
        $1 . 'Infinity';
    }, 'Infinity';
}

sub HexDigit {
    bless sub { shift =~ /^([0-9a-f])/io; $1 }, 'HexDigit';
}

sub HexIntegerLiteral {
    bless sub { 
        my $chars = shift;

        my $literal;
        if (index($chars, '0x') == 0) {
            $chars = substr $chars, 2;
            my $digit;
            while ($digit = HexDigit->($chars)) {
                $chars = substr $chars, 1;
                $literal .= $digit;
            }
            return unless $literal;
            return '0x' . $literal;
        }
    }, 'HexIntegerLiteral';
}

sub DecimalDigit {
    my @digits = qw(0 1 2 3 4 5 6 7 8 9);

    bless sub {
        my $chars = shift or return;
        my $first = substr $chars, 0, 1;
        my @match = grep $first eq $_, @digits;
        return $first if scalar grep $first eq $_, @digits;
        undef;
    }, 'DecimalDigit';
}

sub NonZeroDigit {
    bless sub {
        my $chars = shift;
        return if $chars =~ /^0/o;
        DecimalDigit->($chars);
    }, 'NonZeroDigit';
}

sub DecimalDigits {
    bless sub {
        my $chars = shift or return;
        my $digits;
        while (defined (my $next = DecimalDigit->($chars))) {
            $chars = substr $chars, 1;
            $digits .= $next;
        }
        $digits;
    }, 'DecimalDigits';
}

sub DecimalIntegerLiteral {
    bless sub { DecimalDigits->(shift) }, 'DecimalIntegerLiteral';
}

sub DecimalLiteral {
    bless sub {
        my $chars = shift;

        my $first = index($chars, '.') == 0 && '.'
                 || DecimalIntegerLiteral->($chars);
        return unless defined $first;
        $chars = substr $chars, length $first;

        $first eq '.' or do {
            return unless index($chars, '.') == 0;
            $first .= '.';
        };
        $chars = substr $chars, 1;

        my $digits = DecimalDigits->($chars);
        return unless defined $digits;
        my $exp = &ExponentPart->(substr $chars, length $digits);
        return $first . $digits . (defined $exp ? $exp : '');
    }, 'DecimalLiteral';
}

sub NumericLiteral {
    bless sub {
        my $chars = shift;
        DecimalLiteral->($chars)
        || HexIntegreLiteral->($chars);
    }, 'NumericLiteral';
}

sub BooleanLiteral {
    bless sub { 
        my $chars = shift or return;
        return 'true' if index($chars, 'true') == 0;
        return 'false' if index($chars, 'false') == 0;
        undef;
    }, 'BooleanLiteral';
} 

sub NullLiteral { 
    bless sub { 
        my $chars = shift or return;
        return 'null' if index($chars, 'null') == 0;
        undef;
    }, 'NullLiteral';
}

sub StringLiteral {
    bless sub {
        my $chars = shift;
    }, 'StringLiteral';
}

sub RegularExpressionFirstChar {
    bless sub {
        my $chars = shift;
        my $non_term = RegularExpressionNonTerminator->($chars);
        if ($non_term) {
        }
    }, 'RegularExpressionFirstChar';
}

sub RegularExpressionChar {
    bless sub {
    }, 'RegularExpressionChar';
}

sub RegularExpressionTags {
    bless sub { 
        my $chars = shift;
    }, 'RegularExpressionTags';
}

sub RegularExpressionBody {
    bless sub {
        my $chars = shift;
        my $first = RegularExpressionFirstChar->($chars) or return;
        $chars = RegularExpressionChars->($chars) or return;
        $first . $chars;
    }, 'RegularExpressionBody';
}

sub RegularExpressionLiteral {
    bless sub {
        my $chars = shift;
        my $r = qr/^\//o;
        return unless $chars =~ $r;
        my $body = RegularExpressionBody->($chars) or return;
        $chars = substr $chars, 1;
        return unless $chars =~ $r;
        my $flags = RegularExpressionTags->($chars) or return;
        "/$body/$flags";
    }, 'RegularExpressionLiteral';
}

sub Literal {
    bless sub {
        my $chars = shift;
        NullLiteral->($chars)
        || BooleanLiteral->($chars)
        || NumericLiteral->($chars)
        || StringLiteral->($chars)
        || RegularExpressionLiteral->($chars);
    }, 'Literal';
}

sub SignedInteger {
    bless sub {
        my $chars = shift or return;
        $chars =~ m/^(\+|\-)/o;
        my $sign = $1;
        $chars = substr $chars, 1 if $sign;
        my $digits = DecimalDigits->($chars) or return;
        ($sign ? $sign : '') . $digits;
    }, 'SignedInteger';
}

sub ExponentIndicator {
    bless sub { 
        my $chars = shift or return;
        $chars =~ /^(e|E)/o; $1;
    }, 'ExponentIndicator';
}

sub ExponentPart {
    bless sub {
        my $chars = shift or return;
        my $indicator = ExponentIndicator->($chars) or return;
        $chars = substr $chars, 1;
        my $signed = SignedInteger->($chars) or return;
        $indicator . $signed;
    }, 'ExponentPart';
}

sub Punctuator {
    my $or = quotemeta join '|', (
        '{', '}', '(', ')', '[', ']', '.', ';', ',', '<',
        '>=', '==', '!=', '===', '+', '-', '*', '%', '<<',
        '>>', '>>>', '&', '!', '~', '&&', '||', '=', '+=',
        '-=', '*=', '>>=', '>>>=', '&=', '|='
        );
    my $r = qr/$or/o;
    bless sub { shift =~ $r; $1 }, 'Punctuator';
}

sub UnicodeDigit {
    bless sub { shift =~ /^(\d+)/o; $1 }, 'UnicodeDigit';
}

sub UnicodeLetter { 
    bless sub { Word->(shift) }, 'UnicodeLetter';
}

sub UnicodeCombiningMark {
    bless sub {
        shift =~ /^[\p{Mn}\p{Mc}]/o; $1;
        }, 'UnicodeCombiningMark';
}

sub UnicodeConnectorPunctuation {
    bless sub {
        shift =~ /^\p{Pc}/o; $1;
        }, 'UnicodeConnectorPunctuation';
}

sub IdentifierStart {
    bless sub {
        my $chars = shift;

        my $letter = UnicodeLetter->($chars);
        return $letter if $letter;

        $chars =~ /^(\$|_)/o;
        return $1 if $1;

        return unless $chars =~ /^\\/o;
        $chars = substr $chars, 1;

        my $seq = UnicodeEscapeSequence->($chars);
        $seq ? "/$seq" : undef;
    }, 'IdentifierStart';
}

sub IdentifierPart {
    bless sub {
        my $chars = shift;

        my $part = IdentifierStart->($chars)
                || UnicodeCombiningMark->($chars)
                || UnicodeDigit->($chars)
                || UnicodeConnectorPunctuation->($chars);
        return $part if $part;

        $chars =~ '\\\\u200C';
        return $1 if $1;

        $chars =~ '\\\\u200D';
        $1;
    }, 'IdentifierPart';
}

sub IdentifierName {
    bless sub {
        my $chars = shift;
        my $start = IdentifierStart->new($chars);
        return $start if $start;
        my $name = &IdenitiferName->($chars) or return;
        my $part = IdentifierPart(substr $chars, length $name);
        $name . $part;
    }, 'IdentifyName';
}

sub Identifier {
    bless sub {
        my $chars = shift;
        return if ReservedWord->($chars);
        IdentifierName->($chars);
    }, 'Identifier';
}

sub Keyword {
    my $or = join '|', (qw(
        break case catch continue debugger default delete
        do else finally for function if in instanceof typeof
        new var return void switch while this with throw try
        ));
    my $r = qr/$or/o;
    bless sub { shift =~ $r; $1 }, 'Keyword';
}

sub FutureReservedWord {
    my $or = join '|', (qw(
        class enum extends super const export import 
        implements let private public interface package 
        protected static yield
        ));
    bless sub {
    }, 'FutureReservedWord';
}

sub ReservedWord {
    bless sub {
        my $chars = shift;
        Keyword->($chars)
        || FutureReservedWord->($chars)
        || NullLiteral->($chars)
        || BooleanLiteral->($chars);
    }, 'ReservedWord';
}

sub Token { 
    bless sub {
        my $chars = shift;
        IdentifierName->($chars)
        || Punctuator->($chars)
        || NumericLiteral->($chars)
        || StringLiteral->($chars);
    }, 'Token';
}

sub DivPunctuator { 
    bless sub {
        my $chars = shift;
        return '/=' if index($chars, '/=') == 0;
        return '/'  if index($chars, '/') == 0;
        undef;
    }, 'DivPunctuator';
}

sub InputElementDiv {
    bless sub {
        my $chars = shift;
        WhiteSpace->($chars)
        || LineTerminator->($chars)
        || Comment->($chars)
        || Token->($chars)
        || DivPunctuator->($chars);
    }, 'InputElementDiv';
}

sub InputElementRegExp {
    bless sub {
        my $chars = shift;
        WhiteSpace->($chars)
        || LineTerminator->($chars)
        || Comment->($chars)
        || Token->($chars)
        || RegularExpressionLiteral->($chars);
    } , 'InputElementRegExp';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Javascript::Lexers - Javascript lexers

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
