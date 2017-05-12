package Digest::JHash;

use strict;
use warnings;

require 5.008;

require Exporter;
require DynaLoader;
use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw( jhash );
our $VERSION = '0.10';

bootstrap Digest::JHash $VERSION;

1;

__END__


=head1 NAME

Digest::JHash - Perl extension for 32 bit Jenkins Hashing Algorithm

=head1 SYNOPSIS

    use Digest::JHash qw(jhash);

    $digest = jhash($data);

    # note that calling jhash() directly like this is the fastest way:

    $digest = Digest::JHash::jhash($data);

=head1 DESCRIPTION

The C<Digest::JHash> module allows you to use the fast JHash hashing algorithm
developed by Bob Jenkins from within Perl programs. The algorithm takes as
input a message of arbitrary length and produces as output a 32-bit
"message digest" of the input in the form of an unsigned long integer.

Call it a low calorie version of MD5 if you like.

See http://burtleburtle.net/bob/hash/doobs.html for more information.

=head1 FUNCTIONS

=over 4

=item jhash($data)

This function will calculate the JHash digest of the "message" in $data
and return a 32 bit integer result (an unsigned long in the C)

=back

=head1 EXPORTS

None by default but you can have the jhash() function if you ask nicely.
See below for reasons not to use Exporter (it is slower than a direct call)

=head1 SPEED NOTE

If speed is a major issue it is roughly twice as fast to do call the jhash()
function like Digest::JHash::jhash('message') than it is to import the
jhash() method using Exporter so you can call it as simply jhash('message').
There is a short script that demonstrates the speed of different calling
methods (direct, OO and Imported) in examples/oo_vs_func.pl

=head1 AUTHORS

The JHash implementation was written by Bob Jenkins
<bob_jenkins [at] burtleburtle [dot] net>.

This perl extension was written by Andrew Towers
<mariofrog [at] bigpond [dot] com>.

A few mods were added by James Freeman
<airmedical [at] gmail [dot] com>).

=head1 SEE ALSO

http://burtleburtle.net/bob/hash/doobs.html

=head1 LICENSE

This package is free software and is provided "as is" without express or
implied warranty. It may be used, redistributed and/or modified under the
terms of the Artistic License 2.0. A copy is include in this distribution.

=for stopwords JHash burtleburtle bigpond Jenkins

=cut
