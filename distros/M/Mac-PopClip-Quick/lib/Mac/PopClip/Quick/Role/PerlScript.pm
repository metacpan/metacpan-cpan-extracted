package Mac::PopClip::Quick::Role::PerlScript;
use Moo::Role;
use autodie;

our $VERSION = '1.000002';

requires '_add_files_to_zip', '_add_string_to_zip',
    '_plist_action_key_values';

=head1 NAME

Mac::PopClip::Quick::Role::PerlScript - create the modified perl script

=head1 SYNOPSIS

    package Mac::PopClip::Quick::Generator;
    use Moo;
    with 'Mac::PopClip::Quick::Role::PerlScript';
    ...

=head1 DESCRIPTION

Attributes that create the modified Perl Script

=cut

# TODO: This should probably be something other than declaring the method here
sub BUILD {
    my $self = shift;
    unless ( defined $self->{src}
        || defined $self->{src_filename}
        || defined $self->{filted_src} ) {
        die
            q!Neither 'src' nor 'src_filename' nor 'filtered_src' were passed!;
    }

    return;
}

around '_add_files_to_zip' => sub {
    my $orig = shift;
    my $self = shift;
    my $zip  = shift;

    $self->_add_string_to_zip(
        $zip, $self->filtered_src,
        'script.pl'
    );

    return $orig->( $self, $zip );
};

around '_plist_action_key_values' => sub {
    my $orig = shift;
    my $self = shift;
    return $orig->( $self, @_ ),
        'Shell Script File'  => 'script.pl',
        'Script Interpreter' => $self->script_interpreter;
};

=head2 src_filename

The filename containing a script that should be bundled into the extension and
executed when the extension is run.

=cut

has 'src_filename' => (
    is => 'ro',
);

=head2 src

The source of the script that should be bundled into the extension and executed
when the extension is run..  If not provided then C<src_filename> must be
provided and the source will be read from there.

=cut

has 'src' => (
    is => 'lazy',
);

sub _build_src {
    my $self = shift;
    local $/ = undef;
    open my $fh, '<:raw', $self->src_filename;
    return scalar(<$fh>);
}

=head2 filtered_src

The filtered source of the script.  If not provided then C<src> will be
processed to create this.

Essentially this is exactly the same as the original src, but altered so
that any attempt to use Mac::PopClip::Quick isn't executed (thus avoiding
a dependency on this module in the resulting extensions) and manually adding
the C<popclip_text> function definition to the source code.

=cut

has 'filtered_src' => (
    is => 'lazy',
);

sub _build_filtered_src {
    my $self = shift;

    my $src = $self->src;

    # prevent Mac::PopClip::Quick from loading in the script we're installing
    # and add the popclip_text() function manually
    my $prevent
        = q!BEGIN{$INC{'Mac/PopClip/Quick.pm'}=1}sub popclip_text(){$ENV{POPCLIP_TEXT}}!;
    $src =~ s{use\s+Mac::PopClip::Quick}{$prevent use Mac::PopClip::Quick};

    return $src;
}

=head2 script_interpreter

The program you want to use to execute your Perl script (it can be handy to set
this if you want to use a perl other than the system perl, e.g. a perl you
installed with perlbrew)

By default this is C</usr/bin/perl>, the system perl.

=cut

has 'script_interpreter' => (
    is => 'lazy',
);

sub _build_script_interpreter {
    return '/usr/bin/perl';
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
