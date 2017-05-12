package JavaScript::Toolbox::popUpBox;

require v5.6;

use strict;
use warnings;

our $VERSION = '0.01';
use base qw(JavaScript::Toolbox);


use JavaScript::Toolbox::popUpBox::Browser;

use JavaScript::Toolbox::popUpBox::Browser::DOM;
use JavaScript::Toolbox::popUpBox::Browser::Netscape;
use JavaScript::Toolbox::popUpBox::Browser::IE;

sub new {
  my ($proto, %args) = @_;

  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new();

  if ($self->{BROWSER}->opera) {
    $self->{POPUP} = new JavaScript::Toolbox::popUpBox::Browser::DOM( comply => 'Opera' );
  } elsif ($self->{BROWSER}->ie5up) {
    $self->{POPUP} = new JavaScript::Toolbox::popUpBox::Browser::DOM( comply => 'IE' );
  } elsif ($self->{BROWSER}->nav6up) {
    $self->{POPUP} = new JavaScript::Toolbox::popUpBox::Browser::DOM( comply => 'Standard' );
  } elsif ($self->{BROWSER}->ie4up) {
    $self->{POPUP} = new JavaScript::Toolbox::popUpBox::Browser::IE;
  } elsif ($self->{BROWSER}->nav4up) {
    $self->{POPUP} = new JavaScript::Toolbox::popUpBox::Browser::Netscape;
  } else {
    $self->{POPUP} = new JavaScript::Toolbox::popUpBox::Browser::DOM( comply => 'Standard' );
  }

  bless ($self, $class);
  return $self;
}

sub html {
  my ($self, %args) = @_;

  return $self->{POPUP}->html();
}

sub javascript {
  my ($self, %args) = @_;

  return $self->{POPUP}->javascript();
}

1;
__END__

=head1 NAME

JavaScript::Toolbox::popUpBox - JavaScript popUpBox using <div> tags.

=head1 SYNOPSIS

  use JavaScript::Toolbox::popUpBox;

  my $popup = new JavaSvript::Toolbox::popUpBox;

  $popup->javascript();
  $popup->html();


=head1 DESCRIPTION

Stub documentation for JavaScript::Toolbox, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

St‚phane Peiry, stephane@perlmonk.org

=head1 SEE ALSO

perl(1).

=cut
