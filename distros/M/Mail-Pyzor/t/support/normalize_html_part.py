#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (c) 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

import sys
import getopt

import pyzor.digest


def usage():
    return 'Usage: ' + sys.argv[0] + '\n' + 'Send input via STDIN.\n'


try:
    (opts, args) = getopt.getopt(sys.argv[1:], 'h', ['help'])
except getopt.GetoptError, err:
    sys.stderr.write(usage())
    sys.exit(1)

for (o, a) in opts:
    if o in ('-h', '--help'):
        print usage()
        sys.exit()

digester = pyzor.digest.DataDigester

normalized = digester.normalize_html_part(sys.stdin.read())

sys.stdout.write(normalized)
sys.stdout.flush()
