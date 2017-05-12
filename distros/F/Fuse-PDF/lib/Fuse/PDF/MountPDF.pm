#######################################################################
#      $URL: svn+ssh://equilibrious@equilibrious.net/home/equilibrious/svnrepos/chrisdolan/Fuse-PDF/lib/Fuse/PDF/MountPDF.pm $
#     $Date: 2008-06-06 22:47:54 -0500 (Fri, 06 Jun 2008) $
#   $Author: equilibrious $
# $Revision: 767 $
########################################################################

## no critic(ErrorHandling::RequireCarping)

package Fuse::PDF::MountPDF;

use warnings;
use strict;
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use Fuse::PDF;

our $VERSION = '0.09';

sub run {
   my ($pkg, @args) = @_;

   my %opts = (
      verbose    => 0,
      debug      => 0,
      askforpass => 0,
      info       => 0,
      delete     => 0,
      backup     => 0,
      rev        => 0,
      keep       => 0,
      fs_name    => undef,
      fuseopts   => undef,
      help       => 0,
      version    => 0,
   );

   Getopt::Long::Configure('bundling');
   GetOptionsFromArray(
      \@args,
      'v|verbose'    => \$opts{verbose},
      'd|debug'      => \$opts{debug},
      'p|password'   => \$opts{askforpass},
      'i|info'       => \$opts{info},
      'deletefs'     => \$opts{delete},
      'b|backup'     => \$opts{backup},
      'r|revision=i' => \$opts{rev},
      'k|keep'       => \$opts{keep},
      'f|fs=s'       => \$opts{fs_name},
      'fuseopts=s'   => \$opts{fuseopts},
      'A|all'        => sub {$opts{fs_name} = 'pdf'},
      'h|help'       => \$opts{help},
      'V|version'    => \$opts{version},
    ) or pod2usage(1);

   if ($opts{help}) {
      pod2usage(-exitval => 'NOEXIT', -verbose => 2);
      return 0;
   }
   if ($opts{version}) {
      print "Fuse::PDF v$Fuse::PDF::VERSION\n";
      return 0;
   }

   if (@args < 1) {
      pod2usage(-exitval => 'NOEXIT', -verbose => 1);
      return 1;
   }
   if (@args < 2 && !$opts{info} && !$opts{delete}) {
      pod2usage(-exitval => 'NOEXIT', -verbose => 1);
      return 1;
   }

   my $filename = shift @args;
   my $mountdir = shift @args;

   my $pdf_opts = [q{}, q{}, { prompt_for_password => $opts{askforpass} }];
   my $fuse = Fuse::PDF->new($filename, {
      pdf_constructor => $pdf_opts,
      fs_name         => $opts{fs_name},
      revision        => $opts{rev},
      backup          => $opts{backup},
      compact         => !$opts{keep},
   }) or die 'Failed to open the PDF';

   if ($opts{info}) {
      print $fuse->fs->to_string;
   } elsif ($opts{delete}) {
      $fuse->fs->deletefs($filename);
   } else {
      $fuse->mount($mountdir, {
         $opts{debug}    ? ( debug => 1 )                   : (),
         $opts{fuseopts} ? ( mountopts => $opts{fuseopts} ) : (),
      });
   }

   return 0;
}

1;

__END__

=pod

=head1 NAME

Fuse::PDF::MountPDF - Engine behind the mount_pdf program

=head1 LICENSE

Copyright 2007-2008 Chris Dolan, I<cdolan@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

   use Fuse::PDF::MountPDF;
   Fuse::PDF::MountPDF->run(@ARGV);

=head1 DESCRIPTION

This is the engine that drives the F<mount_pdf> program.  See the
documentation in that program for details.

=head1 METHODS

=over

=item $pkg->run(@ARGV)

Run the application.  See F<mount_pdf> for the C<@ARGV> parsing.

=back

=head1 SEE ALSO

F<mount_pdf>

=head1 AUTHOR

Chris Dolan, I<cdolan@cpan.org>

=cut

# Local Variables:
#   mode: perl
#   perl-indent-level: 3
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
