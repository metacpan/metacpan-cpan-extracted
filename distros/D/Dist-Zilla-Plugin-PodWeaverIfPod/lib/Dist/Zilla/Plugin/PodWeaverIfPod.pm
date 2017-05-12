package Dist::Zilla::Plugin::PodWeaverIfPod;
BEGIN {
  $Dist::Zilla::Plugin::PodWeaverIfPod::VERSION = '0.02';
}

use Moose;
extends qw/ Dist::Zilla::Plugin::PodWeaver /;

around munge_pod => sub {
    my $inner = shift;
    my ( $self, $file ) = @_;

    my $content = $file->content;

    if ( $content =~ /=head1/ ) {
        return $inner->(@_);
    }
    else {
        return;
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::PodWeaverIfPod - Apply PodWeaver if there is already Pod

=head1 SYNOPSIS

In your L<Dist::Zilla> C<dist.ini>:

    [PodWeaverIfPod]

=head1 DESCRIPTION

Dist::Zilla::Plugin::PodWeaverIfPod will only PodWeaver a .pm if there appears
to be Pod there (i.e. a C<=head1> section).

