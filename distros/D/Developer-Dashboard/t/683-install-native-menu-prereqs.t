use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text // '';
}

sub _manifest_lines {
    my ($name) = @_;
    my $text = _slurp( File::Spec->catfile( $ROOT, $name ) );
    return grep { length && $_ !~ /^\s*#/ }
      map {
        my $line = $_;
        $line =~ s/\s*#.*$//;
        $line =~ s/^\s+|\s+$//g;
        $line;
      } split /\n/, $text;
}

sub _has_package {
    my ( $name, $package ) = @_;
    my %packages = map { $_ => 1 } _manifest_lines($name);
    ok( $packages{$package}, "$name includes $package for the Linux System Menu native helper" );
}

for my $manifest (qw(aptfile apkfile dnfile)) {
    my @packages = _manifest_lines($manifest);
    ok( !( grep { /(?:gtk|ayatana-appindicator)/i } @packages ),
        "$manifest does not force optional GTK/Ayatana development packages" );
}

my $installer = _slurp( File::Spec->catfile( $ROOT, 'install.sh' ) );
unlike( $installer, qr/^(?:libgtk-3-dev|libayatana-appindicator3-dev|libayatana-appindicator-dev|libayatana-appindicator-gtk3-devel)$/m,
    'install.sh does not force optional GTK/Ayatana development packages' );
my $makefile = _slurp( File::Spec->catfile( $ROOT, 'Makefile.PL' ) );
like( $makefile, qr/'--exists'.*'ayatana-appindicator3-0\.1'.*'gtk\+-3\.0'/s,
    'the native helper build is gated on GTK/Ayatana availability' );

done_testing();

__END__

=head1 NAME

t/683-install-native-menu-prereqs.t - keep optional GTK packages out of bootstrap requirements

=head1 DESCRIPTION

Checks that Linux bootstrap manifests do not force GTK3/Ayatana development
packages on hosts that do not have them, and that C<Makefile.PL> gates the
optional native menu helper on the corresponding pkg-config modules.

=head1 PURPOSE

Keep source-checkout and streamed Linux installs independent of optional
native System Menu development packages.

=head1 WHY IT EXISTS

The native Linux menu helper is optional. Missing GTK3 or Ayatana development
packages must not prevent the Perl distribution from building or installing.

=head1 WHEN TO USE

Run this test whenever changing Linux installer manifests, C<install.sh>
embedded package fallbacks, or native System Menu build dependencies.

=head1 HOW TO USE

Run the focused regression with:

  prove -lv t/683-install-native-menu-prereqs.t

=head1 WHAT USES IT

Debian/Ubuntu, Alpine, and Fedora bootstrap installs use these manifests before
C<cpanm> compiles the Dashboard native extension.

=head1 EXAMPLES

Check the installer prerequisites directly:

  prove -lv t/683-install-native-menu-prereqs.t

Run them as part of the complete suite:

  prove -lr t

=cut
