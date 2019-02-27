package MikroTik::Client::Response;
use MikroTik::Client::Mo;

use MikroTik::Client::Sentence;

has data     => [];
has sentence => sub { MikroTik::Client::Sentence->new() };

sub parse {
    my ($self, $buf) = @_;

    my $data = [];

    my $sentence = $self->sentence;
    while ($$buf) {
        my $words = $sentence->fetch($buf);
        last if $sentence->is_incomplete;

        my $item = {'.tag' => '', '.type' => (shift @$words)};
        push @$data, $item;

        next unless @$words;

        while (my $w = shift @$words) {
            $item->{$1 || $2} = $3 if ($w =~ /^(?:=([^=]+)|(\.tag))=(.*)/);
        }
    }

    return $self->{data} = $data;
}

1;

=encoding utf8

=head1 NAME

MikroTik::Client::Response - Parse responses from a buffer

=head1 SYNOPSIS

  use MikroTik::Client::Response;

  my $response = MikroTik::Client::Response->new();

  my $list = $response->parse(\$buf);
  for my $re (@$list) {
      my ($type, $tag) = delete @{$re}{'.type'. '.tag'};
      say "$_ => $re->{$_}" for keys %$re;
  }

=head1 DESCRIPTION

Parser for API protocol responses.

=head1 ATTRIBUTES

L<MikroTik::Client::Response> implements the following attributes.

=head2 data

  my $items = $response->data;

Sentences fetched in last operation;

=head2 sentence

  my $sentence = $response->sentence;
  $response->sentence(MikroTik::Client::Sentence->new());

L<MikroTik::Client::Sentence> object used to decode sentences from network buffer.

=head1 METHODS

=head2 parse

  my $list = $response->parse(\$buf);

Parses data from a buffer and returns list of hashrefs with attributes for each
sentence. There are some special attributes:

=over 2

=item '.tag'

  '.tag' => 1

Reply tag.

=item '.type'

  '.type' => '!re'

Reply type.

=back

=head1 SEE ALSO

L<MikroTik::Client>

=cut
