package LibTmux::Schema;
use v5.44;
use JSON::PP       ();
use File::Basename qw(dirname);
use Scalar::Util   qw(blessed reftype);
use Encode         qw(encode decode FB_CROAK LEAVE_SRC);
use LibTmux::X;
my ($catalog, %adapters);

sub catalog ($class) {
    unless ($catalog) {
        open my $in, '<:raw', dirname(__FILE__) . '/schema.json'
            or die "Read schema: $!";
        local $/;
        $catalog = JSON::PP->new->utf8->decode(<$in>);
    }
    return $catalog;
}

sub _version_at_least ($class, $version, $minimum) {
    my @got  = $version =~ /(\d+)\.(\d+)([a-z]?)/;
    my @want = $minimum =~ /(\d+)\.(\d+)([a-z]?)/;
    return false unless @got == 3 && @want == 3;
    return $got[0] > $want[0] if $got[0] != $want[0];
    return $got[1] > $want[1] if $got[1] != $want[1];
    return $got[2] ge $want[2];
}

sub entity ($class, $kind) {
    LibTmux::X::InvalidFilter->throw(
        message => 'entity kind must be a defined string')
        unless defined($kind) && !ref($kind);
    my $spec = $class->catalog->{entities}{$kind};
    LibTmux::X::InvalidFilter->throw(
        message => 'unknown entity',
        entity  => $kind
    ) unless $spec;
    return $spec;
}
sub field ($class, $kind, $field) { $class->entity($kind)->{fields}{$field} }

sub class_for ($class, $kind) {
    'LibTmux::' . join('', map { ucfirst } split /_/, $kind);
}
sub selection_for ($class, $kind) { $class->class_for($kind) . 'Selection' }

sub type_name ($class, $value) {
    defined($value) ? blessed($value) // reftype($value) // 'scalar' : 'undef';
}

sub invalid ($class, $path, $expected, $value, $type = 'InvalidFilter') {
    my $error = "LibTmux::X::$type";
    $error->throw(
        path   => $path,
        entity => do {
            my ($kind) = split /\./, $path;
            exists($class->catalog->{entities}{$kind}) ? $kind : undef;
        },
        expected => $expected,
        received => $class->type_name($value),
        message  => "expected $expected"
    );
}

sub normalize ($class, $field, $value, $path, $error = 'InvalidFilter') {
    if (!defined $value) {
        return undef if $field->{nullable};
        $class->invalid($path, 'defined ' . $field->{type}, $value, $error);
    }
    $class->invalid($path, $field->{type}, $value, $error) if ref $value;
    my $type = $field->{type};
    if ($type eq 'integer') {
        my $text = "$value";
        $class->invalid($path, 'safe decimal integer', $value, $error)
            unless $text =~ /\A[+-]?[0-9]+\z/;
        my $negative = $text =~ s/^-//;
        $text =~ s/^\+//;
        $text =~ s/^0+(?=[0-9])//;
        $class->invalid($path, 'integer within +/-9007199254740991',
            $value, $error)
            if length($text) > 16
            || (length($text) == 16 && $text gt '9007199254740991');
        return 0 + ($negative ? "-$text" : $text);
    }
    if ($type eq 'boolean') {
        $class->invalid($path, 'Boolean or 0/1', $value, $error)
            unless JSON::PP::is_bool($value)
            || "$value" eq '0'
            || "$value" eq '1';
        return $value ? true : false;
    }
    my $text = "$value";
    if ($type eq 'bytes') {
        return utf8::is_utf8($text)
            ? encode('UTF-8', $text, FB_CROAK | LEAVE_SRC)
            : $text;
    }
    if (!utf8::is_utf8($text)) {
        try { $text = decode('UTF-8', $text, FB_CROAK | LEAVE_SRC) }
        catch ($e) {
            $class->invalid($path, 'valid UTF-8 text', $value, $error)
        }
    }
    return $text;
}

sub wire_scalar ($class, $field, $value, $path) {
    return $value unless defined $value && $field->{type} eq 'bytes';
    my $text;
    try { $text = decode('UTF-8', $value, FB_CROAK | LEAVE_SRC) }
    catch ($e) {
        LibTmux::X::UnsupportedValue->throw(
            path    => $path,
            message =>
'non-UTF-8 octets have no string representation in libtmux.where/v1'
        )
    }
    return $text;
}

sub register_adapter ($class, %args) {
    $class->entity($args{entity});
    $class->invalid('adapter.class', 'class name', $args{class})
        unless defined $args{class}
        && $args{class} =~ /\A[A-Za-z_][A-Za-z0-9_:]*\z/;
    $class->invalid('adapter.readers', 'unblessed hash reference',
        $args{readers})
        unless ref($args{readers}) eq 'HASH';
    for my $field (keys $args{readers}->%*) {
        $class->invalid(
            "adapter.$field",
            'registered field reader',
            $args{readers}{$field}
            )
            unless $class->field($args{entity}, $field)
            && ref($args{readers}{$field}) eq 'CODE';
    }
    $adapters{$args{class}} =
        {entity => $args{entity}, readers => {%{$args{readers}}}};
}

sub assert_record ($class, $kind, $record, $path) {
    if (blessed($record) && $record->isa('LibTmux::Entity')) {
        $class->invalid($path, "$kind entity", $record)
            unless $record->kind eq $kind;
        return;
    }
    return if ref($record) eq 'HASH';
    my $adapter = blessed($record) ? $adapters{ref $record} : undef;
    return if $adapter && $adapter->{entity} eq $kind;
    $class->invalid($path, "$kind record or registered adapter", $record);
}

sub read ($class, $kind, $record, $field, $path) {
    $class->assert_record($kind, $record, $path);
    my $spec = $class->field($kind, $field);
    return $record->_read($field)
        if blessed($record) && $record->isa('LibTmux::Entity');
    my $value;
    if (ref($record) eq 'HASH') {
        LibTmux::X::Unloaded->throw(
            path    => $path,
            entity  => $kind,
            message => 'field or relation was not loaded'
        ) unless exists $record->{$field};
        $value = $record->{$field};
    }
    else {
        my $reader = $adapters{ref $record}{readers}{$field};
        LibTmux::X::Unloaded->throw(
            path    => $path,
            entity  => $kind,
            message => 'adapter has no reader for field'
        ) unless $reader;
        $value = $reader->($record);
    }
    return $value if $spec->{type} eq 'relation';
    return $class->normalize($spec, $value, $path, 'Unloaded');
}

=head1 NAME

LibTmux::Schema - Catalog and explicit record adapters

=head1 METHODS

=head2 register_adapter

C<register_adapter(class =E<gt> ..., entity =E<gt> ..., readers =E<gt> {...})>
registers trusted callbacks for declared fields. Unknown criteria keys never
become method names. Missing fields throw; nullable undef is known null.

=cut
