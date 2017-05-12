package Log::Message::Structured::Stringify::Sprintf;
use MooseX::Role::Parameterized;
use MooseX::Types::Moose qw/ ArrayRef /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use namespace::autoclean;

parameter format_string => (
    isa      => NonEmptySimpleStr,
    required => 1,
);

parameter attributes => (
    isa => ArrayRef[NonEmptySimpleStr],
    required => 1,
    auto_deref => 1,
);

role {
    my $p = shift;

    my $format_string = $p->format_string;
    my @attributes = $p->attributes;

    requires $_ for grep { $_ ne 'previous_string' } @attributes;

    has previous_string => (
        isa => 'Str',
        is => 'rw',
        default => '',
    );

    around 'as_string' => sub {
        my $orig = shift;
        my $self = shift;
        $self->previous_string($self->$orig(@_));
        sprintf($format_string, map { defined() ? $_ : '<undef>' } @{$self->as_hash}{@attributes} );
    };

};

1;

=pod

=head1 NAME

Log::Message::Structured::Stringify::Sprintf - Traditional style log lines

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with 'Log::Message::Structured';

    has [qw/ foo bar /] => ( is => 'ro', required => 1 );

    # Note: you MUST compose these together and after defining your attributes!
    with 'Log::Message::Structured::Stringify::Sprintf' => {
        format_string => q{The value of foo is "%s" and the value of bar is "%s"},
        attributes => [qw/ foo bar /],
    }, 'Log::Message::Structured';

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(Event->new( foo => "ONE MILLION", bar => "ONE BILLION" ));
    # Logs an object which will stringify to:
    The value of foo is "ONE MILLION" and the value of bar is "ONE BILLION".

=head1 DESCRIPTION

Augments the C<as_string> method provided by L<Log::Message::Structured> as a
parameterised Moose role.

=head1 PARAMETERS

=head1 attributes

Array of attributes whos values will be interpolated into the format string.

=head2 format_string

This format string is fed to sprintf with the values from the attributes to
produce the output.

=head1 AUTHOR AND COPYRIGHT

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.
Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut

