use strict;

use Test::More;
use HTTP::Exception;

my @tests = (301 .. 304); # only as example
my @fields = qw(location); # has only one field for now

################################################################################
for my $status_code (@tests) {

    # setting fieldnames one by one
    for my $field_name (@fields) {
        my $field_value = rand;

        my $e = HTTP::Exception->new($status_code, $field_name => $field_value);
        _check_exception(
            $e,
            "$status_code / $field_name set with new",
            $field_name => $field_value
        );

        my $e2 = HTTP::Exception->new($status_code);
        $e2->location($field_value);
        _check_exception(
            $e,
            "$status_code / $field_name set with accessor",
            $field_name => $field_value
        );
    }

    # setting all fields at once
    my %field_mapping;
    @field_mapping{@fields} = ((rand()) x scalar @fields);
    my $e = HTTP::Exception->new($status_code, %field_mapping);
    _check_exception(
        $e,
        "all fields set at once",
        %field_mapping
    );
}

################################################################################
sub _check_exception {
    my $e = shift;
    my $message = shift;
    my %fields = @_;

    for my $field_name (keys %fields) {
        is $e->$field_name, $fields{$field_name}, $message;
    }
}

done_testing;