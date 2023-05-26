package Exporter::Extensible::UnimportScopeGuard;
require Exporter::Extensible; # comtains implementation of UnimportScopeGuard

# ABSTRACT: Unimport set of symbols when object is destroyed

__END__

=pod

=encoding UTF-8

=head1 NAME

Exporter::Extensible::UnimportScopeGuard - Unimport set of symbols when object is destroyed

=head1 DESCRIPTION

This is an implementation detail of how Exporter::Extensible removes symbols at the
end of a scope.  The DESTROY method of this package performs the removal of the symbols.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
