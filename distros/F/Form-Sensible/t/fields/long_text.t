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
            field_class => 'LongText',
            name => 'unlimited_text',
        },
        {
            field_class => 'LongText',
            name => 'long_text',
            maximum_length => 10,
            should_truncate => 0,
        },
        { 
            field_class => 'LongText',
            name => 'long_truncated_text',
            maximum_length => 10,
            should_truncate => 1,
        },

    ],
} );

{
    ## test maximum_length
    $form->set_values({
        unlimited_text => 'A' x 11,
        long_text => 'A' x 11,
        long_truncated_text => 'A' x 11,
    });
    my $validation_result = $form->validate();

    #print STDERR Dumper($validation_result->{error_fields});
    ok( !$validation_result->is_valid(), "form with field longer than max length failed");
    is( scalar(keys %{$validation_result->{error_fields}}), 1, "correct number of incorrect fields" );
    is( $validation_result->{error_fields}->{long_text}->[0], "Long text is too long", "too long text should not be valid");
}

done_testing();
