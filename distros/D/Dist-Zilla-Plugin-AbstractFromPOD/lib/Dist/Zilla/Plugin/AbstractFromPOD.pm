package Dist::Zilla::Plugin::AbstractFromPOD;

use 5.008;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Moose;
use English                 qw( -no_match_vars );
use File::Spec::Functions   qw( catfile );

with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
   my $self  = shift;
   my $name  = $self->zilla->name;
   my $class = $name; $class =~ s{ [\-] }{::}gmx;
   my $file  = $self->zilla->_main_module_override
            || catfile( 'lib', split m{ [\-] }mx, "${name}.pm" );

                     $file or die 'No main module specified';
                  -f $file or die "Path ${file} does not exist or not a file";
   open my $fh, '<', $file or die "File ${file} cannot open: ${OS_ERROR}";

   my $content    = do { local $RS; <$fh> }; $fh->close;
   my ($abstract) = $content
      =~ m{ =head1 \s+ Name \s* [\n] \s* $class \s* [\-] \s* ([^\n]+) }imsx;

   $abstract or die "File ${file} contains no abstract";
   $self->zilla->abstract( $abstract );
   return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=encoding utf8

=begin html

<a href="http://badge.fury.io/pl/Dist-Zilla-Plugin-AbstractFromPOD"><img src="https://badge.fury.io/pl/Dist-Zilla-Plugin-AbstractFromPOD.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-AbstractFromPOD"><img src="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-AbstractFromPOD.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Dist::Zilla::Plugin::AbstractFromPOD - Case insensitive head1 POD matching for the Name attribute

=head1 Synopsis

   # In dist.ini
   [AbstractFromPOD]

=head1 Version

This documents version v0.3.$Rev: 1 $ of L<Dist::Zilla::Plugin::AbstractFromPOD>

=head1 Description

Case insensitive head1 POD matching for the Name attribute

L<Dist::Zilla> should do this by default but unfortunately it's pattern
matching is case sensitive so this instead

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 before_build

Read the main module and extract the abstract (case insensitive matching on
the head1 Name POD directive)

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Dist::Zilla::Role::BeforeBuild>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-AbstractFromPOD.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2015 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
