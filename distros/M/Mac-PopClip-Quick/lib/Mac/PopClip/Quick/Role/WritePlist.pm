package Mac::PopClip::Quick::Role::WritePlist;
use Moo::Role;

requires '_add_files_to_zip', '_add_string_to_zip';

our $VERSION = '1.000002';

around '_add_files_to_zip' => sub {
    my $orig = shift;
    my $self = shift;
    my $zip  = shift;

    $self->_add_string_to_zip(
        $zip, $self->plist_xml,
        'Config.plist'
    );

    return $orig->( $self, $zip );
};

# other roles will wrap these two methods with "around" to
# add things that they want to shove in the plist

sub _plist_main_key_values {
    return ();
}

sub _plist_action_key_values {
    return ();
}

=head1 NAME

Mac::PopClip::Quick::Role::WritePlist - write the plist

=head1 SYNOPSIS

    package Mac::PopClip::Quick::Generator;
    use Moo;
    with 'Mac::PopClip::Quick::Role::WritePlist';
    ...

=head1 DESCRIPTION

Add the ability to write the plist

=head1 ATTRIBUTES

=head2 plist_xml

A string containing the XML for the plist.

By default this is constructed from all the other attributes.

=cut

has 'plist_xml' => (
    is => 'lazy',
);

sub _escape_xml {
    my $string = shift;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    return $string;
}

sub _plist_array {
    my $indent = shift;
    return "$indent<array>\n" . (
        join q{},
        map { _plist_string( "$indent    ", $_ ) . "\n" } @_
    ) . "$indent</array>";
}

sub _plist_string {
    my $indent = shift;
    my $value  = shift;
    return "$indent<string>@{[ _escape_xml($value) ]}</string>";
}

sub _plist_integer {
    my $indent = shift;
    my $value  = shift;
    return "$indent<integer>@{[ _escape_xml($value) ]}</integer>";
}

# turn this into a key/value string.  Right now this only handles strings
# integers (which must be passed as references to a scalar) and array of strings
# (since that's all PopClip plist currently uses)
sub _plist_thingy {
    my $key    = shift;
    my $value  = shift;
    my $indent = shift;

    return "$indent<key>@{[ _escape_xml($key) ]}</key>\n"
        . (
          ( ref($value) eq 'ARRAY' ) ? _plist_array( $indent, @{$value} )
        : ( ref($value) eq 'SCALAR' ) ? _plist_integer( $indent, ${$value} )
        :                               _plist_string( $indent, $value )
        );
}

sub _build_plist_xml {
    my $self = shift;

    my %main   = $self->_plist_main_key_values;
    my %action = $self->_plist_action_key_values;

    return <<"XML"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Actions</key>
    <array>
      <dict>
@{[ join "\n\n", map { _plist_thingy( $_, $action{ $_ }, '        ') } sort keys %action ]}
      </dict>
    </array>

@{[ join "\n\n", map { _plist_thingy( $_, $main{ $_ }, '    ') } sort keys %main ]}
    </dict>
  </plist>
XML
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
