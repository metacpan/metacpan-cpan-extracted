#!env sh

if [ "x$1" = "x" -o "x$2" = "x" ]; then
  echo "Usage: $0 ModuleRE t/test.t"
  exit 1
fi

cover -delete
perl -MDevel::Cover=-ignore,.\*,-select,.\*ECMAScript.\*$1 -Ilib $2
cover -report html
