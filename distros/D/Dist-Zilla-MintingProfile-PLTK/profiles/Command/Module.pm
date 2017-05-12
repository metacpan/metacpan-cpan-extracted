use true;
use MooseX::Declare;

#  PODNAME: Text::Toolkit::PLTK::Command::{{$name}}
# ABSTRACT: Short description of {{$name}}

class Text::Toolkit::PLTK::Command::{{$name}} extends (MooseX::App::Cmd::Command,Text::Toolkit::PLTK)
 with MooseX::Log::Log4perl
 with MooseX::Getopt::Dashes
 with Text::Toolkit::PLTK::Role::Command
{
    use Text::Toolkit::PLTK::Syntax;

    ### App::Cmd
    method execute     { say for $self>result } # implement views!
    method description { "{{$name}} help" }
    sub usage_desc     { "This is {{$name}}'s usage description" }
    sub description    { "{{$name}} description" }
    sub abstract       { "This is what {{$name}} does" }


}

=begin wikidoc

= SYNOPSIS

=end wikidoc

=cut
