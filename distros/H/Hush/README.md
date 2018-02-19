# Hushlist: Censorship Resistant Metadata-Minimizing Multi-Blockchain Communication

Hushlist uses the Hush blockchain (Zcash and some other forks will be supported)
to implement anonymous and pseudonymous mailing lists using the encrypted
512 byte memo field of the Zcash Protocol. Hush inherits all RPCs
from Bitcoin 0.11.2 and Zcash, which are used to implement Hushlist.

# Requirements

Hushlist requires a computer with Perl 5.8+, and access to a fullnode RPC server
which is often run on localhost. Hushlist supports all platforms that Hush currently
supports, which is Linux, Mac and Windows. A testnet (TUSH) node can also be used.

Sending shielded transactions (involving zaddrs) can be very resource
intensive, and at least 4GB of RAM is recommended, although 2GB may work in
some situations, depending on hardware, software, virtual machine use and OS.

# Supported Blockchains

* HUSH
* TUSH  (HUSH testnet)
* Zcash (ZEC)
* TAZ   (ZEC testnet)
* Komodo (KMD) - planned

# Examples

    # create a new Hush contact
    hushlist contact add chani z1234...
    hushlist contact add stilgar z1456....

    # see an overview of your local Hushlists
    hushlist status

    # create a new private Hushlist, which exists locally only
    # and has no cost associated, since nothing is sent to the blockchain
    hushlist new fremen

    # see the status of a list
    hushlist status fremen

    # add one or more people to a Hushlist
    hushlist add fremen chani stilgar

    hushlist send listname "A beginning is the time for taking the most delicate care that the balances are correct."

    # send using a non-default chain
    hushlist send listname --chain tush "If wishes were fishes, we'd all cast nets. -- Stilgar"

    # show overview of lists and messages
    hushlist show

    # show most recent messages for listname
    hushlist show listname

    # donate to the nice dev who wrote this, from your main hushlist zaddr
    hushlist donate 5 hush
    hushlist donate 0.5 zec

# In development commands

This will rely on z\_embedstring RPC which will hopefully be in the Hush 1.0.13 release,
it is currently in the `z_embedstring` branch:

    # make an already created private hushlist PUBLIC, i.e.
    # publish it's privkey to the blockchain. This costs HUSH, since
    # we need to send an xtn to the blockchain
    hushlist public listname

# How Is This Different Than Hush Messenger?

Hush Messenger has similar functions, but it more closely maps to "chat
program" versus "mailing list software". Messenger also has a different tech
stack (Javascript vs Perl) and runs in the browser while Hushlist avoids the
convenience of browsers to reduce it's attack surface.

Hushlist is happy to be one of the first Hush Applications with Hush Messenger
and hopes that each project can learn from the other and cross-pollinate ideas
which will turn into more options for Hush users.

# License

GPLv3
