use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Parser

# ABSTRACT: M4 Marpa parser

#
# Expose only the base implementation of parse() method
# required by MarpaX::Languages::M4::Role::Parser
#
class MarpaX::Languages::M4::Impl::Parser {
    use MarpaX::Languages::M4::Impl::Parser::Actions;
    use MarpaX::Languages::M4::Type::Macro -all;
    use MarpaX::Languages::M4::Impl::Value;
    use Marpa::R2;                               # 2.103_004;
    use Scalar::Util qw/readonly/;
    use Types::Common::Numeric -all;
    #
    # --nesting_limit (SHOULD) take care of that
    #
    no warnings 'recursion';

    our $VERSION = '0.019'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    our $BASE_GRAMMAR = q{
inaccessible is ok by default
:default ::= action => ::first
lexeme default = latm => 1

#
# Note: this part of the grammar is giving ambiguity
#       but we do not mind because the effect is always
#       the same: global concatenatation
#
argumentsGroup ::= tokens                                                      action => createArgumentsGroup rank => 1
                 | argumentsGroup LPAREN argumentsGroup RPAREN  argumentsGroup action => mergeArgumentsGroup

arguments ::= argumentsGroup                   action => firstArg
            | arguments (COMMA) argumentsGroup action => nextArg

tokens ::= token*                      action => create
event '^token' = predicted <token>     # This event is to force $r->read() to not advance its location
event 'token$' = completed <token>
token ::= WORD
        | macro
        | QUOTEDSTRING
        | CHARACTER
        | COMMENT
        | ANYTHING

macro ::= MACRO                        # Never lexeme_read'ed
        | MACRO_ARGS macroArguments    # Ditto

event 'macroArguments$' = completed <macroArguments>
macroArguments ::= (LPAREN) arguments (RPAREN)
macroArguments ::= (NOPARAM)           action => fakeOneVoidParam

_ANYTHING    ~ [\s\S]
_NOTHING     ~ [^\s\S]
WORD         ~ _NOTHING
MACRO        ~ _NOTHING
MACRO_ARGS   ~ _NOTHING
QUOTEDSTRING ~ _NOTHING
CHARACTER    ~ _NOTHING
COMMENT      ~ _NOTHING
#
# ANYTHING will automatically eat a character each time we resume the SLIF: we
# do not want this to happen
#
:lexeme ~ <ANYTHING> pause => before event => '^ANYTHING'
ANYTHING     ~ _ANYTHING

_WS ~ [\s]
_WS_any ~ _WS*

:lexeme ~ <LPAREN> priority => 1 pause => before event => '^LPAREN'
LPAREN ~ '(' _WS_any

:lexeme ~ <RPAREN> priority => 1 pause => before event => '^RPAREN'
RPAREN ~ ')'

:lexeme ~ <NOPARAM> priority => 1
NOPARAM ~ '(' _WS_any ')'

#
# Quote from the spec (M4 POSIX):
# If a macro name is followed by a <left-parenthesis>, its arguments are the <comma>-separated tokens
# between the <left-parenthesis> and the matching <right-parenthesis>. Unquoted white-space characters
# preceding each argument shall be ignored. All other characters, including trailing white-space characters,
# are retained.
# <comma> characters enclosed between <left-parenthesis> and <right-parenthesis> characters do not delimit arguments.

:lexeme ~ <COMMA> priority => 1
COMMA ~ ',' _WS_any
};

    our $BYTOKEN_G = do {
        my $g = Marpa::R2::Scanless::G->new(
            {   source => \do {":start ::= tokens\n$BASE_GRAMMAR"}
            }
        );
    };
    our $BYMACROARGUMENTS_G = do {
        my $g = Marpa::R2::Scanless::G->new(
            {   source => \do {":start ::= macroArguments\n$BASE_GRAMMAR"}
            }
        );
    };

