#!perl

use Test::More;
use IUP::ConfigData;

### find lib -name "*.pm" | xargs grep -h "^package" | sort -u | sed -e "s/package /use_ok('/" -e "s/;/');/"

use_ok('IUP::Button');
#use_ok('IUP::Canvas::Bitmap');
use_ok('IUP::Canvas::FileBitmap');
use_ok('IUP::Canvas::FileVector');
#use_ok('IUP::Canvas::Palette');
#use_ok('IUP::Canvas::Pattern');
#use_ok('IUP::Canvas::Stipple');
use_ok('IUP::Canvas');
use_ok('IUP::CanvasGL');
use_ok('IUP::Cbox');
use_ok('IUP::Cells');
use_ok('IUP::Clipboard');
use_ok('IUP::ColorBar');
use_ok('IUP::ColorBrowser');
use_ok('IUP::ColorDlg');
use_ok('IUP::Constants');
use_ok('IUP::Dial');
use_ok('IUP::Dialog');
use_ok('IUP::ElementPropertiesDialog');
use_ok('IUP::Expander');
use_ok('IUP::FileDlg');
use_ok('IUP::Fill');
use_ok('IUP::FontDlg');
use_ok('IUP::Frame');
use_ok('IUP::GL::Button');
use_ok('IUP::GL::CanvasBox');
use_ok('IUP::GL::Expander');
use_ok('IUP::GL::Frame');
use_ok('IUP::GL::Label');
use_ok('IUP::GL::Link');
use_ok('IUP::GL::ProgressBar');
use_ok('IUP::GL::ScrollBox');
use_ok('IUP::GL::Separator');
use_ok('IUP::GL::SizeBox');
use_ok('IUP::GL::SubCanvas');
use_ok('IUP::GL::Toggle');
use_ok('IUP::GL::Val');
use_ok('IUP::Gauge');
use_ok('IUP::GridBox');
use_ok('IUP::Hbox');
use_ok('IUP::Image');
use_ok('IUP::Internal::Callback');
use_ok('IUP::Internal::Canvas');
use_ok('IUP::Internal::Element');
use_ok('IUP::Internal::LibraryIup');
use_ok('IUP::Item');
use_ok('IUP::Label');
use_ok('IUP::LayoutDialog');
use_ok('IUP::Link');
use_ok('IUP::List');
use_ok('IUP::Matrix');
use_ok('IUP::MatrixList');
use_ok('IUP::Menu');
use_ok('IUP::MessageDlg');
use_ok('IUP::MglPlot');
use_ok('IUP::Normalizer');
use_ok('IUP::PPlot');
use_ok('IUP::ProgressBar');
use_ok('IUP::ProgressDlg');
use_ok('IUP::Radio');
use_ok('IUP::Sbox');
use_ok('IUP::Scintilla');
use_ok('IUP::ScrollBox');
use_ok('IUP::Separator');
use_ok('IUP::Spin');
use_ok('IUP::SpinBox');
use_ok('IUP::Split');
use_ok('IUP::Submenu');
use_ok('IUP::Tabs');
use_ok('IUP::Text');
use_ok('IUP::Timer');
use_ok('IUP::Toggle');
use_ok('IUP::Tree');
use_ok('IUP::User');
use_ok('IUP::Val');
use_ok('IUP::Vbox');
use_ok('IUP::Zbox');
use_ok('IUP');

SKIP: {
  skip 'IUP not compiled with CanvasGL support', 1 unless IUP::ConfigData->feature('CanvasGL');
  use_ok('IUP::CanvasGL');
}

SKIP: {
  skip 'IUP not compiled with PPlot support', 1 unless IUP::ConfigData->feature('PPlot');
  use_ok('IUP::PPlot');
}

done_testing;