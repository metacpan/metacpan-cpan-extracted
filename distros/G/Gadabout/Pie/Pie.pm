package Gadabout::Pie;

use Gadabout;
use Apache;

use strict;

use vars qw/$VERSION/;
$VERSION = '1.0001';

my $gcounter = 0;
sub graph_name {
  $gcounter++;
  "/tmp/pe-pie-$$-$gcounter.png";
}
sub handler {
  my $r = shift;
  my $i = 1;
  my %p = $r->args;
  my $width = $p{'width'} || '600';
  my $height = $p{'height'} || '400';
  my $title = $p{'title'};
  my @name;
  my @data;
  my @radmods;
  my %pieData;
  while(1) {
    last unless($p{"n$i"} && $p{"d$i"});
    push @name, $p{"n$i"};
    push @data, $p{"d$i"};
    push @radmods, $p{"r$i"};
    $i++;
  }
  $pieData{name} = \@name;
  $pieData{data} = \@data;
  $pieData{radMod} = \@radmods;
  $pieData{title} = $title;

  my $graph = new Gadabout;
  $graph->InitGraph($width,$height);
  $graph->AddFontPath($r->dir_config('GadaboutFontPath'));
  $graph->SetFont($r->dir_config('GadaboutFont') || 'arial/8');

  $graph->PieChart(\%pieData);
  my $name = graph_name;
  $r->notes("pepiename", $name);
  $graph->ShowGraph($name);
  $r->filename($name);
  $r->push_handlers( PerlCleanupHandler => \&CleanUp );
  $r->content_type("image/png");
  $r->send_http_header();
  my $PNG;
  open($PNG, "<$name") || return 404;
  $r->send_fd($PNG);
  close($PNG);
  return 200;
}
sub CleanUp {
  my $r = shift;
  my $file = $r->notes("pepiename");
  if($file) {
    unlink($file);
  }
}
1;

__END__

=pod

=head1 NAME

Gadabout::Pie

=head1 SYNOPSIS

Gadabout is a reimplementation and improvement on the software called
Vagrant which was written for PHP.

=head1 EXAMPLES

    PerlSetVar GadaboutFontPath '/usr/local/share/fonts/ttf'
    PerlSetVar GadaboutFont 'arial/8'
    <Location /graphs/pie.png>
        PerlHandler Gadabout::Pie
    </Location>

=head1 COPYRIGHT

OmniTI Computer Consulting, Inc.  Copyright (c) 2003

=head1 AUTHOR

Ben Martin <bmartin@omniti.com>

Theo Schlossnagle <jesus@omniti.com>

OmniTI Computer Consulting, Inc.

=cut