    BEGIN {
      #
      # Marpa internal optimisation: we do not want the closures to be rechecked every time
      # we call $r->value(). This is a static information, although determined at run-time
      # the first time $r->value() is called on a recognizer.
      #
      no warnings 'redefine';

      sub Marpa::R2::Recognizer::registrations {
        my $recce = shift;
        if (@_) {
          my $hash = shift;
          if (! defined($hash) ||
              ref($hash) ne 'HASH' ||
              grep {! exists($hash->{$_})} qw/
                                               NULL_VALUES
                                               REGISTRATIONS
                                               CLOSURE_BY_SYMBOL_ID
                                               CLOSURE_BY_RULE_ID
                                               RESOLVE_PACKAGE
                                               RESOLVE_PACKAGE_SOURCE
                                               PER_PARSE_CONSTRUCTOR
                                             /) {
            Marpa::R2::exception(
                                 "Attempt to reuse registrations failed:\n",
                                 "  Registration data is not a hash containing all necessary keys:\n",
                                 "  Got : " . ((ref($hash) eq 'HASH') ? join(', ', sort keys %{$hash}) : '') . "\n",
                                 "  Want: CLOSURE_BY_RULE_ID, CLOSURE_BY_SYMBOL_ID, NULL_VALUES, PER_PARSE_CONSTRUCTOR, REGISTRATIONS, RESOLVE_PACKAGE, RESOLVE_PACKAGE_SOURCE\n"
                                );
          }
          $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES] = $hash->{NULL_VALUES};
          $recce->[Marpa::R2::Internal::Recognizer::REGISTRATIONS] = $hash->{REGISTRATIONS};
          $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_SYMBOL_ID] = $hash->{CLOSURE_BY_SYMBOL_ID};
          $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_RULE_ID] = $hash->{CLOSURE_BY_RULE_ID};
          $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE] = $hash->{RESOLVE_PACKAGE};
          $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE] = $hash->{RESOLVE_PACKAGE_SOURCE};
          $recce->[Marpa::R2::Internal::Recognizer::PER_PARSE_CONSTRUCTOR] = $hash->{PER_PARSE_CONSTRUCTOR};
        }
        return {
                NULL_VALUES => $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES],
                REGISTRATIONS => $recce->[Marpa::R2::Internal::Recognizer::REGISTRATIONS],
                CLOSURE_BY_SYMBOL_ID => $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_SYMBOL_ID],
                CLOSURE_BY_RULE_ID => $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_RULE_ID],
                RESOLVE_PACKAGE => $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE],
                RESOLVE_PACKAGE_SOURCE => $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE],
                PER_PARSE_CONSTRUCTOR => $recce->[Marpa::R2::Internal::Recognizer::PER_PARSE_CONSTRUCTOR]
               };
      } ## end sub registrations

      sub Marpa::R2::Scanless::R::registrations {
        my $slr = shift;
        my $thick_g1_recce =
          $slr->[Marpa::R2::Internal::Scanless::R::THICK_G1_RECCE];
        return $thick_g1_recce->registrations(@_);
      } ## end sub Marpa::R2::Scanless::R::registrations

    }

    has _parse_level => (
        is  => 'rwp',
        isa => PositiveOrZeroInt,

        # trigger => 1,
        default => 0
    );

    method _trigger__parse_level (PositiveOrZeroInt $parse_level, @rest) {
            #
            # GNU testing of nesting_limit is another implementation, this
            # has no meaning for us. So, even if supported, this option does
            # nothing: the trigger is NOT enabled.
            #
        my $nesting_limit = $self->impl_nestingLimit;
        if ( $nesting_limit > 0 && $parse_level > $nesting_limit ) {
            $self->impl_raiseException(
                sprintf( 'Nesting limit of %d exceeded', $nesting_limit ) );
        }
    }

    method parser_parse (Str $input --> Str) {
            #
            # We will modify the buffer in-place, therefore we want to
            # have OUR version of the input.
            # In addition, this will solve the eventual problem of $input
            # being a read-only variable
            #
        my $work = $input;
        return $self->_parseByTokens( \$work );
    }

 #
 # By token => ConsumerOf['MarpaX::Languages::M4::Role::Value by default']
 # By arguments =>  ArrayRef[ConsumerOf['MarpaX::Languages::M4::Role::Value']]
 #
    method _parseByGrammar (Ref['SCALAR'] $inputRef, PositiveOrZeroInt $pos, InstanceOf['Marpa::R2::Scanless::G'] $g, Undef|M4Macro $macro? --> Undef|Dict[pos => PositiveOrZeroInt, value => ConsumerOf['MarpaX::Languages::M4::Role::Value']]) {

        my $maxPos = length( ${$inputRef} ) - 1;
        #
        # Protect the case of empty string.
        # This is affecting all parsing levels.
        #
        if ( $pos > $maxPos ) {
            return;
        }
        #
        # Get the lexemes ordering
        #
        my @lexemeNames = $self->parser_tokensPriority();
        #
        # In the context of a macroArguments, unquoted parenthesis
        # have higher priorities over everything, except quoted string
        # and comment.
        #
        if ( $g == $BYMACROARGUMENTS_G ) {
            unshift( @lexemeNames, 'NOPARAM', 'LPAREN', 'RPAREN', 'COMMA' );
        }

        my $value = MarpaX::Languages::M4::Impl::Value->new();
        my %rc = ( pos => $pos, value => $value );

        #
        # Instanciate and start recognizer
        #
        my $r = Marpa::R2::Scanless::R->new(
            {   grammar => $g,
                semantics_package => 'MarpaX::Languages::M4::Impl::Parser::Actions',
                exhaustion => 'event',

                # trace_terminals => 1,
                # trace_values => 1
            }
        );
        #
        # $prevPos is used only for logging
        #
        my $prevPos = $rc{pos} = $pos;
        #
        # The stream itself is of no importance.
        # We use Marpa to drive the context, nothing more.
        # But is it NOT a hasard that I use the constant '(':
        # when doing a recursive call using
        # the macroByarguments grammar, Marpa will expect this
        # character at the first read, EVEN
        # if we paused before it.
        #
        $r->read( \'(' );

    again:
        while ( $rc{pos} <= $maxPos ) {

            # $self->logger_debug( '[%d..%d/%d] 20 first characters: %s',
            #     $rc{pos}, $rc{pos}, $maxPos,
            #     substr( ${$inputRef}, $rc{pos}, 20 ) );

            my %expected = map { $_ => 1 } @{ $r->terminals_expected };

            # $self->logger_debug(
            #    '[%d..%d/%d] Expected terminals: %s',
            #    $rc{pos}, $rc{pos}, $maxPos,
            #    [ keys %expected ]
            # );

            if ( $r->exhausted ) {

                # $self->logger_debug( '[%d..%d/%d] Parse is exhausted',
                #     $rc{pos}, $rc{pos}, $maxPos );

                last;
            }

            my $lexemeValue;
            my $lexemeLength;
            my $lexeme;

            my $QuotedstringValue;
            my $QuotedstringLength;
            my $isQuotedString = false;

            my $CommentValue;
            my $CommentLength;
            my $isComment = false;

            my $canCollectArguments = true;
            if ( $g == $BYMACROARGUMENTS_G ) {
                my $blockOk = false;
                try {
                    $isQuotedString
                        = $self->parser_isQuotedstring( ${$inputRef},
                        $rc{pos},
                        $maxPos, \$QuotedstringValue, \$QuotedstringLength );
                    $isComment
                        = $self->parser_isComment( ${$inputRef}, $rc{pos},
                        $maxPos, \$CommentValue, \$CommentLength );
                    $canCollectArguments = !$isQuotedString && !$isComment;
                    $blockOk = true;
                };
                if ( !$blockOk ) {
                    goto return_error;
                }
            }

            foreach (@lexemeNames) {
                if ( $_ eq 'NOPARAM' ) {
                    if ( exists( $expected{NOPARAM} )
                        && $canCollectArguments )
                    {
                        pos( ${$inputRef} ) = $rc{pos};
                        if ( ${$inputRef} =~ /\G\(\s*\)/s ) {
                            $lexeme = 'NOPARAM';
                            $lexemeValue = substr( ${$inputRef}, $-[0],
                                $+[0] - $-[0] );
                            $lexemeLength = $+[0] - $-[0];
                            last;
                        }
                    }
                }
                elsif ( $_ eq 'LPAREN' ) {
                    if (   exists( $expected{LPAREN} )
                        && $canCollectArguments
                        && do { pos( ${$inputRef} ) = $rc{pos}; 1 }
                        && ${$inputRef} =~ /\G\(\s*/
                        )
                    {
                        $lexeme       = 'LPAREN';
                        $lexemeLength = $+[0] - $-[0];
                        $lexemeValue
                            = substr( ${$inputRef}, $-[0], $lexemeLength );
                        last;
                    }
                }
                elsif ( $_ eq 'RPAREN' ) {
                    if (   exists( $expected{RPAREN} )
                        && $canCollectArguments
                        && substr( ${$inputRef}, $rc{pos}, 1 ) eq ')' )
                    {
                        $lexeme       = 'RPAREN';
                        $lexemeValue  = ')';
                        $lexemeLength = 1;
                        last;
                    }
                }
                elsif ( $_ eq 'COMMA' ) {
                    if ( exists( $expected{COMMA} ) && $canCollectArguments )
                    {
                        pos( ${$inputRef} ) = $rc{pos};
                        if ( ${$inputRef} =~ /\G,\s*/s ) {
                            $lexeme = 'COMMA';
                            $lexemeValue = substr( ${$inputRef}, $-[0],
                                $+[0] - $-[0] );
                            $lexemeLength = $+[0] - $-[0];
                            last;
                        }
                    }
                }
                else {
                    if ( $g == $BYMACROARGUMENTS_G && $_ eq 'QUOTEDSTRING' ) {
                      #
                      # Already done in the context of macro arguments grammar
                      #
                        if ($isQuotedString) {
                            $lexeme       = $_;
                            $lexemeValue  = $QuotedstringValue;
                            $lexemeLength = $QuotedstringLength;
                            last;
                        }
                    }
                    elsif ( $g == $BYMACROARGUMENTS_G && $_ eq 'COMMENT' ) {
                      #
                      # Already done in the context of macro arguments grammar
                      #
                        if ($isComment) {
                            $lexeme       = $_;
                            $lexemeValue  = $CommentValue;
                            $lexemeLength = $CommentLength;
                            last;
                        }
                    }
                    else {
                        #
                        # QUOTEDSTRING is not already done if not
                        # in the context of macro arguments grammar
                        # Ditto for COMMENT.
                        #
                        my $method  = 'parser_is' . ucfirst( lc($_) );
                        my $blockOk = false;
                        my $isToken;
                        try {
                            $isToken = $self->$method( ${$inputRef}, $rc{pos},
                                $maxPos, \$lexemeValue, \$lexemeLength );
                            $blockOk = true;
                        };
                        if ( !$blockOk ) {
                            goto return_error;
                        }
                        if ($isToken) {
                            $lexeme = $_;
                            last;
                        }
                    }
                }
            }
            #
            # Nothing ?
            #
            if ( Undef->check($lexeme) ) {
                goto return_error;
            }
            #
            # If it is a word, check if this is eventually a macro
            #
            if ( $lexeme eq 'WORD' ) {
                my $thisMacro;
                my $lparenPos;
                if ($self->parser_isMacro(
                        ${$inputRef}, $rc{pos},      $maxPos,
                        $lexemeValue, $lexemeLength, \$thisMacro,
                        \$lparenPos
                    )
                    )
                {
                    my $canTrace = $self->_canTrace($thisMacro);
                    my $macroCallId
                        = $self->impl_macroExecuteHeader( $thisMacro,
                        $canTrace );
                    #
                    # Collect macro arguments
                    #
                    my @args = ();

                    if ( $lparenPos >= 0 ) {

                        $self->_set__parse_level( $self->_parse_level + 1 );
                        my $dict = $self->_parseByGrammar(
                            $inputRef,           $lparenPos,
                            $BYMACROARGUMENTS_G, $thisMacro
                        );
                        $self->_set__parse_level( $self->_parse_level - 1 );
                        if ( Undef->check($dict) ) {
                            goto return_error;
                        }
                        @args         = $dict->{value}->value_elements;
                        $lexemeLength = $dict->{pos} - $rc{pos};
                    }
                    #
                    # It is the reponsability of implementation to make sure
                    # that a macro never croaks.
                    #
                    $lexemeValue
                        = $self->impl_macroExecuteNoHeader( $thisMacro,
                        $macroCallId, $canTrace, @args );
                    #
                    # Eventual postmatch length
                    #
                    $lexemeLength
                        += $thisMacro->macro_postMatchLengthExecute( $self,
                        ${$inputRef}, $rc{pos} + $lexemeLength, $maxPos );
                    #
                    # Input is changing
                    #
                    if ( M4Macro->check($lexemeValue) ) {
                        #
                        # Protect the case of M4Macro
                        #
                        $lexeme = 'ANYTHING';
                    }
                    else {
                       # $self->logger_debug(
                       #    '[%d..%d/%d] Input is changing: replace %s by %s',
                       #    $rc{pos},
                       #    $rc{pos},
                       #     $maxPos,
                       #     substr(
                       #         ${$inputRef}, $rc{pos}, $lexemeLength
                       #     ),
                       #     $lexemeValue
                       # );
                        substr(
                            ${$inputRef},  $rc{pos},
                            $lexemeLength, $lexemeValue
                        );

                        # $self->logger_debug( '[%d..%d/%d] New input: %s',
                        #     $rc{pos}, $rc{pos}, $maxPos, ${$inputRef} );

                        $maxPos = length( ${$inputRef} ) - 1;
                        goto again;
                    }
                }
                else {
                    # $self->logger_debug(
                    #     '[%d..%d/%d] %s is not an acceptable macro call',
                    #     $rc{pos}, $rc{pos}, $maxPos, $lexemeValue );
                }
            }
            #
            # When _parse_level is zero, the current token has been fully
            # parsed, and its output is to
            # to be immediately "flushed".
            # We do not need to do a lexeme_read(), nor a resume in this case:
            # we know where we are.
            #
            if ( $self->_parse_level > 0 ) {
                $r->lexeme_read( $lexeme, 0, 1, $lexemeValue );
                $prevPos = $rc{pos};
                $rc{pos} += $lexemeLength;

                # $self->logger_debug( '[%d->%d/%d] %s: %s',
                #     $prevPos, $rc{pos}, $maxPos, $lexeme, $lexemeValue );

                #
                # We can safely ignore the events from lexeme_read(),
                # because we made sure in the grammar that resume() will
                # NOT advance the position, thanks to those events:
                #
                # ^token
                # ^ANYTHING
                # macroArguments$
                # token$
                #
                # macroArguments$, if it happens will always be standalone.
                # token$, when it happen, can be mixed with ^token or
                # ^ANYTHING.
                #
                # Please note that we do not use resume().
                #
            }
            else {
                #
                # We are at the top level: flush to current diversion
                #
                # $self->logger_debug( '[%d->%d/%d] %s: %s',
                #     $prevPos, $rc{pos}, $maxPos, $lexeme, $lexemeValue );

                my $tmpValue = MarpaX::Languages::M4::Impl::Value->new()
                    ->value_push($lexemeValue);
                $self->impl_appendValue(
                    $tmpValue->value_concat->value_firstElement );
                $prevPos = $rc{pos};
                $rc{pos} += $lexemeLength;
            }
        }

        if ( $self->_parse_level > 0 ) {
            #
            # We are in the context of a recursive call: the output
            # is of concern for a macro that called us.
            #
            local $MarpaX::Languages::M4::Impl::Parser::macro = $macro;
            #
            # For $r->value() optimisations
            #
            state $registrations = undef;

            if (defined($registrations)) {
              $r->registrations($registrations);
            }
            my $valueRef = $r->value;
            if (! defined($registrations)) {
              $registrations = $r->registrations();
            }
            if ( Undef->check($valueRef) || Undef->check( ${$valueRef} ) ) {
                goto return_error;
            }

            $rc{value} = ${$valueRef};
        }
        else {
            #
            # We are at the top level: the output has already been
            # "flushed" to whatever the current diversion said to.
            #
        }

        # $self->logger_debug( '[%d..%d/%d] => %s',
        #     $rc{pos}, $rc{pos}, $maxPos, \%rc );

        return \%rc;

    return_error:
        #
        # We propagate the undef to all levels except number 0
        #
        if ( $self->_parse_level > 0 ) {
            if ( $self->_parse_level == 1 && $self->impl_eoi ) {
                #
                # We want the parsing to stop now
                #
                $self->impl_raiseException('EOF during argument collection');
            }
            return;
        }
        else {
            return \%rc;
        }
    }

    #
    # M4 says that a token is processed as soon as it is recognized.
    # So we loop on token recognition
    #
    method _parseByTokens (Ref['SCALAR'] $inputRef --> Str) {

        my $rc = $self->_parseByGrammar( $inputRef, 0, $BYTOKEN_G );
        if ( !Undef->check($rc) ) {
            return substr( ${$inputRef}, $rc->{pos} );
        }

        return ${$inputRef};
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Parser - M4 Marpa parser

=head1 VERSION

version 0.019

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
