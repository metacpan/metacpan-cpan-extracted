package MikroTik::Client::Sentence;
use Mojo::Base '-base';

use Exporter 'import';
our @EXPORT_OK = qw(encode_sentence);

use MikroTik::Client::Query 'build_query';

has words => sub { [] };

sub encode_sentence {
    shift if ref $_[0];
    my ($command, $attr, $query, $tag)
        = (shift // '', shift // {}, shift, shift);

    my $sentence = _encode_word($command);

    $sentence .= _encode_word("=$_=" . ($attr->{$_} // '')) for keys %$attr;

    if ($query) {
        $sentence .= _encode_word($_) for @{build_query($query)};
    }

    $sentence .= _encode_word(".tag=$tag") if $tag;

    # Closing empty word.
    $sentence .= "\x00";

    return $sentence;
}

sub fetch {
    my ($self, $buff) = @_;
    my $words;

    if (defined(my $old_buff = delete $self->{_buff})) {
        $words = $self->{words};
        $$buff = $old_buff . $$buff;
    }
    else { $words = $self->{words} = [] }

    while (my $w = $self->_fetch_word($buff)) { push @$words, $w }
    return $words;
}

sub is_incomplete {
    return exists $_[0]->{_buff};
}

sub reset {
    delete @{$_[0]}{qw(words _buff)};
    return $_[0];
}

sub _encode_length {
    my $len = shift;

    my $packed;

    # Screw you, mikrotik engineers, just pack length as 4 bytes. >_<
    if ($len < 0x80) {
        $packed = pack 'C', $len;
    }
    elsif ($len < 0x4000) {
        $packed = pack 'n', ($len | 0x8000) & 0xffff;
    }
    elsif ($len < 0x200000) {
        $len |= 0xc00000;
        $packed = pack 'Cn', (($len >> 16) & 0xff), ($len & 0xffff);
    }
    elsif ($len < 0x10000000) {
        $packed = pack 'N', ($len | 0xe0000000);
    }
    else {
        $packed = pack 'CN', 0xf0, $len;
    }

    return $packed;
}

sub _encode_word {
    return _encode_length(length($_[0])) . $_[0];
}

sub _fetch_word {
    my ($self, $buff) = @_;

    return $self->{_buff} = '' unless my $buff_bytes = length $$buff;
    return do { $self->{_buff} = $$buff; $$buff = ''; }
        if $buff_bytes < 5 && $$buff ne "\x00";

    my $len = _strip_length($buff);
    my $word = substr $$buff, 0, $len, '';

    return do { $self->{_buff} = _encode_length($len) . $word; ''; }
        if (length $word) < $len;

    return $word;
}

sub _strip_length {
    my $buff = shift;

    my $len = unpack 'C', substr $$buff, 0, 1, '';

    if (($len & 0x80) == 0x00) {
        return $len;
    }
    elsif (($len & 0xc0) == 0x80) {
        $len &= ~0x80;
        $len <<= 8;
        $len += unpack 'C', substr $$buff, 0, 1, '';
    }
    elsif (($len & 0xe0) == 0xc0) {
        $len &= ~0xc0;
        $len <<= 16;
        $len += unpack 'n', substr $$buff, 0, 2, '';
    }
    elsif (($len & 0xf0) == 0xe0) {
        $len = unpack 'N', pack('C', ($len & ~0xe0)) . substr($$buff, 0, 3, '');
    }
    elsif (($len & 0xf8) == 0xf0) {
        $len = unpack 'N', substr $$buff, 0, 4, '';
    }

    return $len;
}

1;

=encoding utf8

=head1 NAME

MikroTik::Client::Sentence - Encode and decode API sentences

=head1 SYNOPSIS

  use MikroTik::Client::Sentence qw(encode_sentence);

  my $command = '/interface/print';
  my $attr    = {'.proplist' => '.id,name,type'};
  my $query   = {type => ['ipip-tunnel', 'gre-tunnel'], running => 'true'};
  my $tag     = 1;

  my $bytes = encode_sentence($command, $attr, $query, $tag);

  my $sentence = MikroTik::Client::Sentence->new();
  my $words = $sentence->fetch(\$bytes);
  say $_ for @$words;

=head1 DESCRIPTION

Provides subroutines for encoding API sentences and parsing them back into words.

=head1 METHODS

=head2 encode_sentence

  my $bytes = encode_sentence($command, $attr, $query, $tag);

Encodes sentence. Attributes is a hashref with attribute-value pairs. Query will
be parsed with L<MikroTik::Client::Query/build_query>.

Can be also called as an object method.

=head2 fetch

  my $words = $sentence->fetch(\$buff);

Fetches a sentence from a buffer and parses it into a list of API words. In a
situation when amount of data in the buffer are insufficient to complete the
sentence, already processed words and the remaining buffer will be stored in an
object. On a next call will prepend a buffer with kept data and merge a result
with the one stored from a previous call.


=head2 is_incomplete

  my $done = !$sentence->is_incomplete;

Indicates that a processed buffer was incomplete and remaining amount of data was
insufficient to complete a sentence.

=head2 reset

  my $sentence->reset;

Clears an incomplete status and removes a remaining buffer.

=head1 SEE ALSO

L<MikroTik::Client>

=cut

