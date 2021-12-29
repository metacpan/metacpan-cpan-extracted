package Devel::Agent::Util;

=head1 NAME

Devel::Agent::Util - Agent utilities

=head1 SYNOPSIS

  use Devel::Agent;
  use Devel::Agent::Util qw(flush_row);

  my $db=DB->new(
    on_frame_end=>\&flush_row,
  );
  $db->start_trace;

  END {
    $db->stop_trace;
  }
  
=head1 DESCRIPTION

This module exports utility functions for Devel::Agent

=head2 Exported Methods

=cut

use Modern::Perl;
use Devel::Agent;
our $VERSION=$Devel::Agent::VERSION;
use Exporter 'import';
use Data::Dumper;
our @EXPORT_OK=qw(flush_row);
our @EXPORT=qw(flush_row);

my $last=0;
my $self;

=head2 flush_row($agent,$frame,$fh)

Writes the a minimally useful set of frame information to STDERR if $fh is undef, othewise it writes to $fh.

=cut

sub flush_row {
  my ($agent,$frame,$fh)=@_;
  $fh=\*STDERR unless defined $fh;

  $agent->{__pending__}=$agent->{__pending__} || {};
  my $depth=$frame->{depth};
  if($last==0 || $depth > $last +1) {
    # we jumpped some frames.
    my $frames=$agent->grab_missing($last,$frame);
    foreach my $frame ($frames->@*) {
      _print_frame($fh,$agent,$frame,$last);
    }
  }
  
  _print_frame($fh,$agent,$frame,$last);
  $last=$frame->{depth};
}

sub _print_frame {
  my $fh=shift;
  my $agent=shift;
  my $frame=shift;
  my $last=shift;
  my $depth=($frame->{depth} -1) *2;
  my $pending=$agent->{__pending__};
  
  if(exists $frame->{duration}) {
    $fh->print(_frame_start($depth,$frame)) unless delete $pending->{$frame->{depth}};
    $fh->print(_frame_end($depth,$frame));
  } else {
    $pending->{$frame->{depth}}=1;
    $fh->print(_frame_start($depth,$frame));
  }
}

sub _frame_end {
  my ($depth,$frame)=@_;
  sprintf "\%${depth}s%s Depth: %i End Frame:   \%i Line: File: \%s %i Duration: %f\n",'',@{$frame}{qw(class_method depth order_id source line duration)};
}
sub _frame_start{
  my ($depth,$frame)=@_;
  sprintf "\%${depth}s\%s Depth: %i Start Frame: \%i File: \%s Line: \%i\n",'',@{$frame}{qw(class_method depth order_id source line)};
}

1;

__END__

=head1 AUTHOR

Michael Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut

