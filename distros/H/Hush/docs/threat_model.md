# Introduction

Hushlist is a tool for privately communicating in spite of a hostile network, in a censorship-resistant and metadata-minimizing way. For the various different kinds of users of Hush to know when and when they cannot safely use this tool, it is necessary to precisely describe the threat model in which Hushlist operates. This document lists Hushlist user assets at issue, and identifies threat sources that might compromise the user’s privacy by emanating various types of metadata.

# Assets

## Financial assets

* private key of a single taddr/zaddr
* wallet.dat - entire wallet, with entire balance and keys of all taddrs/zaddrs and transaction history
* seed phrase

## Metadata assets

* knowledge that zaddr Z has X coins in it
* knowledge that zaddr Z1 sent zaddr Z2 X coins in a (z,z) transaction
* knowledge that taddr T  sent zaddr Z  X coins in a (t,z) transaction
* knowledge that zaddr Z had X coins in it just before a (z,t) transaction
* the list of taddrs/zaddrs under control by Hushlist

# Classes of Threat Actors

## Users on same computer

Never use Hushlist on the same physical computer or virtual machine with another user you do not trust. If that user can leverage a single CVE and get privilege escalation, full loss of privacy could happen. Best to not ever let this easy-to-prevent situation to occur. Use Hushlist on a private desktop or laptop computer, or a server that you have root on. Practice the art of compartmentalizations and isolation at every level.

## Users on same physical network

Bad actors on your local physical network have elevated risk to you. If you think your local physical network is not secure, use caution.

* ARP poisoning
* DDoSing because there is no firewall/router/NAT between



## Network admins on local physical network

If you can't trust your local network admin, probably not a good idea. They have all things from above, but in addition

* DNS poisoining
* ...

## Internet Service Providers
TODO

## Local Law Enforcement (LEOs)

TODO
## Federal agencies
## Nation-state level intelligence agencies, cyber command of nation-state militaries, "APTs"

* can obtain full cyphertext of all network traffic, via direct methods or the various agreements that various security agencies have to access each others resources.
* can poison BGP routes
* can inject/poison any unencrypted/unauthenticated network traffic such as HTTP

## Nefarious/infected open source projects

Hushlist depends on an immense amount of free and open source software being compiled correctly. Reproducible/deterministic builds allow people to verify that exactly the same code is being compiled by various independent sources, providing evidence that there are not hidden backdoors. If one open source project that Hushlist depended on injected malware into, for instance, a Perl CPAN module and actually released that malware to CPAN, our users would download that code from CPAN and execute it locally. Even more likely is that a "good citizen" open source project has some kind of bug/CVE/malware planted in it by an innocuous-looking patch that fixes something else. Hushlist tries very hard to verify the dependencies it downloads are trusted.
