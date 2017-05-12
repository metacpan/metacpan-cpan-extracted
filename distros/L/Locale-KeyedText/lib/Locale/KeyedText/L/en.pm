use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

# Constant values used by packages in this file:
my $TEXT_STRINGS = {
    # This group of strings is generic and can be used by any package:

    'LKT_ARGS_BAD_PSEUDO_NAMED'
        => q[<CLASS>.<METH>(): bad pseudo-named arguments list;]
            . q[ it must have an even number of positional elements.],

    'LKT_ARG_UNDEF'
        => q[<CLASS>.<METH>(): argument <ARG> is undefined (or missing).],
    'LKT_ARG_NO_ARY'
        => q[<CLASS>.<METH>(): argument <ARG> is not an Array ref,]
           . q[ but rather contains '<VAL>'.],
    'LKT_ARG_NO_HASH'
        => q[<CLASS>.<METH>(): argument <ARG> is not a Hash ref,]
           . q[ but rather contains '<VAL>'.],
    'LKT_ARG_NO_EXP_TYPE'
        => q[<CLASS>.<METH>(): argument <ARG> is not a <EXP_TYPE>,]
           . q[ but rather contains '<VAL>'.],

    'LKT_ARG_ARY_ELEM_UNDEF'
        => q[<CLASS>.<METH>(): argument <ARG> is an Array ref as expected,]
           . q[ but one of its elements is undefined.],
    'LKT_ARG_ARY_ELEM_NO_ARY'
        => q[<CLASS>.<METH>(): argument <ARG> is an Array ref as expected,]
           . q[ but one of its elements is not an Array ref,]
           . q[ but rather contains '<VAL>'.],
    'LKT_ARG_ARY_ELEM_NO_HASH'
        => q[<CLASS>.<METH>(): argument <ARG> is an Array ref as expected,]
           . q[ but one of its elements is not a Hash ref,]
           . q[ but rather contains '<VAL>'.],
    'LKT_ARG_ARY_ELEM_NO_EXP_TYPE'
        => q[<CLASS>.<METH>(): argument <ARG> is an Array ref as expected,]
           . q[ but one of its elements is not a <EXP_TYPE>,]
           . q[ but rather contains '<VAL>'.],

    'LKT_ARG_HASH_VAL_UNDEF'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but the value for its '<KEY>' key is undefined.],
    'LKT_ARG_HASH_VAL_NO_ARY'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but the value for its '<KEY>' key is not an Array ref,]
           . q[ but rather contains '<VAL>'.],
    'LKT_ARG_HASH_VAL_NO_HASH'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but the value for its '<KEY>' key is not a Hash ref,]
           . q[ but rather contains '<VAL>'.],
    'LKT_ARG_HASH_VAL_NO_EXP_TYPE'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but the value for its '<KEY>' key is not a <EXP_TYPE>,]
           . q[ but rather contains '<VAL>'.],

    'LKT_ARG_ARY_NO_ELEMS'
        => q[<CLASS>.<METH>(): argument <ARG> is an Array ref as expected,]
           . q[ but it has no elements.],
    'LKT_ARG_HASH_NO_ELEMS'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but it has no elements.],

    'LKT_ARG_EMP_STR'
        => q[<CLASS>.<METH>(): argument <ARG> is an empty string.],
    'LKT_ARG_ARY_ELEM_EMP_STR'
        => q[<CLASS>.<METH>(): argument <ARG> is an Array ref as expected,]
           . q[ but one of its elements is an empty string.],
    'LKT_ARG_HASH_KEY_EMP_STR'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but one of its keys is an empty string.],
    'LKT_ARG_HASH_VAL_EMP_STR'
        => q[<CLASS>.<METH>(): argument <ARG> is a Hash ref as expected,]
           . q[ but the value for its '<KEY>' key is an empty string.],

    # This group of strings is specific to Locale::KeyedText itself:

    'LKT_T_FAIL_LOAD_TMPL_MOD'
        => q[<CLASS>.<METH>(): can't load Locale::KeyedText Template]
           . q[ module '<TMPL_MOD_NAME>': <REASON>],
    'LKT_T_FAIL_GET_TMPL_TEXT'
        => q[<CLASS>.<METH>(): can't invoke get_text_by_key() on]
           . q[ Locale::KeyedText Template module '<TMPL_MOD_NAME>':]
           . q[ <REASON>],
};

###########################################################################
###########################################################################

{ package Locale::KeyedText::L::en; # module
    BEGIN {
        our $VERSION = '2.001000';
        $VERSION = eval $VERSION;
    }
    sub get_text_by_key {
        my (undef, $msg_key) = @_;
        return $TEXT_STRINGS->{$msg_key};
    }
} # module Locale::KeyedText::L::en

###########################################################################
###########################################################################

1;
