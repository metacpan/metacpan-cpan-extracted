
use strict;
use warnings;
use Test::More;

use_ok 'HTML::TurboForm';

{   # new() - fails as a hashref is required
    my $form = HTML::TurboForm->new();
    $form->add_element({ type => "Text", name => 'query' });
    $form->populate({ query => 'Question' });
    is $form->get_value('query'), 'Question', " .. new(), .. get_value('query')";
}
{   # new( {} ) - ok
    my $form = HTML::TurboForm->new({}); # a hashref is required
    $form->add_element({ type => "Text", name => 'query' });
    $form->populate({ query => 'Question' });
    is $form->get_value('query'), 'Question', " .. new({}), .. get_value('query')";
}
done_testing;