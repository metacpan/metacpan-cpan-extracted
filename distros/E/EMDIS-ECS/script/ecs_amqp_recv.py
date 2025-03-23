#!/usr/bin/env python3
#
# Copyright (C) 2019-2025 National Marrow Donor Program. All rights reserved.
# See also LICENSE file.
#
# Usage example:
# ecs_amqp_recv.py --broker amqps://msg01.emdis.net:5672 --vhost default \
#  --address emdis.us.msg --truststore myKeyStore.pem \
#  --sslcert user-cert.pem --sslkey user-key.pem --sslpass PASSWORD \
#  --username emdis-us --password SECRET --outputdir messages
#
# See also:
# https://qpid.apache.org/releases/qpid-proton-0.37.0/
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.html#proton.SSLDomain
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.handlers.html#proton.handlers.MessagingHandler
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.reactor.html#proton.reactor.Container
#
# Influenced by solace-samples-amqp-qpid-proton-python and cli-proton-python:
# https://github.com/SolaceSamples/solace-samples-amqp-qpid-proton-python
# https://github.com/rh-messaging/cli-proton-python
#

from __future__ import print_function
import optparse
import os
import shutil
import sys
import tempfile
import time
from proton import SSLDomain
from proton.handlers import MessagingHandler
from proton.reactor import Container

# helper function

def get_options():
    parser = optparse.OptionParser(usage="usage: %prog [options]")
    parser.add_option("-d", "--debug", type=int, default=0,
                  help="debug output level (default %default)")
    parser.add_option("-b", "--broker", default=None,
                  help="amqp message broker host url (e.g. amqps://localhost:5672)")
    parser.add_option("-v", "--vhost", default=None,
                  help="virtual host namespace on broker (e.g. default)")
    parser.add_option("-a", "--address", default=None,
                  help="topic or queue from which messages are received (e.g. test_queue)")
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
    parser.add_option("-t", "--timeout", type=int, default=5,
                  help="inactivity timeout threshold, in seconds (default %default)")
    parser.add_option("-o", "--outputdir", action="append", default=None,
                  help="file system directory for output files")
    parser.add_option("-x", "--suffix", default=".amqp.msg",
                  help="filename suffix for output files (default %default)")

    opts, args = parser.parse_args()

    return opts

