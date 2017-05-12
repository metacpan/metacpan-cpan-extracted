use Test::More qw(no_plan);

use Imager::DTP::Textbox::Horizontal;
use Imager::DTP::Textbox::Vertical;

my $tb_opts = {
	font => Imager::Font->new(file=>'t/dodge.ttf',type=>'ft2',size=>14),
	text => "This year's Thrash Domination Tour \n\nhere in Japan was great",
	wspace => 5,
	leading => 130,
	halign  => 'center',
	valign  => 'bottom',
	wrapWidth => 150,
	wrapHeight => 150,
};

my $ln_opts = {
	font => Imager::Font->new(file=>'t/dodge.ttf',type=>'ft2',size=>16),
	text => "Peace sells, but who's buying?",
	wspace => 5,
};

my $lt_opts = {
	font => Imager::Font->new(file=>'t/dodge.ttf',type=>'ft2',size=>18),
	text => 'x',
};

my %modules = (
	"Imager::DTP::Textbox::Horizontal" => $tb_opts,
	"Imager::DTP::Textbox::Vertical"   => $tb_opts,
	"Imager::DTP::Line::Horizontal"    => $ln_opts,
	"Imager::DTP::Line::Vertical"      => $ln_opts,
	"Imager::DTP::Letter"              => $lt_opts,
);

while(my($nm,$opt) = each %modules){
	ok($nm->new(), "$nm"."->new() without options");
	ok($nm->new(%{$opt}), "$nm"."->new() with options");
	my $obj = $nm->new(%{$opt});
	my $img = Imager->new(xsize=>50,ysize=>50);
	if($nm =~ /^Imager::DTP::Textbox/){
		ok($obj->draw(target=>$img,x=>10,y=>10), "$nm"."->draw()");
	}elsif($nm =~ /^Imager::DTP::Line/){
		ok($obj->draw(target=>$img,x=>10,y=>10), "$nm"."->draw()");
	}elsif($nm =~ /^Imager::DTP::Letter/){
		ok($obj->draw(target=>$img,x=>10,y=>10), "$nm"."->draw()");
	}
}
