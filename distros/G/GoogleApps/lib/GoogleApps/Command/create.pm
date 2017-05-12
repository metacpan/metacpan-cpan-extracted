package GoogleApps::Command::create;
use Moose;
use Modern::Perl;
extends qw(MooseX::App::Cmd::Command);
# ABSTRACT: create a new user account
 
has username => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'u',
   documentation => 'name of new Google User Account',
   required => 1,
);
 
has firstname => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'f',
   documentation => 'first name of new Google User Account',
   required => 1,
);
 
has lastname => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'l',
   documentation => 'last name of new Google User Account',
   required => 1,
);
 
has password => (
   traits => [qw(Getopt)],
   isa => 'Str',
   is  => 'rw',
   cmd_aliases   => 'p',
   documentation => 'password of new Google User Account',
   required => 1,
);

sub execute {
   my ($self, $opt, $args) = @_;
   my $user = $self->app->api->CreateUser(
      userName   => $self->username,
      givenName  => $self->firstname,
      familyName => $self->lastname,
      password   => $self->password,
   ) or die "unknow error on creating user!";
   say STDERR "User '", $self->username, "' created!";
   return $user;
};

1;
