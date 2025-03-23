#!/usr/bin/env python3
#
# See also:
# https://qpid.apache.org/releases/qpid-proton-0.37.0/
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.html#proton.Endpoint
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.html#proton.SASL
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.html#proton.SSLDomain
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.handlers.html#proton.handlers.MessagingHandler
# https://qpid.apache.org/releases/qpid-proton-0.37.0/proton/python/docs/proton.reactor.html#proton.reactor.Container
# https://github.com/apache/qpid-proton/blob/0.37.0/python/proton
# https://www.cyrusimap.org/sasl/
#

import collections
import optparse
import uuid

from proton import Endpoint
from proton import SSLDomain
from proton.handlers import MessagingHandler
from proton.reactor import Container


class Queue(object):
    def __init__(self, dynamic=False):
        self.dynamic = dynamic
        self.queue = collections.deque()
        self.consumers = []

    def subscribe(self, consumer):
        self.consumers.append(consumer)

    def unsubscribe(self, consumer):
        """
        :return: True if the queue is to be deleted
        """
        if consumer in self.consumers:
            self.consumers.remove(consumer)
        return len(self.consumers) == 0 and (self.dynamic or len(self.queue) == 0)

    def publish(self, message):
        self.queue.append(message)
        self.dispatch()

    def dispatch(self, consumer=None):
        if consumer:
            c = [consumer]
        else:
            c = self.consumers
        while self._deliver_to(c):
            pass

    def _deliver_to(self, consumers):
        try:
            result = False
            for c in consumers:
                if c.credit:
                    c.send(self.queue.popleft())
                    result = True
            return result
        except IndexError:  # no more messages
            return False


class Broker(MessagingHandler):
    def __init__(self, debug, url, truststore, sslcert, sslkey, sslpass, sasl_config_path, sasl_config_name):
        super(Broker, self).__init__()
        self.debug = debug
        self.url = url
        # SSL trust store
        self.truststore = truststore
        # SSL certificate
        self.sslcert = sslcert
        self.sslkey = sslkey
        self.sslpass = sslpass
        # SASL configuration
        self.sasl_config_path = sasl_config_path
        self.sasl_config_name = sasl_config_name
        # queues
        self.queues = {}

    def on_start(self, event):
        if self.debug >= 1:
            print('on_start:  {}'.format(event))
        ssl_domain = SSLDomain(SSLDomain.MODE_SERVER)
        # SSL trust store (e.g. PEM file containing trusted CA certificate(s))
        if self.truststore:
            ssl_domain.set_trusted_ca_db(self.truststore)

        # server certificate
        if self.sslkey:
            ssl_domain.set_credentials(self.sslcert, self.sslkey, self.sslpass)

        self.acceptor = event.container.listen(url=self.url, ssl_domain=ssl_domain)

    def _queue(self, address):
        if address not in self.queues:
            self.queues[address] = Queue()
        return self.queues[address]

    def on_connection_init(self, event):
        if self.debug >= 1:
            print('on_connection_init:  {}'.format(event))
        # set SASL configuration file
        sasl = event.connection.transport.sasl()
        sasl.config_path(self.sasl_config_path)
        sasl.config_name(self.sasl_config_name)

    def on_link_opening(self, event):
        if self.debug >= 1:
            print('on_link_opening:  {}'.format(event))
        if event.link.is_sender:
            if event.link.remote_source.dynamic:
                address = str(uuid.uuid4())
                event.link.source.address = address
                q = Queue(True)
                self.queues[address] = q
                q.subscribe(event.link)
            elif event.link.remote_source.address:
                event.link.source.address = event.link.remote_source.address
                self._queue(event.link.source.address).subscribe(event.link)
        elif event.link.remote_target.address:
            event.link.target.address = event.link.remote_target.address

    def _unsubscribe(self, link):
        if link.source.address in self.queues and self.queues[link.source.address].unsubscribe(link):
            del self.queues[link.source.address]

    def on_link_closing(self, event):
        if self.debug >= 1:
            print('on_link_closing:  {}'.format(event))
        if event.link.is_sender:
            self._unsubscribe(event.link)

    def on_connection_closing(self, event):
        if self.debug >= 1:
            print('on_connection_closing:  {}'.format(event))
        self.remove_stale_consumers(event.connection)

    def on_disconnected(self, event):
        if self.debug >= 1:
            print('on_disconnected:  {}'.format(event))
        self.remove_stale_consumers(event.connection)

    def remove_stale_consumers(self, connection):
        link = connection.link_head(Endpoint.REMOTE_ACTIVE)
        while link:
            if link.is_sender:
                self._unsubscribe(link)
            link = link.next(Endpoint.REMOTE_ACTIVE)

    def on_sendable(self, event):
        print('on_sendable:  dispatching from queue {}'.format(event.link.source.address))
        self._queue(event.link.source.address).dispatch(event.link)

    def on_message(self, event):
        address = event.link.target.address
        if address is None:
            address = event.message.address
        print('on_message:  publishing message to queue {}'.format(address))
        self._queue(address).publish(event.message)

    # catches event for socket and authentication failures
    def on_transport_error(self, event):
        if self.debug >= 1:
            print('on_transport_error:  {}'.format(event))

        print("Transport error:", event.transport.condition)

    def on_unhandled(self, method, *args):
        if self.debug >= 2:
            print('unhandled event:  {} -- {}'.format(method, args))


def main():
    parser = optparse.OptionParser(usage="usage: %prog [options]")
    parser.add_option("-a", "--address", default="localhost:5671",
                      help="address router listens on (default %default)")
    parser.add_option("-d", "--debug", type=int, default=0,
                      help="debug output level (default %default)")
    parser.add_option("-s", "--truststore", default=None,
                      help="SSL trust store (e.g. cacert.pem)")
    parser.add_option("-c", "--sslcert", default=None,
                      help="SSL certificate / public key (e.g. server-cert.pem)")
    parser.add_option("-k", "--sslkey", default=None,
                      help="SSL private key (e.g. server-key.pem)")
    parser.add_option("-y", "--sslpass", default=None,
                      help="password for client-side SSL private key (overrides ECS_AMQP_SSLPASS env var)")
    parser.add_option("-l", "--sasl_config_path", default=None,
                      help="location of SASL configuration file")
    parser.add_option("-n", "--sasl_config_name", default=None,
                      help="SASL configuration file basename (will have \".conf\" appended)")
    opts, args = parser.parse_args()

    try:
        Container(Broker(opts.debug,
                         opts.address,
                         opts.truststore,
                         opts.sslcert,
                         opts.sslkey,
                         opts.sslpass,
                         opts.sasl_config_path,
                         opts.sasl_config_name)).run()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
