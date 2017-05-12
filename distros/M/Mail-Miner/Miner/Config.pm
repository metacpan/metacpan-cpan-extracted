package Mail::Miner::Config;

our ($db, $username, $password) = 
    @ENV{qw(MM_DATABASE MM_USERNAME MM_PASSWORD)};

if (($password and $password =~ m/^[\.\/]/ && ((-f $password) || (-d $password)))
  and open PSWD, ((-f $password) ? "<$password" : "<$password/$username")) {
  chomp($password = <PSWD>);
}

die "You don't seem to have the MM_* environment variables set up"
    unless $db;

1;

