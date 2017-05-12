package JavaScript::Toolbox::popUpBox::Browser::Netscape;

require v5.6;

use strict;
use warnings;

our $VERSION = '0.01';
use base qw(JavaScript::Toolbox::popUpBox::Browser);


sub new {
  my ($proto, %args) = @_;

  my $class = ref($proto) || $proto;
  my $self  = {};

  bless ($self, $class);
  return $self;
}

sub show {
  my $code = q{
    // -- Netscape 4.x -- The JavaScript::Toolbox.
    function showBox(event, content) {
      var currentX,      //mouse position on X axis
          currentY,      //mouse position on X axis
          x,             //layer target position on X axis
          y,             //layer target position on Y axis
          docWidth,      //width  of current frame
          docHeight,     //height of current frame
          layerWidth,    //width  of popup layer
          layerHeight,   //height of popup layer
          popupElement;  //points to the popup element

      var name     = 'popUpBox';

      currentX     = event.pageX,
      currentY     = event.pageY;
      docHeight    = document.height;
      docWidth     = document.width;

      popupElement = document.layers[name];

      layerWidth   = popupElement.clip.width;
      layerHeight  = popupElement.clip.height;

      // -- Calculate popup new position.
      if ((currentX + layerWidth) > docWidth) {
        x = (currentX - layerWidth);
      } else {
        x = currentX;
      }

      if ((currentY + layerHeight) >= docHeight) {
        y = (currentY - layerHeight - 0);
      } else {
        y = currentY + 10;
      }

      // -- Set content.
      popupElement.document.open();
      popupElement.document.writeln(content);
      popupElement.document.close();

      // -- Set position and visibility.
      popupElement.left = parseInt(x);
      popupElement.top  = parseInt(y);

      popupElement.visibility = "show";
    }
  };

  return $code;
}

sub hide {
  my $code = q{
    function hideBox() {
      var name = 'popUpBox';

      document.layers[name].visibility = "hide";
    }
  };

  return $code;
}

sub javascript {
  my ($self, %args) = @_;

  my $show = $self->show();
  my $hide = $self->hide();

  my $code = qq{
  <script language="JavaScript">
  <!--
    $show
    $hide
  //-->
  </script>
  };

  return $code;
}

1;
__END__

=head1 NAME

JavaScript::Toolbox::popUpBox - JavaScript popUpBox using <div> tags.

=head1 SYNOPSIS

  use JavaScript::Toolbox::popUpBox;
  blah blah blah

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
