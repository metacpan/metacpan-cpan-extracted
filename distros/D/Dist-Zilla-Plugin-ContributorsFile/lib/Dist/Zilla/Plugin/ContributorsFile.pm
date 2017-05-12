package Dist::Zilla::Plugin::ContributorsFile;
BEGIN {
  $Dist::Zilla::Plugin::ContributorsFile::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: add a file listing all contributors
$Dist::Zilla::Plugin::ContributorsFile::VERSION = '0.3.0';
use strict;
use warnings;

use Moose;
use Dist::Zilla::File::InMemory;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::FilePruner
    Dist::Zilla::Role::TextTemplate
/;

has filename => (
    is => 'ro',
    default => 'CONTRIBUTORS',
);

has contributors => (
    traits => [ 'Array' ],
    isa => 'ArrayRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        return [ map {
                Dist::Zilla::Plugin::ContributorsFile::Contributor->new($_) 
            } @{ $self->zilla->distmeta->{x_contributors} || [] }
        ];
    },
    handles => {
        has_contributors => 'count',
        all_contributors => 'elements',
    },
);

sub munge_file {
    my( $self, $file ) = @_;

    return unless $file->name eq $self->filename;

    return $self->log( 'no contributor detected, skipping file' )
        unless $self->has_contributors;

    $file->content( $self->fill_in_string(
        $file->content, {
            distribution => uc $self->zilla->name,
            contributors => [ $self->all_contributors ],
        }
    ));

}

sub gather_files {
    my $self = shift;

    my $file = Dist::Zilla::File::InMemory->new({ 
            content => $self->contributors_template,
            name    => $self->filename,
        }
    );

    $self->add_file($file);
}

sub prune_files {
    my $self = shift;

    return if $self->has_contributors;

    $self->log( 'no contributors, pruning file' );

    for my $file ( grep { $_->name eq $self->filename } @{ $self->zilla->files } ) {
        $self->zilla->prune_file($file);
    }

}

sub contributors_template {
    return <<'END_CONT';

# {{$distribution}} CONTRIBUTORS #

This is the (likely incomplete) list of people who have helped
make this distribution what it is, either via code contributions, 
patches, bug reports, help with troubleshooting, etc. A huge
'thank you' to all of them.

{{ 
    for my $contributor ( @contributors ) {
        $OUT .= sprintf "    * %s\n", $contributor->name;
    } 
}}

END_CONT

}

__PACKAGE__->meta->make_immutable;
no Moose;

package
    Dist::Zilla::Plugin::ContributorsFile::Contributor;

use overload 
    '""' => sub { sprintf "%s <%s>", @$_ };

sub new {
    my $class = shift;

    my @self;

    if( @_ == 2 ) {
        @self = @_;
    }
    else {
        @self = shift =~ /^\s*(.*?)\s*<(.*?)>\s*$/
    }

    return bless \@self, $class;
}

sub name  { $_[0][0] }
sub email { $_[0][1] }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ContributorsFile - add a file listing all contributors

=head1 VERSION

version 0.3.0

=head1 SYNOPSIS

In dist.ini:

    " any plugin populating x_contributors in the META files
    [Git::Contributors]

    [ContributorsFile]
    filename = CONTRIBUTORS

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::ContributorsFile> populates a I<CONTRIBUTORS> file
with all the contributors of the project as found under the
I<x_contributors> key in the META files.

The generated file will look like this:

    # FOO-BAR CONTRIBUTORS #

    This is the (likely incomplete) list of people who have helped
    make this distribution what it is, either via code contributions, 
    patches, bug reports, help with troubleshooting, etc. A huge
    'thank you' to all of them.

        * Albert Zoot
        * Bertrand Maxwell

Note that if no contributors beside the actual author(s) are found,
the file will not be created.

=head1 CONFIGURATION OPTIONS

=head2 filename

The name of the contributor file that is created. Defaults to I<CONTRIBUTORS>.

=head1 TRICKS

Refer to David Golden's blog entry at 
L<http://www.dagolden.com/index.php/1921/how-im-using-distzilla-to-give-credit-to-contributors/>
to get introduced to the C<Dist::Zilla> contributor modules.

Git's C<.mailmap> file is useful to deal with contributors with several email
addresses:
L<https://www.kernel.org/pub/software/scm/git/docs/git-shortlog.html>.

To give credit to bug reporters and other persons who don't commit code
directly, you can use empty git commits:

    git commit --allow-empty --author="David Golden <dagolden@cpan.org>" -m "..."

To populate the META file with the C<x_contributors>, you probably want to use
either L<Dist::Zilla::Plugin::Git::Contributors> or
L<Dist::Zilla::Plugin::ContributorsFromGit>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::ContributorsFromGit>

L<Dist::Zilla::Plugin::Git::Contributors>

L<Pod::Weaver::Section::Contributors>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
