use utf8;
package Hg;
#ABSTRACT: This module exposes a read-only object oriented interface to local
#mercurial repositories.


1;

__END__

=pod

=head1 NAME

Hg - This module exposes a read-only object oriented interface to local

=head1 VERSION

version 0.003

=head1 USAGE

    my $repo = Hg::Repository->new(
            dir => '/path/to/repository',
            hg => '/optional/path/to/mercurial',
        );

    my $tip = $repo->tip;

    my $author = $tip->author;

=head1 AUTHOR

Robert Ward <robert@rtward.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Ward.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
