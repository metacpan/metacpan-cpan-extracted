# KeePass::Reader - Interface to KeePass V4 database files

KeePass::Reader is a perl interface to read KeePass version 4.

It supports following capabilities:
* Encryption Algorithm: AES, TwoFish, ChaCha20 
* Key Derivation Function: Argon2
* Keys: Password, KeyFile (SHA-256 hash of the key file)

It's still in working progress (but it's functional ;)

### MODULE DEPENDENCIES

To install KeePass::Reader, you need following perl module:

* ExtUtils-MakeMaker

For the module execution, you need following perl module dependencies:

* [Crypt-Argon2](https://metacpan.org/pod/Crypt::Argon2)
* [Cryptx](https://metacpan.org/pod/CryptX)

### INSTALLATION

To install KeePass::Reader type the following:

```
# perl Makefile.PL
# make
# make install
```

### SOURCES

Knowledge about the algorithms necessary to decode a KeePass DB v4 format was gleaned from the source code of [keepassxc](https://github.com/keepassxreboot/keepassxc).

### BUGS/FEATURE REQUESTS

Please report bugs and request features on the github : https://github.com/garnier-quentin/perl-KeePass-Reader

All helps are welcomed!
