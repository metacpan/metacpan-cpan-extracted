#!/usr/bin/env bats

load test_helper.bash

# Test: getoptlong command - --version shows the library version
@test "getoptlong command: --version" {
    run $BASH <<'    END'
        . ../script/getoptlong.sh -
        expected=$(getoptlong version)
        [[ $(../script/getoptlong --version) == "$expected" ]] && echo "$expected"
    END
    assert_success
    assert_output --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
}

# Test: getoptlong command - template with the given array name
@test "getoptlong command: template with array name" {
    run ../script/getoptlong MYOPTS
    assert_success
    assert_line '# declare -A MYOPTS=('
    assert_line '. getoptlong.sh MYOPTS "$@"'
}

# Test: getoptlong function - no subcommand under set -u
@test "getoptlong function: no subcommand" {
    run $BASH <<'    END'
        . ../script/getoptlong.sh -
        getoptlong
    END
    assert_failure
    assert_output "unknown subcommand -- "
}

# Test: help - script path with spaces
@test "getoptlong function: help with script path containing spaces" {
    tmp=$(mktemp -d)
    dir="$tmp/a b"
    mkdir -p "$dir"
    cat > "$dir/my cmd.sh" <<'    END'
        . ../script/getoptlong.sh -
        declare -A OPTS=([foo|f]=)
        getoptlong init OPTS
        getoptlong help | head -1
    END
    run $BASH "$dir/my cmd.sh"
    rm -rf "$tmp"
    assert_success
    assert_output "my cmd.sh [ options ] args"
}
