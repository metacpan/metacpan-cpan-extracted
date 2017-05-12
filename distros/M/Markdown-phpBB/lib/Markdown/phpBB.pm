package Markdown::phpBB;

use 5.010;
use strict;
use warnings;
use autodie;
use Moose;

# ABSTRACT: Turn markdown into phpBB code
our $VERSION = '0.02'; # VERSION

use Markdent::Parser;
use Markdown::phpBB::Handler;


my $handler = Markdown::phpBB::Handler->new;

my $parser = Markdent::Parser->new(
    handler => $handler,
    dialect => 'GitHub',
);


sub convert {
    my ($self, $text) = @_;

    $parser->parse(markdown => $text);

    return $handler->result;
}

1;

__END__

=pod

=head1 NAME

Markdown::phpBB - Turn markdown into phpBB code

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $md2php = Markdown::phpBB->new;

    my $phpbb = $md2php->convert($markdown);

=head1 DESCRIPTION

This converts (github-flavoured) markdown into phpBB / BBcode.

It uses L<Markdown::phpBB::Handler> and L<Markdent> to do the
heavy lifting.

=head1 METHODS

=head2 convert

    my $phpbb = $md2php->convert($markdown);

Takes a single string in markdown format, and returns the equivalent
string in phpBB / BBcode.

=head1 SEE ALSO

L<md2phpbb> - A stand-alone script for converting markdown to phpBB / BBcode.

L<phpbb2md>, L<Markdown::phpBB::Handler>, L<Markdent>

=head1 BUGS

Plenty. Report them or fix them at
L<http://github.com/pjf/Markdown-phpBB/issues>.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
