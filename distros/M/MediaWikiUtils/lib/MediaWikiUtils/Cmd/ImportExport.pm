#
# This file is part of MediaWikiUtils
#
# This software is copyright (c) 2014 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MediaWikiUtils::Cmd::ImportExport;
{
  $MediaWikiUtils::Cmd::ImportExport::VERSION = '0.141410';
}

use strict;
use warnings;

use Moo;
extends 'MediaWikiUtils::Common';

use MooX::Cmd;
use MooX::Options;

#ABSTRACT: A tools to provides command to import and export mediawiki data

option 'file' => (
    is       => 'ro',
    formart  => 's',
    default  => sub { 'wiki_dump.xml' },
    doc      => 'The file to use on the import (default wiki_dump.xml)'
);

sub execute {
    my ( $self ) = @_;

    $self->_mediawiki->api({
        action => 'import',
        xml    => [$self->file]
    });

    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWikiUtils::Cmd::ImportExport - A tools to provides command to import and export mediawiki data

=head1 VERSION

version 0.141410

=head1 SYNOPSIS

    mwu importexport --username mediawiki_user --password my_password --url http://mediawiki.com/api.php

=head1 DESCRIPTION

To export and import mediawiki to another mediawiki, at the moment the only
command supported is import.

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
