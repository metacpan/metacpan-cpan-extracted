#!/usr/bin/env bash

test_module() {
  [ -n "$test_dir" ] || die
  [ -e "$test_dir" ] ||
    git clone $test_repo_url &>/dev/null
  [ -e "$test_dir" ] || die
  local test_home="$(pwd)"
  if [ -n "$test_inline_build_dir" ]; then
    inline_module=true
  else
    inline_module=false
  fi

  note "Testing '$test_dir' branch '$test_branch'"
  cd "$test_dir"
  git clean -dxf &>/dev/null
  git checkout "$test_branch" &>/dev/null

  {
    for cmd in "${test_prove_run[@]}"; do
      $cmd &>>out
    done
    pass "Acme::Math::XS ($test_branch) passes its tests w/ prove"
    if $inline_module; then
      ok "`[ -e "$test_inline_build_dir" ]`" \
        "$test_inline_build_dir exists after testing"
    fi
  }

  {
    git clean -dxf &>/dev/null
    if [ -n "$test_test_run" ]; then
      for cmd in "${test_test_run[@]}"; do
        $cmd &>>out
      done
      pass "Acme::Math::XS ($test_branch) passes its test runner"
    fi
  }

  {
    git clean -dxf &>/dev/null
    for cmd in "${test_make_distdir[@]}"; do
      $cmd &>>out
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
        perl Build.PL &>>../out
        ./Build test &>>../out
      else
        perl Makefile.PL &>>../out
        make test &>>../out
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
