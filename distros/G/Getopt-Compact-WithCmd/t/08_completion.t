use strict;
use warnings;
use Test::More;

use File::Basename qw/basename/;
use Getopt::Compact::WithCmd;

sub test_completion {
    my %specs = @_;
    my ($args, $expects, $command, $desc, $extra_test, $argv)
        = @specs{qw/args expects command desc extra_test argv/};

    $expects =~ s/%FILE%/basename($0)/gmse;

    $command ||= 'bash';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $desc => sub {
        local @::ARGV = @$argv if $argv;
        my $go = new_ok 'Getopt::Compact::WithCmd', [%$args];

        my @got     = split "\n", +$go->completion($command);
        my @expects = split "\n", $expects;
        is_deeply \@got, \@expects, 'completion';

        if ($extra_test) {
            $extra_test->($go);
        }

        # open my $fh, '>', "g/".Test::More->builder->current_test or die $!;
        # print {$fh} join("\n",@got)."\n";
        # close $fh;

        done_testing;
    };
}

test_completion(
    args => {},
    desc => 'empty params',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {},
    command => 'zsh',
    desc => 'empty params not bash',
    expects => << 'COMP');
COMP

test_completion(
    args => {
        args => 'ARGS',
    },
    desc => 'with args',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        cmd => 'foo',
    },
    desc => 'with cmd',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        name => 'foo',
    },
    desc => 'with name',
    expects => << 'COMP');
_foo() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _foo foo
COMP

test_completion(
    args => {
        name => 'foo',
        version => '1.0',
    },
    desc => 'with name, version',
    expects => << 'COMP');
_foo() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _foo foo
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    desc => 'with global_struct',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        COMP => 0,
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    desc => 'with global_struct (COMP: 0)',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
    },
    desc => 'with global_struct (foo is required)',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        -f|--foo)
          COMPREPLY=($(compgen -W "Bool" -- "$cur"))
          ;;
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
    },
    desc => 'with global_struct (foo is required) / set help',
    argv => [qw/--help/],
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        -f|--foo)
          COMPREPLY=($(compgen -W "Bool" -- "$cur"))
          ;;
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

{
    test_completion(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \my $foo, { required => 1 } ],
            ],
        },
        desc => 'with global_struct (foo is required and dest)',
        expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        -f|--foo)
          COMPREPLY=($(compgen -W "Bool" -- "$cur"))
          ;;
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP
}

{
    test_completion(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \my $foo, { required => 1 } ],
            ],
        },
        desc => 'with global_struct (foo is required and set dest)',
        argv => [qw/--foo/],
        expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        -f|--foo)
          COMPREPLY=($(compgen -W "Bool" -- "$cur"))
          ;;
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP
}

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    desc => 'with global_struct / command_struct (impl hoge)',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="hoge"

  case "$cmd" in
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv => [qw/help/],
    desc => 'with global_struct / command_struct (impl hoge) / help command',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        -f|--foo)
          COMPREPLY=($(compgen -W "Bool" -- "$cur"))
          ;;
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP
test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv => [qw/help/],
    desc => 'with global_struct / command_struct (impl hoge) / help command',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        -f|--foo)
          COMPREPLY=($(compgen -W "Bool" -- "$cur"))
          ;;
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge'
            },
        },
    },
    desc => 'with global_struct / command_struct (impl hoge (desc))',
    argv => [qw/help hoge/],
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge) / command mode',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args    => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv    => [],
    desc    => 'with global_struct / command_struct (impl hoge) / args hoge',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="hoge"

  case "$cmd" in
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                args => 'FILE',
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge (args)) / command mode',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help FILE" -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                args => 'FILE',
                options => [
                    [ [qw/o output/] , 'output' ],
                ],
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge (args, options)) / command mode',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -o --output"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help -h --help -o --output FILE" -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                args => 'FILE',
                options => [
                    [ [qw/o output/] , 'output' ],
                ],
                other_COMP => 'blah blah blah',
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge (args, options other_COMP)) / command mode',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -o --output"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help -h --help -o --output FILE" -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
            },
        },
    },
    argv => [qw/fuga/],
    desc => 'with global_struct / command_struct (impl hoge (desc)) / Unknown command',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
            },
        },
    },
    argv => [qw/--hoge hoge/],
    desc => 'with global_struct / command_struct (impl hoge (desc)) / Unknown option',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="hoge"

  case "$cmd" in
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                options => [
                    [ [qw/b bar/], 'bar' ],
                ],
            },
        },
    },
    argv => [qw/hoge --hoge/],
    desc => 'with global_struct / command_struct (impl hoge (desc options)) / Unknown option',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -b --bar"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help -h --help -b --bar " -- "$cur"))
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', undef, undef, { default => sub {} } ],
        ],
    },
    argv => [qw/hoge --hoge/],
    desc => 'with global_struct / Invalid default option',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds=""

  case "$cmd" in
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                other_COMP => 'blah blah blah',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                    },
                },
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = hoge',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "${cmd[1]}" in
        fuga)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help -b --bar " -- "$cur"))
              ;;
          esac
          ;;
        *)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help  fuga" -- "$cur"))
              ;;
          esac
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_COMP => 'blah blah blah',
                    },
                },
            },
        },
    },
    argv => [qw/hoge fuga/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = hoge, fuga',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -b --bar"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "${cmd[1]}" in
        fuga)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help -h --help -b --bar " -- "$cur"))
              ;;
          esac
          ;;
        *)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help  fuga help" -- "$cur"))
              ;;
          esac
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_COMP => 'blah blah blah',
                    },
                },
            },
        },
    },
    argv => [qw/help hoge/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = help, hoge, fuga',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "${cmd[1]}" in
        fuga)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help -b --bar " -- "$cur"))
              ;;
          esac
          ;;
        *)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help  fuga" -- "$cur"))
              ;;
          esac
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_COMP => 'blah blah blah',
                    },
                },
            },
        },
    },
    argv => [qw/help hoge fuga/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = help, hoge, fuga',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="help hoge"

  case "$cmd" in
    help)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "-h --help [COMMAND]" -- "$cur"))
          ;;
      esac
      ;;
    hoge)
      case "${cmd[1]}" in
        fuga)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help -b --bar " -- "$cur"))
              ;;
          esac
          ;;
        *)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help  fuga" -- "$cur"))
              ;;
          esac
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

test_completion(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_COMP => 'blah blah blah',
                    },
                },
            },
        },
    },
    run_ok  => 1,
    desc    => 'with global_struct / command_struct (impl hoge -> fuga) / command = hoge, fuga',
    expects => << 'COMP');
_08_completion_t() {
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

  local global_opts="-h --help -f --foo"
  local cmds="hoge"

  case "$cmd" in
    hoge)
      case "${cmd[1]}" in
        fuga)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help -b --bar " -- "$cur"))
              ;;
          esac
          ;;
        *)
          case "$prev" in
            *)
              COMPREPLY=($(compgen -W "-h --help  fuga" -- "$cur"))
              ;;
          esac
          ;;
      esac
      ;;
    *)
      case "$prev" in
        *)
          COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))
          ;;
      esac
      ;;
  esac
}

complete -F _08_completion_t 08_completion.t
COMP

done_testing;
