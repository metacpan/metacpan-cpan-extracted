package Log::Message::Structured::Stringify::AsYAML;
use Moose::Role;
use namespace::autoclean;

use YAML::Any;

requires 'as_hash';

around 'as_string' => sub {
    my $orig = shift;
    my $self = shift;
    my $hashref = $self->as_hash;
    my $yaml = Dump( $hashref );
    return $yaml;
};


1;

__END__

=pod

=head1 NAME

Log::Message::Structured::Stringify::AsYAML - YAML log lines

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with qw/
        Log::Message::Structured
        Log::Message::Structured::Stringify::AsYAML
    /;

    has foo => ( is => 'ro', required => 1 );

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(message => Event->new( foo => "bar" ));

=head1 DESCRIPTION

Augments the C<as_string> method provided by L<Log::Message::Structured>, by
delegating to the C<Dump> function from L<YAML::Any> module, and thus returning
a YAML string.

=head1 METHODS

=head2 as_string

Returns the event as YAML

=head1 AUTHOR AND COPYRIGHT

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.
Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut
