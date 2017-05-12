#!/usr/bin/perl
# $File: //member/autrijus/Lingua-ZH-Numbers/t/0-signature.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 1871 $ $DateTime: 2002/11/03 20:22:02 $

use strict;
print "1..1\n";

if (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
    print "ok 1 # skip - Cannot connect to the keyserver";
}
elsif (!eval { require Module::Signature; 1 }) {
    warn "# Next time around, consider install Module::Signature,\n".
	 "# so you can verify the integrity of this distribution.\n";
    print "ok 1 # skip - Module::Signature not installed\n";
}
else {
    (Module::Signature::verify() == Module::Signature::SIGNATURE_OK())
	or print "not ";
    print "ok 1 # Valid signature\n";
}

__END__
# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
