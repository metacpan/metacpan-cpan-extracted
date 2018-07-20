package Dist::Zilla::Plugin::UseBuildPL;
$Dist::Zilla::Plugin::UseBuildPL::VERSION = '0.3';
use Moose;
with 'Dist::Zilla::Role::BuildPL';

sub setup_installer {}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::UseBuildPL - BYOB (Bring Your Own Build.PL)

=head1 DESCRIPTION

This plugin will just use the F<Build.PL> that I<you> have included.

=head1 BUGS

Please report any bugs or requests on L<GitHub issues|https://github.com/vlyon/Dist-Zilla-Plugin-UseBuildPL/issues>.

=head1 AUTHOR

Vernon Lyon E<lt>vlyon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Vernon Lyon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
