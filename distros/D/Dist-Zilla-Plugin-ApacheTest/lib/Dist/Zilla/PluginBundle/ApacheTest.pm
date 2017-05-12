package Dist::Zilla::PluginBundle::ApacheTest;
$Dist::Zilla::PluginBundle::ApacheTest::VERSION = '0.03';
# ABSTRACT: Dist::Zilla Plugin Bundle That Configures Makefile.PL for Apache::Test

use Moose;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my $self = shift;

    my $args = $self->payload;

    $self->add_plugins(
        [
            'MakeMaker::ApacheTest' => {
                min_version => ($$args{min_version} || 0)
            }
        ],
        [
            'DynamicPrereqs' =>  {
                -raw => join('',
                    q[if ($mp_version == 2) { ],
                    q[    requires('mod_perl2', '1.999022'); ],
                    q[} ],
                    q[elsif ($mp_version == 1) { ],
                    q[    requires('mod_perl', '1.27'); ],
                    q[}]
                )
            }
        ]
    );
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::ApacheTest - Dist::Zilla Plugin Bundle That Configures Makefile.PL for Apache::Test

=head1 VERSION

version 0.03

=head1 SYNOPSIS

in dist.ini

 ; remove MakeMaker
 ;[MakeMaker]
 [@ApacheTest]
 min_version = 1.39

or, if you are using a bundle like L<@Classic|Dist::Zilla::PluginBundle::Classic>:

 [@Filter]
 bundle = @Classic
 remove = MakeMaker

 [@ApacheTest]

This is equivalent to the following:

 [MakeMaker::ApacheTest]
 [DynamicPrereqs]
 -raw = (code to require mod_perl if installed, otherwise mod_perl2)

=head1 DESCRIPTION

This plugin makes use of
L<MakeMaker::Awesome|Dist::Zilla::Plugin::MakeMaker::Awesome> to produce a
Makefile.PL with L<Apache::Test> hooks enabled.  If this plugin is loaded, you
should also load the L<Manifest|Dist::Zilla::Plugin::Manifest> plugin should
also be loaded, and the L<MakeMaker|Dist::Zilla::Plugin::MakeMaker> plugin.

=head1 CONFIGURATION OPTIONS

The following options are available in C<dist.ini> for this plugin:

=over 4

=item *

min_version

The minimum version of Apache::Test that will be required in C<Makefile.PL>.
The default is C<0>.  You are B<strongly> encouraged to explicitly specify the
version of L<Apache::Test> that is required by your module instead of relying
on the default.

=back

=head1 SEE ALSO

=over 4

=item *

L<MakeMaker::Awesome|Dist::Zilla::Plugin::MakeMaker::Awesome>

=item *

L<MakeMaker::ApacheTest|Dist::Zilla::Plugin::MakeMaker::ApacheTest>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/dist-zilla-plugin-apachetest>
and may be cloned from L<git://github.com/mschout/dist-zilla-plugin-apachetest.git>

=head1 BUGS

Please report any bugs or feature requests to bug-dist-zilla-plugin-apachetest@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-ApacheTest

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
