use 5.014;
use utf8;
use warnings;

package Device::Inverter::KOSTAL::PIKO::Status;

our $VERSION = '0.01';

use Mouse;
use Mouse::Util::TypeConstraints;
use namespace::clean -except => 'meta';

sub _declare_attr {
    my ( $name, $type ) = @_;
    has $_, coerce => 1, is => 'ro', required => 1, isa => $type;
}

for (qw(Int Num)) {
    subtype "Maybe_$_" => as "Maybe[$_]";
    coerce "Maybe_$_"  => from Str => via {
        if   ( $_ eq 'x x x&nbsp' ) { undef }
        else                        { $_ }
    };
}

_declare_attr $_, 'Str' for qw(html status);
_declare_attr $_, 'Maybe_Int'
  for qw(ac_power_current total_energy),
  map( ( "power_l$_", "voltage_l$_" ), 1 .. 3 ),
  map "voltage_string_$_", 1, 2;
_declare_attr $_, 'Maybe_Num'
  for qw(ac_power_current daily_energy),
  map "current_string_$_", 1, 2;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_ == 1 && !ref $_[0] ? ( html => @_ ) : @_;
    ( my $html = $args{html} ) =~ y/\cM//d;
    state $RE_Int = qr/\d+|x x x&nbsp/;
    state $RE_Num = qr/0|\d+\.\d\d|x x x&nbsp/;
    $html =~ m{
<table cellspacing="0" cellpadding="0" width="770">
<tr><td></td></tr>
<tr>
<td width="190"></td>
<td colspan="2">
  <b>AC(?: power|-Leistung)</b></td>
<td>&nbsp</td>
<td>
  <b>(?:energy|Energie)</b></td></tr>
<tr><td height="10"></td></tr>

<tr>
<td width="190"></td>
<td width="100">
  (?:aktuell|current)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<ac_power_current>$RE_Int)</td>
<td width="140">&nbsp W</td>
<td width="100">
  (?:total energy|Gesamtenergie)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<total_energy>$RE_Int)</td>
<td width="50">&nbsp kWh</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  &nbsp</td>
<td width="70" align="right">
  &nbsp</td>
<td width="140">&nbsp</td>
<td width="100">
  (?:daily energy|Tagesenergie)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<daily_energy>$RE_Num)</td>
<td width="50">&nbsp kWh</td>
<td>&nbsp</td></tr>
<tr height="5"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  (?:status|Status)</td>
<td colspan="4">
  (?<status>[\w ]+)</td>
<td>&nbsp</td></tr>
<tr height="8"><td></td></tr>
<tr><td colspan="7">
<table align="top" width="100%"><tr>
<td width="182"></td>
<td><hr size="1"></font></td></tr>
<tr><td height="5"></td></tr></table>
</td></tr>
<tr>
<td width="190"></td>
<td colspan="2">
  <b>PV(?: generator|-Generator)</b></td>
<td width="140">&nbsp</td>
<td colspan="2">
  <b>(?:output power|Ausgangsleistung)</b></td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr><td height="10"></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  <u>String 1</u></td>
<td width="70">&nbsp</td>
<td width="140">&nbsp</td>
<td width="95">
  <u>L1</u></td>
<td width="70">&nbsp</td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr>
<td width="190"></td>
<td width="100">
  (?:voltage|Spannung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<voltage_string_1>$RE_Int)</td>
<td width="140">&nbsp V</td>
<td width="100">
  (?:voltage|Spannung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<voltage_l1>$RE_Int)</td>
<td width="30">&nbsp V</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr valign="top" align="left">
<td width="190">&nbsp</td>
<td width="100">
  (?:current|Strom)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<current_string_1>$RE_Num)</td>
<td width="140">&nbsp A</td>
<td width="100">
  (?:power|Leistung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<power_l1>$RE_Int)</td>
<td width="30">&nbsp W</td>
<td>&nbsp</td></tr>
<tr height="22"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  <u>String 2</u></td>
<td width="70">&nbsp</td>
<td width="140">&nbsp</td>
<td width="100">
  <u>L2</u></td>
<td width="70">&nbsp</td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr>
<td width="190"></td>
<td width="100">
  (?:voltage|Spannung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<voltage_string_2>$RE_Int)</td>
<td width="140">&nbsp V</td>
<td width="100">
  (?:voltage|Spannung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<voltage_l2>$RE_Int)</td>
<td width="30">&nbsp V</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr valign="top" align="left">
<td width="190">&nbsp</td>
<td width="100">
  (?:current|Strom)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<current_string_2>$RE_Num)</td>
<td width="140">&nbsp A</td>
<td width="100">
  (?:power|Leistung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<power_l2>$RE_Int)</td>
<td width="30">&nbsp W</td>
<td>&nbsp</td></tr>
<tr height="22"><td></td></tr>
<tr>
<td width="190"></td>
<td width="100">
  <u> </u></td>
<td width="70">&nbsp</td>
<td width="140">&nbsp</td>
<td width="100">
  <u>L3</u></td>
<td width="70">&nbsp</td>
<td width="30">&nbsp</td>
<td>&nbsp</td></tr>
<tr>
<td width="190"></td>
<td width="100">
   </td>
<td width="70" align="right" bgcolor="#EAF7F7">
   </td>
<td width="140">&nbsp
   </td>
<td width="95">
  (?:voltage|Spannung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<voltage_l3>$RE_Int)</td>
<td width="30">&nbsp V</td>
<td>&nbsp</td></tr>
<tr height="2"><td></td></tr>
<tr valign="top" align="left">
<td width="190">&nbsp</td>
<td width="95">
   </td>
<td width="70" align="right" bgcolor="#EAF7F7">
   </td>
<td width="140">&nbsp
 </td>
<td width="95">
  (?:power|Leistung)</td>
<td width="70" align="right" bgcolor="#FFFFFF">
  (?<power_l3>$RE_Int)</td>
<td width="30">&nbsp W</td>
<td>&nbsp</td></tr>

<tr><td height="15"></td></tr>
<tr><td colspan="7">
<table align="top" width="100%">
<tr><td width="182"></td>
<td><hr size="1"></font></td>
</tr><tr><td height="5"></td></tr></table>
</td></tr></table>
}
      or die "Cannot parse status page:\n$args{html}";
    %args = ( %+, %args );
    $class->$orig(%args);
};

__PACKAGE__->meta->make_immutable;
no Mouse;

1;

__END__

=encoding UTF-8

=head1 NAME

Device::Inverter::KOSTAL::PIKO::Status -
current status of a L<Device::Inverter::KOSTAL::PIKO> device

=head1 SYNOPSIS

    use Device::Inverter::KOSTAL::PIKO;
    my $device = Device::Inverter::KOSTALL:PIKO->new;
    my $status = $device->get_current_status;
    say $status->ac_power_current;

=head1 ATTRIBUTES

=over 4

=item html

HTML code of the status page which has been returned by the device

=item ac_power_current

=item status

=item total_energy

=item daily_energy

=item voltage_string_1

=item voltage_string_2

=item current_string_1

=item current_string_2

=item voltage_l1

=item voltage_l2

=item voltage_l3

=item power_l1

=item power_l2

=item power_l3

=back
