package Git::Database::Backend::Git;
$Git::Database::Backend::Git::VERSION = '0.012';
use Git::Version::Compare qw( ge_git );
use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git object'
          if !eval { $_[0]->isa('Git') }
    } ),
);

has object_factory => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { [ $_[0]->store->command_bidi_pipe( 'cat-file', '--batch' ) ] },
    predicate => 1,
    clearer   => 1,
);

has object_checker => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { [ $_[0]->store->command_bidi_pipe( 'cat-file', '--batch-check' ) ] },
    predicate => 1,
    clearer   => 1,
);

# Git::Database::Role::Backend
sub hash_object {
    my ( $self, $object ) = @_;
    my ( $pid, $in, $out, $ctx ) =
      $self->store->command_bidi_pipe( 'hash-object', '-t', $object->kind,
        '--stdin' );
    print {$out} $object->content;
    close $out;
    chomp( my $digest = <$in> );
    $self->store->command_close_bidi_pipe( $pid, $in, undef, $ctx ); # $out closed
    return $digest;
}

# Git::Database::Role::ObjectReader
sub get_object_meta {
    my ( $self, $digest ) = @_;
    my $checker = $self->object_checker;

    # request the object
    print { $checker->[2] } $digest, "\n";

    # process the reply
    local $/ = "\012";
    chomp( my $reply = $checker->[1]->getline );

    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $reply;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;
    my $factory = $self->object_factory;

    # request the object
    print { $factory->[2]} $digest, "\n";

    # process the reply
    my $out = $factory->[1];
    local $/ = "\012";
    chomp( my $reply = <$out> );

    # protect against weird cases like if $sha1 contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $reply;

    # git versions >= 2.11.0.rc0 throw more verbose errors
    if ( $parts[0] =~ /^(?:symlink|dangling|loop|notdir)$/ ) {
        <$out>;    # eat the next line
        return undef;
    }

    # object does not exist in the git object database
    return undef if $parts[-1] eq 'missing';

    # git versions >= 2.21.0.rc0 explicitely say if a sha1 is ambiguous
    return undef if $kind eq 'ambiguous';

    # read the whole content in memory at once
    my $res = read $out, (my $content), $size;
    if( $res != $size ) {
         $factory->close; # in case the exception is trapped
         $self->clear_object_factory;
         die "Read $res/$size of content from git";
    }

    # read the last byte
    $res = read $out, (my $junk), 1;
    if( $res != 1 ) {
         $factory->close; # in case the exception is trapped
         $self->clear_object_factory;
         die "Unable to finish reading content from git";
    }

    # careful with utf-8!
    # create a new hash with kind, digest, content and size
    return {
        kind       => $kind,
        size       => $size,
        content    => $content,
        digest     => $sha1
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;
    my $store = $self->store;
    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;

    # the --batch-all-objects option appeared in v2.6.0-rc0
    if ( ge_git $store->version, '2.6.0.rc0' ) {
        return map +( split / / )[0],
          grep /$re/,
          $store->command(qw( cat-file --batch-check --batch-all-objects ));
    }
    else {    # this won't return unreachable objects
        my ( $pid, $in, $out, $ctx ) =
          $store->command_bidi_pipe(qw( cat-file --batch-check ));

        my @digests =
          map +( split / / )[0], grep /$re/,
          map { print {$out} ( split / / )[0], "\n"; $in->getline }
          sort $store->command(qw( rev-list --all --objects ));
        $store->command_close_bidi_pipe(  $pid, $in, $out, $ctx );
        return @digests;
    }
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    my ( $pid, $in, $out, $ctx ) =
      $self->store->command_bidi_pipe( 'hash-object', '-t', $object->kind,
        '-w', '--stdin' );
    print {$out} $object->content;
    close $out;
    chomp( my $digest = <$in> );
    $self->store->command_close_bidi_pipe( $pid, $in, undef, $ctx ); # $out closed
    return $digest;
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    return {
        reverse map +( split / / ),
        $self->store->command(qw( show-ref --head ))
    };
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ($self, $refname, $digest ) = @_;
    $self->store->command( 'update-ref', $refname, $digest );
}

sub delete_ref {
    my ($self, $refname ) = @_;
    $self->store->command( 'update-ref', '-d', $refname );
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    return if $in_global_destruction;    # why bother?

    $self->store->command_close_bidi_pipe( @{ $self->object_factory } )
      if $self->has_object_factory;
    $self->store->command_close_bidi_pipe( @{ $self->object_checker } )
     if $self->has_object_checker;
}

1;

__END__

=pod

=for Pod::Coverage
  has_object_checker
  has_object_factory
  DEMOLISH
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git - A Git::Database backend based on Git

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    # get a store
    my $r  = Git->new();

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads and writes data from a Git repository using the
L<Git> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016-2019 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
