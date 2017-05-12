package Kwiki::Template::TT2::UTF8;
use Kwiki::Template::TT2 -Base;
use Kwiki::Template::TT2::UTF8::Provider;

our $VERSION = '0.02';

sub create_template_object {
    require Template;
    # XXX Make template caching a configurable option
    Template->new({
        LOAD_TEMPLATES => [
            Kwiki::Template::TT2::UTF8::Provider->new({
		INCLUDE_PATH => $self->path,
            })],
        TOLERANT => 0,
        COMPILE_DIR => $self->compile_dir,
        COMPILE_EXT => '.ttc',
    });
}

__DATA__

=head1 NAME

Kwiki::Template::TT2::UTF8 - UTF8 safe Kwiki Template Toolkit Class

=head1 INSTALLATION

Edit your config.yaml, and put this line into it:

    template_class: Kwiki::Template::TT2::UTF8

Then, do a 'kwiki -update'.

=head1 DESCRIPTION

This module provide a Template::Providor hack to deal with UTF8
characters in templates. With the base class any non-ASCII characters
would be encoded to utf8 as latin-1, which means Kanji characters will
be split into byes, and displaied corruptly.

This module is not a Kwiki plugin, therefore it's useless to edit the
C<plugins> file.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

=cut

