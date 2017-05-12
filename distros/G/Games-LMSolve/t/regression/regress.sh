#!/bin/bash

run_lm_solve()
{
    local method="$1"
    local path="$dir/$T"
    (cd ../../ && perl -I./lib ./lm-solve -g $maze_type --rtd --method $method --output-states t/regression/layouts/$path) | md5sum > checksums/$path.$method.md5.new
    if ! cmp checksums/$path.$method.md5.new checksums/$path.$method.md5 ; then
        echo "$method solutions are not equal for $path"
    fi
}

for TYPE in "alice alice" "minotaur minotaur" "plank plank" \
    "hex_plank plank/hex" "plank plank/sample" "numbers number_mazes" \
    "tilt_single tilt/single" "tilt_multi tilt/multi" "tilt_rb tilt/red_blue" \
    ; do
    maze_type=$(sh -c "echo \$0" $TYPE)
    dir=$(sh -c "echo \$1" $TYPE)
    if [ ! -e ./layouts/$dir ] ; then
        echo "$dir does not exist"
    fi
    mkdir -p checksums/$dir
    (cd ./layouts/$dir/; ls) |
        (while read T ; do
            if [ -f ./layouts/$dir/$T ] ; then
                run_lm_solve brfs
                run_lm_solve dfs
            fi
        done
        )
done
