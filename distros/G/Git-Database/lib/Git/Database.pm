package Git::Database;
$Git::Database::VERSION = '0.011';
use strict;
use warnings;

use Module::Runtime qw( use_module );
use File::Spec;

sub _absdir {
    my ($dir) = @_;
    return    # coerce to an absolute path
      File::Spec->file_name_is_absolute($dir) ? $dir
      : ref $dir ? eval { ref($dir)->new( File::Spec->rel2abs($dir) ) }
                     || File::Spec->rel2abs($dir)
      :            File::Spec->rel2abs($dir);
}

use Moo::Object ();
use namespace::clean;

# all known backend stores
my @STORES = (

    # complete backends, fastest first
    'Git::Raw::Repository',
    'Git',
    'Git::Repository',
    'Git::Wrapper',
    'Git::Sub',

    # incomplete backends (don't do the Git::Database::Role::RefWriter role)
    'Cogit',
    'Git::PurePerl',
);

my %MIN_VERSION = (
    'Git::Raw::Repository' => 0.74,
    'Git::Repository'      => 1.300,
    'Git::Sub'             => 0.163320,
);

# all installed backend stores
my $STORES;

sub available_stores {
    $STORES ||= [ map eval { use_module( $_ => $MIN_VERSION{$_} || 0 ) }, @STORES ];
    return @$STORES;
}

# creating store from a standard set of paramaters
my %STORE_FOR = (
    'Cogit' => sub {
        my %args = (
            ( directory => _absdir($_[0]->{work_tree}) )x!! $_[0]->{work_tree},
            ( gitdir    => _absdir($_[0]->{git_dir})   )x!! $_[0]->{git_dir},
        );
        return Cogit->new( %args ? %args : ( directory => _absdir('.') ) );
    },
    'Git' => sub {
        return Git->repository(
            ( WorkingCopy => _absdir($_[0]->{work_tree}) )x!! $_[0]->{work_tree},
            ( Repository  => _absdir($_[0]->{git_dir})   )x!! $_[0]->{git_dir},
        );
     },
    'Git::PurePerl' => sub {
        my %args;
        $args{directory} = _absdir("$_[0]->{work_tree}") if $_[0]->{work_tree};
        $args{gitdir}    = _absdir("$_[0]->{git_dir}")   if $_[0]->{git_dir};
        return Git::PurePerl->new( %args ? %args : ( directory => _absdir('.') ) );
    },
    'Git::Raw::Repository' => sub {
        return Git::Raw::Repository->open(
            $_[0]->{work_tree} || $_[0]->{git_dir} || '.'
        );
    },
    'Git::Repository' => sub {
        return Git::Repository->new(
            ( work_tree => $_[0]->{work_tree} )x!! $_[0]->{work_tree},
            ( git_dir   => $_[0]->{git_dir}   )x!! $_[0]->{git_dir},
        );
    },
    'Git::Sub'     => sub { $_[0]->{work_tree} || $_[0]->{git_dir} || _absdir('.') },
    'Git::Wrapper' => sub {
        return Git::Wrapper->new(
            { dir => _absdir( $_[0]->{work_tree} || $_[0]->{git_dir} || '.' ) }
        );
    },
);

sub new {
    my $args = Moo::Object::BUILDARGS(@_);

    # store: an object that gives actual access to a git repo
    my ( $backend, $store );
    if ( defined( $store = $args->{store} ) ) {
        if ( $store eq '' ) {
            return use_module('Git::Database::Backend::None')->new;
        }
        elsif ( !ref $store || -d $store ) {
            return use_module('Git::Database::Backend::Git::Sub')
              ->new( store => $store );
        }
        $backend = ref($store) || 'Git::Sub';
    }

    # build the store using: backend, work_tree, git_dir
    else {
        if ( $backend = $args->{backend} ) {
            return use_module('Git::Database::Backend::None')->new
              if $backend eq 'None';
            use_module $backend, $MIN_VERSION{$backend} || 0
        }
        else {

            # build the list of all installed store classes
            my @stores = available_stores();

            # some really basic default
            return use_module('Git::Database::Backend::None')->new
              if !@stores;

            # pick the best available
            $backend = shift @stores;
        }
        $store = $STORE_FOR{$backend}->($args);
    }

    return use_module("Git::Database::Backend::$backend")->new( store => $store );
}

