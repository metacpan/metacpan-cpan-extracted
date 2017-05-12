package inc::InlineBuild;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use base 'Module::Build';


=head2 process_pm_files

  $builder->process_pm_files();

=cut

sub process_pm_files {
  my $self = shift;

  # find & copy lib tree into blib/lib
  my $cfiles = $self->rscan_dir('lib', qr{\.c(pp)?$});

  foreach my $file (@$cfiles) {
    $self->copy_if_modified(from => $file, to => 'blib/'.$file, verbose => 1);
  }

  # now the .pm files
  my $pmfiles = $self->rscan_dir('lib', qr{\.pm$});
  foreach my $file (@$pmfiles) {
    my $to = 'blib/' . $file;
    next if($self->up_to_date($file, $to));

    my $code = do {open(my $fh, '<', $file) or die; local $/; <$fh>;};

    # look for a name
    my ($name) = ($code =~ m/^package ([\w:]+);/) or die "cannot find name";

    # turn the the version on
    my $count = ($code =~ s/^(\s*)#(\s*VERSION *=>)/$1$2/mg);
    $count or die "missing '#VERSION =>' entry";
    ($count == 1) or die "too many '#VERSION =>' entries?";

    # write
    open(my $fh, '>', $to) or die "cannot write '$to' $!";
    print $fh $code;
    close($fh) or die "$!";

    # then build it
    $self->do_system($^X, '-Iblib/lib', '-MInline=_INSTALL_',
      "-M$name", '-e1', $self->dist_version, 'blib/arch'
    );
  }
} # end subroutine process_inline_files definition
########################################################################

