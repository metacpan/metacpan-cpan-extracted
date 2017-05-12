use IUP ':all';
use OpenGL ':all';

my $cnv = IUP::GL::CanvasBox->new(BUFFER => "DOUBLE",
                                  RASTERSIZE => "500x300",
                                  ACTION => sub {
                                    my ($self, $x, $y) = @_;
                                    #warn "ACTION: x=$x y=$y\n";
                                    $self->GLMakeCurrent();
                                    glClearColor(1.0, 1.0, 1.0, 1.0);
                                    glClear(GL_COLOR_BUFFER_BIT);
                                    glBegin(GL_LINES);
                                      glColor3f(1.0, 0.0, 0.0);
                                      glVertex2f(0.0, 0.0);
                                      glVertex2f(10.0, 10.0);
                                    glEnd();
                                    $self->GLSwapBuffers();
                                    return IUP_DEFAULT;
                                  },
                                  K_ANY => sub {
                                    my ($self, $c) = @_;
                                    #warn sprintf("K_ANY: c=%x\n", $c);
                                    if ($c == K_q || $c == K_ESC) {
                                      return IUP_CLOSE;
                                    }
                                    else {
                                      return IUP_DEFAULT;
                                    }
                                  },
                                  RESIZE_CB => sub {
                                    my ($self, $width, $height) = @_;
                                    #warn "RESIZE_CB: width=$width height=$height\n";
                                    $self->GLMakeCurrent();
                                    glViewport(0, 0, $width, $height); 
                                    glMatrixMode(GL_PROJECTION);
                                    glLoadIdentity();
                                    glMatrixMode(GL_MODELVIEW);
                                    glLoadIdentity();
                                    return IUP_DEFAULT;
                                  },
);

my $img_release = IUP::Image->new( pixels=>
     [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
      [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]],
      colors => [ "215 215 215", "40 40 40", "30 50 210", "240 0 0" ],
);

my $glabel   = IUP::GL::Label->new(TITLE => "Label", FONT => "Arial, 18", IMAGE => $img_release);
my $gbutton1 = IUP::GL::Button->new(TITLE => "Button", IMAGE => $img_release,  TIP => "Button Tip", PADDING => "5x5");
my $gtoggle  = IUP::GL::Toggle->new(TITLE => "Toggle", PADDING => "5x5");
my $gtoggle1 = IUP::GL::Toggle->new(PADDING => "5x5", IMAGE => $img_release);
my $gsep1    = IUP::GL::Separator->new();
my $glink    = IUP::GL::Link->new(URL => "http://www.tecgraf.puc-rio.br/iup", TITLE => "IUP Toolkit");
my $pbar1    = IUP::GL::ProgressBar->new(VALUE => "0.3", SHOW_TEXT => "Yes");
my $gval1    = IUP::GL::Val->new(VALUE => "0.3", TIP => "Val Tip");

my $hbox     = IUP::Hbox->new(child=>[$glabel, $gsep1, $gbutton1, $gtoggle, $glink, $pbar1, $gval1],
                              ALIGNMENT => "ACENTER", MARGIN => "5x5", GAP => "5");

my $gframe   = IUP::GL::Frame->new(child=>$hbox, TITLE => "frame",
                                   HORIZONTALALIGN => "ACENTER", VERTICALALIGN => "ATOP");

$cnv->Append($gframe);

my $dlg = IUP::Dialog->new(child=>$cnv, TITLE=>"IUP::GL::CanvasBox Example");

# Shows dialog in the center of the screen
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);
$cnv->RASTERSIZE(undef); # reset minimum limitation
IUP->MainLoop;
