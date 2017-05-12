use strict;

sub last 
#gm (filter => 'result', ) 
{
  $_[-1] 
}

sub LASTitem 
{
  $_[-1] 
}

sub one 
#gm (
#gm   filter => 'result', 
#gm   around => sub { 
#gm     my $self = shift; 
#gm     my $r = $self->call( 'one', @_ ); 
#gm     use Sys::Hostname;
#gm     $r."Local machine: ".hostname()."\n" 
#gm   },
#gm )
{
  SERVER->host." received: <@_>\n";
}

