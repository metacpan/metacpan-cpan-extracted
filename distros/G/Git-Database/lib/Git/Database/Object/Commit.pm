package Git::Database::Object::Commit;
$Git::Database::Object::Commit::VERSION = '0.010';
use Git::Database::Actor;
use DateTime;
use Encode qw( decode );

use Moo;
use namespace::clean;

with 'Git::Database::Role::Object';

sub kind {'commit'}

has commit_info => (
    is        => 'rwp',
    required  => 0,
    predicate => 1,
    lazy      => 1,
    builder   => 1,
);

sub BUILD {
    my ($self) = @_;
    die "One of 'digest' or 'content' or 'commit_info' is required"
      if !$self->has_digest && !$self->has_content && !$self->has_commit_info;
}

for my $attr (
    qw(
    tree_digest
    author
    author_date
    committer
    committer_date
    comment
    encoding
    )
    )
{
    no strict 'refs';
    *$attr = sub { $_[0]->commit_info->{$attr} };
}

sub parents_digest { @{ $_[0]->commit_info->{parents_digest} ||= [] }; }

sub _build_content {
    my ($self) = @_;

    if ( !$self->has_commit_info ) {
        my $attr = $self->_get_object_attributes();
        return $attr->{content} if exists $attr->{content};

        if ( exists $attr->{commit_info} ) {
            $self->_set_commit_info( $attr->{commit_info} );
        }
        else {
            die "Can't build content from these attributes: "
              . join( ', ', sort keys %$attr );
        }
    }

    my $content  = 'tree ' . $self->tree_digest . "\n";
    $content .= "parent $_\n" for $self->parents_digest;
    $content .= join(
        ' ',
        author => $self->author->ident,
        $self->author_date->epoch,
        DateTime::TimeZone->offset_as_string( $self->author_date->offset )
    ) . "\n";
    $content .= join(
        ' ',
        committer => $self->committer->ident,
        $self->committer_date->epoch,
        DateTime::TimeZone->offset_as_string( $self->committer_date->offset )
    ) . "\n";
    $content .= "\n";
    my $comment = $self->comment;
    chomp $comment;
    $content .= "$comment\n";

    return $content;
}

sub _build_commit_info {
    my ($self) = @_;

    if ( !$self->has_content ) {
        my $attr = $self->_get_object_attributes();
        return $attr->{commit_info} if exists $attr->{commit_info};

        if ( exists $attr->{content} ) {
            $self->_set_content( $attr->{content} );
        }
        else {
            die "Can't build content from these attributes: "
              . join( ', ', sort keys %$attr );
        }
    }

    my @lines = split "\n", $self->content;

    # parse the headers
    my %header;
    my $mergetag_num = 0;
    while ( my $line = shift @lines ) {
        my ( $key, $value ) = split / /, $line, 2;

        # multiline value that may appear multiple times
        $key = $mergetag_num++ . $key if $key eq 'mergetag';

        # each key points to an array ref
        push @{ $header{$key} }, $value;

        # handle continuation lines
        $header{''} = $header{$key} if $key;
    }
    delete $header{''};

    # construct commit_info from the header values
    my %commit_info = (

        # those appear once and only once
        tree_digest => ( delete $header{tree} )->[0],
        author      => ( delete $header{author} )->[0],
        committer   => ( delete $header{committer} )->[0],

        # may appear zero or one time (with a default value)
        encoding => ( delete $header{encoding} || ['utf-8'] )->[0],

        # optional list
        parents_digest => delete $header{parent} || [],
    );

    # we should have processed all possible keys at this stage
    die "Unknown commit keys: @{[ keys %header ]}"
      if keys %header;

    # the message is made of the remaining lines
    $commit_info{comment} =
      decode( $commit_info{encoding}, join "\n", @lines );

    # instantiate actors and datetimes
    for my $key (qw( author committer )) {
        my @data = split ' ', $commit_info{$key};
        my ( $email, $epoch, $tz ) = splice( @data, -3 );
        $commit_info{$key} = Git::Database::Actor->new(
            name => join( ' ', @data ),
            email => substr( $email, 1, -1 ),
        );
        $commit_info{"${key}_date"} = DateTime->from_epoch(
            epoch     => $epoch,
            time_zone => $tz
        );
    }

    return \%commit_info;
}

1;

__END__

=pod

=for Pod::Coverage
  BUILD
  has_commit_info

=head1 NAME

Git::Database::Object::Commit - A commit object in the Git object database

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    my $r      = Git::Database->new();       # current Git repository
    my $commit = $r->get_object('ef25e8');   # abbreviated digest

    # attributes
    $commit->kind;              # commit
    $commit->digest;            # ef25e81ba86b7df16956c974c8a9c1ff2eca1326
    $commit->tree_digest;       # b52168be5ea341e918a9cbbb76012375170a439f
    $commit->parents_digest;    # []
    ...;                        # etc., see below

=head1 DESCRIPTION

Git::Database::Object::Commit represents a C<commit> object
obtained via L<Git::Database> from a Git object database.

=head1 ATTRIBUTES

All major attributes (L</digest>, L</content>, L</size>, L</commit_info>)
have a predicate method.

=head2 kind

The object kind: C<commit>.

=head2 digest

The SHA-1 digest of the commit object.

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head2 commit_info

A hash reference containing the all the attributes listed below, as
values for the keys with the same names.

=head2 tree_digest

The SHA-1 digest of the tree object corresponding to the commit.

=head2 parents_digest

An array reference containing the list of SHA-1 digests of the
commit's parents.

=head2 author

A L<Git::Database::Actor> object representing the author of
the commit.

=head2 author_date

A L<DateTime> object representing the date at which the author
created the commit.

=head2 committer

A L<Git::Database::Actor> object representing the committer of
the commit.

=head2 committer_date

A L<DateTime> object representing the date at which the committer
created the commit.

=head2 comment

The text of the commit message.

=head2 encoding

The encoding of the commit message.

=head1 METHODS

=head2 new()

Create a new Git::Object::Database::Commit object.

One (and only one) of the C<content> or C<commit_info> arguments is
required.

C<commit_info> is a reference to a hash containing the keys listed
above, i.e. C<tree_digest>, C<parents_digest> (optional), C<author>,
C<author_date>, C<committer>, C<committer_date>, C<comment>, and
C<encoding> (optional).

=head1 SEE ALSO

L<Git::Database>,
L<Git::Database::Role::Object>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
