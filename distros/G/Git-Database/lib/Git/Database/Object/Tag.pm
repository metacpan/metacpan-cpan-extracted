package Git::Database::Object::Tag;
$Git::Database::Object::Tag::VERSION = '0.010';
use Git::Database::Actor;
use DateTime;
use Encode qw( decode );

use Moo;
use namespace::clean;

with 'Git::Database::Role::Object';

sub kind {'tag'}

has tag_info => (
    is        => 'rwp',
    required  => 0,
    predicate => 1,
    lazy      => 1,
    builder   => 1,
);

sub BUILD {
    my ($self) = @_;
    die "One of 'digest' or 'content' or 'tag_info' is required"
      if !$self->has_digest && !$self->has_content && !$self->has_tag_info;
}

for my $attr (
    qw(
    object
    type
    tag
    tagger
    tagger_date
    comment
    )
    )
{
    no strict 'refs';
    *$attr = sub { $_[0]->tag_info->{$attr} };
}

sub _build_tag_info {
    my ($self) = @_;

    if ( !$self->has_content ) {
        my $attr = $self->_get_object_attributes();
        return $attr->{tag_info} if exists $attr->{tag_info};

        if ( exists $attr->{content} ) {
            $self->_set_content( $attr->{content} );
        }
        else {
            die "Can't build content from these attributes: "
              . join( ', ', sort keys %$attr );
        }
    }

    my $tag_info = {};
    my @lines    = split "\n", $self->content;
    while ( my $line = shift @lines ) {
        my ( $key, $value ) = split ' ', $line, 2;

        if ( $key eq 'tagger' ) {
            my @data = split ' ', $value;
            my ( $email, $epoch, $tz ) = splice( @data, -3 );
            $tag_info->{tagger} = Git::Database::Actor->new(
                name => join( ' ', @data ),
                email => substr( $email, 1, -1 )
            );
            $tag_info->{tagger_date} = DateTime->from_epoch(
                epoch     => $epoch,
                time_zone => $tz
            );
        }
        else {
            $tag_info->{$key} = $value;
        }
    }
    $tag_info->{comment} = join "\n", @lines;
    return $tag_info;
}

sub _build_content {
    my ($self) = @_;

    if ( ! $self->has_tag_info ) {
        my $attr = $self->_get_object_attributes();
        return $attr->{content} if exists $attr->{content};

        if ( exists $attr->{tag_info} ) {
            $self->_set_tag_info( $attr->{tag_info} );
        }
        else {
            die "Can't build content from these attributes: "
              . join( ', ', sort keys %$attr );
        }
    }

    my $content;
    $content .= "$_ " . $self->$_ . "\n" for qw( object type tag );
    $content .= join(
        ' ',
        tagger => $self->tagger->ident,
        $self->tagger_date->epoch,
        DateTime::TimeZone->offset_as_string( $self->tagger_date->offset )
    ) . "\n";
    $content .= "\n";
    my $comment = $self->comment;
    chomp $comment;
    $content .= "$comment\n";

    return $content;
}

1;

__END__

=pod

=for Pod::Coverage
  BUILD
  has_tag_info

=head1 NAME

Git::Database::Object::Tag - A tag object in the Git database

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    my $r   = Git::Database->new();       # current Git repository
    my $tag = $r->get_object('f5c10c');   # abbreviated digest

    # attributes
    $tag->kind;              # tag
    $tag->digest;            # f5c10c1a841419d3b1db0c3e0c42b554f9e1eeb2
    $tag->object;            # ef25e81ba86b7df16956c974c8a9c1ff2eca1326
    $tag->type;              # commit
    ...;                     # etc., see below

=head1 DESCRIPTION

Git::Database::Object::Tag represents a C<tag> object
obtained via L<Git::Database> from a Git object database.

=head1 ATTRIBUTES

All major attributes (L</digest>, L</content>, L</size>, L</tag_info>)
have a predicate method.

=head2 kind

The object kind: C<tag>

=head2 digest

The SHA-1 digest of the digest object.

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head2 tag_info

A hash reference containing the all the attributes listed below, as
values for the keys with the same names.

=head2 object

The SHA-1 digest of the tagged object.

=head2 type

The type of the tagged object.

=head2 tag

The tag name.

=head2 tagger

A L<Git::Database::Actor> object representing the author of
the tag.

=head2 tagger_date

A L<DateTime> object representing the date at which the author
created the tag.

=head2 comment

The text of the tag.

=head1 METHODS

=head2 new()

Create a new Git::Object::Database::Tag object.

One (and only one) of the C<content> or C<tag> arguments is
required.

C<tag_info> is a reference to a hash containing the keys listed
above, i.e.  C<object>, C<type>, C<tag>, C<tagger>, C<tagger_time>,
and C<comment>.

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
