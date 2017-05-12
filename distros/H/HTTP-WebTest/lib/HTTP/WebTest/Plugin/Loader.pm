# $Id: Loader.pm,v 1.7 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::Loader;

=head1 NAME

HTTP::WebTest::Plugin::Loader - Loads external plugins

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin lets you to load external L<HTTP::WebTest|HTTP::WebTest>
plugins.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::WebTest::Utils qw(load_package);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 plugins

I<GLOBAL PARAMETER>

A list of module names.  Loads these modules and registers them as
L<HTTP::WebTest|HTTP::WebTest> plugins.  If the name of the plugin starts with
C<::>, it is prepended with C<HTTP::WebTest::Plugin>.  So

    plugins = ( ::Click )

is equal to

    plugins = ( HTTP::WebTest::Plugin::Click )

=cut

sub param_types {
    return q(plugins list);
}

sub start_tests {
    my $self = shift;

    $self->global_validate_params(qw(plugins));

    my $plugins = $self->global_test_param('plugins');

    for my $plugin (@$plugins) {
	my $name = $plugin;

	if($name =~ /^::/) {
	    $name = 'HTTP::WebTest::Plugin' . $name;
	}

	load_package($name);

	push @{$self->webtest->plugins}, $name->new($self->webtest);
    }
}

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
