# ABSTRACT: Parser glue between YAML::PP and LibYAML::FFI
package LibYAML::FFI::YPP::Parser;
use strict;
use warnings;

use LibYAML::FFI;
use LibYAML::FFI::YPP;
use base 'YAML::PP::Parser';

our $VERSION = 'v0.0.1'; # VERSION

sub parse {
    my ($self) = @_;
    my $reader = $self->reader;
    my $parser;
    my $events = [];
    if (0 and $reader->can('open_handle')) {
#        if (openhandle($reader->input)) {
#            my $test = YAML::LibYAML::API::XS::parse_filehandle_events($reader->open_handle, $events);
#        }
#        else {
#            my $test = YAML::LibYAML::API::XS::parse_file_events($reader->input, $events);
#        }
    }
    else {
        $parser = LibYAML::FFI::Parser->new;
        my $ok = $parser->yaml_parser_initialize or die "Could not create parser";
        my $yaml = $reader->read;
        $parser->yaml_parser_set_input_string($yaml, length($yaml));
        my $event = LibYAML::FFI::Event->new;
        while (1) {
            my $ok = $parser->yaml_parser_parse($event);
            my $type = $event->type;
            my $event_hash = $event->to_hash;
            my $name = $event_hash->{name};
            $self->callback->( $self, $name => $event_hash );
            last unless $ok;
            last if $type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT;
        }
    }
}

1;
