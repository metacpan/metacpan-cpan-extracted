package Log::Message::Structured::Stringify::AsJSON;
use Moose::Role;
use namespace::autoclean;

use JSON::Any;
use utf8 ();

requires 'as_hash';

around 'as_string' => sub {
    my $orig = shift;
    my $self = shift;
    my $hashref = $self->as_hash;
    my $json = JSON::Any->objToJson( $hashref );
    utf8::decode($json) if !utf8::is_utf8($json) and utf8::valid($json); # if it's valid utf8 mark it as such
    return $json;
};


1;

__END__

=pod

=head1 NAME

Log::Message::Structured::Stringify::AsJSON - JSON log lines

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with qw/
        Log::Message::Structured
        Log::Message::Structured::Stringify::AsJSON
    /;

    has foo => ( is => 'ro', required => 1 );

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(message => Event->new( foo => "bar" ));
    # Logs:
    {"__CLASS__":"MyLogEvent","foo":1,"date":"2010-03-28T23:15:52Z","hostname":"mymachine.domain"}

=head1 DESCRIPTION

Augments the C<as_string> method provided by L<Log::Message::Structured> as a, by delegateing to
the C<objToJson> from L<JSON::Any> module, and thus returning a JSON string.

=head1 METHODS

=head2 as_string

Returns the event as JSON

=head1 AUTHOR AND COPYRIGHT

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.
Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut
