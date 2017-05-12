package HTML::Display::TempFile;
use strict;
use parent 'HTML::Display::Common';
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::TempFile - base class to display HTML via a temporary file

=head1 SYNOPSIS

=for example begin

  package HTML::Display::External;
  use parent 'HTML::Display::TempFile';

  sub browsercmd {
    # Return the string to pass to system()
    # %s will be replaced by the temp file name
  };

=for example end

=cut

sub display_html {
  # We need to use a temp file for communication
  my ($self,$html) = @_;

  $self->cleanup_tempfiles;  

  require File::Temp;
  my($tempfh, $tempfile) = File::Temp::tempfile(SUFFIX => '.html');
  print $tempfh $html;
  close $tempfh;

  push @{$self->{delete}}, $tempfile;  
  
  my $cmdline = sprintf($self->browsercmd, $tempfile);
  system( $cmdline ) == 0
    or warn "Couldn't launch '$cmdline' : $?";
};

sub cleanup_tempfiles {
  my ($self) = @_;
  for my $file (@{$self->{delete}}) {
    unlink $file
      or warn "Couldn't remove tempfile $file : $!\n";
  };
  $self->{delete} = [];
};

sub browsercmd { $_[0]->{browsercmd} };

=head1 AUTHOR

Copyright (c) 2004-2013 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
