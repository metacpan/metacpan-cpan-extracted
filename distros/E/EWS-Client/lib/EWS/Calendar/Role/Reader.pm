package EWS::Calendar::Role::Reader;
BEGIN {
  $EWS::Calendar::Role::Reader::VERSION = '1.143070';
}
use Moose::Role;

with 'EWS::Calendar::Role::RetrieveWithinWindow','EWS::Calendar::Role::RetrieveAvailability';
use EWS::Calendar::Window;

sub retrieve {
    my ($self, $opts) = @_;
    if($opts->{'freebusy'}){
        return $self->retrieve_availability({
            window => EWS::Calendar::Window->new($opts),
            %$opts,
        });
    } else {
        return $self->retrieve_within_window({
            window => EWS::Calendar::Window->new($opts),
            %$opts,
        });
    }
}

no Moose::Role;
1;
