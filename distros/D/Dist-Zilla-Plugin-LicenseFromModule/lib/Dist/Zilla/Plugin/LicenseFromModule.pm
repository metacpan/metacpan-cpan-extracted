package Dist::Zilla::Plugin::LicenseFromModule;
use strict;
our $VERSION = '0.05';

use Moose;
with 'Dist::Zilla::Role::LicenseProvider';

has 'override_author', is => 'rw', isa => 'Bool', default => 0;

has source_file => (
    is => 'ro',
    lazy => 1,
    isa => 'Str',
    builder => '_default_source_file',
);

sub _default_source_file {
    my $self = shift;
    my $pm = $self->zilla->main_module->name;
    (my $pod = $pm) =~  s/\.pm$/\.pod/;
    return -e $pod ? $pod : $pm;
}

sub _file_from_filename {
    my ($self, $filename) = @_;
    for my $file (@{$self->zilla->files}) {
        return $file if $file->name eq $filename;
    }
    die 'no file module $filename in dist';
}

use Software::LicenseUtils;
use Module::Load ();

sub should_override_author {
    my $self = shift;

    return unless $self->override_author;

    my $stash = $self->zilla->stash_named('%User');
    return unless $stash; # no %User stash means author is taken out of copyright_holder anyway

    return $stash->authors->[0] eq $self->zilla->authors->[0];
}

sub provide_license {
    my($self, $args) = @_;

    my $content = $self->_file_from_filename($self->source_file)->content;

    my $author = $self->author_from($content);
    my $year = $self->copyright_year_from($content);

    if ($self->should_override_author) {
        $self->zilla->{authors} = [ $author ]; # XXX ughhh because it's readonly
    }

    my @guess = Software::LicenseUtils->guess_license_from_pod($content);

    if (@guess != 1) {
        $self->log(["Failed to parse license from %s", $self->zilla->main_module->name]);
        return;
    }

    my $license_class = $guess[0];

    $self->log(["guessing from %s, License is %s\nCopyright %s %s",
                $self->source_file, $license_class,
                $year || '(unknown)', $author || '(unknown)']);

    Module::Load::load($license_class);

    return $license_class->new({
        holder => $author || $args->{copyright_holder},
        year   => $year   || $args->{copyright_year},
    });
}

# taken from Module::Install::Metadata::author_from (as well as Minilla)
sub author_from {
    my($self, $content) = @_;

    if ($content =~ m/
        =head \d \s+ (?:authors?)\b \s*
        ([^\n]*)
        |
        =head \d \s+ (?:licen[cs]e|licensing|copyright|legal)\b \s*
        .*? copyright .*? \d\d\d[\d.]+ \s* (?:\bby\b)? \s*
        ([^\n]*)
    /ixms) {
        my $author = $1 || $2;

        # XXX: ugly but should work anyway...
        if (eval "require Pod::Escapes; 1") { ## no critics.
            # Pod::Escapes has a mapping table.
            # It's in core of perl >= 5.9.3, and should be installed
            # as one of the Pod::Simple's prereqs, which is a prereq
            # of Pod::Text 3.x (see also below).
            $author =~ s{ E<( (\d+) | ([A-Za-z]+) )> }
            {
                defined $2
                ? chr($2)
                : defined $Pod::Escapes::Name2character_number{$1}
                ? chr($Pod::Escapes::Name2character_number{$1})
                : do {
                    warn "Unknown escape: E<$1>";
                    "E<$1>";
                };
            }gex;
        }
            ## no critic.
        elsif (eval "require Pod::Text; 1" && $Pod::Text::VERSION < 3) {
            # Pod::Text < 3.0 has yet another mapping table,
            # though the table name of 2.x and 1.x are different.
            # (1.x is in core of Perl < 5.6, 2.x is in core of
            # Perl < 5.9.3)
            my $mapping = ($Pod::Text::VERSION < 2)
                ? \%Pod::Text::HTML_Escapes
                : \%Pod::Text::ESCAPES;
            $author =~ s{ E<( (\d+) | ([A-Za-z]+) )> }
            {
                defined $2
                ? chr($2)
                : defined $mapping->{$1}
                ? $mapping->{$1}
                : do {
                    warn "Unknown escape: E<$1>";
                    "E<$1>";
                };
            }gex;
        }
        else {
            $author =~ s{E<lt>}{<}g;
            $author =~ s{E<gt>}{>}g;
        }
        return $author;
    }

    return;
}

sub copyright_year_from {
    my($self, $content) = @_;

    if ($content =~ m/
        =head \d \s+ (?:licen[cs]e|licensing|copyright|legal|authors?)\b \s*
        .*? copyright .*? ([\d\-]+)
    /ixms) {
        return $1;
    }

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::LicenseFromModule - Extract License and Copyright from its main_module file

=head1 SYNOPSIS

  ; dist.ini
  [LicenseFromModule]

=head1 DESCRIPTION

Dist::Zilla::Plugin::LicenseFromModule is a Dist::Zilla plugin to
extract license, author and copyright year from your main module's POD
document.

Dist::Zilla by default already extracts license from POD when it's not
specified, but it will bail out if you don't specify the right
copyright holder. This plugin will scan license B<and> copyright
holder from the POD document, like L<Module::Install>'s
C<license_from> and C<author_from>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Dist::Zilla> L<Dist::Zilla::Plugin::VersionFromModule>

=cut
