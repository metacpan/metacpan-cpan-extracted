use strict;
use warnings;

=head1 NAME

JiftyTest::Action::DoNothing

=cut

package JiftyTest::Action::DoNothing;
our $VERSION = '0.07';

use base qw/JiftyTest::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {

  param title => 
    label       is "Title",
    max_length  is 50,
                is mandatory;

  param category => 
    label       is 'Category',
    max_length  is 30;

  param body => 
    label       is 'Entry',
    render      as 'Textarea';

};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    
    # Custom action code
    
    $self->report_success if not $self->result->failure;
    
    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message('Success');
}

1;

