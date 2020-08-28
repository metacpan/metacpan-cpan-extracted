#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (c) 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

import sys
import getopt

import pyzor.digest

set_utf8 = False


def usage():
    return 'Usage: ' + sys.argv[0] + ' [--utf8]\n' + 'Send input via STDIN.\n'


try:
    (opts, args) = getopt.getopt(sys.argv[1:], 'uh', ['utf8', 'utf-8', 'help'])
except getopt.GetoptError, err:
    sys.stderr.write(usage())
    sys.exit(1)

for (o, a) in opts:
    if o in ('-h', '--help'):
        print usage()
        sys.exit()
    elif o in ('-u', '--utf8', '--utf-8'):
        set_utf8 = True

digester = pyzor.digest.DataDigester

from_stdin = sys.stdin.read()

if set_utf8:
    from_stdin = from_stdin.decode(encoding='utf-8')

normalized = digester.normalize(from_stdin)

if set_utf8:
    normalized = normalized.encode('utf-8')

sys.stdout.write(normalized)
sys.stdout.flush()
