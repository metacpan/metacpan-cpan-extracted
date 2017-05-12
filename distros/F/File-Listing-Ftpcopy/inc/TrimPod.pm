package inc::TrimPod;

use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_files
{
  my($self) = @_;
  
  my($pm) = grep { $_->name eq 'lib/File/Listing/Ftpcopy.pm' } @{ $self->zilla->files };

  my @content = split /\n/, $pm->content;
  pop @content while $content[-1] ne '=head1 AUTHOR';
  
  if($content[-1] eq '=head1 AUTHOR')
  {
    $content[-1] = '=cut';
    $pm->content(join("\n", @content));  
    $self->log("rm extra AUTHOR and COPYRIGHT sections");
  }
  else
  {
    $self->log_fatal("unable to find AUTHOR tag");
  }
}

1;
