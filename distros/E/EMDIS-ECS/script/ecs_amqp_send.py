#!/usr/bin/env python3
#
# Copyright (C) 2019 National Marrow Donor Program. All rights reserved.
# See also LICENSE file.
#
# Usage example:
# ecs_amqp_send.py --broker amqps://msg01.emdis.net:5672 --vhost default \
#  --address emdis.us.msg --truststore myKeyStore.pem \
#  --sslcert user-cert.pem --sslkey user-key.pem --sslpass PASSWORD \
#  --username emdis-us --password SECRET --inputfile test_msg.txt
#
# See also:
# https://qpid.apache.org/releases/qpid-proton-0.29.0/
# https://qpid.apache.org/releases/qpid-proton-0.29.0/proton/python/book/overview.html
# https://qpid.apache.org/releases/qpid-proton-0.29.0/proton/python/book/tutorial.html
# https://qpid.apache.org/releases/qpid-proton-0.29.0/proton/python/api/
# https://qpid.apache.org/releases/qpid-proton-0.29.0/proton/c/api/
#
# Influenced by solace-samples-amqp-qpid-proton-python and cli-proton-python:
# https://github.com/SolaceSamples/solace-samples-amqp-qpid-proton-python
# https://github.com/rh-messaging/cli-proton-python
#

from __future__ import print_function, unicode_literals
import optparse
import os
import sys
from proton import Message
from proton import SSLDomain
from proton.handlers import MessagingHandler
from proton.reactor import Container

# helper function
def get_options():
    parser = optparse.OptionParser(usage="usage: %prog [options]",
                  description="Send message to the supplied address.")
    parser.add_option("-d", "--debug", type=int, default=0,
                  help="debug output level (default %default)")
    parser.add_option("-b", "--broker", default=None,
                  help="amqp message broker host url (e.g. amqps://localhost:5672)")
    parser.add_option("-v", "--vhost", default=None,
                  help="virtual host namespace on broker (e.g. default)")
    parser.add_option("-a", "--address", default=None,
                  help="topic or queue to which message is sent (e.g. test_queue)")
    parser.add_option("-s", "--truststore", default=None,
                  help="SSL trust store (e.g. cacert.pem)")
    parser.add_option("-c", "--sslcert", default=None,
                  help="client-side SSL certificate / public key (e.g. user-cert.pem)")
    parser.add_option("-k", "--sslkey", default=None,
                  help="client-side SSL private key (e.g. user-key.pem)")
    parser.add_option("-y", "--sslpass", default=None,
                  help="password for client-side SSL private key (overrides ECS_AMQP_SSLPASS env var)")
    parser.add_option("-u", "--username", default=None,
                  help="username for SASL authentication")
    parser.add_option("-p", "--password", default=None,
                  help="password for SASL authentication (overrides ECS_AMQP_PASSWORD env var)")
    parser.add_option("-i", "--inputfile", default=None,
                  help="input file containing message to be sent")
    parser.add_option("-P", "--property", action="append", default=None,
                  help="application defined message property and value (e.g. x-emdis-hub-snd=DE)")
    parser.add_option("-E", "--encoding", default='UTF-8',
                  help="message Content-Encoding (default %default)")
    parser.add_option("-T", "--type", default='text/plain',
                  help="message Content-Type (default %default)")
    parser.add_option("-S", "--subject", default=None,
                  help="message Subject (e.g. EMDIS)")
    opts, args = parser.parse_args()
    return opts



