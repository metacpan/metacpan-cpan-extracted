package Dist::Zilla::Role::DumpPerinciCmdLineScript;

our $DATE = '2016-05-20'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Moose::Role;

use Data::Dmp;
use Perinci::CmdLine::Dump;

sub dump_perinci_cmdline_script {
    my ($self, $file) = @_;

    my $filename = $file->name;

    # if file object is not a real file on the filesystem, put it in a temporary
    # file first so Perinci::CmdLine::Dump can see it.
    unless ($file->isa("Dist::Zilla::File::OnDisk")) {
        require File::Temp;
        my ($fh, $tempname) = File::Temp::tempfile();
        print $fh $file->encoded_content;
        close $fh;
        $filename = $tempname;
    }

    # so scripts can know that they are being dumped in the context of
    # Dist::Zilla
    local $ENV{DZIL} = 1;

    $self->log_debug(["Dumping Perinci::CmdLine script '%s'", $filename]);

    my $res = Perinci::CmdLine::Dump::dump_perinci_cmdline_script(
        filename => $filename,
        libs => ['lib'],
    );

    $self->log_debug(["Dump result: %s", dmp($res)]);
    $res;
}

no Moose::Role;
1;
# ABSTRACT: Role to dump Perinci::CmdLine script

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::DumpPerinciCmdLineScript - Role to dump Perinci::CmdLine script

=head1 VERSION

This document describes version 0.04 of Dist::Zilla::Role::DumpPerinciCmdLineScript (from Perl distribution Dist-Zilla-Role-DumpPerinciCmdLineScript), released on 2016-05-20.

=head1 METHODS

=head2 $obj->dump_perinci_cmdline_script($file)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Role-DumpPerinciCmdLineScript>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Role-DumpPerinciCmdLineScript>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-DumpPerinciCmdLineScript>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Role::DumpPerinciCmdLineScript> basically does the same thing,
but it accepts a slightly different argument (C<$input> instead of C<$file>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
