package Gapp::App::Types;
{
  $Gapp::App::Types::VERSION = '0.222';
}

use MooseX::Types -declare => [qw(
GappAppHookAction
)];

use MooseX::Types::Moose qw( Str );

subtype GappAppHookAction
    => as Str
    => where { $_ eq 'aggregate' || $_ eq 'halt' }
    => message { "hook action must be 'aggregate' or 'halt'" };

# accept aggr* for 'aggregate'
coerce GappAppHookAction
    => from Str
    => via { /^aggr/ ? 'aggregate' : undef };


1;