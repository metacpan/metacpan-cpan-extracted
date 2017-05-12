package LWP::Simple::WithCache;

use strict;
use LWP::Simple;
use LWP::UserAgent::WithCache;
our $VERSION = 0.03;

$LWP::Simple::ua = new LWP::UserAgent::WithCache;
$LWP::Simple::ua->agent("LWP::Simple::WithCache/$VERSION");
$LWP::Simple::FULL_LWP = 1;

1;

__END__

=head1 NAME

LWP::Simple::WithCache - LWP::Simple with cache

=head1 SYNOPSIS

  use LWP::Simple;
  use LWP::Simple::WithCache;

  print get('http://www.leeym.com/');

=head1 DESCRIPTION

LWP::Simple::WithCache reassign the $ua used by LWP::Simple to
LWP::UserAgent::WithCache, and allow users to use the function provided
by LWP::Simple with some cache functionality.

Users can access the cache object by using $LWP::Simple::ua->{cache} to
get or set cache_root, namespace, etc.

=head1 SEE ALSO

  LWP::Simple
  LWP::UserAgent::WithCache
  Cache::Cache
  Cache::FileCache

=head1 AUTHOR

Yen-Ming Lee, E<lt>leeym@leeym.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Yen-Ming Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
