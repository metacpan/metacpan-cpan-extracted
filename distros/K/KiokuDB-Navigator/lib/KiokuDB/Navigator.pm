package KiokuDB::Navigator;
use Moose;
use MooseX::Types::Path::Class;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use Try::Tiny;
use POSIX          ":sys_wait_h";
use Path::Class    ();
use File::ShareDir ();
use Browser::Open  ();

use JSORB;
use JSORB::Dispatcher::Path;
use JSORB::Server::Simple;
use JSORB::Server::Traits::WithStaticFiles;

use KiokuDB;
use KiokuDB::Backend::Serialize::JSPON::Collapser;

has 'db' => (
    is       => 'ro',
    isa      => 'KiokuDB',
    required => 1,
);

has 'doc_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        try {
            Path::Class::Dir->new(
                File::ShareDir::dist_dir('KiokuDB-Navigator')
            )
        } catch {
            # for development ..
            require Class::Inspector;
            Path::Class::File->new(
                Class::Inspector->loaded_filename( __PACKAGE__ )
            )->parent # KiokuDB
             ->parent # lib
             ->parent->subdir('share'),
        };
    }
);

has 'jsorb_namespace' => (
    is      => 'ro',
    isa     => 'JSORB::Namespace',
    default => sub {
        return JSORB::Namespace->new(
            name     => 'KiokuDB',
            elements => [
                JSORB::Interface->new(
                    name       => 'Navigator',
                    procedures => [
                        JSORB::Method->new(
                            name        => 'lookup',
                            method_name => '_lookup',
                            spec        => [ 'Str' => 'HashRef' ]
                        ),
                        JSORB::Method->new(
                            name        => 'root_set',
                            method_name => '_root_set',
                            spec        => [ 'Unit' => 'ArrayRef' ]
                        )
                    ]
                )
            ]
        );
    },
);

sub _lookup {
    my $self = shift;
    my $id   = shift;
    my $obj  = $self->db->lookup($id);

    (defined $obj)
        || die "No object found for $id\n";

    my $collapser = KiokuDB::Backend::Serialize::JSPON::Collapser->new;

    return $collapser->collapse_jspon(
        $self->db->live_objects->object_to_entry(
            $obj
        )
    );
}

sub _root_set {
    my $self = shift;
    my @root = $self->db->backend->root_entry_ids->all;
    return \@root;
}

sub _create_server {
    my $self = shift;
    JSORB::Server::Simple->new_with_traits(
        traits     => [
            'JSORB::Server::Traits::WithDebug',
            'JSORB::Server::Traits::WithStaticFiles',
            'JSORB::Server::Traits::WithInvocant',
        ],
        invocant   => $self,
        doc_root   => $self->doc_root,
        dispatcher => JSORB::Dispatcher::Path->new_with_traits(
            traits    => [ 'JSORB::Dispatcher::Traits::WithInvocant' ],
            namespace => $self->jsorb_namespace,
        )
    )
}

sub run {
    my $self = shift;

    my $s   = $self->db->new_scope;
    my $pid = $self->_create_server->background;

    Browser::Open::open_browser('http://localhost:9999/index.html');

    local $SIG{'INT'} = sub {
        kill TERM => $pid;
        exit(0);
    };

    # block waiting for the children to die
    # or someone to throw the INT signal.
    return if (my $x = CORE::wait()) < 0;
}

no Moose; 1;

__END__

=pod

=head1 NAME

KiokuDB::Navigator - KiokuDB Database Navigator

=head1 SYNOPSIS.

  use KiokuDB::Navigator;

  my $dir = KiokuDB->connect( ... );

  KiokuDB::Navigator->new( db => $dir )->run;

  # or you can use the KiokuDB::Cmd extension

  % kioku nav --dsn bdb:dir=root/db

=head1 DESCRIPTION

This is a KiokuDB database navigator and is meant to help
you browse the structure of your KiokuDB object database.

This is a very early version of this module, it still needs
a lot of polishing and additional features, but so far it
does a pretty good job. Try it and see.

=head1 METHODS

=over 4

=item B<run>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
