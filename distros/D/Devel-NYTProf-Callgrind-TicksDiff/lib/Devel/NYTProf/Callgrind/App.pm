use MooseX::Declare;

class Devel::NYTProf::Callgrind::App extends MooseX::App::Cmd  with MooseX::Getopt {
   

    # this is a workaround to keep it named Command.pm. Hopefully rjbs merges my
    # changes, so this wont be needed in the future.
    use constant plugin_search_path => 'Devel::NYTProf::Callgrind::Command';
    
    method default_command{
        'help';
    }
   
}
