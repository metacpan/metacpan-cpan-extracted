package GoogleApps::Command::retrieve;
use Moose;
use Modern::Perl;
extends qw(MooseX::App::Cmd::Command);
# ABSTRACT: retrieve an user account and print in stdout
 
has username => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'u',
   documentation => 'name of Google User Account',
   required => 1,
);

sub execute {
   my ($self, $opt, $args) = @_;
   use Data::Dumper;
   say Dumper $self->app->api->RetrieveUser($self->username);
};

1;
