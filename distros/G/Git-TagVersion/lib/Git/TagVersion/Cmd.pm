package Git::TagVersion::Cmd;

use Moose;

our $VERSION = '1.01'; # VERSION
# ABSTRACT: commandline wrapper for Git::TagVersion
 
extends qw(MooseX::App::Cmd);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::Cmd - commandline wrapper for Git::TagVersion

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
