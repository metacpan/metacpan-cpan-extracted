package {{ $name }};

use OpusVL::FB11::Plugin::FormHandler;
#with 'HTML::FormHandler::TraitFor::Model::DBIC';
with 'OpusVL::FB11::RolesFor::Form::Parsley';

#use HTML::FormHandler::Types qw/Collapse Trim/;

use v5.20;
use warnings;
use strict;

# ABSTRACT: A Form for a thing.
our $VERSION = '0';

#has_field name => (
#    type => 'Text',
#    required => 1,
#);

has_field submit_it => (
    type => 'Submit',
    widget => 'ButtonTag',
    widget_wrapper => 'None',
    value => '<i class="fa fa-floppy-o"></i> Save',
    element_attr => { class => ['btn', 'btn-primary']},
);


#sub validate {
#    my $self = shift;

#    unless ($self->field('fieldname') SOMETHING) {
#        $self->field('fieldname')->add_error('Error message');
#    }
#}


1;

__END__

=head1 NAME

{{ $name }} - 

=cut
