package Dist::Zilla::Plugin::ApacheTest;
$Dist::Zilla::Plugin::ApacheTest::VERSION = '0.04';
# ABSTRACT: DEPRECATED ApacheTest Compatibility Module.

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::ApacheTest';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::ApacheTest - DEPRECATED ApacheTest Compatibility Module.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

B<DEPRECATED>.  Use L<@ApacheTest> instead.

=head1 DESCRIPTION

This plugin exists for compatibility reasons with previouis versions of this
module.  You whould switch to the L<@ApacheTest> bundle instead.  This module
simply uses the
L<MakeMaker::ApacheTest|Dist::Zilla::Plugin::MakeMaker::ApacheTest> plugin.

=head1 SEE ALSO

L<@ApacheTest|Dist::Zilla::PluginBundle::ApacheTest>

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/dist-zilla-plugin-apachetest>
and may be cloned from L<git://github.com/mschout/dist-zilla-plugin-apachetest.git>

=head1 BUGS

Please report any bugs or feature requests to bug-dist-zilla-plugin-apachetest@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-ApacheTest

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
