package Lemonldap::NG::Portal::UserDB::Combination;

our $VERSION = '2.23.0';

sub new {

    # Find a already loaded instance of ::Auth::Combination
    my ($module) =
      grep { ref($_) eq "Lemonldap::NG::Portal::Auth::Combination" }
      values %{ $_[1]->{p}->loadedModules };
    return $module;
}

1;
