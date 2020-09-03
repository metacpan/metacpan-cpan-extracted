package File::LibMagic::Constants;

use 5.008;

use strict;
use warnings;

use Exporter qw( import );

our $VERSION = '1.23';

sub constants {
    return qw(
        MAGIC_CHECK
        MAGIC_COMPRESS
        MAGIC_CONTINUE
        MAGIC_DEBUG
        MAGIC_DEVICES
        MAGIC_ERROR
        MAGIC_MIME
        MAGIC_NONE
        MAGIC_PRESERVE_ATIME
        MAGIC_RAW
        MAGIC_SYMLINK
        MAGIC_PARAM_INDIR_MAX
        MAGIC_PARAM_NAME_MAX
        MAGIC_PARAM_ELF_PHNUM_MAX
        MAGIC_PARAM_ELF_SHNUM_MAX
        MAGIC_PARAM_ELF_NOTES_MAX
        MAGIC_PARAM_REGEX_MAX
        MAGIC_PARAM_BYTES_MAX
    );
}

our @EXPORT_OK = ('constants');

1;

# ABSTRACT: Contains a list of libmagic constant names that we use in many places

__END__

=pod

=encoding UTF-8

=head1 NAME

File::LibMagic::Constants - Contains a list of libmagic constant names that we use in many places

=head1 VERSION

version 1.23

=for Pod::Coverage .+

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/File-LibMagic/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for File-LibMagic can be found at L<https://github.com/houseabsolute/File-LibMagic>.

=head1 AUTHORS

=over 4

=item *

Andreas Fitzner

=item *

Michael Hendricks <michael@ndrix.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andreas Fitzner, Michael Hendricks, Dave Rolsky, and Paul Wise.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
