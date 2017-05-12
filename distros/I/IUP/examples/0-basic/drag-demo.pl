# IUP::Text DRAG-and-DROP demo (drag part)

use strict;
use warnings;

use IUP ':all';

my $text = IUP::Text->new( 
    VALUE           => "Write a text, press Ctrl-Q to exit",
    EXPAND          => "HORIZONTAL",
    K_ANY           => sub {
                             my ($self, $c) = @_;
                             return IUP_CLOSE if $c == K_cQ;
                             return IUP_DEFAULT;
                           },
    DRAGSOURCE      => 'YES',
    DRAGTYPES       => "TEXT,STRING",                           
    DRAGBEGIN_CB    => sub { warn "DRAGBEGIN_CB\n" },
    DRAGEND_CB      => sub { warn "DRAGEND_CB\n" },
    DRAGDATASIZE_CB => sub { 
                             my ($self) = @_;
                             my $l = length $self->VALUE;
                             warn "DRAGDATASIZE_CB VALUE.len=$l\n"; 
                             return $l+1;
                           },
    DRAGDATA_CB     => sub { 
                             my ($self, $type, $size) = @_;
                             warn length $self->VALUE;
                             return IUP_DEFAULT, $self->VALUE;
                       },
);

my $dlg = IUP::Dialog->new( child=>$text, TITLE=>"IUP::Text - DRAG-and-DROP demo", SIZE=>"QUARTERxQUARTER" );
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);
$text->SetFocus();
IUP->MainLoop;
