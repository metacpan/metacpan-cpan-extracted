package JSONSchema::Validator::Util;

# ABSTRACT: Useful functions

use strict;
use warnings;

use URI 1.00;
use File::Basename;
use B;
use Carp 'croak';

use Scalar::Util 'looks_like_number';

our @ISA = 'Exporter';
our @EXPORT_OK = qw(
    json_encode json_decode user_agent_get serialize unbool
    round read_file is_type detect_type get_resource decode_content
    data_section
);

use constant FILE_SUFFIX_TO_MIME_TYPE => {
    'yaml' => 'text/vnd.yaml',
    'yml' => 'text/vnd.yaml',
    'json' => 'application/json'
};

use constant TYPE_MAP => {
    'array' => \&is_array,
    'boolean' => \&is_bool,
    'integer' => \&is_integer,
    'number' => \&is_number,
    'object' => \&is_object,
    'null' => \&is_null, # for OAS30 null is not defined
    'string' => \&is_string,

    # it is for some buggy code
    '_ref' => \&is_ref
};

# such order is required
use constant TYPE_LIST => ['array', 'object', 'null', '_ref', 'integer', 'number', 'boolean', 'string'];

BEGIN {
    # YAML
    if (eval { require YAML::XS; YAML::XS->VERSION(0.67); 1; }) {
        *yaml_load = sub { local $YAML::XS::Boolean = 'JSON::PP'; YAML::XS::Load(@_) };
    }
    elsif (eval { require YAML::PP; 1; }) {
        my $pp = YAML::PP->new(boolean => 'JSON::PP');
        *yaml_load = sub { $pp->load_string(@_) };
    } else {
        *yaml_load = sub { croak 'No YAML package installed' };
    }

    # JSON
    my $json_class;
    if (eval { require Cpanel::JSON::XS; 1; }) {
        $json_class = 'Cpanel::JSON::XS';
    } elsif (eval { require JSON::XS; JSON::XS->VERSION(3.0); 1; }) {
        $json_class = 'JSON::XS';
    } else {
        require JSON::PP;
        $json_class = 'JSON::PP';
    }
    my $json = $json_class->new->canonical(1)->utf8;
    *json_encode = sub { $json->encode(@_); };
    *json_decode = sub { $json->decode(@_); };

    # UserAgent
    if (eval { require LWP::UserAgent; 1; }) {
        my $ua = LWP::UserAgent->new;
        *user_agent_get = sub {
            my $uri = shift;
            my $response = $ua->get($uri);
            if ($response->is_success) {
                return $response->decoded_content, $response->headers->content_type;
            }
            croak "Can not get uri $uri";
        };
    } elsif (eval { require Mojo::UserAgent; 1; }) {
        my $ua = Mojo::UserAgent->new;
        *user_agent_get = sub {
            my $uri = shift;
            my $response = $ua->get($uri)->result;
            if ($response->is_success) {
                return $response->body, $response->headers->content_type;
            }
            croak "Can not get uri $uri";
        };
    } else {
        *user_agent_get = sub { croak 'No UserAgent package installed' };
    }
}

sub unbool {
    my $x = shift;
    return "$x" if ref $x eq 'JSON::PP::Boolean';
    return $x if ref $x;
    return '1' if $x && $x eq '1';
    return '0' if !defined $x || $x eq '0' || $x eq '';
    return $x;
}

sub serialize { json_encode(shift) }

sub round {
    my $value = shift;
    return int($value + ($value >= 0 ? 0.5 : -0.5));
}

# scheme_handlers - map[scheme -> handler]
# uri - string
sub get_resource {
    my ($scheme_handlers, $uri) = @_;
    $uri = URI->new($uri);

    for my $s ('http', 'https') {
        $scheme_handlers->{$s} = \&user_agent_get unless exists $scheme_handlers->{$s};
    }

    my $scheme = $uri->scheme;

    my ($response, $mime_type);
    if (exists $scheme_handlers->{$scheme}) {
        ($response, $mime_type) = $scheme_handlers->{$scheme}->($uri->as_string);
    } elsif ($scheme eq 'file') {
        ($response, $mime_type) = read_file($uri->file);
    } else {
        croak 'Unsupported scheme of uri ' . $uri->as_string;
    }
    return ($response, $mime_type);
}

