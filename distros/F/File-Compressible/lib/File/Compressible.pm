package File::Compressible;

use strict;
use warnings;

use List::Util 'first';
use Exporter 'import';

our $VERSION   = '1.00';
our @EXPORT_OK = (qw(compressible));

our @compressible = qw(
    application/octet-stream
    application/x-sh
    application/x-executable-file
    application/postscript
    application/x-csh
    application/x-perl
    application/x-awk
    application/x-javascript
    application/x-dvi
    application/pdf
    application/msword
    application/rtf
    application/x-tar
    application/x-gtar
);
push @compressible, 'Lisp/Scheme program text';

our @compressible_re = ( qr|^text/|o, qr|^message/|o );

sub compressible {
    my $mime_type = shift;
    return 1 if first { $_ eq $mime_type } @compressible;
    for my $re (@compressible_re) {
        return 1 if $mime_type =~ m/$re/;
    }
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

File::Compressible - determine if a mime type is compressible

=head1 SYNOPSIS

  use File::Compressible 'compressible';
  use File::Type;
  ...
  my $ft = File::Type->new();
  for my $file (@files) {
    my $type = checktype_filename($file);
    next unless $type;
    next unless compressible($type);
    # do some compression magic!
  }


=head1 DESCRIPTION

File::Compressible supplies one exportable function, C<compressible>, which takes
a mime type and returns true if it is compressible, undef if not.

Compressible mime types are stored in a package variable,
C<@File::Compressible::compressible>.  It is concidered okay to modify this list
and future versioins will maintain this.  A second package variable contains
precompiled regular expressions that are tested against passed mime types, it
is named C<@File::Compressible::compressible_re>.

=head1 AUTHOR

Mike Greb E<lt>michael@thegrebs.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Mike Greb

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Type>

=cut
