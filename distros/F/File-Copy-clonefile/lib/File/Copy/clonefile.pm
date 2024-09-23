package File::Copy::clonefile v0.0.8;
use v5.20;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    clonefile
    CLONE_NOFOLLOW CLONE_NOOWNERCOPY CLONE_ACL
);

use XSLoader;
XSLoader::load __PACKAGE__, __PACKAGE__->VERSION;

1;
__END__

=encoding utf-8

=head1 NAME

File::Copy::clonefile - call clonefile system call

=head1 SYNOPSIS

  use File::Copy::clonefile qw(clonefile);

  clonefile "source.txt", "destination.txt"
    or die "failed to clonefile source.txt to destination.txt: $!";

=head1 DESCRIPTION

File::Copy::clonefile is a wrapper for
L<clonefile|https://www.manpagez.com/man/2/clonefile/> system call.
Thus, this module only supports platforms that have clonefile system call, such as macos.

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
