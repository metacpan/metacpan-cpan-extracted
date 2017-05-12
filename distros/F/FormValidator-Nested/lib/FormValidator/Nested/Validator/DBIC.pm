package FormValidator::Nested::Validator::DBIC;
use strict;
use warnings;
use utf8;


sub unique {
    my ( $value, $options, $req, $param_name ) = @_;

    return 0 if !defined $options->{resultset};

    my %criteria = ();
    if ( !$options->{criteria} ) {
        # criteriaが指定されてない場合
        %criteria = (
            $param_name => $value,
        );
    }
    else {
        while ( my ($name, $check_value) = each %{$options->{criteria}} ) {
            my $op = '=';
            if ( ref $check_value eq 'HASH' ) {
                # operand指定
                ($op)          = keys   %{$check_value};
                ($check_value) = values %{$check_value};
            }
            if ( $check_value =~ m/^`([^`]*)`$/ ) {
                # eval
                $check_value = eval($1); ## no critic
            
            }
            elsif ( $check_value eq '__value__' ) {
                $check_value = $value;
            }
            $criteria{$name} = {$op => $check_value};
        }
    }

    my $count = $options->{resultset}->count(\%criteria);

    return $count > 0 ? 0 : 1;
}

sub exist {
    return !unique(@_);
}


1;
