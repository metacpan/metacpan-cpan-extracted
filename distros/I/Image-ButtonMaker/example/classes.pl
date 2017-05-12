#### This file contains a list of classes that will be used
##   by the Image::Buttonmaker in the run.pl script
##   Most of available button properties are demonstrated and
##   simple inheritance of properties between classes is used.
[
 [
  classname  => 'aquatic',
  properties => {
                 FileType => 'gif',

                 HeightMin        => 23,
                 HeightMax        => 23,
                 WidthMin         => 90,

                 CanvasType        => 'pixmap',
                 CanvasTemplateImg => 'aqua-blue.png',
                 CanvasCutRight    => 10,
                 CanvasCutLeft     => 15,
                 CanvasCutTop      => 2,
                 CanvasCutBottom   => 2,

                 ArtWorkType   => 'text',
                 ArtWorkHAlign => 'center',
                 ArtWorkVAlign => 'baseline',

                 TextColor     => '#f0f0ff',
                 TextSize      => 14,
                 TextFont      => 'aispec.ttf',
                 TextAntiAlias => 'yes',
                 TextScale     => 1.0,

                 MarginLeft   => 10,
                 MarginRight  => 10,
                 MarginTop    => 2,
                 MarginBottom => 7,
                }
 ],

 [
  classname  => 'aquatic-red',
  parent     => 'aquatic',
  properties => {
                 CanvasTemplateImg => 'aqua-red.png',
                 TextColor => '#d00000',
                }
 ],

 [
  classname => 'square',
  properties => {
                 FileType => 'png',

                 HeightMin        => 24,
                 HeightMax        => 24,
                 WidthMin         => 90,

                 CanvasType            => 'color',
                 CanvasBackgroundColor => '#ffffff',
                 CanvasBorderWidth     => 1,
                 CanvasBorderColor     => '#808080',

                 ArtWorkType   => 'text',
                 ArtWorkHAlign => 'center',
                 ArtWorkVAlign => 'baseline',

                 TextColor     => '#808080',
                 TextSize      => 12,
                 TextFont      => 'aispec.ttf',
                 TextAntiAlias => 'yes',
                 TextScale     => 1.0,

                 MarginLeft   => 10,
                 MarginRight  => 10,
                 MarginTop    => 2,
                 MarginBottom => 7,
                }
 ],

 [
   classname  => 'square-icon',
   parent     => 'square',
   properties => {
                  ArtWorkType        => 'icon+text',
                  ArtWorkHAlign      => 'left',

                  IconName           => 'blink.gif',
                  IconSpace          =>  3,
                  IconVerticalAdjust =>  5,
                 }
  ],

 [
   classname  => 'square-noborder',
   parent     => 'square',
   properties => {
                  CanvasBorderWidth => 0,
                 }
  ],

];
