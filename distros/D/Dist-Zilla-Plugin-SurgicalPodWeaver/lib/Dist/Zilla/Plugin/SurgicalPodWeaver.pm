package Dist::Zilla::Plugin::SurgicalPodWeaver;
# git description: v0.0022-4-g8ecd8b5

# ABSTRACT: Surgically apply PodWeaver
$Dist::Zilla::Plugin::SurgicalPodWeaver::VERSION = '0.0023';

use Moose;
extends qw/ Dist::Zilla::Plugin::PodWeaver /;

sub parse_hint {
    my $self = shift;
    my $content = shift;

    my %hint;
    if ( $content =~ m/^\s*#+\s*(?:Dist::Zilla):\s*(.+)$/m ) {
        %hint = map {
            m/^([\+\-])(.*)$/ ?
                ( $1 eq '+' ? ( $2 => 1 ) : ( $2 => 0 ) ) :
                ()
        } split m/\s+/, $1;
    }

    return \%hint;
}

around munge_pod => sub {
    my $inner = shift;
    my ( $self, $file ) = @_;

    my $content = $file->content;

    my $yes = 0;
    if ( my $hint = __PACKAGE__->parse_hint( $content ) ) {
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

version 0.0023

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

If either condition is satisfied, PodWeavering will be done.

You can forcefully disable PodWeaver on a .pm by using the C<-PodWeaver> hint

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTOR

=for stopwords Robert Krimen

Robert Krimen <rokr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
