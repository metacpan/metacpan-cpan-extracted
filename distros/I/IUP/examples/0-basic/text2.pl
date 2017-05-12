# IUP::Text example
#
# Creates a IupText that shows asterisks instead of characters (password-like).

use strict;
use warnings;

use IUP ':all';

my $password = '';
my $text = IUP::Text->new( SIZE=>"200x", ACTION=>\&cb_action, K_ANY=>\&cb_k_any );
my $pwd = IUP::Text->new( READONLY=>"YES", SIZE=>"200x");
my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new([$text, $pwd]), TITLE=>"IUP::Text");

sub bs_handler {
  return IUP_IGNORE if $password eq '';
  $password = substr($password, 0, -1);
  $pwd->VALUE($password);
  return IUP_DEFAULT;
}

sub cb_k_any {
  my ($self, $c) = @_;
  return bs_handler if $c == K_BS;
  return IUP_IGNORE if $c==K_CR || $c==K_SP || $c==K_ESC || $c==K_INS || 
                       $c==K_DEL || $c==K_TAB || $c==K_HOME || $c==K_UP || 
                       $c==K_PGUP || $c==K_LEFT || $c==K_MIDDLE || 
                       $c==K_RIGHT || $c==K_END || $c==K_DOWN || $c==K_PGDN;
  return IUP_DEFAULT;
}

sub cb_action {
  my ($self, $c, $after) = @_;
  if ($c) {
    $password .= chr($c);
    $pwd->VALUE($password);
  }
  return K_asterisk;
}

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
