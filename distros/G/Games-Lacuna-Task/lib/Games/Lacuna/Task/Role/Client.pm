package Games::Lacuna::Task::Role::Client;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Games::Lacuna::Task::Client;

our $DEFAULT_DIRECTORY = Path::Class::Dir->new($ENV{HOME}.'/.lacuna');

has 'configdir' => (
    is              => 'rw',
    isa             => 'Path::Class::Dir',
    coerce          => 1,
    documentation   => 'Path to the lacuna directory [Default '.$DEFAULT_DIRECTORY.']',
    default         => sub { return $DEFAULT_DIRECTORY },
);

has 'client' => (
    is              => 'ro',
    isa             => 'Games::Lacuna::Task::Client',
    traits          => ['NoGetopt'],
    lazy_build      => 1,
    handles         => [qw(get_cache set_cache clear_cache request paged_request empire_name build_object storage_prepare storage_do get_stash has_stash stash)]
);

sub _build_client {
    my ($self) = @_;
    
    # Build new client
    my $client = Games::Lacuna::Task::Client->new(
        loglevel        => $self->loglevel,
        configdir       => $self->configdir,
        debug           => $self->debug,
    );
    
    return $client;
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::Client - Client glue code

=head1 METHODS

=head2 configdir

Path to the config directory.

=head2 client

L<Games::Lacuna::Task::Client> object. Most public methods in this class
are available via method delegation.

=cut
