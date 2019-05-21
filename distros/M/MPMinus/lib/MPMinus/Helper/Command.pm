package MPMinus::Helper::Command; # $Id: Command.pm 266 2019-04-26 15:56:05Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

MPMinus::Helper::Command - Utilities to extend common UNIX commands in Makefiles etc.

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    perl -MMPMinus::Helper::Command -e crlf source... destination

=head1 DESCRIPTION

Utilities to extend common UNIX commands in Makefiles etc.

The module is used to extend common UNIX commands. In all cases the
functions work from @ARGV rather than taking arguments. This makes
them easier to deal with in Makefiles. Call them like this:

    perl -MMPMinus::Helper::Command -e some_command some files to work on

All filenames with * and ? will be glob expanded

=head1 FUNCTIONS

=head2 crlf

    perl -MMPMinus::Helper::Command -e crlf -- build/conf

Converts DOS and OS/2 linefeeds to Unix style recursively.

=head2 install

    perl -MMPMinus::Helper::Command -e install -- build

Copy all files and directoryes to destination directory (project installing)

=head2 replace

    perl -MMPMinus::Helper::Command -e replace -- build/inc build/conf build/*.conf

Renames files with os-names and apache version and removes all mismatch files

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

Coming soon

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION @EXPORT);
$VERSION = 1.04;

use base qw /Exporter/;
@EXPORT = qw(
        crlf
        replace
        install
    );

use Carp;
use CTK::Util ();
use CTK::ConfGenUtil;
use Cwd;
use File::Find;
use File::Copy qw/copy cp/;
use YAML::XS ();
use Try::Tiny;
use File::Spec ();
use Digest::MD5 qw/md5_hex/;
use MPMinus::Helper::Util qw/getApache load_metadata/;

use constant {
        META_FILES => [qw/MYMETA.yml MYMETA.json META.yml META.json/],
        MACRO_KEY  => 'x_macro',
        OS_TYPES => [qw/
                Unix
                Windows
            /],
        OS_NAMES => [qw/
                centos debian ubuntu
                interix gnu gnukfreebsd nto qnx android dos MSWin32 aix bsdos beos
                bitrig dgux dragonfly dynixptx freebsd linux haiku hpux iphoneos
                irix darwin machten midnightbsd minix mirbsd next openbsd netbsd
                dec_osf nto svr4 svr5 sco sco_sv unicos unicosmk solaris sunos
                cygwin msys os2
            /],
    };

my $basedir = getcwd();

# Original in package ExtUtils::Command
sub _expand_wildcards { @ARGV = map(/[*?]/o ? glob($_) : $_, @ARGV) }

# Original see in package ExtUtils::Command::dos2unix()
sub crlf {
    _expand_wildcards();
    find({ wanted => sub {
        return if -d;
        return unless -w _;
        return unless -r _;
        my $orig = $_;
        my $dir = $File::Find::dir;
        my $file = File::Spec->catfile($dir, $orig);
        print "Normalizing the linefeeds in file $file... ";
        my $skip = _normalize($orig, $orig) or do {
            print "error\n";
            warn "Can't create file $orig: $!\n";
            return
        };
        if ($skip == 1) {
            print "ok\n";
        } else {
            print "skip\n";
        }
    }}, @ARGV);
}
sub replace {
    _expand_wildcards();
    my %macro = _getMacro();
    return 0 unless %macro;
    $macro{L} = '[';
    $macro{R} = ']';
    my $aver = $macro{APACHE_SIGN} || "";
    my $abanner = sprintf("apache%s", $aver);
    my $os = "unix"; for (@{(OS_NAMES())}) { $os = $_ if CTK::Util::isos($_)};
    my $ostype = "unix"; for (@{(OS_TYPES())}) { $os = $_ if CTK::Util::isostype($_)};

    find({ wanted => sub {
        return if -d;
        return unless -w _;
        return unless -r _;
        return unless -T _;
        my $orig = $_;
        my $dir = $File::Find::dir;
        my $file = File::Spec->catfile($dir, $orig);
        print "Replacing variables in file $file... ";

        # ApacheXY testing
        if ($orig =~ /\.apache\d+/i) {
            unless (index(lc($orig), $abanner) > 0) {
                printf "skip: %s required\n", lc($abanner);
                return;
            }
        }

        # OS testing
        if (grep {index(lc($orig), sprintf(".%s.",lc($_))) > 0} @{(OS_NAMES())}) { # OS Catched!
            unless (index(lc($orig), sprintf(".%s.",lc($os))) > 0) {
                printf "skip: %s required\n", lc($os);
                return;
            }
        }

        # OSType testing
        if (grep {index(lc($orig), sprintf(".%s.",lc($_))) > 0} @{(OS_TYPES())}) { # OStype Catched!
            unless (index(lc($orig), sprintf(".%s.",lc($ostype))) > 0) {
                printf "skip: %s required\n", lc($ostype);
                return;
            }
        }

        # Replacing!
        my (@fromstat) = stat $orig;
        my $temp = $orig.'.tmp';
        my $data = CTK::Util::fload($orig);
        my $md5_in = md5_hex($data);
        my $output = CTK::Util::dformat($data, {%macro});
        my $md5_out = md5_hex($output);
        # Check
        if ($md5_in eq $md5_out) {
            print "skip\n";
            return;
        }
        CTK::Util::bsave($temp, $output) or do {
            printf("error: can't create temp file %s: %s\n", $temp, $!);
            return;
        };
        my $perm = $fromstat[2] || 0;
        $perm &= 07777;
        rename $temp, $orig;
        eval { chmod $perm, $orig; };
        print "ok\n";

    }}, @ARGV);

    return 1;
}
sub install {
    my $src = @ARGV ? shift(@ARGV) : '';
    croak("Source directory missing!") unless $src;
    my %macro = _getMacro();
    croak("Can't get metadata!") unless %macro;
    my $dst = $macro{DOCUMENT_ROOT};
    croak("Target directory missing!") unless defined($dst) && length($dst);
    CTK::Util::preparedir($dst);
    chdir($src) or croak("Can't change directory: $!");
    find({ wanted => sub {
        return unless -e;
        return unless -r _;
        my $f = $_;
        return if $f =~ /^\.+$/;
        return if $f =~ /^\.exists/;
        my $dir = $File::Find::dir;
        if (-f $f) {
            my $to = File::Spec->catfile($dst, $dir, $f);
            printf("Installing %s... ", $to);
            cp($f, $to) or do {
                printf("error: %s\n", $!);
                return;
            };
        } elsif (-d $f) {
            my $to = File::Spec->catdir($dst, $dir, $f);
            printf("Installing %s... ", $to);
            if (!-e $to) {
                my (@fromstat) = stat $f;
                my $perm = $fromstat[2] || 0;
                $perm &= 07777;
                mkdir $to or do {
                    printf("error: %s\n", $!);
                    return;
                };
                eval { chmod $perm, $to; };
            } else {
                print("skip\n");
                return
            }
        } else {
            printf("Skip %s. This is not file and not directory\n", $f);
            return;
        }
        print "ok\n";
    }}, '.');
    chdir($basedir) or croak("Can't change directory: $!");
    return 1;
}

sub _normalize {
    my $in = shift // return 0;
    return -1 unless -e $in and -T _; # Only text files passed
    my $out = shift // return 0;
    my $prm = shift || 0;
    my $temp = $in.'.tmp';
    my (@fromstat) = stat $in;
    my $data = CTK::Util::fload($in);
    CTK::Util::bsave($temp, CTK::Util::lf_normalize($data)) or do {
        warn "Can't create temp file $temp: $!\n";
        return 0;
    };
    rename $temp, $out;
    my $perm = $prm || $fromstat[2] || 0;
    $perm &= 07777;
    eval { chmod $perm, $out; };
    return 1;
}
sub _getMacro {
    my @metaf = grep { -e and -s and -T } @{(META_FILES())};
    croak("Can't select metafile") unless @metaf;
    foreach my $f (@metaf) {
        my %meta = load_metadata($f);
        my $macro = $meta{(MACRO_KEY())};
        if ($macro && ref($macro) eq 'HASH') {
            return %$macro;
        }
        return ();
    }
    croak("Can't get metafile data");
}

1;

__END__

