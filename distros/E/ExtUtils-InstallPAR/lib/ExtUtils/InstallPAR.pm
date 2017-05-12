package ExtUtils::InstallPAR;
use strict;
use vars qw/$VERSION @ISA @EXPORT_OK %EXPORT_TAGS/;
BEGIN {
    $VERSION = '0.03';
}

use Config;
use Carp qw/croak/;
require PAR::Dist;
require Config;
require File::Spec;
require Exporter;
@ISA = qw(Exporter);
%EXPORT_TAGS = ('all' => [qw(install)]);
@EXPORT_OK = @{$EXPORT_TAGS{all}};

=head1 NAME

ExtUtils::InstallPAR - Install .par's into any installed perl

=head1 SYNOPSIS

  use ExtUtils::InstallPAR;
  
  # Install into the currently running perl:
  ExtUtils::InstallPAR::install(
    par => './Foo-Bar-0.01-MSWin32-multi-thread-5.10.0.par',
  );
  
  # Install into a different perl on the system,
  # this requires the ExtUtils::Infer module.
  ExtUtils::InstallPAR::install(
    par => './Foo-Bar-0.01-MSWin32-multi-thread-5.10.0.par',
    perl => '/path/to/perl.exe',
  );
  
  # If LWP::Simple is available, it works with URLs, too:
  ExtUtils::InstallPAR::install(
    par => 'http://foo.com/Foo-Bar-0.01-MSWin32-multi-thread-5.10.0.par',
  );

=head1 DESCRIPTION

This module installs PAR distributions (i.e. C<.par> files) into
any perl installation on the system. The L<PAR::Dist> module can
install into the currently running perl by default and provides
the necessary parameters to override any installation directories.
Figuring out how to use those overrides in order to install into
an arbitrary perl installation on the system may be beyond most users,
however. Hence this convenience wrapper using L<ExtUtils::InferConfig>
to automatically determine the typical I<site> installation paths
of any perl interpreter than can be executed by the current user.

=head1 FUNCTIONS

=head2 install

Install a PAR archive into any perl on the system. Takes named parameters:

C<par =E<gt> '/path/to/foo.par'> or C<par =E<gt> 'http://URL/to/foo.par'>
specifies the path to the .par file to install or an URL to fetch it from
(of LWP::Simple is available). This parameter is mandatory.

The C<perl =E<gt> '/path/to/perl'> parameter can be used to specify
the perl interpreter to install into. If you omit this option or set
it to C<undef>, the currently running perl will be used as target.
If you want to install into different perls, you will need to
install the C<ExtUtils::InferConfig> module.

C<verbosity =E<gt> $value> can be used to set the verbosity of the
installation process. Defaults to C<1>.

=cut

sub install {
  shift if $_[0] =~ __PACKAGE__;
  my %args = @_;

  my $par = $args{par};
  my $perl = $args{perl};
  my $verbosity = $args{verbosity} || 0;
  if (not defined $par) {
    croak(__PACKAGE__."::install requires a 'par' parameter");
  }

  my $name = $par;
  $name =~ s/^\w+:\/\///;
  my @name_elems = PAR::Dist::parse_dist_name($name);
  if (2 <= grep {defined} @name_elems) {
    $name = join('-', @name_elems);
  }
  else {
    (undef, undef, my $file) = File::Spec->splitpath($name);
    $name = $file;
    $name =~ s/\.par$//i;
  }

  my $config;
  if (defined $perl) {
    require ExtUtils::InferConfig;
    my $eic = ExtUtils::InferConfig->new(
      perl => $perl,
    );

    $config = $eic->get_config();
  }
  else {
    $config = \%Config::Config;
  }

  my $par_target = {
    inst_lib => $config->{installsitelib},
    inst_archlib => $config->{installsitearch},
    inst_bin => $config->{installbin},
    inst_script => $config->{installscript},
    inst_man1dir => $config->{installman1dir},
    inst_man3dir => $config->{installman3dir},
    packlist_write => $config->{sitearchexp} . "/auto/$name/.packlist",
    packlist_read => $config->{sitearchexp} . "/auto/$name/.packlist",
  };

  
  return PAR::Dist::install_par(
    name => $name,
    dist => $par,
    %$par_target,
    auto_inst_lib_conversion => 1,
  );
}

1;
__END__

=head1 CAVEATS


=head1 SEE ALSO

L<PAR> and L<PAR::Dist> for the gist on PAR distributions/archives.

L<ExtUtils::InferConfig> for details on how the installation paths
are determined.

L<ExtUtils::Install> is used to install the files into the system.

C<PAR::Dist> can use L<LWP::Simple> to fetch from URLs.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
