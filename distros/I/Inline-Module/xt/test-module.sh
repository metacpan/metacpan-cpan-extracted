#!/usr/bin/env bash

test_module() {
  [ -n "$test_dir" ] || die "'\$test_dir' not set"
  if [ ! -e "$test_dir" ]; then
    if [ ! -e "$test_repo_url" ]; then
      local github_repo="https://github.com/$test_author/$test_dir"
      local test_repo="${test_repo_url%/.git}"
      if [ -z "$CLONE_OK" ]; then
        cat <<...
The repo '$test_repo' is missing. Either run:

  git clone $github_repo $test_repo

or rerun this command with the env var:

  CLONE_OK=1

…
...
        exit 1
      fi
      git clone "$github_repo" "$test_repo" &>out || die "$(cat out)"
      # Get all remote branches:
      (
        cd "$test_repo"
        git branch -a |
          cut -c3- |
          grep ^remotes/ |
          cut -d' ' -f1 |
          cut -d/ -f3- |
          grep -v HEAD |
          xargs -n1 git checkout -q
        git checkout -q master
      )
    fi
    git clone $test_repo_url &>out || die "$(cat out)"
  fi
  [ -e "$test_dir" ] || die "'$test_dir' does not exist"
  local test_home="$(pwd)"
  if [ -n "$test_inline_build_dir" ]; then
    inline_module=true
  else
    inline_module=false
  fi

  note "Testing '$test_dir' branch '$test_branch'"
  cd "$test_dir"
  git clean -dxf &>out || die "$(cat out)"
  git checkout "$test_branch" &>out || die "$(cat out)"

  {
    for cmd in "${test_prove_run[@]}"; do
      $cmd &>>out || die "$(cat out)"
    done
    pass "Acme::Math::XS ($test_branch) passes its tests w/ prove"
    if $inline_module; then
      ok "`[ -e "$test_inline_build_dir" ]`" \
        "$test_inline_build_dir exists after testing"
    fi
  }

  {
    git clean -dxf &>out || die "$(cat out)"
    if [ -n "$test_test_run" ]; then
      for cmd in "${test_test_run[@]}"; do
        $cmd &>>out || die "$(cat out)"
      done
      pass "Acme::Math::XS ($test_branch) passes its test runner"
    fi
  }

  {
    git clean -dxf &>out || die "$(cat out)"
    for cmd in "${test_make_distdir[@]}"; do
      $cmd &>>out || die "$(cat out)"
    done
    dd=( $test_dist-* )
    [ -n "$dd" ] || die
    ok "`[ -e "$dd/MANIFEST" ]`" "$dd/MANIFEST exists"
    ok "`[ ! -e "$dd/MANIFEST.SKIP" ]`" \
      "$dd has no MANIFEST.SKIP"
    if $inline_module; then
      for file in "${test_dist_files[@]}"; do
        ok "`[ -e "$dd/$file" ]`" \
          "$dd/$file exists"
      done
    fi
    (
      cd $dd
      if [ -e Build.PL ]; then
        perl Build.PL &>>../out || die "$(cat out)"
        ./Build test &>>../out || die "$(cat out)"
      else
        perl Makefile.PL &>>../out || die "$(cat out)"
        make test &>>../out || die "$(cat out)"
      fi
    )
    pass "$dd passes its tests"

    if $test_no_bundle; then
        ok "`[ ! -e "$dd/inc/Inline/Module.pm" ]`" \
          "Inline::Module is not bundled in inc/"
    fi
  }

  cd "$test_home"
}
