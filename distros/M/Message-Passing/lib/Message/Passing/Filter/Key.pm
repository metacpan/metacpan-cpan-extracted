package Message::Passing::Filter::Key;
use Moo;
use MooX::Types::MooseLike::Base qw/ Str /;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Filter';

has key => (
    isa => Str,
    is => 'ro',
    required => 1,
);

has match => (
    isa => Str,
    is => 'ro',
    required => 1,
);

has match_type => (
    is => 'ro',
#    isa => enum(['regex', 'eq']),
    default => sub { 'eq' },
);

has _re => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $match = $self->match;
        if ($self->match_type eq 'regex') {
            return qr/$match/;
        }
        else {
            return qr/^\Q$match\E$/;
        }
    },
);

sub filter {
    my ($self, $message) = @_;
    my $re = $self->_re;
    my @key_parts = split /\./, $self->key;
    my $m = $message;
    do {
        my $part = shift(@key_parts);
        $m = (ref($m) eq 'HASH' && exists($m->{$part})) ? $m->{$part} : undef;
    } while ($m && scalar(@key_parts));
    return unless $m && !ref($m) && $m =~ /$re/;
    return $message;
}


1;

=head1 NAME

Message::Passing::Filter::Key - Filter a subset of messages out.

=head1 DESCRIPTION

This filter just removes messages which do not have a key matching a certain value.

=head1 ATTRIBUTES

=head2 key

The name of the key. You may use a C< foo.bar > syntax to indicate variables below the top level
of the hash (i.e. the example would look in C<< $msg->{foo}->{bar} >>.).

=head2 match

The value to match to determine if the message should be passed onto the next stage or filtered out.

=head2 match_type

The type of match to perform, valid values are 'regex' or 'eq', and the latter is the default.

=head1 METHODS

=head2 filter

Does the actual filtering work.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut