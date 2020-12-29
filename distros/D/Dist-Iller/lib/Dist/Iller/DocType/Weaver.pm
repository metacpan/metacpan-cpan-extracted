use 5.10.0;
use strict;
use warnings;

package Dist::Iller::DocType::Weaver;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Turn the Dist::Iller config into a weaver.ini file
our $VERSION = '0.1409';

use Dist::Iller::Elk;
with qw/
    Dist::Iller::DocType
    Dist::Iller::Role::HasPlugins
/;

sub filename { 'weaver.ini' }

sub phase { 'before' }

sub comment_start { ';' }

sub parse {
    my $self = shift;
    my $yaml = shift;
    $self->parse_plugins($yaml->{'plugins'});
}

sub to_hash {
    my $self = shift;

    return {
        plugins => $self->plugins_to_hash,
    }
}

sub to_string {
    my $self = shift;

    my @strings = ();
    foreach my $plugin ($self->all_plugins) {
        push @strings => $plugin->to_string, '';
    }
    return join "\n" => @strings;
}

sub packages_for_plugin {

    return sub {
        my $plugin = shift;

        my $packages = [];
        # For -Transformer
        if($plugin->has_base) {
            if($plugin->in eq 'Elemental') {
                my $base = $plugin->base;
                $base =~ s{^[^a-zA-Z]}{};

                push @{ $packages } => { version => $plugin->version, package => sprintf 'Pod::Elemental::%s::%s', $base, $plugin->plugin_name };
                push @{ $packages } => { version => 0, package => "Pod::Weaver::Plugin::$base" };
                return $packages;
            }
        }
        my $name = $plugin->has_base ? $plugin->base : $plugin->plugin_name;
        $name =~ m{^(.)};
        my $first = $1;

        my $clean_name = $name;
        $clean_name =~ s{^[-%=@]}{};

        push @{ $packages } => $first eq '-' ? { version => $plugin->version, package => sprintf 'Pod::Weaver::Plugin::%s', $clean_name }
                            :  $first eq '@' ? { version => $plugin->version, package => sprintf 'Pod::Weaver::PluginBundle::%s', $clean_name }
                            :  $first eq '=' ? { version => $plugin->version, package => sprintf $clean_name }
                            :                  { version => $plugin->version, package => sprintf 'Pod::Weaver::Section::%s', $clean_name }
                            ;
        return $packages;
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::DocType::Weaver - Turn the Dist::Iller config into a weaver.ini file

=head1 VERSION

Version 0.1409, released 2020-12-27.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
