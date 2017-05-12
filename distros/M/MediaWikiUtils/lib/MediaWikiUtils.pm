#
# This file is part of MediaWikiUtils
#
# This software is copyright (c) 2014 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MediaWikiUtils;
{
  $MediaWikiUtils::VERSION = '0.141410';
}

use strict;
use warnings;

use Moo;
use MooX::Cmd;
use MooX::Options;

#ABSTRACT: A tools provide few useful MediaWiki operation

sub execute {
    shift->options_usage();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWikiUtils - A tools provide few useful MediaWiki operation

=head1 VERSION

version 0.141410

=head1 SYNOPSIS

    mwu

=head1 DESCRIPTION

Provides few useful command for mediawiki, like a mediawiki converter to
dokuwiki.

=head1 CONTRIBUTING

This module is developed on Github at:

L<http://github.com/hobbestigrou/MediaWikiUtils>

Feel free to fork the repo and submit pull requests

=head1 BUGS

Please report any bugs or feature requests in github.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MediaWikiUtils

=head1 SEE ALSO

L<MediaWiki::API>

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
