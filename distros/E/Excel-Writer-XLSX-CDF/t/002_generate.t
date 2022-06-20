use strict;
use warnings;
use File::Temp qw{tempdir};

use Test::More tests => 11;
BEGIN { use_ok('Excel::Writer::XLSX::CDF') };

SKIP: {
  my $tempdir = tempdir();
  skip "Error: Cannot create a temp file. Read-only file system?", 4 unless ($tempdir && -d $tempdir && -r $tempdir);
  unlink $tempdir;

  my @data     = map {
                      [ one   => rand            ],
                      [ two   => int(10*rand)/10 ],
                      [ three => int(50*rand)/50 ],
                     } (1 .. 1000);

  {
    my $e        = Excel::Writer::XLSX::CDF->new(chart_title => "", chart_x_label => "", chart_y_label => "", chart_legend_display=>0);
    my $filename = $e->generate_file(\@data);
    ok(-r $filename, 'generate_file');
    ok(-s $filename, 'generate_file');
    diag("Created: $filename");
  }

  {
    my $e        = Excel::Writer::XLSX::CDF->new(
                                                 chart_title          => "My Title",
                                                 chart_x_label        => "My X Axis",
                                                 chart_y_label        => "My Y Axis",
                                                 chart_legend_display => 1,
                                                 chart_colors         => ['#EE1111', '#11EE11', '#1111EE'],
                                                 group_names_sort     => 1,
                                                );
    my $filename = $e->generate_file(\@data);
    ok(-r $filename, 'generate_file');
    ok(-s $filename, 'generate_file');
    diag("Created: $filename");
  }

  {
    my $e        = Excel::Writer::XLSX::CDF->new(
                                                 chart_title          => "My Title",
                                                 chart_x_label        => "My X Axis",
                                                 chart_y_label        => "My Y Axis",
                                                 chart_legend_display => 1,
                                                 chart_colors         => ['#EE1111', '#11EE11', '#1111EE'],
                                                 group_names_sort     => 1,
                                                 chart_x_min          => 0.4,
                                                 chart_x_max          => 0.6,
                                                );
    my $filename = $e->generate_file(\@data);
    ok(-r $filename, 'generate_file');
    ok(-s $filename, 'generate_file');
    diag("Created: $filename");
  }

  {
    my $e        = Excel::Writer::XLSX::CDF->new(
                                                 chart_title          => "My Title",
                                                 chart_x_label        => "My X Axis",
                                                 chart_y_label        => "My Y Axis",
                                                 chart_legend_display => 1,
                                                 chart_colors         => ['#EE1111', '#11EE11', '#1111EE'],
                                                 group_names_sort     => 1,
                                                 chart_x_min          => 'auto',
                                                 chart_x_max          => 'auto',
                                                );
    my $filename = $e->generate_file(\@data);
    ok(-r $filename, 'generate_file');
    ok(-s $filename, 'generate_file');
    diag("Created: $filename");
  }

  {
    my @additional = map {[one => $_/10]} (-5 .. 15);
    my $e        = Excel::Writer::XLSX::CDF->new(
                                                 chart_title          => "My Title",
                                                 chart_x_label        => "My X Axis",
                                                 chart_y_label        => "My Y Axis",
                                                 chart_legend_display => 1,
                                                 chart_colors         => ['#EE1111', '#11EE11', '#1111EE'],
                                                 group_names_sort     => 1,
                                                );
    my $filename = $e->generate_file([@data, @additional]);
    ok(-r $filename, 'generate_file');
    ok(-s $filename, 'generate_file');
    diag("Created: $filename");
  }
}
