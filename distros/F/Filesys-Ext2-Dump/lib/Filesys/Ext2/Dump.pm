package Filesys::Ext2::Dump;

our $DATE = '2016-07-26'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(dump_ext2);

our %SPEC;

$SPEC{dump_ext2} = {
    v => 1.1,
    summary => 'Interface to dumpe2fs command',
    args => {
        device => {
            schema => 'str*',
            pos => 0,
            summary => 'Device name',
        },
        mount_point => {
            schema => 'dirname',
            summary => 'Mount point',
            description => <<'_',

Either specify a device name, or a mount point.

_
        },
    },
    args_rels => {
        req_one => [qw/mount_point device/],
    },
    deps => {
        prog => 'dumpe2fs',
    },
};
sub dump_ext2 {
    require File::Which;
    require IPC::System::Options;
    require Proc::ChildError;

    my %args = @_;

    my $dumpe2fs_path = File::Which::which("dumpe2fs")
        or return [412, "Can't find dumpe2fs in PATH, please make sure ".
                   "the program is installed and you are root"];

    my $device = $args{device};
    unless ($device) {
        my $mp = $args{mount_point}
            or return [400, "Please specify device or mount_point"];
        require Sys::Filesystem;
        my $sysfs = Sys::Filesystem->new;
        $device = $sysfs->device($mp)
            or return [400, "Can't find device at mount point '$mp'"];
    }

    my ($stdout, $stderr);
    IPC::System::Options::system(
        {
            lang=>'C', log=>1,
            capture_stdout => \$stdout,
            capture_stderr => \$stderr,
        },
        $dumpe2fs_path, "-h", $device,
    );
    return [500, "Can't run $dumpe2fs_path successfully: ".
                Proc::ChildError::explain_child_error(), undef, {
                    'func.raw_stderr' => $stderr,
                }
              ]
        if $?;

    my %raw_parse = $stdout =~ /^([^:]+?)\s*:\s*(.*)/gm;

    my $res = {};
    $res->{label} = $raw_parse{"Filesystem volume name"};
    $res->{uuid}  = $raw_parse{"Filesystem UUID"};

    [200, "OK", $res, {
        'func.device' => $device,
        'func.raw_stdout' => $stdout,
        'func.raw_stderr' => $stderr,
    }];
}

1;
# ABSTRACT: Interface to dumpe2fs command

__END__

=pod

=encoding UTF-8

=head1 NAME

Filesys::Ext2::Dump - Interface to dumpe2fs command

=head1 VERSION

This document describes version 0.002 of Filesys::Ext2::Dump (from Perl distribution Filesys-Ext2-Dump), released on 2016-07-26.

=head1 SYNOPSIS

 use Filesys::Ext2::Dump qw(dump_ext2);

 my $res = dump_ext2(device => "/dev/sdc1");

Sample result (on error):

 [412, "Can't find dumpe2fs in PATH"];

Sample result (on success):

 [200, "OK",

  # main result is a hash
  {
      label => "foo",
      uuid  => "f172f8e5-74b1-4f51-a7c4-6b2ddad31ac0",
      ...
  },

  # metadata (extra results)
  {
      "func.device" => "/dev/sdc1",
      "func.raw_stdout" => "...",
      "func.raw_stderr" => "...",
      ...
  },
 ]

=head1 FUNCTIONS


=head2 dump_ext2(%args) -> [status, msg, result, meta]

Interface to dumpe2fs command.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<device> => I<str>

Device name.

=item * B<mount_point> => I<dirname>

Mount point.

Either specify a device name, or a mount point.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filesys-Ext2-Dump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filesys-Ext2-Dump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filesys-Ext2-Dump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
