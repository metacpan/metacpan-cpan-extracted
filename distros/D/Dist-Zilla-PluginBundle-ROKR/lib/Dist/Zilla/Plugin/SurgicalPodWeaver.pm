package Dist::Zilla::Plugin::SurgicalPodWeaver;
BEGIN {
  $Dist::Zilla::Plugin::SurgicalPodWeaver::VERSION = '0.0019';
}
# ABSTRACT: Surgically apply PodWeaver


use Moose;
extends qw/ Dist::Zilla::Plugin::PodWeaver /;

require Dist::Zilla::PluginBundle::ROKR;

around munge_pod => sub {
    my $inner = shift;
    my ( $self, $file ) = @_;

    my $content = $file->content;

    my $yes = 0;
    if ( my $hint = Dist::Zilla::PluginBundle::ROKR->parse_hint( $content ) ) {
        if ( exists $hint->{PodWeaver} ) {
            return unless $hint->{PodWeaver};
            $yes = 1;
        }
    }

    if ( $yes || $content =~ m/^\s*#+\s*(?:ABSTRACT):\s*(.+)$/m ) { }
    else { return }

    return $inner->( @_ )
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::SurgicalPodWeaver - Surgically apply PodWeaver

=head1 VERSION

version 0.0019

=head1 SYNOPSIS

In your L<Dist::Zilla> C<dist.ini>:

    [SurgicalPodWeaver]

To hint that you want to apply PodWeaver:

    package Xyzzy;
    # Dist::Zilla: +PodWeaver

    ...

=head1 DESCRIPTION

Dist::Zilla::Plugin::SurgicalPodWeaver will only PodWeaver a .pm if:

    1. There exists an # ABSTRACT: ...
    2. The +PodWeaver hint is present

You can forcefully disable PodWeaver on a .pm by using the C<-PodWeaver> hint

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

