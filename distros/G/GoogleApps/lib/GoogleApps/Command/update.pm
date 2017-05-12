package GoogleApps::Command::update;
use Moose;
use Modern::Perl;
extends qw(MooseX::App::Cmd::Command);
# ABSTRACT: update an user account (for now support only password change)
 
has username => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'u',
   documentation => 'name of Google User Account to update',
   required => 1,
);
 
has password => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'p',
   documentation => 'new password of Google User Account',
   required => 1,
);

sub execute {
   my ($self, $opt, $args) = @_;
   my $user = $self->app->api->ChangePassword($self->username, $self->password)
      or die "unknow error on changing password!";
   say STDERR "Password for '", $self->username, "' changed!";
   return $user;
};

1;
