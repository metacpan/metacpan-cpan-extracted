package Mac::PopClip::Quick::Role::CoreAttributes;
use Moo::Role;
use autodie;

use File::Temp qw(tempfile);
use File::Spec::Functions qw(tmpdir);
use File::Basename qw(fileparse);
use Digest::MD5 qw(md5_hex);

our $VERSION = '1.000001';

requires '_plist_action_key_values', '_plist_main_key_values';

around '_plist_action_key_values' => sub {
    my $orig = shift;
    my $self = shift;
    return $orig->( $self, @_ ),
        'Title', $self->title,
};

around '_plist_main_key_values' => sub {
    my $orig = shift;
    my $self = shift;
    return $orig->( $self, @_ ),
        'Extension Identifier',      $self->extension_identifier,
        'Extension Name',            $self->extension_name,
        'Required Software Version', $self->required_software_version;
};

=head1 NAME

Mac::PopClip::Quick::Role::CoreAttributes - core attributes for generation

=head1 SYNOPSIS

    package Mac::PopClip::Quick::Generator;
    use Moo;
    with 'Mac::PopClip::Quick::Role::CoreAttributes';
    ...

=head1 DESCRIPTION

Core attributes for PopClip generation

=head1 ATTRIBUTES

=head2 extension_name

The name of the extension.  Required.

=cut

has 'extension_name' => (
    is       => 'ro',
    required => 1,
);

=head2 title

The title.

By default, the same as the C<extension_name>.

=cut

has 'title' => (
    is => 'lazy',
);

sub _build_title {
    my $self = shift;
    return $self->extension_name;
}

=head2 filename

The path to the the tarball that this module will create.  Should end with
C<.popclipextz> (though we don't force you to.)

By default a random filename in the temp directory is used if no value is
provided.

=cut

has 'filename' => (
    is => 'lazy',
);

sub _build_filename {
    my ( undef, $filename ) = tempfile(
        'X' x 15,
        SUFFIX => '.popclipextz',
        DIR    => tmpdir(),
        OPEN   => 0,
    );
    return $filename;
}

=head2 extension_identifier

A unique identifier for your extension.  This enables PopClip to identify
if an extension it's installing should install as a new extension or replace
an older version of the same extension.

By default this will generate something unique for you by using the unique ID of
your Mac and the extension name.  This is B<not> suitable for distribution (if
you change hardware you won't be able to use it anymore) and you should set a
value for this attribute before distributing your extension.

=cut

has 'extension_identifier' => (
    is => 'lazy',
);

sub _build_extension_identifier {
    my $self = shift;

    # get a UUID for this Mac OS X system
    ## no critic (InputOutput::ProhibitBacktickOperators)
    my ($id)
        = `ioreg -rd1 -c IOPlatformExpertDevice`
        =~ /"IOPlatformUUID" = "([^"]+)/
        or die
        'The ioreg way of automatically getting the unique ID for a machine has stopped working';
    ## use critic

    # append the extension name then make it into a
    my $hash = md5_hex( $id . $self->extension_name );

    # return in reverse dotted notation
    return "com.macnperl.macpopquickthirdparty.hash$hash";
}

=head2 required_software_version

The required version of PopClip.  By default this is 701.

=cut

has 'required_software_version' => (
    is => 'lazy',
);

sub _build_required_software_version {
    return 701;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Fowler.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<Mac::PopClip::Quick> is the main public interface to this module.

This role is consumed by L<Mac::PopClip::Quick::Generator>.