1;

__END__

=pod

=head1 NAME

Git::Database - Provide access to the Git object database

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Repository->new();

    # build a backend to access the store
    my $db = Git::Database::Backend::Git::Repository->new( store => $r );

    # or let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $r );

    # or let Git::Database assemble the store from its parts
    my $db = Git::Database->new(
        backend   => 'Git::Repository',
        work_tree => $work_tree,
    );

    my $db = Git::Database->new(
        backend => 'Git::Repository',
        git_dir => $git_dir,
    );

    # work in the current directory
    my $db = Git::Database->new( backend => 'Git::Repository' );

    # pick the best available backend
    my $db = Git::Database->new;

=head1 DESCRIPTION

Git::Database provides access from Perl to the object database stored
in a Git repository. It can use any supported Git wrapper to access
the Git object database maintained by Git.

Git::Database is actually a factory class: L</new> returns
L<backend|Git::Database::Tutorial/backend> instances.

Check L<Git::Database::Tutorial> for details.

=head1 METHODS

=head2 new

    my $r = Git::Repository->new;

    # $db is-a Git::Database::Backend::Git::Repository
    my $db = Git::Database->new( store => $r );

Return a L<backend|Git::Database::Tutorial/backend> object, based on
the parameters passed to C<new()>.

If the C<store> parameter is given, all other paramaters are ignored,
and the returned backend is of the class corresponding to the
L<store|Git::Database::Tutorial/store> object.

If the C<store> parameter is missing, the backend class is selected
according to the C<backend> parameter, or picked automatically among the
L<available store classes|available_stores> (picking the fastest
and more feature-complete among them). The actual store object
is then instantiated using the C<work_tree> and C<git_dir> optional
parameters. If none is given, the repository is assumed to be in the
current directory.

=head2 available_stores

    say for Git::Database->available_stores;

This class methods returns the list of L<store|Git::Database::Tutorial/store>
classes that are available (i.e. installed with a version matching the
minimum version requirements).

=head1 BACKEND METHODS

The backend methods are split between several roles, and not all backends
do all the roles. Therefore not all backend objects support all the
following methods.

=head2 From L<Git::Database::Role::Backend>

This is the minimum required role to be a backend. Hence this method is
always available.

=over 4

=item L<hash_object|Git::Database::Role::Backend/hash_object>

=back

=head2 From L<Git::Database::Role::ObjectReader>

=over 4

=item L<has_object|Git::Database::Role::ObjectReader/has_object>

=item L<get_object_meta|Git::Database::Role::ObjectReader/get_object_meta>

=item L<get_object_attributes|Git::Database::Role::ObjectReader/get_object_attributes>

=item L<get_object|Git::Database::Role::ObjectReader/get_object>

=item L<all_digests|Git::Database::Role::ObjectReader/all_digests>

=back

=head2 From L<Git::Database::Role::ObjectWriter>

=over 4

=item L<put_object|Git::Database::Role::ObjectWriter/put_object>

=back

=head2 From L<Git::Database::Role::RefReader>

=over 4

=item L<refs|Git::Database::Role::RefReader/refs>

=item L<ref_names|Git::Database::Role::RefReader/ref_names>

=item L<ref_digest|Git::Database::Role::RefReader/ref_digest>

=back

=head2 From L<Git::Database::Role::RefWriter>

=over 4

=item L<put_ref|Git::Database::Role::RefWriter/put_ref>

=item L<delete_ref|Git::Database::Role::RefWriter/delete_ref>

=back

=head1 SEE ALSO

=over 4

=item Objects

L<Git::Database::Object::Blob>,
L<Git::Database::Object::Tree>,
L<Git::Database::Object::Commit>,
L<Git::Database::Object::Tag>.

=item Backend roles

L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=item Backends

L<Git::Database::Backend::None>,
L<Git::Database::Backend::Git::Repository>,
L<Git::Database::Backend::Git::Sub>,
L<Git::Database::Backend::Git::PurePerl>,
L<Git::Database::Backend::Cogit>,
L<Git::Database::Backend::Git>,
L<Git::Database::Backend::Git::Wrapper>,
L<Git::Database::Backend::Git::Raw>.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::Database

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Database>

=item * MetaCPAN

L<http://metacpan.org/release/Git-Database>

=back

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2019 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
