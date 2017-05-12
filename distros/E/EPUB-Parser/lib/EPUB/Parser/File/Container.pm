package EPUB::Parser::File::Container;
use strict;
use warnings;
use Carp;
use EPUB::Parser::File::Parser::Container;

use constant FILE_PATH => 'META-INF/container.xml';

sub new {
    my $class = shift;
    my $zip = ( shift || {} )->{zip} or croak "mandatory parameter 'zip'";
   
    my $self = bless {
        zip => $zip,
    } => $class;

    return $self;
}

sub parser {
    my $self = shift;
    $self->{parser}
        ||= EPUB::Parser::File::Parser::Container->new({ data => $self->data });
}

sub data {
    my $self = shift;
    $self->{data} ||= $self->{zip}->get_member_data({ file_path => FILE_PATH() });
}

sub opf_path {
    my $self = shift;
    $self->{opf_path} ||= $self->parser->single('/container:container/container:rootfiles/container:rootfile[1]/@full-path')->string_value;
}

1;

