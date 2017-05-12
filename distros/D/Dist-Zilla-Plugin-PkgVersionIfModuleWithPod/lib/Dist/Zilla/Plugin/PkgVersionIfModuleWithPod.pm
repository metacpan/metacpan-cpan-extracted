package Dist::Zilla::Plugin::PkgVersionIfModuleWithPod;
BEGIN {
  $Dist::Zilla::Plugin::PkgVersionIfModuleWithPod::VERSION = '0.01';
}
use Moose;
extends qw/ Dist::Zilla::Plugin::PkgVersion /;

around munge_perl => sub {
    my $inner = shift;
    my ( $self, $file ) = @_;

    my $content = $file->content;

    if ( $file->name =~ /\.pm/ && $content =~ /=pod/ ) {
        return $inner->(@_);
    }
};

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Dist::Zilla::Plugin::PkgVersionIfModuleWithPod - Apply PkgVersion to .pm files
with =pod sections

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your L<Dist::Zilla> C<dist.ini>:

    [PkgVersionIfModuleWithPod]

=head1 DESCRIPTION

Like L<Dist::Zilla::Plugin::PkgVersion>, but only for .pm files with =pod
sections.

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
