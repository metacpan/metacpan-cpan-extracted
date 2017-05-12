package GoogleApps::Command::delete;
use Moose;
use Modern::Perl;
extends qw(MooseX::App::Cmd::Command);
# ABSTRACT: delete an user account
 
has username => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'u',
   documentation => 'name of Google User Account to delete',
   required => 1,
);

sub execute {
   my ($self, $opt, $args) = @_;
   if ($self->app->api->DeleteUser($self->username)) {
      say STDERR "User '", $self->username, "' deleted!";
      return 1;
   }
   else {
      die "unknow error on deleting user!";
   }
};

1;
