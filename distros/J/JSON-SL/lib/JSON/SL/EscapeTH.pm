package JSON::SL::EscapeTH;
use strict;
use warnings;

sub TIEHASH {
    my ($cls,$o) = @_;
    my $self = bless { pjsn => $o }, $cls;
    return $self;    
}

sub STORE {
    my $self = $_[0];
    $self->{pjsn}->_escape_table_chr(ord($_[1]), $_[2]);    
}

sub FETCH {
    my $self = $_[0];
    my $c = $_[1];
    # always unescape RFC 4627-mandated escaped characters
    $self->{pjsn}->_escape_table_chr(ord($_[1]));
}

sub EXISTS {
    goto &FETCH;
}

sub DELETE {
    $_[2] = 0;
    goto &STORE;
}

sub FIRSTKEY {
    my $self = $_[0];
    $self->{idx} = -1;
    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = $_[0];
    return if ++$self->{idx} > 0x7f;
    chr($self->{idx});
}

sub SCALAR {
    '127/127';
}

sub CLEAR {
    my $self = $_[0];
    $self->{pjsn}->_escape_table_chr($_, 0) foreach (0..0x7f);
}

1;

__END__

=head3 unescape_settings()

=head3 unescape_settings($character)

=head3 unescape_settings($character, $boolean)

Inspects and modifies the preferences for unescaping JSON strings. JSON allows
several forms of escape sequences, either via the C<\uXXXX> form, or via a two-
character 'common' form for specific characters.

=head4 DEFAULT UNESCAPING BEHAVIOR

For C<\uXXXX> escapes, the single or multi-byte representation of the encoded
character is placed into the resultant string, thus:

    \u0041 becomes A

For JSON structural tokens, the backslash is swallowed and the character following
it is left as-is. JSON I<requires> that these characters be escaped.

    \"     becomes "
    \\     becomes \
    

Additionally, JSON allows the C</> character to be escaped (though it is not
a JSON structural token, and does not require escaping).

    \/     becomes /
    
For certain allowable control and whitespace characters, the escape is translated
into its corresponding ASCII value, thus:

    \n    becomes chr(0x0A) <LF>
    \r    becomes chr(0x0D) <CR>
    \t    becomes chr(0x09) <TAB>
    \b    becomes chr(0x08) <Backspace>
    \f    becomes chr(0x0C) <Form Feed>

Any other two-character escape sequence is not allowed, and JSON::SL will croak
upon encountering it.

By default, all that is allowed to be escaped is also automatically unescaped,
but this behavior is configurable via the C<unescape_settings>

Called without any arguments, C<unescape_settings> returns a reference to a hash.
Its keys are valid ASCII characters and its values are booleans
indicating whether C<JSON::SL> should treat them specially if they follow a C<\>.

Thus, to disable special handling for newlines and tabs:
    
    delete @{$json->unescape_settings}{"\t","\n","\r"};


If C<unescape_settings> is called with one or two arguments, the first argument
is taken as the character, and the second argument (if present) is taken as a
boolean value which the character should be set to:

Check if forward-slashes are unescaped:

    my $fwslash_is_unescaped = $json->unescape_settings("/");


Disable handling for C<\uXXXX> sequences:

    $json->unescape_settings("u", 0);
