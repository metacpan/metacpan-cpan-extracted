package Mail::MtPolicyd::SessionCache::None;

use Moose;

our $VERSION = '2.05'; # VERSION
# ABSTRACT: dummy session caching adapter

extends 'Mail::MtPolicyd::SessionCache::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::SessionCache::None - dummy session caching adapter

=head1 VERSION

version 2.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
