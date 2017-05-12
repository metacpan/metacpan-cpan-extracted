use 5.008;
use strict;
use warnings;

package Hook::Modular::CacheProxy;
BEGIN {
  $Hook::Modular::CacheProxy::VERSION = '1.101050';
}
# ABSTRACT: Cache proxy for Hook::Modular

sub new {
    my ($class, $plugin, $cache) = @_;
    bless {
        namespace => $plugin->plugin_id,
        cache     => $cache,
    }, $class;
}
for my $meth (qw(get get_callback set remove)) {
    no strict 'refs';
    *{$meth} = sub {
        my $self = shift;
        my $key  = shift;
        $key = "$self->{namespace}|$key";
        $self->{cache}->$meth($key, @_);
    };
}

sub path_to {
    my ($self, @path) = @_;
    $self->{cache}->path_to($self->{namespace}, @path);
}
1;


__END__
=pod

=head1 NAME

Hook::Modular::CacheProxy - Cache proxy for Hook::Modular

=head1 VERSION

version 1.101050

=head1 METHODS

=head2 get

FIXME

=head2 get_callback

FIXME

=head2 new

FIXME

=head2 path_to

FIXME

=head2 remove

FIXME

=head2 set

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

