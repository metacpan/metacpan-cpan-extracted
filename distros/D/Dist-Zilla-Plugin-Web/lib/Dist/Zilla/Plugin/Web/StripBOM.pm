package Dist::Zilla::Plugin::Web::StripBOM;
$Dist::Zilla::Plugin::Web::StripBOM::VERSION = '0.0.10';
# ABSTRACT: Embedd module version to sources

use Moose;

use Path::Class;
use String::BOM qw(string_has_bom strip_bom_from_string);

with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Plugin::Web::Role::FileMatcher';

has 'file_match' => (
    is      => 'rw',

    default => sub { [ '.*' ] }
);



sub munge_files {
    my ($self) = @_;
    
    $self->for_each_matched_file(sub {
        my ($file)    = @_;

        my $content             = $file->content;
        
        if (string_has_bom($content)) {
            $file->content(strip_bom_from_string($content));
        }
    });
}


no Moose;
__PACKAGE__->meta->make_immutable();


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Web::StripBOM - Embedd module version to sources

=head1 VERSION

version 0.0.10

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
