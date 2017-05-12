package IUP::Internal::Canvas;

use strict;
use warnings;

use IUP::Internal::LibraryIup; #loads also XS part

# accessor
sub cnvhandle {
  if ($_[1]) {
    IUP::Internal::LibraryIup::_register_ch($_[1], $_[0]);    
    return $_[0]->{'!int!cnvhandle'} = $_[1]    
  }
  else {
    return $_[0]->{'!int!cnvhandle'};
  }
}

sub new_from_cnvhandle {
  my ($class, $ch) = @_;
  my $self = { class => $class };
  #warn "XXX-DEBUG: IUP::Internal::Canvas::new_from_cnvhandle(): class=$class [" . ref($self) . "]\n";
  return undef unless($ch); #XXX-CHECKLATER
  bless($self, $class);
  $self->cnvhandle($ch);
  return $self;
}

sub cdKillCanvas {
  my $self = shift;
  #warn "XXX-DEBUG: IUP::Internal::Canvas::cdKillCanvas(): " . ref($self) . " [" . $self->cnvhandle . "]\n";  
  $self->_cdKillCanvas();
  $self->cnvhandle(undef);
  #warn "XXX-DEBUG: IUP::Internal::Canvas::cdKillCanvas(): done\n";  
}

sub DESTROY {
  my $self = shift;
  #XXX-CHECKLATER not sure if we handle correctly canvas destruction
  #warn "XXX-DEBUG: IUP::Internal::Canvas::DESTROY(): " . ref($self) . " [" . $self->cnvhandle . "]\n";  
  $self->cdKillCanvas;    
  #warn "XXX-DEBUG: IUP::Internal::Canvas::DESTROY(): done\n";  
}

#Note: all canvas related methods implemented directly in XS

1;

__END__

=head1 NAME

IUP::Internal::Canvas - [internal only] DO NOT USE this unless you know what could happen!

=cut