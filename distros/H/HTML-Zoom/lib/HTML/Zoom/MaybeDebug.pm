package HTML::Zoom::MaybeDebug;

use strictures 1;

sub import { }

if (my $level = $ENV{'HTML_ZOOM_DEBUG'}) {
  foreach my $mod (qw(Smart::Comments Data::Dumper::Concise JSON)) {
    (my $file_stem = $mod) =~ s/::/\//g;
    die "HTML_ZOOM_DEBUG env var set to ${level} - this requires the ${mod}\n"
        ."module but it failed to load with error:\n$@"
      unless eval { require "${file_stem}.pm"; 1 };
  }
  my @smartness = map '#'x$_, 3 .. $level+2;
  no warnings 'redefine';
  *import = sub { Smart::Comments->import(@smartness) };
  my $j = JSON->new->space_after;
  my $d = \&Data::Dumper::Concise::Dumper;
  *Smart::Comments::Dumper = sub {
    my $r;
    unless (eval { $r = $j->encode($_[0]); 1 }) {
      $r = $d->($_[0]);
    }
    $r;
  };
}

1;
