package MColPro::Util::Serial;

use Carp;
use Data::Dumper;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw( serial unserial deepcopy );

sub serial
{
    my $hash = shift;

    $Data::Dumper::Purity = 1;
    $Data::Dumper::Deepcopy = 1;
    return Dumper( $hash );
}

sub unserial
{
    my $dump = shift;

    my $VAR1;
    my $ret = eval $dump;

    croak $@ if $@;

    return $ret;
}

sub deepcopy
{
    return &unserial( &serial( shift ) );
}

1;
