#!/usr/bin/env bash
# 10_repeat.bats requires ex/getoptlong.sh symlink which is excluded by Minilla
shopt -s extglob
cd t && exec bats --tap !(10_*).bats
