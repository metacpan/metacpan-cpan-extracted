package IO::File::WithFilename;

use 5.010001;
use strict;
use warnings;

use IO::File;

require Exporter;

use overload '""' => \&filename, fallback => 1;

our $VERSION = '0.01';

our @ISA = qw/IO::File Exporter/;

our @EXPORT = @IO::File::EXPORT;

sub open {
    my $self = shift;
    ${*$self} = $_[0]; # store the filename in the scalar slot
    $self->SUPER::open(@_);
}

sub filename {
    my $self = shift;
    return ${*$self};
}

1;
__END__

=head1 NAME

IO::File::WithFilename - filehandles that know their origin

=head1 SYNOPSIS

    use IO::File::WithFilename;

    my $fh = IO::File::WithFilename->new('../movies/kin-dza-dza.ogg', O_RDONLY);
    print $fh->filename, "\n";
    print "$fh\n"; # same as above

=head1 DESCRIPTION

This module does everything that C<IO::File> does, but implements C<filename>
method, that C<File::Temp> objects have. It lets you write the code that is
ignorant of what classes of objects it works with.

If you want to check if it is safe to call C<filename> method, you are
recommended to call C<can> method rather than to check an object's
inheritance:

    print $obj->filename, "\n" if eval { $obj->can('filename') };

=head2 EXPORT

Same as C<IO::File>, i. e. C<O_XXX> constants from the C<Fcntl> module
(if this module is available).

=head1 SEE ALSO

L<IO::File>, L<File::Temp>

=head1 AUTHOR

Ivan Fomichev, E<lt>ifomichev@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ivan Fomichev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
