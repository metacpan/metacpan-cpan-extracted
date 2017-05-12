#!/usr/bin/perl
use strict;
use warnings;

# To test this, run it as:
#   plackup --host 127.0.0.1 --port 8080 app.psgi
# On browser, access page via:
#   http://127.0.0.1:8080


BEGIN {
    unshift @INC, '../lib';
}

use Plack::Request;
use HTML::FormBuilder::Validation;
use HTML::FormBuilder::Select;


sub get_form {
    my $form = HTML::FormBuilder::Validation->new(data => {
        name   => 'openAccForm',
        id     => 'openAccForm',
        class  => 'formObject grd-row-padding',
        method => 'post',
        action => '/test',
    });

    my $fieldset = $form->add_fieldset({ legend => 'details' });
    $fieldset->add_field({
        'label' => {
            'text' => 'Salutation',
            'for'  => 'salutation',
        },
        'input' => HTML::FormBuilder::Select->new(
            'id'      => 'salutation',
            'name'    => 'salutation',
            'options' => [ { value => '', text => 'Select Salutation' }, { value => 'Mr', text => 'Mr' }, { value => 'Ms', text => 'Ms' }, { value => 'Dr', text => 'Dr' } ],
        ),
        'error' => {
            'id'    => 'errorsalutation',
            'class' => 'errorfield'
        },
        'validation' => [{
                'type'    => 'regexp',
                'regexp'  => '^\w+$',
                'err_msg' => 'Please select salutation.',
            },
        ],
    });

    $fieldset->add_field({
        'label' => {
            'text' => 'Name',
            'for'  => 'name',
        },
        'input' => {
            'id'        => 'name',
            'name'      => 'name',
            'type'      => 'text',
            'maxlength' => 30,
        },
        'error' => {
            'id'    => 'errorname',
            'class' => 'errorfield'
        },
        'validation' => [{
                'type'    => 'regexp',
                'regexp'  => '^.{5}.*$',
                'err_msg' => 'Name should be > 5 characters.',
            },
            {
                'type'    => 'regexp',
                'regexp'  => '^[a-zA-Z\s\'.-]+$',
                'err_msg' => 'Please use only letters, spaces, hyphens, full-stops or apostrophes.',
            },
        ],
    });

    $fieldset->add_field({
        'label' => {},
        'input' => {
            'id'    => 'submit',
            'name'  => 'submit',
            'type'  => 'submit',
            'value' => 'Submit',
        },
        'error' => {
            'id'    => 'invalidinputfound',
            'class' => 'errorfield'
        },
    });

    my $server_side_validation_sub = sub {
        if ($form->get_field_value('name') !~ /^\w{10,20}$/) {
            $form->set_field_error_message('name', 'Name must be within 10 to 20 characters');
        }
    };
    $form->set_server_side_checks($server_side_validation_sub);

    return $form;
}

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $response = $req->new_response(200);
    $response->content_type('text/html');

    if ($req->method eq 'POST') {
        my $form = get_form();
        $form->set_input_fields({
            salutation  => $req->param('salutation'),
            name        => $req->param('name'),
        });

        if (not $form->validate()) {
            my $html = '<html><body>' . $form->build() . '</body></html>';
            $response->body($html);
        } else {
            $response->body('OK');
        }
    } else {
        my $html = '<html><body>' . get_form()->build() . '</body></html>';
        $response->body($html);
    }
    $response->finalize;
};

