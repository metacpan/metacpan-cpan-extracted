use strict;
use warnings FATAL => 'all';

package MarpaX::RFC::RFC3629;

# ABSTRACT: Marpa parsing of UTF-8 byte sequences as per RFC3629

our $VERSION = '0.001'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


use Encode qw/decode/;
use Marpa::R2;
use Moo;
use Types::Standard -all;
use Types::Encodings qw/Bytes/;

has input     => ( is => 'ro',  isa => Bytes, required => 1, trigger => 1);
has output    => ( is => 'rwp', isa => Str|Undef);

our $DATA = do { local $/; <DATA> };
our $G = Marpa::R2::Scanless::G->new({source => \$DATA});

sub BUILDARGS {
  my ($class, @args) = @_;

  unshift @args, 'input' if @args % 2 == 1;
  return { @args };
}

sub _trigger_input { shift->_set_output(decode('UTF-8', ${$G->parse(\shift)}, Encode::FB_CROAK)) }
sub _concat        { shift; join('', @_) }


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::RFC::RFC3629 - Marpa parsing of UTF-8 byte sequences as per RFC3629

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::RFC::RFC3629;
    use Encode qw/encode/;
    use Data::HexDump;
    #
    # Parse octets
    #
    my $orig = "\x{0041}\x{2262}\x{0391}\x{002E}";
    my $octets = encode('UTF-8', $orig, Encode::FB_CROAK);
    my $string = MarpaX::RFC::RFC3629->new($octets)->output;
    print STDERR "Octets:\n" . HexDump($octets) . "\n";
    print STDERR "String:\n" . HexDump($string) . "\n";

=head1 DESCRIPTION

This module is parsing byte sequences as per RFC3629. It will croak if parsing fails.

=head1 SUBROUTINES/METHODS

=head2 new(ClassName $class: Bytes $octets --> InstanceOf['MarpaX::RFC::RFC3629'])

Instantiate a new object. Takes as parameter the octets.

=head2 output(InstanceOf['MarpaX::RFC::RFC3629'] $self --> Str)

Returns the UTF-8 string (utf8 flag might be on, depends).

=head1 SEE ALSO

L<Syntax of UTF-8 Byte Sequences|https://tools.ietf.org/html/rfc3629#section-4>

L<Marpa::R2>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-RFC-RFC3629>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/jddurand/marpax-rfc-rfc3629>

  git clone git://github.com/jddurand/marpax-rfc-rfc3629.git

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
lexeme default = latm => 1
:default ::= action => MarpaX::RFC::RFC3629::_concat
:start        ::= <UTF8 octets>
<UTF8 octets> ::= <UTF8 char>*
<UTF8 char>   ::= <UTF8 1>
                | <UTF8 2>
                | <UTF8 3>
                | <UTF8 4>
<UTF8 1>        ~                                                 [\x{00}-\x{7F}]
<UTF8 2>        ~                                 [\x{C2}-\x{DF}]     <UTF8 tail>
<UTF8 3>        ~                        [\x{E0}] [\x{A0}-\x{BF}]     <UTF8 tail>
                |                 [\x{E1}-\x{EC}]     <UTF8 tail>     <UTF8 tail>
                |                        [\x{ED}] [\x{80}-\x{9F}]     <UTF8 tail>
                |                 [\x{EE}-\x{EF}]     <UTF8 tail>     <UTF8 tail>
<UTF8 4>        ~        [\x{F0}] [\x{90}-\x{BF}]     <UTF8 tail>     <UTF8 tail>
                | [\x{F1}-\x{F3}]     <UTF8 tail>     <UTF8 tail>     <UTF8 tail>
                |        [\x{F4}] [\x{80}-\x{8F}]     <UTF8 tail>     <UTF8 tail>
<UTF8 tail>     ~ [\x{80}-\x{BF}]
