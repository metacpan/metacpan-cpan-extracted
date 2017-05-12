use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Data::Dumper;
use Form::Sensible;

use Form::Sensible::Form;

my $form = Form::Sensible->create_form( {
    name => 'test',
    fields => [
        { 
            field_class => 'Text',
            name => 'string',
            minimum_length => 6,
            maximum_length => 16,
            should_truncate => 1,
        },
        { 
            field_class => 'Text',
            name => 'string_no_min',
            maximum_length => 16,
            should_truncate => 1,
        },
        { 
            field_class => 'Text',
            name => 'string_no_trunc',
            maximum_length => 16,
            should_truncate => 0,
        },
    ],
} );

{
    ## test minimum_length
    $form->set_values({
        string => 'short',
        string_no_min => 'short',
        string_no_trunc => 'much longer than the short one',
    });
    my $validation_result = $form->validate();

    #print STDERR Dumper($validation_result->{error_fields});
    ok( !$validation_result->is_valid(), "form with field shorter than min length failed");
    is( scalar(keys %{$validation_result->{error_fields}}), 2, "correct number of incorrect fields" );
    is( $validation_result->{error_fields}->{string}->[0], "String is too short", "correct field is invalid with correct text");
    is( $validation_result->{error_fields}->{string_no_trunc}->[0], "String no trunc is too long", "correct field is invalid with correct text");
}

done_testing();
