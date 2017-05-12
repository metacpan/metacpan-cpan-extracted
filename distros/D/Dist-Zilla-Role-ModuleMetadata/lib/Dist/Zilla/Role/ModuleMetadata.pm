use strict;
use warnings;
package Dist::Zilla::Role::ModuleMetadata; # git description: v0.003-16-g7ff5130
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A role for plugins that use Module::Metadata
# KEYWORDS: zilla distribution plugin role metadata cache packages versions

our $VERSION = '0.004';

use Moose::Role;
use Module::Metadata 1.000005;
use Digest::MD5 'md5';
use namespace::autoclean;

# filename => md5 content => MMD object
my %CACHE;

sub module_metadata_for_file
{
    my ($self, $file) = @_;

    Carp::croak('missing file argument for module_metadata_for_file') if not $file;

    # handle dzil v4 files by assuming no (or latin1) encoding
    my $encoded_content = $file->can('encoded_content') ? $file->encoded_content : $file->content;

    # We cache on the MD5 checksum to detect if the file has been modified
    # by some other plugin since it was last parsed, making our object invalid.
    my $md5 = md5($encoded_content);
    my $filename = $file->name;
    return $CACHE{$filename}{$md5} if $CACHE{$filename}{$md5};

    open(
        my $fh,
        ($file->can('encoding') ? sprintf('<:encoding(%s)', $file->encoding) : '<'),
        \$encoded_content,
    ) or $self->log_fatal([ 'cannot open handle to %s content: %s', $filename, $! ]);

    $self->log_debug([ 'parsing %s for Module::Metadata', $filename ]);
    my $mmd = Module::Metadata->new_from_handle($fh, $filename);
    return ($CACHE{$filename}{$md5} = $mmd);
}

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        'Module::Metadata' => Module::Metadata->VERSION,
        version => $VERSION,
    };

    return $config;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ModuleMetadata - A role for plugins that use Module::Metadata

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::YourNewPlugin;
    use Moose;
    with
        'Dist::Zilla::Role::...',
        'Dist::Zilla::Role::ModuleMetadata';
    use namespace::autoclean;

    sub your_method {
        my $self = shift;

        my $file = ...; # perhaps via the :InstallModules filefinder?
        my $version = $self->module_metadata_for_file->($file)->version;
        ...
    }

=head1 DESCRIPTION

This L<role|Moose::Role> provides some common utilities for L<Dist::Zilla>
plugins which use L<Module::Metadata> and the information that it provides.

=head1 METHODS PROVIDED

=head2 C<module_metadata_for_file>

    my $mmd = $self->module_metadata_for_file($file);

Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
method returns a L<Module::Metadata> object for that file's content.

=for stopwords reparsing

Internally, this method caches these objects. If multiple plugins want an
object for the same file, this avoids reparsing it.

=head1 SEE ALSO

=over 4

=item *

L<Module::Metadata>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-ModuleMetadata>
(or L<bug-Dist-Zilla-Role-ModuleMetadata@rt.cpan.org|mailto:bug-Dist-Zilla-Role-ModuleMetadata@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
