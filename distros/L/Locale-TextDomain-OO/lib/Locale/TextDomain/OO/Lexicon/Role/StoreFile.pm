package Locale::TextDomain::OO::Lexicon::Role::StoreFile; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR);
use Moo::Role;
use MooX::Types::MooseLike::Base qw(Str);
use namespace::autoclean;

our $VERSION = '1.017';

has filename => (
    is  => 'ro',
    isa => Str,
);

has file_handle => (
    is       => 'ro',
    ducktype => 'print',
);

sub store_content {
    my ($self, $content) = @_;

    if ( $self->file_handle ) {
        my $quoted_filename = $self->filename;
        $quoted_filename &&= qq{"$quoted_filename"};
        $self->file_handle->print( $self->file_handle, $content )
            or confess qq{Unable to print file$quoted_filename $OS_ERROR};
        return;
    }
    if ( $self->filename ) {
        my $filename = $self->filename;
        open my $file_handle, q{> :raw}, $self->filename
            or confess qq{Unable to open file "$filename" $OS_ERROR};
        $file_handle->print($content)
            or confess qq{Unable to print file "$filename" $OS_ERROR};
        $file_handle->close
            or confess qq{Unable to close file "$filename" $OS_ERROR};
        return;
    }

    return $content;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Lexicon::Role::StoreFile - Role to store a lexicon as file

$Id: StoreFile.pm 573 2015-02-07 20:59:51Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Lexicon/Role/StoreFile.pm $

=head1 VERSION

1.017

=head1 DESCRIPTION

This module contains methods that helps to store the lexicon as file.

Implements attributes "filename" and "file_handle".

=head1 SYNOPSIS

    with qw(
        Locale::TextDomain::OO::Lexicon::Role::StoreFile
    );

    $self->store_content($content);

=head1 SUBROUTINES/METHODS

=head2 method store_content

If "file_handle" is set the content will print;

If "filename" is set and not "file_handle" a file will be stored.

If both not set the content itself will be returned.

    $content = $self->store_content($content);

=head2 method filename

    $self->filename('myfile.myext')
    $self->store_content;

=head2 method file_handle

Set filename also to get a speaking error messages.
Must not a real filename if the handle is not a real file.

    my $filename = 'myfile.myext';
    $self->filename($filename);
    open my $file_handle, q{>}, $filename
        or confess qq{Unable to open file "$filename" $OS_ERROR};
    $self->file_handle($file_handle);
    $self->store_content;
    close $file_handle
        or confess qq{Unable to close file "$filename" $OS_ERROR};

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<English|English>

L<Moo::Role|Moo::Role>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
