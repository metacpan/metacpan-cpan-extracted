package Mic::ContractConfig;
use strict;

sub configure {
    my ($contract_for) = @_;

    foreach my $class (keys %{ $contract_for }) {
        foreach my $type (keys %{ $contract_for->{$class} }) {
            if ($contract_for->{$class}{$type} =~ /^off|false$/i) {
                $contract_for->{$class}{$type} = 0;
            }
        }
        $Mic::Contracts_for{$class} = $contract_for->{$class};
        if ( $Mic::Contracts_for{$class}{all} ) {
            $Mic::Contracts_for{$class} = { map { $_ => 1 } qw/pre post invariant/ };
        }
    }
}

1;
