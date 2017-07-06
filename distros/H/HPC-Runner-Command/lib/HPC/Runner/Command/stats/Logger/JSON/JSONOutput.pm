package HPC::Runner::Command::stats::Logger::JSON::JSONOutput;

use Moose::Role;
use namespace::autoclean;
use JSON;

has 'json_data' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { return [] }
);

after 'iter_submissions' => sub {
    my $self = shift;
    my $json = encode_json( $self->json_data );
    print $json;
    print "\n";
};

1;
