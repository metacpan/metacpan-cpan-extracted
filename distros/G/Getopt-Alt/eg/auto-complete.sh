#!/bin/bash

# to use this for your own code all you should need to do is change the
# eg/auto-complete.pl to your scripts name and rename the function.
_auto-complete() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    local sonames=$(eg/auto-complete.pl --auto-complete ${COMP_WORDS[@]} -- ${cur})
    COMPREPLY=($(compgen -W "${sonames}" -- ${cur}))
}
complete -F _auto-complete eg/auto-complete.pl

