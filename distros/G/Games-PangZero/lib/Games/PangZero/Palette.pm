##########################################################################
# PALETTE MANIPULATION
##########################################################################

package Games::PangZero::Palette;

sub RgbToHsi {
  my ($r, $g, $b) = @_;
  my ($min, $max, $delta, $h, $s, $i);

  if ($r > $g) {
    $max = $r > $b ? $r : $b;
    $min = $g < $b ? $g : $b;
  } else {
    $max = $g > $b ? $g : $b;
    $min = $r < $b ? $r : $b;
  }
  $i = ($min + $max) / 2;
  if ($min == $max) {
    return (0, 0, $i);
  }

  $delta = ($max - $min);
  if ($i < 128) {
    $s = 255 * $delta / ($min + $max);
  } else {
    $s = 255 * $delta / (511 - $min - $max);
  }

  if ($r == $max) {
    $h = ($g - $b) / $delta;
  } elsif ($g == $max) {
    $h = 2 + ($b - $r) / $delta;
  } else {
    $h = 4 + ($r - $g) / $delta;
  }
  $h = $h * 42.5;
  $h += 255 if $h < 0;
  $h -= 255 if $h > 255;

  return ($h, $s, $i);
}

sub HsiToRgb {
  my ($h, $s, $i) = @_;
  my ($m1, $m2);

  if ($s < 1) {
    $i = int($i + 0.5);
    return ($i, $i, $i);
  }

  if ($i < 128) {
    $m2 = ($i * (255 + $s)) / 65025.0;
  } else {
    $m2 = ($i + $s - ($i * $s) / 255.0) / 255.0;
  }
  $m1 = ($i / 127.5) - $m2;

  return (
    &GetHsiValue( $m1, $m2, $h + 85),
    &GetHsiValue( $m1, $m2, $h),
    &GetHsiValue( $m1, $m2, $h - 85)
  );
}

sub GetHsiValue {
  my ($n1, $n2, $hue) = @_;
  my ($value);

  $hue -= 255 if ($hue > 255);
  $hue += 255 if ($hue < 0);
  if ($hue < 42.5) {
    $value = $n1 + ($n2 - $n1) * ($hue / 42.5);
  } elsif ($hue < 127.5) {
    $value = $n2;
  } elsif ($hue < 170) {
    $value = $n1 + ($n2 - $n1) * ((170 - $hue) / 42.5);
  } else {
    $value = $n1;
  }
  return int($value * 255 + 0.5);
}

1;