"""
Proton event handler class
Creates an amqp connection and a sender to publish messages.
"""
class Send(MessagingHandler):
    def __init__(self, debug, url, vhost, address, truststore, sslcert, sslkey, sslpass, username, password, inputfile, properties, content_encoding, content_type, message_subject):
        super(Send, self).__init__()

        # exit status
        self.exit_status = 1

        # debug output level
        self.debug = debug

        # amqp broker host url
        self.url = url

        # target amqp node address
        self.address = address

        # broker virtual host name
        self.virtual_host = vhost

        # SSL trust store
        self.truststore = truststore

        # client-side SSL certificate
        self.sslcert = sslcert
        self.sslkey = sslkey
        self.sslpass = sslpass

        # authentication credentials
        self.username = username
        self.password = password

        # input file
        self.inputfile = inputfile
        if self.inputfile == '-':
            self.inputfile = sys.stdin.fileno()

        # application defined message properties
        self.application_defined_message_properties = None
        if properties:
            self.application_defined_message_properties = dict([prop.split('=', maxsplit=1) for prop in properties])

        # standard message properties
        self.content_encoding = content_encoding
        self.content_type = content_type
        self.message_subject = message_subject

        # done sending yet?
        self.done_sending = False

    def on_start(self, event):
        if self.debug >= 1:
            print('on_start:  {}'.format(event))

        # SSL trust store (e.g. PEM file containing trusted CA certificate(s))
        if self.truststore:
            event.container.ssl.client.set_trusted_ca_db(self.truststore)
        if True:
            # use trust store to verify peer's (e.g. broker's) SSL certificate
            event.container.ssl.client.set_peer_authentication(SSLDomain.VERIFY_PEER)
        else:
            # verify hostname on peer's (e.g. broker's) SSL certificate
            event.container.ssl.client.set_peer_authentication(SSLDomain.VERIFY_PEER_NAME)

        # client-side certificate
        if self.sslkey:
            event.container.ssl.client.set_credentials(self.sslcert,
                                                       self.sslkey,
                                                       self.sslpass)

        if self.username:
            # basic username and password authentication
            event.container.connect(url=self.url,
                                    user=self.username,
                                    password = self.password,
                                    allow_insecure_mechs=False,
                                    sasl_enabled=True,
                                    allowed_mechs="PLAIN",
                                    virtual_host=self.virtual_host)
        else:
            # anonymous authentication
            event.container.connect(url=self.url,
                                    allow_insecure_mechs=False,
                                    sasl_enabled=True,
                                    allowed_mechs="ANONYMOUS",
                                    virtual_host=self.virtual_host)

    def on_connection_opened(self, event):
        if self.debug >= 1:
            print('on_connection_opened:  {}'.format(event))

        # attaches sender link to transmit messages
        event.container.create_sender(event.connection, target=self.address)

    def on_sendable(self, event):
        if self.debug >= 1:
            print('on_sendable:  {}'.format(event))

        if event.sender.credit and not self.done_sending:
            # creates message to send
            msg = None
            with open(self.inputfile, "r") as fd:
                msg = Message(body=fd.read(),
                              subject=self.message_subject,
                              content_type=self.content_type,
                              content_encoding=self.content_encoding,
                              properties=self.application_defined_message_properties,
                              durable=True)
            self.done_sending = True
            if msg:
                # send message
                event.sender.send(msg)
            else:
                self.exit_status = 2
                event.connection.close()

    def on_accepted(self, event):
        if self.debug >= 1:
            print('on_accepted:  {}'.format(event))

        print("Message accepted by broker", self.url)
        self.exit_status = 0
        event.connection.close()

    def on_rejected(self, event):
        if self.debug >= 1:
            print('on_rejected:  {}'.format(event))

        print("Message rejected by broker", self.url)
        print("Delivery tag:", event.delivery.tag)
        self.exit_status = 3
        event.connection.close()

    # catches event for socket and authentication failures
    def on_transport_error(self, event):
        if self.debug >= 1:
            print('on_transport_error:  {}'.format(event))

        print("Transport error:", event.transport.condition)
        self.exit_status = 4
        MessagingHandler.on_transport_error(self, event)

    def on_disconnected(self, event):
        if self.debug >= 1:
            print('on_disconnected:  {}'.format(event))

        if event.transport and event.transport.condition :
            print('Disconnected with error:', event.transport.condition)
            self.exit_status = 5
            event.connection.close()

    def on_unhandled(self, method, *args):
        if self.debug >= 2:
            print('unhandled event:  {} -- {}'.format(method, args))


# get application options
opts = get_options()
# sslpass and password can be set via environment variables,
# but those settings can be overridden via command line options
sslpass = os.environ.get('ECS_AMQP_SSLPASS')
if opts.sslpass:
    sslpass = opts.sslpass
password = os.environ.get('ECS_AMQP_PASSWORD')
if opts.password:
    password = opts.password

"""
The amqp address can be a topic or a queue.
Do not use a prefix or use 'queue://' in the amqp address for 
the amqp sender link target address.
"""

try:
    send = Send(opts.debug,
                opts.broker,
                opts.vhost,
                opts.address,
                opts.truststore,
                opts.sslcert,
                opts.sslkey,
                sslpass,
                opts.username,
                password,
                opts.inputfile,
                opts.property,
                opts.encoding,
                opts.type,
                opts.subject)
    container = Container(send)
    # start proton event reactor
    container.run()
    # check exit status
    if send.exit_status != 0:
        print("exit status", send.exit_status, file=sys.stderr)
    sys.exit(send.exit_status)
except KeyboardInterrupt: pass