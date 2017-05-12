package Devel::SizeMe::Core;

use strict;

require 5.008;
require Exporter;
require XSLoader;

our $VERSION = '0.19';
our @ISA = qw(Exporter);

XSLoader::load("Devel::SizeMe", $VERSION);

our @EXPORT_OK = (keys %Devel::SizeMe::Core::);
our %EXPORT_TAGS = (
    type => [ grep { /^NPtype_/ } @EXPORT_OK ],
    attr => [ grep { /^NPattr_/ } @EXPORT_OK ],
);

1;
__END__

=head1 NAME

Devel::SizeMe::Core - Guts of Devel::SizeMe

=head1 SYNOPSIS

    use Devel::SizeMe::Core qw(:type :attr);

=head1 DESCRIPTION

NOTE: This is all rather alpha and anything may change.

The functions traverse memory structures and return the total memory size in
bytes.  See L<Devel::Size> for more information.

=head1 SEE ALSO

L<Devel::Size>.

=cut
