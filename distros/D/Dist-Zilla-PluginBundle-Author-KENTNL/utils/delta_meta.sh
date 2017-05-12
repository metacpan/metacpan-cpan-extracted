#!/usr/bin/env bash

self=$(realpath $0);
selfdir=$(dirname $self);

perl $selfdir/delta_meta.pl \
    <( perl $selfdir/git_fastcat.pl $1 META.json) \
    <( perl $selfdir/git_fastcat.pl $2 META.json);

perl $selfdir/delta_deps.pl \
    <( perl $selfdir/git_fastcat.pl $1 META.json) \
    <( perl $selfdir/git_fastcat.pl $2 META.json);

