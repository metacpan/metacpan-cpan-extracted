package Dist::Zilla::Plugin::DynamicManifest;
BEGIN {
  $Dist::Zilla::Plugin::DynamicManifest::VERSION = '0.0019';
}
# ABSTRACT: Dynamically build a sane MANIFEST


use Moose;
with qw/ Dist::Zilla::Role::FilePruner /;

has pruner => qw/ is ro lazy_build 1 isa CodeRef /;
sub _build_pruner {
    return sub { m{^(?!
        bin/|
        script/|
        TODO$|
        lib/.+(?<!ROADMAP)\.p(m|od)$|
        inc/|
        t/|
        Makefile\.PL$|
        README$|
        MANIFEST$|
        Changes$|
        META\.json$|
        META\.yml$|
        [^\/]+\.xs$
    )}x }
}

sub prune_files {
    my $self = shift;

    my $prune = $self->pruner;
    my $files = $self->zilla->files;
    @$files = grep {
        my $file = $_;
        local $_ = $file->name;
        if ( $prune->( $file ) ) {
            $self->log_debug([ 'pruning %s', $file->name ]);
            0;
        }
        else {
            1;
        }
    } @$files;

    return;

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::DynamicManifest - Dynamically build a sane MANIFEST

=head1 VERSION

version 0.0019

=head1 SYNOPSIS

In your L<Dist::Zilla> C<dist.ini>:

    [DynamicManifest]

=head1 DESCRIPTION

DynamicManifest will build a sane MANIFEST without the need for manually specifying MANIFEST or MANIFEST.SKIP.

In essence, DynamicManifest is a built-in MANIFEST.SKIP that will prune everything that doesn't look like it should be included. Specifically, it will use the following regular expression for pruning:

        m{^(?!
            bin/|
            script/|
            TODO$|
            lib/.+(?<!ROADMAP)\.p(m|od)$|
            inc/|
            t/|
            Makefile\.PL$|
            README$|
            MANIFEST$|
            Changes$|
            META\.json$|
            META\.yml$|
            \.xs$
        )}x

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

