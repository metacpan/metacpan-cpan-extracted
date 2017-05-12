package Devel::ebug::Backend::Plugin::Filenames;
$Devel::ebug::Backend::Plugin::Filenames::VERSION = '0.59';
use strict;
use warnings;

sub register_commands {
    return ( filenames   => { sub => \&filenames } );

}

sub filenames {
  my($req, $context) = @_;
  my %filenames;
  foreach my $sub (keys %DB::sub) {
    my($filename, $start, $end) = $DB::sub{$sub} =~ m/^(.+):(\d+)-(\d+)$/;
    next if $filename =~ /^\(eval/;
    $filenames{$filename}++;
  }
  return { filenames => [sort keys %filenames] };
}
1;
