package Mason::Plugin::Cache;
BEGIN {
  $Mason::Plugin::Cache::VERSION = '0.05';
}
use Moose;
with 'Mason::Plugin';

__PACKAGE__->meta->make_immutable();

1;



=pod

=head1 NAME

Mason::Plugin::Cache - Provide component cache object and filter

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my $result = $.cache->get('key');
    if (!defined($result)) {
        ... compute $result ...
        $.cache->set('key', $result, '5 minutes');
    }

    ...

    % $.Cache('key2', '1 hour') {{
      <!-- this will be cached for an hour -->
    % }}

=head1 DESCRIPTION

Adds a C<cache> method and C<Cache> filter to access a cache (L<CHI|CHI>)
object with a namespace unique to the component.

=head1 INTERP PARAMETERS

=over

=item cache_defaults

Hash of parameters passed to cache constructor. Defaults to

    driver=>'File', root_dir => 'DATA_DIR/cache'

which will create a basic file cache under Mason's L<data directory|data_dir>.

=item cache_root_class

Class used to create a cache. Defaults to L<CHI|CHI>.

=back

=head1 COMPONENT CLASS METHODS

=over

=item cache

Returns a new cache object with the namespace set to the component's path.
Parameters to this method, if any, are combined with L<cache_defaults> and
passed to the L<cache_root_class> constructor.  The cache object is memoized
when no parameters are passed.

    my $result = $.cache->get('key');

=back

=head1 REQUEST METHODS

=over

=item cache

Same as calling C<cache> on the current component class. This usage will be
familiar to Mason 1 users.

    my $result = $m->cache->get('key');

=back

=head1 FILTERS

=over

=item Cache ($key, $options, [%cache_params])

Caches the content using C<< $self->cache >> and the supplied cache I<$key>.

I<$options> is a scalar or hash reference. If a scalar, it is treated as the
C<expires_in> duration and passed as the third argument to C<set>. If it is a
hash reference, it may contain name/value pairs for both C<get> and C<set>.

I<%cache_params>, if any, are passed to C<< $self->cache >>.

    % $.Cache($my_key, '1 hour') {{
      <!-- this will be cached for an hour -->
    % }}

    % $.Cache($my_key, { expire_if => sub { $.refresh } }, driver => 'RawMemory') {{
      <!-- this will be cached until $.refresh is true -->
    % }}

If neither I<$key> nor I<$options> are passed, the key is set to 'Default' and
the cache never expires.

    % $.Cache() {{
      <!-- cache this forever, or until explicitly removed -->
    % }}

=back

=head1 SUPPORT

The mailing list for Mason and Mason plugins is
L<mason-users@lists.sourceforge.net>. You must be subscribed to send a message.
To subscribe, visit
L<https://lists.sourceforge.net/lists/listinfo/mason-users>.

You can also visit us at C<#mason> on L<irc://irc.perl.org/#mason>.

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mason-Plugin-Cache
    bug-mason-plugin-cache@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-mason-plugin-cache
    git clone git://github.com/jonswar/perl-mason-plugin-cache.git

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

