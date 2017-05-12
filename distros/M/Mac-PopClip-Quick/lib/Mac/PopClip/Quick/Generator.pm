package Mac::PopClip::Quick::Generator;

use Moo;

our $VERSION = '1.000001';

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

with
    'Mac::PopClip::Quick::Role::WritePlist',
    'Mac::PopClip::Quick::Role::CoreAttributes',
    'Mac::PopClip::Quick::Role::PerlScript',
    'Mac::PopClip::Quick::Role::BeforeAfter',
    'Mac::PopClip::Quick::Role::Regex',
    'Mac::PopClip::Quick::Role::Apps';

=head1 NAME

Mac::PopClip::Quick::Generator - quickly generate PopClip extensions in Perl

=for test_synopsis my $script_src = 'dummy';

=head1 SYNOPSIS

   use Mac::PopClip::Quick::Generator;
   my $g = Mac::PopClip::Quick::Generator->new(
      extension_name => 'delete',
      src => $script_src,
   );

=head1 DESCRIPTION

This is a module that can create PopClip extensions in Perl.  Users aren't
expected to use this module directly, but instead use the interface provided
by the L<Mac::PopClip::Quick> module.

Internally it's a simple L<Moo> class that loads a bunch of roles that actually
provide the functionality to add files and create the l

=head1 METHODS

=head2 $class->new

Standard constructor.  Requires a bunch of stuff.

=head2 $generator->create

Create the file containing the PopClip extension.

=cut

# this method should be extended with "around" by the various roles
# it's passed the zip file as it's only argument
sub _add_files_to_zip {
    return;
}

# this is designed to be called from the 'around' wrappers that
# the various roles wrap _add_files_to_zip
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _add_string_to_zip {
    my $self     = shift;
    my $zip      = shift;
    my $string   = shift;
    my $filename = shift;

    my $new_file = $zip->addString( $string, $filename );
    $new_file->desiredCompressionMethod(COMPRESSION_DEFLATED);

    return;
}
## use critic

sub create {
    my $self = shift;

    my $zip = Archive::Zip->new;
    $self->_add_files_to_zip($zip);

    unless ( $zip->writeToFileNamed( $self->filename ) == AZ_OK ) {
        die 'Cannot create zipfile containing extension';
    }

    return;
}

=head2 $generator->install

Install the module (requires PopClip to be installed)

WARNING: This leaves the temp file that this creates in the temp directory.

=cut

sub install {
    my $self = shift;
    system( 'open', $self->filename ) == 0
        or die "Can't execute 'open' in order to install extension: $!";
    return;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Fowler.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

This module consumes the following roles:

=over

=item L<Mac::PopClip::Quick::Role::WritePlist>

=item L<Mac::PopClip::Quick::Role::CoreAttributes>

=item L<Mac::PopClip::Quick::Role::PerlScript>

=item L<Mac::PopClip::Quick::Role::BeforeAfter>

=item L<Mac::PopClip::Quick::Role::Regex>

=back

This module is used by the main module, L<Mac::PopClip::Quick>.

