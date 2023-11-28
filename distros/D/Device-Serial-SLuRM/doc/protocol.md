SLµRM Protocol
==============

SLµRM ("Serial Link Microcontroller Reliable Messaging") is a simple bidirectional communication protocol for adding reliable message framing and request/response semantics to byte-based data links (such as asynchronous serial ports), which may themselves be somewhat unreliable.

SLµRM can tolerate bytes arriving corrupted or going missing altogether, or additional noise bytes being received, while still maintaining a reliable bidirectional flow of messages. There are two main kinds of message flows - NOTIFYs and REQUESTs. In all cases, packet payloads can be of a variable length (including zero bytes), and the protocol itself does not put semantic meaning on those bytes - they are free for the application to use as required.

A NOTIFY message is a simple notification from one peer to the other, that does not yield a response.

A REQUEST message carries typically some sort of command instruction, to which the peer should respond with a RESPONSE or ERR packet. Replies to a REQUEST message do not have to be sent sequentially.

Topology
--------

There are two variants of the protocol, for different topology situations, which use different header formats.

* 3-byte header: Used between exactly two endpoints connected by a full-duplex asynchronous serial connection, such as RS-232 or TTL UART. In this situation, node IDs are not needed as a message transmitted by either node will only be received by the other. Any received message is already received by only the intended node.

* 4-byte header: Used on an entire bus of two or more endpoints connected by a shared half-duplex asynchronous serial connection, such as RS-485. One endpoint is distinguished as being special; the "controller". This is typically a computer (or at least, the endpoint with the most compute power and memory) controlling the bus. All other endpoints are called "nodes", and are distinguished by having unique 7-bit ID numbers. The controller does not need an ID number. All messages are sent from the controller to some node, or from a node to the controller; non-controller nodes do not communicate directly. This variant is called "MSLµRM", for "Multidrop SLµRM".

Packets
-------

Packets are variable-length over async serial at an application-defined baud rate. 8 bits are required. Parity checking is not required as higher-level checksumming is employed by the protocol.

Each packet consists of a SYNC byte (0x55), followed by a 3- or 4-byte header, a variable-length application data payload, and a final checksum byte.

The 3-byte header is used in full-duplex 2-node situations, and consists of a packet-control field, a length field, and a CRC which protects the header itself:

```
  0x55  PKTCTRL LENGTH HEADER-CRC body... PACKET-CRC
        +------------------||                  ||
        +--------------------------------------||
```

The 4-byte header is used in multi-drop situations, and adds a node addressing field to the header:

```
  0x55  PKTCTRL ADDR LENGTH HEADER-CRC body... PACKET-CRC
        +-----------------------||                  ||
        +-------------------------------------------||
```

The HEADER-CRC is the CRC8 checksum of the preceeding header bytes. The PACKET-CRC is the CRC8 checksum of the entire packet, including all the header bytes and the entire body. LENGTH gives the number of bytes in the body section; this may be zero. The initial sync byte is not included in either CRC check.

Example: The "trivial" packet consisting of a zero PKTCTRL field and no body bytes:

```
  0x55 0x00 0x00 0x00 0x00
```

A packet with PKTCTRL=0x12 and three body bytes ("ABC"):

```
  0x55 0x12 0x03 0x74 0x41 0x42 0x43 0x52
```

The PKTCTRL field itself is broken into two 4-bit sub-fields; the packet type occupies the upper 4 bits, the sequence number the lower 4. The above packet has packet type 0x10, sequence number 2, and the body bytes "ABC".

The ADDR field is broken into a single bit indicating direction, and a 7-bit field containing the node ID. The topmost bit of the ADDR field is 1 for messages transmitted by the controller to a node, and 0 for messages transmitted by nodes to the controller. The remaining 7 bits encode the ID number of the destination or source node.

The ADDR field gives a simple way for endpoints to filter received packets for interest; as on a shared bus system such as RS-485 each node will receive messages destined for others, and may also receive reflections of its own transmissions. The controller must ignore any incoming packet with the direction bit high, and other nodes must ignore any packet with the direction bit low, or whose ID number does not match its own.

On a multi-drop system, after packets are filtered, the remaining packet semantics work the same as for the direct two-endopoint case described below.

Messages
--------

The packet type field indicates the type of message being conveyed. Regular messages use a non-zero packet type. In this case, the sequence number field contains an integer that is incremented for each new message. Transmitters may wish to transmit packets more than once for reliability; receivers should discard duplicates based on the sequence number. Reply packets (those with packet type 0x80 or above) use the sequence number of the originating message they reply to, and *not* the next sequence number the transmitting party would have sent.

When implementing the controller of a multi-drop system, remember that sequence numbers apply per node ID and each must be handled independently.

Packets whose packet type is zero are protocol-control messages, not for delivery to the application. Instead they are interpreted internally within the protocol. They use the sequence number field of the PKTCTRL byte 

### META-RESET (0x01)

A META-RESET packet resets the peer's expectation of the next message sequence number. This is typically used on boot or program startup, or after some other form of error recovery.

The body contains a single byte, whose lower 8 bits reset the peer's expectation of the next message sequence number. On receipt of a META-RESET message, a META-RESETACK should be sent in reply.

### META-RESETACK (0x02)

Treated similarly to a META-RESET packet, except that a RESETACK is not sent after it.

### NOTIFY (0x10)

A NOTIFY (packet type 0x10) message carries body bytes to deliver to the application. There is no expected response to it.

### REQUEST (0x30)

A REQUEST (packet type 0x30) message carries body bytes to deliver to the application. The sender expects to receive either a RESPONSE or an ERR message in reply.

### RESPONSE (0xB0)

A RESPONSE (packet type 0xB0) message carries body bytes to return to the originating application that sent the corresponding request. Note that (as with all message types) a zero-length body is valid here. In particular, it could mean that a command request was received and understood, and there is no further data in the response to it. The receiver should send an ACK to it.

### ACK (0xC0)

An ACK (packet type 0xC0) message is sent by the originating application that sent the initial request, to say that the response (or error) has been received, and the transaction is now complete. After this the sequence number may be reused.

### ERR (0xE0)

An ERR (packet type 0xE0) message carries body bytes to return to the originating application that sent the corresponding request. Unlike a RESPONSE packet this indicates some sort of abnormal condition happened. The meaning of the bytes is not further defined by the protocol, other than to suggest that receipt of this packet type should be treated in a way to indicate its error-like nature. The receiver should send an ACK to it.
