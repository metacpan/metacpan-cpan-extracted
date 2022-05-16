package File::KeePass::KDBX::Tie::Strings;
# ABSTRACT: Entry strings

use warnings;
use strict;

use parent 'File::KeePass::KDBX::Tie::Hash';

our $VERSION = '0.902'; # VERSION

my %STANDARD = map { $_ => 1 } qw(Notes Password Title UserName URL);

sub keys {
    my $self = shift;
    my ($entry) = @$self;
    return [grep { !$STANDARD{$_} } keys %{$entry->strings}];
}

sub default_getter { my $key = $_[1]; sub { $_[0]->string_value($key) } }
sub default_setter { my $key = $_[1]; sub { $_[0]->string_value($key, $_) } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::KDBX::Tie::Strings - Entry strings

=head1 VERSION

version 0.902

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KeePass-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
