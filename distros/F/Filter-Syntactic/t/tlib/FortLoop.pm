package FortLoop;

use 5.022;
use warnings;

use Filter::Syntactic;

filter PerlControlBlock :extend (
    (?>
        fort \b
        (?<SETUP>
            (?>(?&PerlOWS))
            (?:
                (?> # Explicitly aliased iterator variable...
                    (?> \\ (?>(?&PerlOWS))  (?> my | our | state )
                    |                       (?> my | our | state )  (?>(?&PerlOWS)) \\
                    )
                    (?>(?&PerlOWS))
                    (?> (?&PerlVariableScalar)
                    |   (?&PerlVariableArray)
                    |   (?&PerlVariableHash)
                    )
                |
                    # List of scalar iterator variables...
                    my                                   (?>(?&PerlOWS))
                    \(                                   (?>(?&PerlOWS))
                            (?>(?&PerlVariableScalar))   (?>(?&PerlOWS))
                        (?: ,                            (?>(?&PerlOWS))
                            (?>(?&PerlVariableScalar))   (?>(?&PerlOWS))
                        )*+
                        (?: ,                            (?>(?&PerlOWS)) )?+
                    \)

                |
                    # Implicitly aliased iterator variable...
                    (?> (?: my | our | state ) (?>(?&PerlOWS)) )?+
                    (?&PerlVariableScalar)
                )?+
                (?>(?&PerlOWS))
                (?> (?&PerlParenthesesList) | (?&PerlQuotelikeQW) )
            |
                (?&PPR_X_three_part_list)
            )
        )
    )

    (?>(?&PerlOWS)) (?<BLOCK> (?>(?&PerlBlock)) )
)
{
    qq{for $SETUP { state \$n=0; \$n++; pass "iteration \$n passed"; $BLOCK }}
}

1; # Magic true value required at end of module

