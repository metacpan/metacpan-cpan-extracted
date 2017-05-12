use Test::More;

use lib qw(t/lib);

use Data::Dumper;
use My::Form::Story;


my $form = My::Form::Story->new();

my $expected_profile =  {
    'messages' => {
        'ref_code' => 'Ref code field is required',
        'name' => 'Name field is required'
    },
    'rules' => {
        'summary' => {},
        'ref_code' => {
            'required' => 1
        },
        'name' => {
            'required' => 1
        },
        'start_date' => {},
        'description' => {}
    }
};

is_deeply($form->to_jquery_validation_profile(), $expected_profile);

done_testing();
