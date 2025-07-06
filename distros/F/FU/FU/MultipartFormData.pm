package FU::MultipartFormData 1.2;
use v5.36;
use Carp 'confess';
use FU::Util 'utf8_decode';

sub _arg($d) { $d =~ s{^"(.+)"$}{$1 =~ s/\\([\\"])/$1/rg}er }

sub parse($pkg, $header, $data) {
    confess "Invalid multipart header '$header'"
        if $header !~ m{^multipart/form-data\s*;\s*boundary\s*=(.+)$};
    my $boundary = _arg $1;
    confess "Invalid multipart boundary '$boundary'" if $boundary !~ /^[\x21-\x7e]+$/;
    utf8::encode($boundary);

    my @a;
    while ($data =~ m{--\Q$boundary\E(?:--\r\n|\r\n((?:.+\r\n)+)\r\n)}xg) {
        my $hdrs = $1;
        $a[$#a]{length} = $-[0] - 2 - $a[$#a]{start} if @a;
        if (!$hdrs) {
            confess "Trailing garbage" if pos $data != length $data;
            last;
        }

        my $d = bless {
            data => $data,
            start => pos $data,
        }, $pkg;

        confess "Missing content-disposition header" if $hdrs !~ /content-disposition:\s*form-data(.+)/i;
        my $v = $1;
        my $pvalue = qr/("(?:\\[\\"]|[^\\"\r\n]+)*"|[^\s;"]*)/;
        confess "Missing 'name' parameter" if $v !~ /;\s*name\s*=\s*$pvalue/;
        $d->{name} = utf8_decode _arg $1;
        $d->{filename} = utf8_decode _arg $1 if $v =~ /;\s*filename\s*=\s*$pvalue/;

        if ($hdrs =~ /content-type:\s*$pvalue(?:\s*;\s*charset\s*=\s*$pvalue)?/i) {
            $d->{mime} = utf8_decode _arg $1;
            $d->{charset} = utf8_decode _arg $2 if $2;
        }
        push @a, $d;
    }
    confess "Missing end-of-data marker" if @a && !defined $a[$#a]{length};
    \@a
}

sub name     { $_[0]{name} }
sub filename { $_[0]{filename} }
sub mime     { $_[0]{mime} }
sub charset  { $_[0]{charset} }
sub length   { $_[0]{length} }

sub substr($o,$off,$len=undef) {
    $off += $o->{length} if $off < 0;
    $off = 0 if $off < 0;
    $off = $o->{length} if $off > $o->{length};

    $len //= $o->{length} - $off;
    $len += $o->{length} - 1 if $len < 0;
    $len = 0 if $len < 0;
    $len = $o->{length} - $off if $len > $o->{length} - $off;

    substr $o->{data}, $o->{start} + $off, $len;
}

sub data     { $_[0]->substr(0) }
sub value    { utf8_decode $_[0]->data }

sub syswrite($o, $fh) {
    my $off = $o->{start};
    my $end = $o->{start} + $o->{length};
    while ($off < $end) {
        my $r = syswrite $fh, $o->{data}, $end-$off, $off;
        return if !defined $r;
        $off += $r;
    }
    $o->{length};
}

sub save($o, $fn) {
    open my $F, '>', $fn or confess "Error opening '$fn': $!";
    defined $o->syswrite($F) or confess "Error writing to '$fn': $!";
}

sub describe($o) {
    my $head = eval { utf8_decode $o->substr(0, 100) };
    if (defined $head && $head =~ /\n/) {
        ($head) = split /\n/, $head, 2;
        $head .= '...';
    } elsif (defined $head && $o->{length} > 100) {
        $head .= '...';
    }
    $o->{name}.': '.join ' ',
        $o->{filename} ? "filename=$o->{filename}" : (),
        $o->{mime} ? "mime=$o->{mime}" : (),
        $o->{charset} ? "charset=$o->{charset}" : (),
        "length=$o->{length}",
        defined $head ? "value=$head" : ();
}

1;
__END__

=head1 NAME

FU::MultipartFormData - Parse multipart/form-data

=head1 SYNOPSIS

  my $fields = FU::MultipartFormData->parse($content_type_header, $request_body);

  for my $f (@$fields) {
      print "%s   %d\n", $f->name, $f->length;

      $f->save('file.png') if $f->name eq 'image';
  }

=head1 DESCRIPTION

This is a tiny module to parse an HTTP request body encoded as
C<multipart/form-data>, which is typically used to handle file uploads.

The entire request body is assumed to be in memory as a Perl string, but this
module makes an attempt to avoid any further copies of data values.

=head1 Parsing

=over

=item FU::MultipartFormData->parse($header, $body)

Returns an array of field objects from the given C<$header>, which must be a
valid value for the C<Content-Type> request header, and the given C<$body>,
which must hold the request body as a byte string. An error is thrown if the
header is not valid or parsing failed.

This module is pretty lousy and does not fully comform to any HTTP standards,
but it does happen to be able to parse POST data from any browser that I've
tried.

=back

=head1 Field Object

Each field is parsed into a field object that supports the following methods:

=over

=item name

Returns the field name as a Perl Unicode string.

=item filename

Returns the filename as a Perl Unicode string, or C<undef> if no filename was
provided.

=item mime

Returns the mime type extracted from the field's C<Content-Type> header, or
C<undef> if none was present.

=item charset

Returns the charset extracted from the field's C<Content-Type> header, or
C<undef> if none was present.

=item length

Returns the byte length of the field value.

=item data

Returns a copy of the field value as a byte string. You'll want to avoid using
this on large fields.

=item value

Returns a copy of the field value as a Unicode string. Uses C<utf8_decode()>
from L<FU::Util>, so also throws an error if the value contains control
characters.

=item substr($off, $len)

Equivalent to calling C<substr()> on the string returned by C<data>, but avoids
a copy of the entire field value.

=item syswrite($fh)

Write the field value to C<$fh> using Perl's C<syswrite()>, returns C<undef> on
error or the number of bytes written on success.

Can be used to write uploaded file data to a file or send it over a socket or
pipe, without making a full in-memory copy of the data.

=item save($fn)

Save the field value to the file C<$fn>, throws an error on failure.

=item describe

Returns a human-readable string to describe this field. Mainly for debugging
purposes, the exact format is subject to change.

=back

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
