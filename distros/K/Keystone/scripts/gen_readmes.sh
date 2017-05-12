#!/bin/sh

echo "[+] Gen README.md"
pod2markdown.pl < lib/Keystone.pm > README.md

echo "[+] Gen README"
pod2text < lib/Keystone.pm > README
