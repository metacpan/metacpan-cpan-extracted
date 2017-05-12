package Devel::ebug::Backend::Plugin::Ping;
$Devel::ebug::Backend::Plugin::Ping::VERSION = '0.59';
use strict;
use warnings;


sub register_commands {
    return ( ping => { sub => \&ping } );

}

sub ping {
  my($req, $context) = @_;
  my $secret = $ENV{SECRET};
  die "Did not pass secret" unless $req->{secret} eq $secret;
  $ENV{SECRET} = "";
  return {
    version => $DB::VERSION,
  }
}

1;
