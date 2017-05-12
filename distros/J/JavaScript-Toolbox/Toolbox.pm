package JavaScript::Toolbox;

require v5.6;

use strict;
use warnings;

use HTTP::BrowserDetect;


our $VERSION = '0.01';

sub new {
  my ($proto, %args) = @_;

  my $class = ref($proto) || $proto;
  my $self  = {};

  $self->{BROWSER} = new HTTP::BrowserDetect($ENV{'HTTP_USER_AGENT'});

  bless ($self, $class);
  return $self;
}


1;
__END__

=head1 NAME

JavaScript::Toolbox - Collection of JavaScript Tools.

=head1 SYNOPSIS

  use JavaScript::Toolbox::popUpBox;

  $popup = new JavaScript::Toolbox::popUpBox;

  $popup->content('hello');

  $popup->script();
  $popup->tag();

=head1 DESCRIPTION

Stub documentation for JavaScript::Toolbox, created by h2xs.


    .------------------.         .------------------.
    |   popUpBox       |         |   Browser        |
    |==================|<>-------|==================|
    |   javascript()   |         |   javascript()   |
    |   html()         |         |   html()         |
    `------------------'         `------------------'
                                           ^
                             .-------------|------------.
                             |             |            |
          .------------------|   .------------------.   |------------------.
          |   W3C            |   |   Netscape       |   |      IE          |
          |==================|   |==================|   |==================|
          |   javascript()   |   |   javascript()   |   |   javascript()   |
          |   html()         |   |   html()         |   |   html()         |
	  `------------------'   `------------------'   `------------------'



=head1 AUTHOR

St‚phane Peiry, stephane@perlmonk.org

=head1 SEE ALSO

perl(1).

=cut
