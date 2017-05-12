package Story;
use strict;
use warnings;
use HTML::FormHandler::Moose;

extends 'HTML::FormHandler::Model::DBIC';
with 'HTML::FormHandler::Render::Simple';
with 'HTML::FormHandlerX::Form::JQueryValidator';

has_field 'name'        => ( type => 'Text',     required => 1 );
has_field 'ref_code'    => ( type => 'Text',     required => 1 );
has_field 'summary'     => ( type => 'TextArea', required => 0 );
has_field 'description' => ( type => 'TextArea', required => 0 );
has_field 'start_date'  => ( type => 'Date', required => 0, format => "%d-%m-%y" );

1;

