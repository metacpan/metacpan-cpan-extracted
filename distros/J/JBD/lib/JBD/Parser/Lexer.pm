package JBD::Parser::Lexer;
# ABSTRACT: Provides match() and tokens()
our $VERSION = '0.04'; # VERSION

# match()  - Determines the token (type, value) pair for
#            the given text and associated pattern-matcher
#            subs. Matcher subs array order is important.
#            The first sub that yields a pair is returned.
#
# tokens() - Iterates over match() with its input text, 
#            and chooses whichever token (type, value) pair 
#            match has the longest value (character count).
#            In this manner, input text of '-1.0' with 
#            matcher subs Int and Float defined in
#            JBD::Parser::Lexer::Std would lex like this:
#
#            Int->('-1.0')   --> '-1'   match len: 2.
#            Float->('-1.0') --> '-1.0' match len: 4.
#                ====> Float is chosen.
#
# @author Joel Dalley
# @version 2014/Feb/23

use JBD::Core::stern;
use JBD::Core::Exporter ':omni';

use JBD::Parser::Token 'token';
use Scalar::Util 'reftype';
use Carp 'croak';

# @param mixed Either a string (scalar), or reference to one.
# @return scalarref A reference to the given string.
sub toref($) {
    croak 'Missing required text' unless @_;
    return $_[0] if ref $_[0] eq 'SCALAR';
    croak 'Not a scalar or scalarref!' if ref $_[0];
    \$_[0];
}

# @param scalar/ref $text Unstructured/arbitrary text.
# @param arrayref $matchers Pattern-matcher subs.
# @param coderef [opt] $want Token value requirement sub.
# @return mixed Array of (type, value), or undef.
sub match($$;$) {
    my ($text, $matchers) = (toref shift, shift);
    my $want = shift || sub {defined $_[0]};
    for my $m (@$matchers) {
        my ($mtype, $mref) = (ref $m, reftype $m);

        croak 'Element valued `' . substr($m, 0, 24) . '`'
            . " is not a CODE ref; given text `$$text`"
            unless $mtype;
        croak "Element reference typed `$mtype` in matchers"
            . " array isn't CODE; given text `$$text`" 
            unless $mref eq 'CODE';

        my $v = $m->($$text);
        return [ref $m, $v] if $want->($v);
    }
    undef;
}

# @param scalar/ref $text Unstructured/arbitrary text.
# @param arrayref $matchers Pattern-matcher subs.
# @param coderef [opt] $sift Input token filter, or undef.
# @return scalar: An arrayref of JBD::Parser::Tokens.
#          array: ([JBD::Parser::Token], tokenized text length).
sub tokens($$;$) {
    my ($text, $matchers, $sift) = (toref shift, shift, shift);

    my (@tok, $matched);
    while (length $$text) {
        my @best = ('', '');
        my $pair = match $text, $matchers, sub {
            my $v = shift;
            return unless defined $v;
            length $v > length $best[0] 
        };
        my $lv = ref $pair && length $pair->[1] || 0;
        ref $pair && do {@best = @$pair; $matched += $lv};
        my $lt = defined $$text && length $$text  || 0;

        if ($lv && $lt > $lv) {
            $$text = substr $$text, $lv;
        }
        elsif ($lv && $lt == $lv) {
            $$text = undef;
        }
        elsif (!$lv) {
            $$text = $lt > 1 ? substr $$text, 1 : undef;
        }

        next unless defined $pair->[1] && length $pair->[1];
        push @tok, token shift @best, shift @best;
    }

    @tok = ref $sift ? grep $sift->($_), @tok : @tok;
    wantarray ? (\@tok, $matched) : \@tok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Parser::Lexer - Provides match() and tokens()

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
