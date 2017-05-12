use strictures 1;

# lots of this stuff was sponsored by socialflow.com

package JSON::Diffable;

use JSON::MaybeXS ();
use Exporter 'import';

our $VERSION = '0.000002'; # 0.0.2

$VERSION = eval $VERSION;

my $real = JSON::MaybeXS->new->relaxed->allow_nonref->utf8;

our @EXPORT_OK = qw( encode_json decode_json );

sub encode_json {
    my $data = shift;
    return _encode($data, 0);
}

sub decode_json {
    my $str = shift;
    return $real->decode($str);
}

sub _indent {
    my $str = shift;
    $str =~ s{^}{  }gm;
    return $str;
}

sub _encode {
    my $data = shift;
    if (ref $data eq 'HASH') {
        return sprintf "{\n%s}",
            join '',
            map {
                my $key  = $real->encode($_);
                my $data = _encode($data->{$_});
                _indent("$key: $data") . ",\n";
            }
            sort keys %$data;
    }
    elsif (ref $data eq 'ARRAY') {
        return sprintf "[\n%s]",
            join '',
            map {
                _indent(_encode($_)) . ",\n";
            }
            @$data;
    }
    else {
        return $real->encode($data);
    }
}

1;

__END__

=head1 NAME

JSON::Diffable - A relaxed and easy diffable JSON variant

=head1 SYNOPSIS

    use JSON::Diffable qw( encode_json decode_json );

    $json = encode_json $data;
    $data = decode_json $json;

=head1 DESCRIPTION

This module allows to create a JSON variant that is suitable for easy
diffing. This means:

=over

=item * Commas after each hash or array element.

=item * Consistent indentation

=item * One line per entry

=back

The data can be read again by a relaxed L<JSON> parser or the exported
L</decode_json> function.

=head1 EXPORTS

=head2 encode_json

    my $json = encode_json($data);

Turns a Perl data structure into diffable JSON.

=head2 decode_json

    my $data = decode_json($json);

Turns relaxed JSON into a Perl data structure.

=head1 AUTHOR

 Robert Sedlacek <r.sedlacek@shadowcat.co.uk>

=head1 SPONSORED

The development of this module was sponsored by L<http://socialflow.com/>.

=cut
