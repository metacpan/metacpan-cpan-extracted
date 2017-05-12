package Dist::Zilla::Plugin::TemplateFiles;
# ABSTRACT:  Use files to template a distribution
$Dist::Zilla::Plugin::TemplateFiles::VERSION = '0.03';
use Moose;
use Moose::Autobox;
use namespace::autoclean;

with qw/ 
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::TextTemplate 
/;

# Don't ask me, I just copied from 
sub mvp_multivalue_args { qw/ filename / }

has filename => (
    is => 'rw',
    isa => 'ArrayRef',
);

my %files;

sub munge_file {
    my ($self,$file) = @_;
    unless (%files) { 
        for my $filename (@{$self->filename}) {
            $files{$filename} = 1;
        }
    }
    return unless $files{$file->name};
    my $content = $self->fill_in_string( $file->content, { plugin => \$self, dist => \($self->zilla) } );
    $file->content( $content ) if defined $content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TemplateFiles - Use files to template a distribution

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your F<dist.ini>:

  [TemplateFiles]
      filename = README
      filename = path/to/other/file

=head1 DESCRIPTION

Utilize L<Text::Template> to turn certain files into templates.  Each
template has available to it the C<$dist> variable that is the instance
of L<Dist::Zilla> currently running.  Only those files listed in
C<dist.ini> as C<filename = blah> will be considered templates.
Filenames are given relative to the root of the build. 

=head1 NAME

Dist::Zilla::Plugin::TemplateFiles - use files as templates to build a distribution

=head1 AUTHOR

Jonathan Scott Duff <duff@pobox.com>

=head1 COPYRIGHT

This software is copyright (c) 2010 by Jonathan Scott Duff

This is free sofware; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language itself.

=head1 AUTHOR

Jonathan Scott Duff <duff@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Scott Duff.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
