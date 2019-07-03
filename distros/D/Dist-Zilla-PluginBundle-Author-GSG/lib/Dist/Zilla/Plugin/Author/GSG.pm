package Dist::Zilla::Plugin::Author::GSG;
use Moose;
with qw(
    Dist::Zilla::Role::Plugin
);
use Git::Wrapper qw();
use version;
use namespace::autoclean;

# ABSTRACT: Grant Street Group defaults CPAN dists
our $VERSION = '0.0.11'; # VERSION

before 'BUILDARGS' => sub {
    my ($class, $args) = @_;

    $args->{zilla}->{authors}
        ||= ['Grant Street Group <developers@grantstreet.com>'];

    $args->{zilla}->{_license_class}    ||= 'Artistic_2_0';
    $args->{zilla}->{_copyright_holder} ||= 'Grant Street Group';

    if ( not $args->{zilla}->{_copyright_year} ) {
        my $git = Git::Wrapper->new( $args->{zilla}->root );

        # We need v1.7.5 of git in order to get all the flags
        # necessary to do all the things.
        my $git_version = $git->version || 0;
        $args->{zilla}
            ->log_fatal( "[Author::GSG] Git 1.7.5 or greater is required"
                . ", only have $git_version." )
            if $git_version < version->parse(v1.7.5);

        local $@;
        my ( $commit, $date ) = eval { local $SIG{__DIE__};
            $git->rev_list(qw( --max-parents=0 --pretty=format:%ai HEAD )) };

        my $year = 1900 + (localtime)[5];
        if ($date) {
            my $this_year = $year;
            $year = $1 if $date =~ /^(\d{4})/;
            $year .= " - $this_year" unless $year == $this_year;
        }
        else {
            $args->{zilla}->log("Didn't find copyright start date: $@");
        }

        $args->{zilla}->{_copyright_year} = $year;
    }
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::GSG - Grant Street Group defaults CPAN dists

=head1 VERSION

version 0.0.11

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