"""
Proton event handler class
Creates an amqp connection using ANONYMOUS or PLAIN authentication.
Then attaches a receiver link to consume messages from the broker.
"""
class Recv(MessagingHandler):
    def __init__(self, debug, url, vhost, address, truststore, sslcert, sslkey, sslpass, username, password, timeout, outputdir, suffix):
        super(Recv, self).__init__()

        self.connection = None
        self.receiver = None

        # exit status
        self.exit_status = 1

        # debug output level
        self.debug = debug

        # amqp broker host url
        self.url = url

        # amqp node address
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

        # inactivity timeout
        self.inactivity_timestamp = 0
        self.inactivity_threshold = timeout

        # output dir
        self.outputdir = outputdir
        self.hextrans = str.maketrans('0123456789abcdef', 'BCDFGHJKLMNPQRST')
        self.old_prefix_ts = ''
        self.msg_seqnum = 0

        # suffix
        self.suffix = suffix

    def on_start(self, event):
        if self.debug >= 1:
            print('on_start:  {}'.format(event))

        ssl_domain = SSLDomain(SSLDomain.MODE_CLIENT)
        # SSL trust store (e.g. PEM file containing trusted CA certificate(s))
        if self.truststore:
            ssl_domain.set_trusted_ca_db(self.truststore)
        if True:
            # use trust store to verify peer's (e.g. broker's) SSL certificate
            ssl_domain.set_peer_authentication(SSLDomain.VERIFY_PEER)
        else:
            # verify hostname on peer's (e.g. broker's) SSL certificate
            ssl_domain.set_peer_authentication(SSLDomain.VERIFY_PEER_NAME)

        # client-side certificate
        if self.sslkey:
            ssl_domain.set_credentials(self.sslcert, self.sslkey, self.sslpass)

        if self.username:
            # username and password authentication
            self.connection = event.container.connect(url=self.url,
                                                      ssl_domain=ssl_domain,
                                                      user=self.username,
                                                      password = self.password,
                                                      allow_insecure_mechs=False,
                                                      sasl_enabled=True,
                                                      allowed_mechs="PLAIN",
                                                      virtual_host=self.virtual_host)
        else:
            # anonymous authentication
            self.connection = event.container.connect(url=self.url,
                                                      ssl_domain=ssl_domain,
                                                      allow_insecure_mechs=False,
                                                      sasl_enabled=True,
                                                      allowed_mechs="ANONYMOUS",
                                                      virtual_host=self.virtual_host)

    def on_connection_opened(self, event):
        if self.debug >= 1:
            print('on_connection_opened:  {}'.format(event))

        # create receiver link to consume messages
        self.receiver = event.container.create_receiver(event.connection, source=self.address)
        self.exit_status = 0

    def on_connection_closed(self, event):
        if self.debug >= 1:
            print('on_connection_closed:  {}'.format(event))

    def on_reactor_quiesced(self, event):
        if self.debug >= 1:
            print('on_reactor_quiesced [{},{}]:  {}'.format(self.inactivity_timestamp, time.time(), event))

        # TODO: improve robustness of link/session/connection/container teardown (instead of relying solely on inactivity timeout)
        if self.inactivity_timestamp == 0:
            self.inactivity_timestamp = time.time()
        inactivity_seconds = time.time() - self.inactivity_timestamp
        if inactivity_seconds > 0.1 and inactivity_seconds >= self.inactivity_threshold:
            if self.connection:
                self.connection.close()
            else:
                event.container.stop()

    def on_message(self, event):
        if self.debug >= 1:
            print('on_message:  {}'.format(event))

        filename_prefix = int(time.time() * 16).to_bytes(8, byteorder='big').hex().translate(self.hextrans)[8:]
        if self.old_prefix_ts != filename_prefix:
            self.old_prefix_ts = filename_prefix
            # reset msg_seqnum when prefix_ts changes
            self.msg_seqnum = 0
        self.msg_seqnum += 1
        filename_prefix += '%03i.' % self.msg_seqnum

        created_filename = None
        with tempfile.NamedTemporaryFile(dir=self.outputdir[0], mode='wt', prefix=filename_prefix, suffix=self.suffix, delete=False) as fd:
            if event.message.annotations:
                for k, v in event.message.annotations.items():
                    print("{}: {}".format(k,v), file=fd)
            if event.message.instructions:
                for k, v in event.message.instructions.items():
                    print("{}: {}".format(k,v), file=fd)
            if event.message.properties:
                for k, v in event.message.properties.items():
                    print("{}: {}".format(k,v), file=fd)
            if event.message.content_encoding and event.message.content_encoding != 'None':
                print("Content-Encoding: {}".format(event.message.content_encoding), file=fd)
            if event.message.content_type and event.message.content_type != 'None':
                print("Content-Type: {}".format(event.message.content_type), file=fd)
            if event.message.subject:
                print("Subject: {}".format(event.message.subject), file=fd)
            else:
                print("Subject: ", file=fd)
            print("", file=fd)
            print(event.message.body, file=fd)
            fd.flush()
            created_filename = fd.name
        print("Message received and stored in file", created_filename)

        # copy to additional output directories, if specified
        for otherdir in self.outputdir[1:]:
            with open(created_filename, mode='rt') as fd1:
                copied_filename = None
                with tempfile.NamedTemporaryFile(dir=otherdir, mode='wt', prefix=filename_prefix, suffix='.amqp.msg', delete=False) as fd2:
                    shutil.copyfileobj(fd1, fd2)
                    copied_filename = fd2.name
                print("Copied to file", copied_filename)

        self.inactivity_timestamp = 0

    # the on_transport_error event catches socket and authentication failures
    def on_transport_error(self, event):
        if self.debug >= 1:
            print('on_transport_error:  {}'.format(event))

        print("Transport error:", event.transport.condition)
        MessagingHandler.on_transport_error(self, event)

    def on_disconnected(self, event):
        if self.debug >= 1:
            print('on_disconnected:  {}'.format(event))

        print("Disconnected")

    def on_unhandled(self, method, *args):
        if self.debug >= 2:
            print('unhandled event:  {} -- {}'.format(method, args))


# parse arguments and get options
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
the amqp receiver source.
"""

try:
    recv = Recv(opts.debug,
                opts.broker,
                opts.vhost,
                opts.address,
                opts.truststore,
                opts.sslcert,
                opts.sslkey,
                sslpass,
                opts.username,
                password,
                opts.timeout,
                opts.outputdir,
                opts.suffix)
    container = Container(recv)
    # start proton event reactor
    container.run()
    # check exit status
    if recv.exit_status != 0:
        print("exit status", recv.exit_status, file=sys.stderr)
    sys.exit(recv.exit_status)
except KeyboardInterrupt: pass