sub decode_content {
    my ($response, $mime_type, $resource) = @_;

    my $schema;
    if ($mime_type) {
        $schema = yaml_load($response) if $mime_type =~ m/yaml/;
        $schema = json_decode($response) if $mime_type =~ m/json/;
    }
    unless ($schema) {
        # try to guess
        $schema = eval { json_decode($response) };
        $schema = eval { yaml_load($response) } if $@;
        croak "Unsupported mime type $mime_type of resource " . $resource unless $schema;
    }

    return $schema;
}

sub read_file {
    my $path = shift;
    croak "File $path does not exists" unless -e $path;
    croak "File $path does not have read permission" unless -r _;
    my $size = -s _;

    my ($filename, $dir, $suffix) = File::Basename::fileparse($path, 'yml', 'yaml', 'json');
    croak "Unknown file format of $path" unless $suffix;

    my $mime_type = FILE_SUFFIX_TO_MIME_TYPE->{$suffix};

    open my $fh, '<', $path or croak "Open file $path error: $!";
    read $fh, (my $file_content), $size;
    close $fh;

    return $file_content, $mime_type;
}

# params: $value, $type, $is_strict
sub is_type {
    return 0 unless exists TYPE_MAP->{$_[1]};
    return TYPE_MAP->{$_[1]}->($_[0], $_[2]);
}

# params: $value, $is_strict
sub detect_type {
    for my $type (@{TYPE_LIST()}) {
        return $type if TYPE_MAP->{$type}->(@_);
    }
    # it must be unreachable code
    croak 'Unknown type detected';
}

# params: $value, $is_strict
sub is_array {
    return ref $_[0] eq 'ARRAY';
}

# params: $value, $is_strict
sub is_bool {
    return 1 if ref $_[0] eq 'JSON::PP::Boolean';
    return 0 if $_[1]; # is strict
    my $is_number = looks_like_number($_[0]) && ($_[0] == 1 || $_[0] == 0);
    my $is_string = defined $_[0] && $_[0] eq '';
    my $is_undef = !defined $_[0];
    return 1 if $is_number || $is_string || $is_undef;
    return 0;
}

# params: $value, $is_strict
sub is_integer {
    return 1 if B::svref_2object(\$_[0])->FLAGS & B::SVf_IOK();
    return 0 if $_[1]; # is strict
    return 0 if ref $_[0];
    return 1 if looks_like_number($_[0]) && int($_[0]) == $_[0];
    return 0;
}

# params: $value, $is_strict
sub is_number {
    return 1 if B::svref_2object(\$_[0])->FLAGS & (B::SVf_IOK() | B::SVf_NOK());
    return 0 if $_[1]; # is strict
    return 0 if ref $_[0];
    return 1 if looks_like_number($_[0]);
    return 0;
}

# params: $value, $is_strict
sub is_ref {
    my $ref = ref $_[0];
    return 0 unless $ref;
    return 0 if $ref eq 'JSON::PP::Boolean' ||
                $ref eq 'HASH' ||
                $ref eq 'ARRAY';
    return 1;
}

# params: $value, $is_strict
sub is_object {
    return ref $_[0] eq 'HASH';
}

# params: $value, $is_strict
sub is_null {
    return !(defined $_[0]);
}

# params: $value, $is_strict
sub is_string {
    return !(ref $_[0]) && !is_number(@_) && defined $_[0] if $_[1]; # is strict
    return !(ref $_[0]) && defined $_[0];
}

sub data_section {
    my $class = shift;
    my $handle = do { no strict 'refs'; \*{"${class}::DATA"} };
    return unless fileno $handle;
    seek $handle, 0, 0;
    local $/ = undef;
    my $data = <$handle>;
    $data =~ s/^.*\n__DATA__\r?\n//s;
    $data =~ s/\r?\n__END__\r?\n.*$//s;
    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Util - Useful functions

=head1 VERSION

version 0.006

=head1 AUTHORS

=over 4

=item *

Alexey Stavrov <logioniz@ya.ru>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

Anton Fedotov <tosha.fedotov.2000@gmail.com>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Andrey Khozov <andrey@rydlab.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
