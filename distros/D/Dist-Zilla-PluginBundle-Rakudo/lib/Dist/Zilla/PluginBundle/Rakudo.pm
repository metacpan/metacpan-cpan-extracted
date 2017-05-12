package Dist::Zilla::PluginBundle::Rakudo;
BEGIN {
  $Dist::Zilla::PluginBundle::Rakudo::VERSION = '0.01';
}
# ABSTRACT: Bundle of plugins needed for building a rakudo distribution
use Moose;
use namespace::autoclean;
with qw/ Dist::Zilla::Role::PluginBundle::Easy /;

sub configure {
    my $self = shift;

    $self->add_plugins(qw(
        GatherDir
        PruneCruft
        PruneFiles
        License
        Manifest
        AutoVersion
        SvnObtain
        GitObtain
        TemplateFiles
    ));
}
 
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

=head1 SYNOPSIS

=head1 VERSION

version 0.01

=head1 DESCRIPTION

=head1 AUTHOR

Jonathan Scott Duff <duff@pobox.com>

=head1 COPYRIGHT

This software is copyright (c) 2010 by Jonathan Scott Duff

This is free sofware; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language itself.

=cut