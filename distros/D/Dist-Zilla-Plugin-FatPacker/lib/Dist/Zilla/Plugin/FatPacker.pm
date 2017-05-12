package Dist::Zilla::Plugin::FatPacker;
use 5.008;
use strict;
use warnings;
# ABSTRACT: Pack your dependencies onto your script file
our $VERSION = '1.161631'; # VERSION

use File::Temp 'tempfile';
use File::Path 'remove_tree';
use File::pushd 'tempd';
use Path::Class 'file';
use Moose;
with 'Dist::Zilla::Role::FileMunger';
has script => (is => 'ro');

around munge_files => sub {
    my ($orig, $self, @args) = @_;
    my $tmpdir = tempd();

    for my $file (@{ $self->zilla->files }) {
        my $path = file($file->name);
        $path->dir->mkpath();

        my $fh = $path->open('>:bytes')
            or die "Can't create $path in fatpacking work dir: $!\n";
        $fh->print($file->encoded_content);
    }

    return $self->$orig(@args);
};

sub safe_pipe_command {
    my ($binmode, @cmd) = @_;

    open(my($pipe), '-|', @cmd) or die "can't run command @cmd: $!";
    binmode($pipe, $binmode);
    my $output = join('', <$pipe>);
    close($pipe);

    return $output;
}

sub safe_system {
    my $cmd = shift;
    system($cmd) == 0 or die "can't $cmd: $?";
}

sub safe_remove_tree {
    my $errors;
    remove_tree(@_, { error => \$errors });
    return unless @$errors;
    for my $diag (@$errors) {
        my ($file, $message) = %$diag;
        if ($file eq '') {
            warn "general error: $message\n";
        } else {
            warn "problem unlinking $file: $message\n";
        }
    }
    die "remove_tree had errors, aborting\n";
}

sub munge_file {
    my ($self, $file) = @_;
    unless (defined $self->script) {
        our $did_warn;
        $did_warn++ || warn "[FatPacker] requires a 'script' configuration\n";
        return;
    }
    return unless $file->name eq $self->script;
    my $content = $file->encoded_content;
    my ($fh, $temp_script) = tempfile();
    binmode($fh, ':bytes');
    warn "temp script [$temp_script]\n";
    print $fh $content;
    close $fh or die "can't close temp file $temp_script: $!\n";

    $ENV{PERL5LIB} = join ':', grep defined, 'lib', $ENV{PERL5LIB};
    safe_system("fatpack trace $temp_script");
    safe_system("fatpack packlists-for `cat fatpacker.trace` >packlists");
    safe_system("fatpack tree `cat packlists`");
    my $fatpack = safe_pipe_command(':bytes', 'fatpack', 'file', $temp_script);

    for ($temp_script, 'fatpacker.trace', 'packlists') {
        unlink $_ or die "can't unlink $_: $!\n";
    }
    safe_remove_tree('fatlib');
    $file->encoded_content($fatpack);
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FatPacker - Pack your dependencies onto your script file

=head1 VERSION

version 1.161631

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=head1 SYNOPSIS

In C<dist.ini>:

    [FatPacker]
    script = bin/my_script

=head1 DESCRIPTION

This plugin uses L<App::FatPacker> to pack your dependencies onto your script
file.

=head2 munge_file

When processing the script file indicated by the C<script> configuration parameter,
it prepends its packed dependencies to the script.

This process creates temporary files outside the build directory, but if there
are no errors, they will be removed again.

=head2 safe_pipe_command

Runs a command in a pipe, and returns the stdout.

=head2 safe_remove_tree

A wrapper around C<remove_tree()> from C<File::Path> that adds some
error checks.

=head2 safe_system

A wrapper around C<system()> that adds some error checks.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::FatPacker/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-FatPacker>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-FatPacker.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-FatPacker/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
