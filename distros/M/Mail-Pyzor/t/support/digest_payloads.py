#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (c) 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

import sys
import json
import email

import pyzor.digest

#----------------------------------------------------------------------
import getopt

def usage():
    return "Prints a message’s digest payload in newline-delimited JSON.\n\n" + "Usage: " + sys.argv[0] + "\n\nGive input via STDIN.\n";

try:
    (opts, args) = getopt.getopt(sys.argv[1:], 'h', ['help'])
except getopt.GetoptError, err:
    sys.stderr.write(usage())
    sys.exit(1)

for (o, a) in opts:
    if o in ('-h', '--help'):
        print usage()
        sys.exit();
#----------------------------------------------------------------------

msg = email.message_from_file( sys.stdin )

import pprint

digester=pyzor.digest.DataDigester

for payload in digester.digest_payloads(msg):
    print( json.dumps(payload) )
