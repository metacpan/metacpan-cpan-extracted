package CalcApp;

use warnings;
use strict;

use base 'Wx::App';

use Class::Accessor::Classy;
ri qw(frame);
no  Class::Accessor::Classy;

sub OnInit {
  my $self = shift;
  $self->set_frame(my $frame = CalcFrame->new(undef, "whee"));
  $frame->Show(1);
}
########################################################################
package CalcFrame;

use Class::Accessor::Classy;
ri qw(input red green blue font);
ri qw(scroller);
ri qw(csizer rsizer);
ri qw(bucket);
no  Class::Accessor::Classy;

use wxPerl::Constructors;
use wxPerl::Styles qw(style wxVal);

use base qw(wxPerl::Frame);

sub new {
  my $class = shift;
  my ($parent, $title, %opts) = @_;
  my $self = $class->SUPER::new($parent, $title, %opts,
    position => Wx::Point->new(1624,718),
    #position => Wx::Point->new(624,0),
    size => [400,-1],
    style(
      'stay_on_top|no_border|transparent_window',
      frame => 'no_taskbar',
    )
  );
  my $reg = Wx::Region->newPolygon([
    map({for(@$_) { $_ *= 20}; $_} [0,0], [1,0], [1,1], [0,1])
  ]);

  # some styles and colors
  my $green = $self->set_green(Wx::Colour->new(127,255,127));
  my $blue  = $self->set_blue(Wx::Colour->new(127,127,255));
  my $red   = $self->set_red(Wx::Colour->new(255,127,127));
  my $font = $self->set_font(Wx::Font->new(16,
    75, # XXX Wx::wxFONTFAMILY_MODERN is unbound in older Wx?!
    wxVal('normal'), wxVal('bold'), 1, '')
  );
  my $scroller = $self->set_scroller(wxPerl::ScrolledWindow->new($self));
  $scroller->SetScrollbars(0,1,0,1);

  my $input = $self->set_input(wxPerl::TextCtrl->new($self, '',
    position => [1,20],
    style(
      te => 'readonly'
    ),
  ));
  $input->SetFont($font); $input->SetBackgroundColour($green);

  $self->__do_layout;

  # Hmm, I would like to create this later...
  my $output = wxPerl::TextCtrl->new($self->scroller, '',
    style(te => 'readonly|multiline'));
  $output->SetFont($self->font);
  $output->SetBackgroundColour($self->blue);
  $self->rsizer->Add($output, 1, wxVal('expand'), 0);
  $self->set_bucket($output);

  return($self);
}
########################################################################
sub add_output {
  my $self = shift;
  my ($quest, $ans) = @_;
  $quest .= ' =';

  #$self->bucket->SetValue($content);
  my $output = wxPerl::TextCtrl->new($self->scroller, '',
    style(te => 'readonly|multiline'));
  $output->SetFont($self->font);
  $output->SetBackgroundColour($self->blue);
  my $r1 = length($quest);
  my $r2 = $r1 + length($ans);

  # XXX formatting on ~28 characters could be nicer
  $output->SetValue($quest . "\n");
  $output->SetInsertionPointEnd;
  $output->WriteText(' 'x(27-length($ans)) . $ans);

  # XXX my Wx.pm needs an upgrade to get these
  # my $s = Wx::TextAttr->new(); $s->SetAlignment(3);
  # $output->SetStyle($r1, $r2, $s);


  $self->rsizer->Add($output, 1, wxVal('expand'), 1);
  $self->rsizer->FitInside($self->scroller);
  #$self->rsizer->RecalcSizes;
  $self->scroller->Layout;
  $self->Layout;
  my $p = $self->scroller->GetScrollRange(wxVal('vertical'));
  warn "p: $p\n";
  $self->scroller->Refresh;
  #$self->scroller->SetScrollPos(wxVal('vertical'), 10, 1);
  $self->scroller->Scroll(-1, $p);

  $self->Refresh;
  $output->ShowPosition($r1*2+$r2);
  $output->Refresh;
  # XXX hair-pulling!
  #my $pos = $output->GetScrollRange(wxVal('vertical'));
  #warn "got the position $pos\n";
  #$output->SetScrollPos(wxVal('vertical'), 7, 1);
}

sub __do_layout {
	my $self = shift;

  my $cs = $self->set_csizer(Wx::BoxSizer->new(wxVal('vertical')));
  my $rs = $self->set_rsizer(Wx::BoxSizer->new(wxVal('vertical')));
  $cs->Add($self->scroller, 4, wxVal('expand'), 0);
  $cs->Add($self->input, 1, wxVal('expand'), 0);
  $self->SetSizer($cs);
  $self->scroller->SetSizer($rs);
  $self->Layout;
}

1;
# vim:ts=2:sw=2:et:sta
