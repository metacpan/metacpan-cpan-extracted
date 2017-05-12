package {{$name}};

use MooseX::Declare;
use true;

#  PODNAME: {{$name}}
# ABSTRACT: Fun with {{$name}}!

class {{$name}} extends MooseX::App::Cmd with MooseX::Log::Log4perl {
    use MooseX::StrictConstructor;
    use MooseX::AlwaysCoerce;
    use MooseX::MultiMethods;
    use MooseX::Types::Moose -all;

    use v5.14;
    use Carp;
    use FindBin;
    use Moose::Autobox;

    use Data::Dumper;
    use Data::Printer;

    method BUILD {
        Log::Log4perl->init_and_watch( "$FindBin::Bin/../etc/log.conf", 10 );
        $self->log->trace( 'Object constructed' );
        $self->log->trace( p $self );
    }


}

=begin wikidoc

=end wikidoc

=cut



##### ##### ##### ##### ##### Cut here ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### #####

use true;
use MooseX::Declare;

#  PODNAME: {{ $name }}::Command
# ABSTRACT: Command class which all commands will inherit from.

class {{ $name }}::Command extends (MooseX::App::Cmd::Command, {{ $name }})
 with MooseX::Getopt::Dashes with MooseX::Log::Log4perl {
    use metaclass 'MooseX::MetaDescription::Meta::Class'; # TODO: Offer description-tag on attributes
    use MooseX::Types::Moose -all;
    has global => (
        is            => 'rw',
        isa           => Bool,
        default       => 0,
        documentation => q{[Bool] Some common option which is shared by all commands.},
    );
}

=begin wikidoc

=end wikidoc

=cut



##### ##### ##### ##### ##### Cut here ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### #####

package {{ $name }}::Types {
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose -all;
    use MooseX::Types -declare => [qw(

    )];

    #  PODNAME: {{ $name }}::Types
    # ABSTRACT: Types library for {{ $name }}::Types

    # use Module::Util;
    #
    # subtype VersionString,
    #      as Str,
    #   where { m/ ^ v\d{1,2}\.\d{1,2} $ /x },
    # message { qq<Unable to parse $_ as a VersionString. Needs to be something like `v1.0'>};
    #
    #  coerce VersionString,
    #    from Num,
    #     via { 'v' . $_ },
    #    from Str,
    #     via { /^v/ ? $_ : "v$_" };

}
1;