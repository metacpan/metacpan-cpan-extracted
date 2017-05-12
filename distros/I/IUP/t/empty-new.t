#!perl

BEGIN {
  if (!$ENV{DISPLAY} && $^O ne 'MSWin32' && $^O ne 'cygwin') {
    print "1..0 # skip: no display available for GUI tests\n";
    exit;
  }
}

use Test::More;
use IUP::ConfigData;
use IUP ':all';

isnt(IUP::Button->new(),undef,'Testing IUP::Button->new()');
isnt(IUP::Canvas->new(),undef,'Testing IUP::Canvas->new()');
isnt(IUP::Cbox->new(),undef,'Testing IUP::Cbox->new()');
isnt(IUP::Cells->new(),undef,'Testing IUP::Cells->new()');
isnt(IUP::Clipboard->new(),undef,'Testing IUP::Clipboard->new()');
isnt(IUP::ColorBar->new(),undef,'Testing IUP::ColorBar->new()');
isnt(IUP::ColorBrowser->new(),undef,'Testing IUP::ColorBrowser->new()');
isnt(IUP::ColorDlg->new(),undef,'Testing IUP::ColorDlg->new()');
isnt(IUP::Dial->new(),undef,'Testing IUP::Dial->new()');
isnt(IUP::Dialog->new(),undef,'Testing IUP::Dialog->new()');
isnt(IUP::FileDlg->new(),undef,'Testing IUP::FileDlg->new()');
isnt(IUP::Fill->new(),undef,'Testing IUP::Fill->new()');
isnt(IUP::FontDlg->new(),undef,'Testing IUP::FontDlg->new()');
isnt(IUP::Frame->new(),undef,'Testing IUP::Frame->new()');
isnt(IUP::Hbox->new(),undef,'Testing IUP::Hbox->new()');
isnt(IUP::Image->new(WIDTH=>1, HEIGHT=>1, pixels=>[0]),undef,'Testing IUP::Image->new()');
isnt(IUP::Image->new(WIDTH=>1, HEIGHT=>1, pixels=>[0,1,2]),undef,'Testing IUP::Image->new() - RGB');
isnt(IUP::Image->new(WIDTH=>1, HEIGHT=>1, pixels=>[0,1,2,3]),undef,'Testing IUP::Image->new() - RGBA');
isnt(IUP::Item->new(),undef,'Testing IUP::Item->new()');
isnt(IUP::Label->new(),undef,'Testing IUP::Label->new()');
isnt(IUP::List->new(),undef,'Testing IUP::List->new()');
isnt(IUP::Matrix->new(),undef,'Testing IUP::Matrix->new()');
isnt(IUP::Menu->new(),undef,'Testing IUP::Menu->new()');
isnt(IUP::MessageDlg->new(),undef,'Testing IUP::MessageDlg->new()');
isnt(IUP::Normalizer->new(),undef,'Testing IUP::Normalizer->new()');
isnt(IUP::ProgressBar->new(),undef,'Testing IUP::ProgressBar->new()');
isnt(IUP::Radio->new(),undef,'Testing IUP::Radio->new()');
isnt(IUP::Sbox->new(),undef,'Testing IUP::Sbox->new()');
isnt(IUP::Separator->new(),undef,'Testing IUP::Separator->new()');
isnt(IUP::Spin->new(),undef,'Testing IUP::Spin->new()');
isnt(IUP::SpinBox->new(),undef,'Testing IUP::SpinBox->new()');
isnt(IUP::Split->new(),undef,'Testing IUP::Split->new()');
isnt(IUP::Submenu->new(),undef,'Testing IUP::Submenu->new()');
isnt(IUP::Tabs->new(),undef,'Testing IUP::Tabs->new()');
isnt(IUP::Text->new(),undef,'Testing IUP::Text->new()');
isnt(IUP::Timer->new(),undef,'Testing IUP::Timer->new()');
isnt(IUP::Toggle->new(),undef,'Testing IUP::Toggle->new()');
isnt(IUP::Tree->new(),undef,'Testing IUP::Tree->new()');
isnt(IUP::User->new(),undef,'Testing IUP::User->new()');
isnt(IUP::Val->new(),undef,'Testing IUP::Val->new()');
isnt(IUP::Vbox->new(),undef,'Testing IUP::Vbox->new()');
isnt(IUP::Zbox->new(),undef,'Testing IUP::Zbox->new()');

SKIP: {
  skip 'IUP not compiled with CanvasGL support', 1 unless IUP::ConfigData->feature('CanvasGL');
  isnt(IUP::CanvasGL->new(),undef,'Testing IUP::CanvasGL->new()');
}

SKIP: {
  skip 'IUP not compiled with PPlot support', 1 unless IUP::ConfigData->feature('PPlot');
  isnt(IUP::PPlot->new(),undef,'Testing IUP::PPlot->new()');
}

done_testing();
