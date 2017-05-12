package Mason::PluginBundle::Default;
$Mason::PluginBundle::Default::VERSION = '2.24';
use Mason::PluginRole;
with 'Mason::PluginBundle';

sub requires_plugins { qw(Defer DollarDot) }

1;

__END__

=pod

=head1 NAME

Mason::PluginBundle::Default - Default plugins

=head1 DESCRIPTION

Plugins in this bundle are always added by default, regardless of whether you
pass a plugins list to C<< Mason->new >>. You can use the '-' prefix to remove
individual plugins or the whole bundle. e.g.

    # Will get just the default plugins
    Mason->new(...);
    Mason->new(plugins => [], ...);

    # Will get the default plugins plus the 'Foo' plugin
    Mason->new(plugins => ['Foo'], ...);

    # Will get the default plugins except for 'DollarDot'
    Mason->new(plugins => ['-DollarDot'], ...);

    # Will get no plugins
    Mason->new(plugins => ['-Default'], ...);

=head1 INCLUDED PLUGINS

=over

=item L<Defer|Mason::Plugin::Defer>

=item L<DollarDot|Mason::Plugin::DollarDot>

=back

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
