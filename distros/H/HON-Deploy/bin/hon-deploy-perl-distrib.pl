#!/usr/bin/env perl
use strict;
use warnings;

use charnames ':full';
use Getopt::Long;
use Pod::Usage;

use LWP::Simple qw/mirror/;
use IO::All;
use Archive::Tar;
use Module::Build;
use File::Temp qw/tempdir/;

=head1 NAME

hon-deploy-perl-distrib.pl

=head1 DESCRIPTION

Deploy perl module + bin + cgi

=head1 VERSION

Version 0.03

=head1 USAGE

  hon-deploy-perl-distrib.pl --dist=path/to/HON-Deploy.tar.gz --dir-base=/path/to/base

  hon-deploy-perl-distrib.pl --dist=http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Deploy.tar.gz --dir-base=/path/to/base

  hon-deploy-perl-distrib.pl --dist=http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Utils-latest.tar.gz,http://znverdi.hcuge.ch/~hondist/perl/dist/HON-Http-Mirror-latest.tar.gz --dir-base=$HOME/perl --dir-cgi=$HOME/public_html/cgi-bin --perl-interpreter=$(which perl)

=head1 REQUIRED ARGUMENTS

=over 2

=item --dist=/path/to/HON-Deploy.tar.gz

Either file or url

=item --dir-base=/path/to/base

An absolute path where the module is to be installed

=back

=head1 OPTIONS

=over 2

=item --dir-cgi=/path/to/cgi

An absolute path where the CGI scripts are to be installed

=item --perl-interpreter=/path/to/perl

Where the perl interpreter is installed

=item --installdeps

Install missing prerequisites

=back

=cut

our $VERSION = '0.03';

my ($help);
my ( $pDistSrc, $pDirBase, $pDirCgi, $perlInterpeter );
my ($installdeps);

GetOptions(
  'dist=s'             => \$pDistSrc,
  'dir-base=s'         => \$pDirBase,
  'dir-cgi=s'          => \$pDirCgi,
  'perl-interpreter=s' => \$perlInterpeter,
  'installdeps'        => \$installdeps,
  'help'               => \$help,
) || pod2usage(2);

if ( $help || !$pDirBase || !$pDistSrc ) {
  pod2usage(1);
  exit 0;
}

foreach my $dSrc ( split /,/xms, $pDistSrc ) {
  installDistrib(
    src         => $dSrc,
    base        => $pDirBase,
    cgi         => $pDirCgi,
    installdeps => $installdeps
  );
}

sub installDistrib {
  my %args    = @_;
  my $distSrc = $args{src};
  my $dirBase = $args{base};
  my $dirCgi  = $args{cgi};

  my $tmpdir = tempdir( TEMPLATE => 'hon-deploy-XXXXXXXX', CLEANUP => 1 );

  my $distGz = "$tmpdir/dist.tgz";
  warn "mirroring: $distSrc\n";
  if ( $distSrc =~ /^(https?|ftp):\/\//xms ) {
    mirror( $distSrc, $distGz );
  }
  else {
    io($distSrc) > io($distGz);
  }
  my $tar = Archive::Tar->new;

  $tar->read($distGz);
  $tar->setcwd($tmpdir);
  $tar->extract();
  my $distTmpir = "$tmpdir/" . ( split /\//xms, ( $tar->list_files() )[0] )[0];
  warn "working dir: $distTmpir\n";
  chdir $distTmpir;

  if ($perlInterpeter) {
    my @scripts;
    @scripts = grep { "$_" =~ /\N{ONE DOT LEADER}pl$/ixms } io('bin')->all()
      if -d 'bin';

    push @scripts,
      grep { "$_" =~ /\N{ONE DOT LEADER}(pl|cgi)$/ixms } io('cgi')->all()
      if -d 'cgi';
    foreach my $s (@scripts) {
      system "chmod +w $s";
      my $txt = io($s)->slurp;
      $txt =~ s/^#!.*?\n/#!$perlInterpeter\n/xms;
      io($s) < $txt;
      system "chmod -w $s";
    }
  }

  my @cmd = ('perl Build.PL');
  push @cmd, './Build installdeps' if $args{installdeps};
  push @cmd, './Build test';

  my $installCmd = "./Build install  --install_base $dirBase";
  $installCmd .= " --install_path cgi=$dirCgi" if $dirCgi;
  push @cmd, $installCmd;

  foreach my $cmd (@cmd) {
    warn "$cmd\n";
    system($cmd) && die 'cannot execute';
  }
  chdir $ENV{HOME};

  return;
}

=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot at gmail.com> >>

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-hon-deploy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HON-Deploy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
