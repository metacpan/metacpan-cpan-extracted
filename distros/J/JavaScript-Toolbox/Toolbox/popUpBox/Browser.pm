package JavaScript::Toolbox::popUpBox::Browser;

require v5.6;

use strict;
use warnings;

our $VERSION = '0.01';


sub new {
  my ($proto, %args) = @_;

  my $class = ref($proto) || $proto;
  my $self  = {};

  bless ($self, $class);
  return $self;
}

sub javascript {
  die "Abstract method: $!";
}

sub html {
  my $styleParams  = q{position:absolute; z-index:20; };
  $styleParams    .= q{overflow:visible; visibility:hidden; };
  $styleParams    .= q{top:0px; left:0px;};

  my $code = qq{
    <DIV ID="popUpBox" STYLE="$styleParams">
    </DIV>
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
