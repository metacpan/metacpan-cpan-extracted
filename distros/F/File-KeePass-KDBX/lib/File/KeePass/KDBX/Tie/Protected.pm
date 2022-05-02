package File::KeePass::KDBX::Tie::Protected;
# ABSTRACT: Entry memory protection flags

use warnings;
use strict;

use boolean;
use namespace::clean;

use parent 'File::KeePass::KDBX::Tie::Hash';

our $VERSION = '0.901'; # VERSION

my %GET = (
    comment     => sub { $_[0]->string('Notes')     ->{protect} ? 1 : 0 },
    password    => sub { $_[0]->string('Password')  ->{protect} ? 1 : 0 },
    title       => sub { $_[0]->string('Title')     ->{protect} ? 1 : 0 },
    url         => sub { $_[0]->string('URL')       ->{protect} ? 1 : 0 },
    username    => sub { $_[0]->string('UserName')  ->{protect} ? 1 : 0 },
);
my %SET = (
    comment     => sub { $_[0]->string('Notes')     ->{protect} = boolean($_) },
    password    => sub { $_[0]->string('Password')  ->{protect} = boolean($_) },
    title       => sub { $_[0]->string('Title')     ->{protect} = boolean($_) },
    url         => sub { $_[0]->string('URL')       ->{protect} = boolean($_) },
    username    => sub { $_[0]->string('UserName')  ->{protect} = boolean($_) },
);

sub getters { \%GET }
sub setters { \%SET }
sub default_getter { my $key = $_[1]; sub { $_[0]->string($key)->{protect} ? 1 : 0 } }
sub default_setter { my $key = $_[1]; sub { $_[0]->string($key)->{protect} = boolean($_) } }

sub keys {
    my $self = shift;
    my ($entry) = @$self;
    my @keys;
    while (my ($key, $string) = each %{$entry->strings}) {
        $key = 'comment' if $key eq 'Notes';
        $key = lc($key) if $key =~ /^(?:Password|Title|URL|UserName)$/;
        push @keys, $key if $string->{protect};
    }
    return \@keys;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::KDBX::Tie::Protected - Entry memory protection flags

=head1 VERSION

version 0.901

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
