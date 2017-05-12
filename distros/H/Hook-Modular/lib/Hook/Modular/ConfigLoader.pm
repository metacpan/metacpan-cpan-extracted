use 5.008;
use strict;
use warnings;

package Hook::Modular::ConfigLoader;
BEGIN {
  $Hook::Modular::ConfigLoader::VERSION = '1.101050';
}
# ABSTRACT: Configuration loader for Hook::Modular
use Carp;
use Hook::Modular::Walker;
use YAML;
use Storable;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub load {
    my ($self, $stuff, $context) = @_;
    my $config;
    if (   (!ref($stuff) && $stuff eq '-')
        || (-e $stuff && -r _)) {
        $config = YAML::LoadFile($stuff);
        $context->{config_path} = $stuff if $context;
    } elsif (ref($stuff) && ref $stuff eq 'SCALAR') {
        $config = YAML::Load(${$stuff});
    } elsif (ref($stuff) && ref $stuff eq 'HASH') {
        $config = Storable::dclone($stuff);
    } else {
        croak "Hook::Modular::ConfigLoader->load: $stuff: $!";
    }
    unless ($config->{global} && $config->{global}->{no_decode_utf8}) {
        Hook::Modular::Walker->decode_utf8($config);
    }
    return $config;
}

sub load_include {
    my ($self, $config) = @_;
    my $includes = $config->{include} or return;
    $includes = [$includes] unless ref $includes;
    for my $file (@$includes) {
        my $include = YAML::LoadFile($file);
        for my $key (keys %{$include}) {
            my $add = $include->{$key};
            unless ($config->{$key}) {
                $config->{$key} = $add;
                next;
            }
            if (ref $config->{$key} eq 'HASH') {
                next unless ref $add eq 'HASH';
                for (keys %{ $include->{$key} }) {
                    $config->{$key}->{$_} = $include->{$key}->{$_};
                }
            } elsif (ref $include->{$key} eq 'ARRAY') {
                $add = [$add] unless ref $add eq 'ARRAY';
                push(@{ $config->{$key} }, @{ $include->{$key} });
            } elsif ($add) {
                $config->{$key} = $add;
            }
        }
    }
}

sub load_recipes {
    my ($self, $config) = @_;
    for (@{ $config->{recipes} }) {
        $self->error("no such recipe to $_")
          unless $config->{define_recipes}->{$_};
        my $plugin = $config->{define_recipes}->{$_};
        $plugin = [$plugin] unless ref $plugin eq 'ARRAY';
        push(@{ $config->{plugins} }, @{$plugin});
    }
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::ConfigLoader - Configuration loader for Hook::Modular

=head1 VERSION

version 1.101050

=head1 METHODS

=head2 load

FIXME

=head2 load_include

FIXME

=head2 load_recipes

FIXME

=head2 new

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Hook-Modular>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Hook-Modular/>.

The development version lives at
L<http://github.com/hanekomu/Hook-Modular/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

