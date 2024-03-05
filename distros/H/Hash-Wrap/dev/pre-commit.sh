test ${IGNORE_PRE_COMMIT_TIDY:-0} -eq 1 && exit 0
test -d .plx && plx=plx
test -n "$*" && exec $plx tidyall --mode commit --check-only "$@"
