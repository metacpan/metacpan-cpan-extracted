sub newimage {
  my $numlayers = shift;
  my $i = Gimp::Image->new(200,200,RGB);
  for my $layernum (1..$numlayers) {
    my $l0 = $i->layer_new(200,200,RGBA_IMAGE,"layer $layernum",100,LAYER_MODE_HSV_VALUE_LEGACY);
    $i->insert_layer($l0,0,0);
  }
  $i;
}

use constant {
  REQ_NONE  => 0,
  REQ_ALPHA => 1 << 0,
  REQ_SEL   => 1 << 1,
  REQ_GUIDE => 1 << 2,
  REQ_DIR   => 1 << 3,
  REQ_LAYER => 1 << 4,
  REQ_FILE  => 1 << 5,
};

my $color1 = 'blue';
my $color2 = 'dark red';
my $black = 'black';
my $white  = 'white';
my $gradient1 = "Burning Paper";
my $width     = 10;
my $height    = 10;

our @testbench = (
["add_glow"            , 2, REQ_ALPHA, [$color1, 5] ],
["animate_cells"       , 3, REQ_ALPHA, [0] ],
["auto_red_eye"        , 1, REQ_NONE , [] ],
["blowinout"           , 1, REQ_NONE , [ 30, 8, "30", 0, 0] ],
["blur_2x2"            , 1, REQ_NONE , [] ],
["brushed_metal"       , 1, REQ_NONE , [40,120,1,$gradient1] ],
["burst"               , 1, REQ_NONE , [0,0,14,30,50,80,140] ],
["center_guide"        , 1, REQ_NONE , [0] ],
["center_layer"        , 2, REQ_ALPHA, [] ],
["contrast_enhance_2x2", 1, REQ_NONE , [] ],
["ditherize"           , 1, REQ_NONE , [1, 10] ],
["do_bricks"           , 0, REQ_NONE , ["Leather",0,"",'grey50',1,8,16,256,256,0] ],
["dots"                , 1, REQ_NONE , [8,$color1,80,20,16,0,0] ],
["dust"                , 1, REQ_NONE , [0.0005,0,50] ],
["edge_detect_2x2"     , 1, REQ_NONE , [] ],
["file_dataurl_save"   , 1, REQ_FILE , [32, 32, 0] ],
["file_colorhtml_save" , 1, REQ_FILE , [2, "", "+1", 1, 1, 1] ],
["glowing_steel"       , 0, REQ_NONE , ["GET LOST","Bitstream Charter Bold 72",100,$color1,$black,4,0,0] ],
["golden_mean"         , 0, REQ_NONE , [233, 0] ],
["guide_grid"          , 1, REQ_NONE , [24,14,0,0,0] ],
["guide_to_selection"  , 1, REQ_GUIDE, [CHANNEL_OP_REPLACE,0,0] ],
["highlight_edges"     , 1, REQ_ALPHA, [ 10] ],
["inner_bevel"         , 0, REQ_NONE , ["URW Bookman L, Bold",80,"INNERBEVEL",$color1,$color2,132,30,7,2] ],
["layer_apply"         , 1, REQ_NONE , ['$d->gauss_rle($P*100+1,1,1)',0] ],
["layer_reorder"       , 3, REQ_ALPHA, [1,""] ],
["map_to_gradient"     , 1, REQ_NONE , [$gradient1] ],
["mirror_split"        , 1, REQ_NONE , [0] ],
["perlotine"           , 1, REQ_GUIDE|REQ_DIR, ["foo.html","t","png",0,"",1,0] ],
["pixelgen"            , 0, REQ_NONE , [$width,$height,RGB_IMAGE,'($x*$y*0.01)->slice("*$bpp")'] ],
["pixelmap"            , 1, REQ_NONE , ['($x*$y*0.01)->slice("*$bpp")'] ],
["prep4gif"            , 2, REQ_ALPHA, [64,1,0,1,255] ],
["random_art_1"        , 0, REQ_NONE , [$width,$height,20,10,1,30,0] ],
["random_blends"       , 1, REQ_NONE , [7] ],
["red_eye"             , 1, REQ_NONE , [0] ],
["repdup"              , 1, REQ_SEL  , [3,50,50] ],
["scratches"           , 1, REQ_NONE , [30,70,0.3,15,10] ],
["selective_sharpen"   , 1, REQ_NONE , [5.0,1.0,20] ],
["seth_spin"           , 2, REQ_LAYER, [16,$color1,40,1,1] ],
["stamps"              , 0, REQ_NONE , [90,$white,$color1,10,5] ],
#["tex_string_to_float" , 1, REQ_NONE , ["","I can write \\\\TeX",72,6,4] ],
#["view3d"             , 1, REQ_NONE , [0,1,1] ],
#["warp_sharp"          ,
["webify"              , 1, REQ_NONE , [1,1,$white,3,32,1] ],
["windify"             , 1, REQ_NONE , [120,80,30,1] ],
["xach_blocks"         , 1, REQ_NONE , [10,40] ],
["xach_shadows"        , 1, REQ_NONE , [10] ],
["xachvision"          , 1, REQ_NONE , [$color1,25] ],
["yinyang"             , 0, REQ_NONE , [$width,$height,1,0,"","",1] ],
);

