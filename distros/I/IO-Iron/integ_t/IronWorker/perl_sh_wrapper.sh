#!/bin/sh
# iron_worker_ruby_ng-1.2.0 (iron_core_ruby-1.0.3)
# Modified by mikkoi@github.com

root() {
  while [ $# -gt 1 ]; do
    if [ "$1" = "-d" ]; then
      printf "%s" "$2"
      break
    fi

    shift
  done
}

cd "$(root "$@")"

LD_LIBRARY_PATH=.:./lib:./__debs__/usr/lib:./__debs__/usr/lib/x86_64-linux-gnu:./__debs__/lib:./__debs__/lib/x86_64-linux-gnu
export LD_LIBRARY_PATH
PATH=.:./bin:./__debs__/usr/bin:./__debs__/bin:$PATH
export PATH
perl iron-pl.pl "$@"
