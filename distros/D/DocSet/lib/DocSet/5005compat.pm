package DocSet::5005compat;

$DocSet::5005compat::VERSION = '0.01';

use strict;
use Symbol ();
use File::Basename;
use File::Path;

my %compat_files = (
     'lib/warnings.pm' => \&warnings_pm,
);

sub import {
    if ($] >= 5.006) {
        #make sure old compat stubs dont wipe out installed versions
        unlink for keys %compat_files;
        return;
    }

    eval { require File::Spec::Functions; } or
      die "this is only Perl $], you need to install File-Spec from CPAN";

    my $min_version = 0.82;
    unless ($File::Spec::VERSION >= $min_version) {
        die "you need to install File-Spec-$min_version or higher from CPAN";
    }

    while (my ($file, $sub) = each %compat_files) {
        $sub->($file);
    }
}

sub open_file {
    my $file = shift;

    unless (-d 'lib') {
        $file = "Apache-Test/$file";
    }

    my $dir = dirname $file;

    unless (-d $dir) {
        mkpath([$dir], 0, 0755);
    }

    my $fh = Symbol::gensym();
    print "creating $file\n";
    open $fh, ">$file" or die "open $file: $!";

    return $fh;
}

sub warnings_pm {
    return if eval { require warnings };

    my $fh = open_file(shift);

    print $fh <<'EOF';
package warnings;

sub import {}

1;
EOF

    close $fh;
}

1;

=head1 NAME

DocSet::5005compat - perl 5.005_03 compatibility module

=head1 SYNOPSIS

  # must be loaded as early as possible
  use DocSet::5005compat;

=head1 DESCRIPTION

This module encapsulates the functionalities/modules unavailable under
5.005_03.

Currently it only creates the warnings pragma's shell, so the code like:

 use warnings;

won't fail under 5.005_03.

=head1 ORIGIN

Borrowed from Apache::Test project.

=cut

