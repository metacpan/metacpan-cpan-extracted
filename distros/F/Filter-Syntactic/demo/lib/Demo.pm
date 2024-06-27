package Demo;

use 5.022;
use warnings;

use Filter::Syntactic;

# Extend an existing rule with a new alternative (which is tried FIRST)...
filter ControlBlock :extend
    (
        DWIM (?&PerlOWS)
        (?<REQUEST> \{ (?&PPR_X_balanced_curlies_interpolated) \} )
    )
    {
        "{ DWIM::Block::_DWIM(qq $REQUEST) }"
    }

# Extend an existing rule with a new alternative (which is tried AFTER)...
filter PerlCall :extend
    # When the new syntax matches...
    (
        (?<ARG> (?&Termlike) )  ->&  (?<SUBNAME> (?&PerlIdentifier) )
        (?(DEFINE)
            (?<Termlike> (?&PerlVariable) | (?&PerlLiteral) )
        )
    )
    # Replace the matched source code with this...
    { "$SUBNAME($ARG)" }

# Replace an existing rule...
filter Label  ( \[ (?>(?&PerlIdentifier)) \] )  { substr($_,1,-1) . ":" }

# Apply a filter to every match of an existing (unchanged) rule...
filter QuotelikeQQ {
    s{ (?: \A qq \s* \S ) | \{ (?<CODE>  (?>(?&PPR_X_balanced_curlies)) ) \}  $PPR::X::GRAMMAR }
     { $+{CODE} ? "\${\\scalar do{ $+{CODE} }}" : $& }gxmsre;
}


warn __LINE__, " (should be 41)";

1; # Magic true value required at end of module