our %file2procs = (
  animate_cells => [ qw(animate_cells) ],
  blended2 => [ qw(make_bevel_logos) ],
  blowinout => [ qw(blowinout) ],
  bricks => [ qw(do_bricks) ],
  burst => [ qw(burst) ],
  centerguide => [ qw(center_guide) ],
  colorhtml => [ qw(file_colorhtml_save) ],
  dataurl => [ qw(file_dataurl_save) ],
  ditherize => [ qw(ditherize) ],
  dots => [ qw(dots) ],
  dust => [ qw(dust gen_rand_1f) ],
  frame_filter => [ qw(layer_apply) ],
  frame_reshuffle => [ qw(layer_reorder) ],
  glowing_steel => [ qw(highlight_edges brushed_metal add_glow glowing_steel) ],
  goldenmean => [ qw(golden_mean) ],
  gouge => [ qw(blur_2x2 contrast_enhance_2x2) ],
  gouge => [ qw(edge_detect_2x2) ],
  guidegrid => [ qw(guide_grid) ],
  guides_to_selection => [ qw(guide_to_selection) ],
  layerfuncs => [ qw(center_layer) ],
  map_to_gradient => [ qw(map_to_gradient) ],
  mirrorsplit => [ qw(mirror_split) ],
  perlotine => [ qw(perlotine) ],
  pixelmap => [ qw(pixelmap pixelgen) ],
  prep4gif => [ qw(prep4gif) ],
  randomart1 => [ qw(random_art_1) ],
  randomblends => [ qw(random_blends) ],
  redeye => [ qw(auto_red_eye red_eye) ],
  repdup => [ qw(repdup) ],
  roundsel => [ qw(round_sel) ],
  scratches => [ qw(scratches) ],
  selective_sharpen => [ qw(selective_sharpen) ],
  sethspin => [ qw(seth_spin) ],
  stamps => [ qw(stamps) ],
  translogo => [ qw(make_trans_logos) ],
  'warp-sharp' => [ qw(warp_sharp) ],
  webify => [ qw(webify) ],
  windify => [ qw(windify) ],
  xachlego => [ qw(xach_blocks) ],
  xachshadow => [ qw(xach_shadows) ],
  xachvision => [ qw(xachvision) ],
);

our %proc2file;
while (my ($file, $procs) = each %file2procs) {
  map { $proc2file{$_} = $file; } @$procs;
}

sub setup_args {
  my ($name, $numlays, $flags, $params) = @_;
  my @actualparams = @$params;
  my ($tempdir, $tempfile);
  if ($flags & REQ_FILE) {
    $tempfile = File::Temp->newdir($DEBUG ? (CLEANUP => 0) : ());
    # put 2 copies on input params - for use with export-handler!
    # use a dir so any side-files created will get zapped on cleanup
    unshift @actualparams, $tempfile.'/file.xcf', $tempfile.'/file.xcf';
  }
  if ($flags & REQ_DIR) {
    $tempdir = File::Temp->newdir($DEBUG ? (CLEANUP => 0) : ());
    unshift @actualparams, $tempdir.'';
  }
  if ($numlays > 0) {
    my $img = newimage($numlays);
    my $drw = $img->get_active_layer;
    unshift @actualparams, ($img->get_layers)[1] if $flags & REQ_LAYER;
    unshift @actualparams, $img, $drw;
    if ($flags & REQ_ALPHA) {
      $drw->add_alpha;
      $img->select_rectangle(CHANNEL_OP_REPLACE,0.1*$height,0.1*$width,0.8*$height,0.8*$width);
      $img->selection_invert;
      $drw->edit_cut;
      $img->selection_none;
    }
    $img->select_rectangle(
      CHANNEL_OP_REPLACE,0.2*$height,0.2*$width,0.6*$height,0.6*$width
    ) if $flags & REQ_SEL;
    map {
      $img->add_hguide($width * $_); $img->add_vguide($height * $_);
    } (0.3, 0.6, 0.9) if $flags & REQ_GUIDE;
  }
  return (\@actualparams, $tempdir, $tempfile);
}

1;
