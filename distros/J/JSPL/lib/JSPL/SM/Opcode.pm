package JSPL::SM::Opcode;
use strict;
use warnings;
use Carp;

use JSPL;
use Carp;
our $VERSION = '0.11';

our @Opcodes;
BEGIN { JSPL::_boot_(__PACKAGE__, $JSPL::VERSION) }

use Exporter qw(import);
our @EXPORT = qw();
our %EXPORT_TAGS = (
    jof => [map "JOF_$_", qw(
	BYTE JUMP ATOM UINT16 TABLESWITCH LOOKUPSWITCH QARG LOCAL SLOTATOM JUMPX
        TABLESWITCHX LOOKUPSWITCHX UINT24 UINT8 INT32 OBJECT SLOTOBJECT REGEX INT8
	ATOMOBJECT UINT16PAIR TYPEMASK NAME PROP ELEM XMLNAME VARPROP MODEMASK SET
	DEL DEC INC INCDEC POST FOR ASSIGNING DETECTING BACKPATH LEFTASSOC DECLARING
	INDEXBASE CALLOP PARENHEAD INVOKE TMPSLOT TMPSLOT2 TMPSLOT_SHIFT TMPSLOT_MASK
	SHARPSLOT
    )],
    opcodes => [map $_->id, @Opcodes],
);
{
    my %seen;
    push @{$EXPORT_TAGS{all}},
        grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
our @EXPORT_OK = (qw(@Opcodes), @{$EXPORT_TAGS{all}});

sub val { &{$_[0]->id}; }

sub AUTOLOAD {
    our $AUTOLOAD;
    my $const;
    ($const = $AUTOLOAD) =~ s/.*:://;
    my ($err, $val) = _constant($const);
    croak $err if $err;
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}
sub DESTROY {}

1;

__END__

=head1 NAME

JSPL::SM::Opcode - Class that encapsulates SpiderMonkey's jsopcodes.

=head1 SYNOPSYS

 use JSPL::SM::Opcode qw(:opcodes @Opcodes);

 my $oppush = $Opcodes[JSOP_PUSH];
 print $oppush->name;  # 'push'

=head1 DESCRIPTION

Provides access to SM's jsopcodes. Useful if you ever need to work with
SpiderMonkey bytecode.  See F<jsopcode.tbl> is SM sources for details.

=head1 EXPORT TAGS

=over 4

=item B<jof> - The C<JOF_*> constants in F<jsopcode.h>.

=item B<opcodes> - The C<JSOP_*> enums in F<jsopcode.h>.

=back

=head1 INTERFACE

=head2 @Opcodes

This array hold the jsopcodes defined in SM. Every value is an C<JSPL::SM::Opcode>
object. You can use the C<JSOP_*> constants for indexing C<@Opcodes>.

=head1 INSTANCE METHODS

=over 4

=item id

Returns the I<id> of the jsopcode. For example "JSOP_PUSH"

=item val

Returns the number of the jsopcode, that is its index in C<@Opcodes>.

=item name

Returns the I<name> of the jsopcode. For example "push".

=item len

Returns the length of the jsopcode in bytes including any immediate operands,
or -1 for jsopcodes with variable len.

=item uses

Returns the number of stack elements consumed by the jsopcode, -1 if variadic.

=item defs

Returns the number of stack elements produced by the jsopcode.

=item prec

Returns the operator precedence, zero if not an operator.

=item format

Returns the encoding format of the jsopcode.

=back

=cut

