package Dist::Zilla::Plugin::PerlTidy;
$Dist::Zilla::Plugin::PerlTidy::VERSION = '0.21';

# ABSTRACT: PerlTidy in Dist::Zilla

use Moose;
with(
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules', ':ExecFiles', ':TestFiles' ],
    },
);

has 'perltidyrc' => ( is => 'ro' );

sub munge_files {
    my ($self) = @_;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ( $self, $file ) = @_;

    return $self->_munge_perl($file) if $file->name =~ /\.(?:pm|pl|t)$/i;
    return if -B $file->name;    # do not try to read binary file
    return $self->_munge_perl($file) if $file->content =~ /^#!.*\bperl\b/;
    return;
}

sub _munge_perl {
    my ( $self, $file ) = @_;

    return if ref($file) eq 'Dist::Zilla::File::FromCode';
    return
        if $file->name
        and $file->name eq 't/00-compile.t'
        ;    # simply skip Dist::Zilla::Plugin::Test::Compile (RT 88601)

    my $source = $file->content;

    my $perltidyrc;
    if ( defined $self->perltidyrc ) {
        if ( -r $self->perltidyrc ) {
            $perltidyrc = $self->perltidyrc;
        } else {
            $self->log_fatal(
                [ "specified perltidyrc is not readable: %s", $perltidyrc ] );
        }
    }

    # make Perl::Tidy happy
    local @ARGV = ();

    my $destination;
    require Perl::Tidy;
    Perl::Tidy::perltidy(
        source      => \$source,
        destination => \$destination,
        ( $perltidyrc ? ( perltidyrc => $perltidyrc ) : () ),
    );

    $file->content($destination);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PerlTidy - PerlTidy in Dist::Zilla

=head1 VERSION

version 0.21

=head1 METHODS

=head2 munge_file

Implements the required munge_file method for the
L<Dist::Zilla::Role::FileMunger> role, munging each Perl file it finds.
Files whose names do not end in C<.pm>, C<.pl>, or C<.t>, or whose contents
do not begin with C<#!perl> are left alone.

=head2 SYNOPSIS

    # dist.ini
    [PerlTidy]

    # or
    [PerlTidy]
    perltidyrc = xt/.perltidyrc

=head2 DEFAULTS

If you do not specify a specific perltidyrc in dist.ini it will try to use
the same defaults as Perl::Tidy.

=head2 SEE ALSO

L<Perl::Tidy>

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Mark Gardner <mjgardner@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
