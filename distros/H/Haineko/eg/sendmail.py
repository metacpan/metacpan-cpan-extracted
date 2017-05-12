#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os, sys, commands, json
import httplib, urllib, base64, codecs

credential = { 
    'username': 'haineko', 
    'password': 'kijitora',
}
clientname = commands.getoutput("hostname")
clientname.rstrip("\n")
servername = '127.0.0.1:2794'
emaildata1 = {
    'ehlo': clientname,
    'mail': 'envelope-sender@example.jp',
    'rcpt': [ 'envelope-recipient@example.org' ],
    'body': 'メール本文です。',
    'header': {
        'from': 'キジトラ <envelope-sender@example.jp>',
        'subject': 'テストメール',
        'replyto': 'neko@example.jp'
    }
}

httpheader = {}
jsonstring = json.dumps( emaildata1, ensure_ascii=False )
basicauth1 = 0
arguments1 = sys.argv

try:
    basicauth1 = os.environ['HAINEKO_AUTH']
except KeyError:
    try:
        basicauth1 = sys.argv[1]
    except IndexError:
        basicauth1 = 0

if( basicauth1 ):
    import base64
    _authentication = base64.encodestring('%s:%s' % ( credential['username'], credential['password'] )).replace('\n', '')
    httpheader['Authorization'] = "Basic %s" % _authentication

connection = httplib.HTTPConnection( servername )
connection.request( 'POST', '/submit', jsonstring, httpheader )
htresponse = connection.getresponse()
htcontents = htresponse.read()
print htcontents

