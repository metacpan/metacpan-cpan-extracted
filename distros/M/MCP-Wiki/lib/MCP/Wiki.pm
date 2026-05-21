package MCP::Wiki;

# ABSTRACT: Markdown wiki MCP server with TOC extraction and git history

use strict;
use warnings;

our $VERSION = '0.001';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki - Markdown wiki MCP server with TOC extraction and git history

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use MCP::Wiki::Server;

    my $server = MCP::Wiki::Server->new(
        wiki_root => '/path/to/wiki',
        use_git   => 1,
    );

    $server->to_stdio;

=head1 DESCRIPTION

An MCP server that manages a markdown wiki in a directory. Supports TOC
extraction, paragraph-level editing, and git history tracking.

=head1 SEE ALSO

L<MCP::Wiki::Server>, L<MCP::Wiki::Document>, L<MCP::Wiki::TOC::Parser>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-wiki/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
