package Dist::Zilla::Plugin::Author::GSG;
use Moose;
with qw(
    Dist::Zilla::Role::LicenseProvider
);
use Git::Wrapper qw();
use namespace::autoclean;

# ABSTRACT: Grant Street Group defaults CPAN dists
# VERSION

around 'BUILDARGS' => sub {
    my ($orig, $self, $args) = @_;

    $args->{zilla}->{authors}
        ||= ['Grant Street Group <developers@grantstreet.com>'];

    $args->{zilla}->{_copyright_holder} ||= 'Grant Street Group';

    if ( not $args->{zilla}->{_copyright_year} ) {
        my ( $commit, $date ) = do { local $@; eval { local $SIG{__DIE__};
            Git::Wrapper->new('.')->RUN(
                qw( rev-list --max-parents=0 --pretty=format:%ai HEAD )) } };

        my $year = 1900 + (localtime)[5];
        if ($date) {
            my $this_year = $year;
            $year = $1 if $date =~ /^(\d{4})/;
            $year .= " - $this_year" unless $year == $this_year;
        }

        $args->{zilla}->{_copyright_year} = $year;
    }

    return $self->$orig($args);
};

sub provide_license {
    my ( $self, $conf ) = @_;

    my $license_class = $self->zilla->_license_class || 'Artistic_2_0';
    $license_class =~ s/^(?:Software::License::)?/Software::License::/;

    {
        local $@ = undef;
        {
            local $SIG{__DIE__} = 'DEFAULT';
            eval "require $license_class";
        }
        die if $@;
    }

    return $license_class->new( {
        holder => $conf->{copyright_holder},
        year   => $conf->{copyright_year},
    } );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::GSG - Grant Street Group defaults CPAN dists

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

If you don't want the whole L<Dist::Zilla::PluginBundle::Author::GSG>
you can get the licence and author default from this Plugin.

    name = Foo-Bar-GSG
    [@Basic]
    [Author::GSG]

Which is the same as

    name = Foo-Bar-GSG
    author = Grant Street Group <developers@grantstreet.com>
    license = Artistic_2_0
    copyright_holder = Grant Street Group
    copyright_year = # detected from git

    [@Basic]

=head1 DESCRIPTION

Provides a default license L<Software::License::Artistic_2_0>,
as well as default authors, copyright holder, and copyright years from git.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
