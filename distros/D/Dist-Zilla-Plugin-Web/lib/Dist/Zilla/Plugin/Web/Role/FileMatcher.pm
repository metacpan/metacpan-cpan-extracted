package Dist::Zilla::Plugin::Web::Role::FileMatcher;
$Dist::Zilla::Plugin::Web::Role::FileMatcher::VERSION = '0.0.10';
# ABSTRACT: Embedd module version to sources

use Moose::Role;


has 'file_match' => (
    is      => 'rw',

    default => sub { [ '^lib/.*\\.js$' ] }
);


has 'exculde_match' => (
    is      => 'rw',

    default => sub { [] }
);


around mvp_multivalue_args => sub {
    my ($orig, $self) = @_;
    
    my $original = $self->$orig;
    
    qw( file_match exculde_match $original)
};


sub for_each_matched_file {
    my ($self, $sub) = @_;
    
    my $matches_regex = qr/\000/;
    my $exclude_regex = qr/\000/;

    $matches_regex = qr/$_|$matches_regex/ for (@{$self->file_match});
    $exclude_regex = qr/$_|$exclude_regex/ for (@{$self->exculde_match});

    for my $file (@{$self->zilla->files}) {
        next unless $file->name =~ $matches_regex;
        next if     $file->name =~ $exclude_regex;
        
        $sub->($file);
    }
}


no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Web::Role::FileMatcher - Embedd module version to sources

=head1 VERSION

version 0.0.10

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
