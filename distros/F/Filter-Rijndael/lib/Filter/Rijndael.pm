package Filter::Rijndael;

require 5.8.0;

use strict;
use warnings;
use utf8;

require Exporter;
require DynaLoader;

our @ISA = qw( Exporter DynaLoader );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use Filter::Rijndael ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();
our $VERSION = '0.04';

bootstrap Filter::Rijndael $VERSION;

# Preloaded methods go here.

return 1;

__END__

=head1 NAME

Filter::Rijndael - Source Filter used for encrypting source code based on Filter::decrypt

=head1 SYNOPSIS

    use Filter::Rijndael;

=head1 DESCRIPTION

This is a decrypting source filter based on Rijndael encryption.

The purpose of this source filter is to hide the source code from a I<casual user>
that would want to change your code.

=head1 WARNING

It is important to note that a decryption filter can I<never> provide
complete security against attack. At some point the parser within Perl
needs to be able to scan the original decrypted source. That means that
at some stage fragments of the source will exist in a memory buffer.

Also, with the introduction of the Perl Compiler backend modules, and
the B::Deparse module in particular, using a Source Filter to hide source
code is becoming an increasingly futile exercise.

The best you can hope to achieve by decrypting your Perl source using a
source filter is to make it unavailable to the casual user.

Given that proviso, there are a number of things you can do to make
life more difficult for the prospective cracker.

=over 5

=item 1.

Strip the Perl binary to remove all symbols.

=item 2.

Build the decrypt extension using static linking. If the extension is
provided as a dynamic module, there is nothing to stop someone from
linking it at run time with a modified Perl binary.

=item 3.

Do not build Perl with C<-DDEBUGGING>. If you do then your source can
be retrieved with the C<-Dp> command line option. 

The sample filter contains logic to detect the C<DEBUGGING> option.

=item 4.

Do not build Perl with C debugging support enabled.

=item 5.

Do not implement the decryption filter as a sub-process (like the cpp
source filter). It is possible to peek into the pipe that connects to
the sub-process.

=item 6.

Check that the Perl Compiler isn't being used.

There is code in the BOOT: section of Rijndael.xs that shows how to detect
the presence of the Compiler. Make sure you include it in your module.

Assuming you haven't taken any steps to spot when the compiler is in
use and you have an encrypted Perl script called "myscript.pl", you can
get access the source code inside it using the perl Compiler backend,
like this

    perl -MO=Deparse myscript.pl

Note that even if you have included the BOOT: test, it is still
possible to use the Deparse module to get the source code for individual
subroutines.

=back

If you feel that the source filtering mechanism is not secure enough
you could try using the unexec/undump method. See the Perl FAQ for
further details.

=head1 FUTURE

Maybe transform the code to Opcodes first, change IV after each block...

=head1 AUTHOR

Sorin Pop <asp@cpan.org>

=head1 CONTRIBUTORS

Paul Marquess ( Filter::decrypt )
Rafael R. Sevilla ( Crypt::Rijndael )
Mark Shelor ( Digest::SHA )

=head1 DATE

19th February 2012

=cut
