package JSON5::Parser;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use JSON::PP;
use Encode;

our $ROOT;
our $POINTER;

sub new {
    my $class = shift;
    return bless +{
        utf8             => 0,
        allow_nonref     => 0,
        max_size         => 0,
        inflate_boolean  => sub { $_[0] eq 'true' ? JSON::PP::true : JSON::PP::false },
        inflate_nan      => sub { 0+'NaN' },
        inflate_null     => sub { undef },
        inflate_infinity => sub { $_[0] eq '+' ? 0+'Inf' : 0+'-Inf' },
    } => $class;
}

# define accessors
BEGIN {
    # boolean accessors
    for my $attr (qw/utf8 allow_nonref/) {
        my $attr_accessor = sub {
            my $self = shift;
            $self->{$attr} = @_ ? shift : 1;
            return $self;
        };
        my $attr_getter = sub {
            my $self = shift;
            return $self->{$attr};
        };

        no strict qw/refs/;
        *{"$attr"}     = $attr_accessor;
        *{"get_$attr"} = $attr_getter;
    }

    # value accessors
    for my $attr (qw/max_size inflate_boolean inflate_nan inflate_null inflate_infinity/) {
        my $attr_accessor = sub {
            my $self = shift;
            $self->{$attr} = shift if @_;
            return $self;
        };
        my $attr_getter = sub {
            my $self = shift;
            return $self->{$attr};
        };

        no strict qw/refs/;
        *{"$attr"}     = $attr_accessor;
        *{"get_$attr"} = $attr_getter;
    }
}

sub parse {
    my ($self, $content) = @_;
    if (my $max_size = $self->{max_size}) {
        use bytes;
        my $bytes = length $content;
        $bytes <= $max_size
            or croak sprintf 'attempted decode of JSON5 text of %s bytes size, but max_size is set to %s', $bytes, $max_size;
    }
    if ($self->{utf8}) {
        $content = Encode::decode_utf8($content);
    }

    # normalize linefeed
    $content =~ s!\r\n?!\n!mg;

    local $ROOT;
    local $POINTER = \$ROOT;

    $self->_parse() for $content;

    return $ROOT;
}

sub _parse {
    my $self = shift;

    $self->_parse_value();
    return if m!\G(?:\s*|//.*$|/\*.*?\*/)*\z!msgc;
    $self->_error('Syntax Error');
}

sub _skip_whitespace { /\G\s*/msgc }
sub _skip_comments { m!\G//.*$!mgc || m!\G/\*.*?\*/!msgc }

sub _parse_value {
    my $self = shift;

    # skip
    1 while $self->_skip_whitespace() || $self->_skip_comments();

    my $allow_nonref = $self->{allow_nonref} || $POINTER != \$ROOT;

    if ($self->_parse_object_or_array()) {
        return 1;
    }
    elsif ($allow_nonref) {
        if ($self->_parse_number()) {
            return 1;
        }
        elsif ($self->_parse_boolean()) {
            return 1;
        }
        elsif ($self->_parse_string()) {
            return 1;
        }
        elsif (/\Gnull/mgc) {
            ${$POINTER} = $self->{inflate_null}->();
            return 1;
        }
    }

    return;
}

sub _parse_object_or_array {
    my $self = shift;

    if (/\G\{/mgc) {
        local $POINTER = ${$POINTER} = {};
        return $self->_parse_object_kv();
    }
    elsif (/\G\[/mgc) {
        local $POINTER = ${$POINTER} = [];
        return $self->_parse_array_value();
    }

    return;
}

sub _parse_object_kv {
    my $self = shift;

    # skip
    1 while $self->_skip_whitespace() || $self->_skip_comments();

    # is last?
    if (/\G\}/mgc) {
        return 1;
    }

    # parse key
    my $key; {
        local $POINTER = \$key;
        if (!$self->_parse_string() && !$self->_parse_identifier()) {
            return;
        }
    }

    # skip
    1 while $self->_skip_whitespace() || $self->_skip_comments();

    # parse object key sep
    unless (/\G\:/mgc) {
        return;
    }

    # parse value
    my $value; {
        local $POINTER = \$value;
        if (!$self->_parse_value()) {
            return;
        }
    }

    # set value
    my $hash = $POINTER;
    $hash->{$key} = $value;

    # skip
    1 while $self->_skip_whitespace() || $self->_skip_comments();

    # is last?
    if (/\G\}/mgc) {
        return 1;
    }
    elsif (/\G,/mgc) {
        return $self->_parse_object_kv;
    }

    return;
}

sub _parse_array_value {
    my $self = shift;

    # skip
    1 while $self->_skip_whitespace() || $self->_skip_comments();

    # is last?
    if (/\G\]/mgc) {
        return 1;
    }

    # parse value
    my $value; {
        local $POINTER = \$value;
        if (!$self->_parse_value()) {
            return;
        }
    }

    # set value
    my $array = $POINTER;
    push @$array => $value;

    # skip
    1 while $self->_skip_whitespace() || $self->_skip_comments();

    # is last?
    if (/\G\]/mgc) {
        return 1;
    }
    elsif (/\G,/mgc) {
        return $self->_parse_array_value;
    }

    return;
}

sub _parse_number {
    my $self = shift;

    if (/\G([-+])?Infinity/mgc) {
        my $number = $self->{inflate_infinity}->($1 || '+');
        ${$POINTER} = $number;
        return 1;
    }
    elsif (/\GNaN/mgc) {
        my $number = $self->{inflate_nan}->();
        ${$POINTER} = $number;
        return 1;
    }
    elsif (/\G([-+]?)0x([0-9a-f]+)/imgc) {
        my $number = hex $2;
        $number *= -1 if $1 && $1 eq '-';
        ${$POINTER} = $number;
        return 1;
    }
    elsif (/\G([-+]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+))(?:e([-+]?[0-9]+))?/mgc) {
        my $number = 0+$1;
        $number *= 10 ** $2 if defined $2;
        ${$POINTER} = $number;
        return 1;
    }

    return;
}

sub _parse_boolean {
    my $self = shift;

    if (/\G(true|false)/mgc) {
        my $bool = $self->{inflate_boolean}->($1);
        ${$POINTER} = $bool;
        return 1;
    }

    return;
}

sub _parse_string {
    my $self = shift;

    if (/\G(?:"((?:.|(?<=\\)\n)*?)(?<!(?<!\\)\\)"|\'((?:.|(?<=\\)\n)*?)(?<!(?<!\\)\\)\')/mgc) {
        my $str = join '', grep defined, $1, $2;

        # ignore escaped linefeed
        $str =~ s!\\\n!!xmg;

        # de-escape
        $str =~ s!\\b !\x08!xmg;      # backspace       (U+0008)
        $str =~ s!\\t !\x09!xmg;      # tab             (U+0009)
        $str =~ s!\\n !\x0A!xmg;      # linefeed        (U+000A)
        $str =~ s!\\f !\x0C!xmg;      # form feed       (U+000C)
        $str =~ s!\\r !\x0D!xmg;      # carriage return (U+000D)
        $str =~ s!\\" !\x22!xmg;      # quote           (U+0022)
        $str =~ s!\\' !\x27!xmg;      # single-quote    (U+0027)
        $str =~ s!\\/ !\x2F!xmg;      # slash           (U+002F)
        $str =~ s!\\\\!\x5C!xmg;      # backslash       (U+005C)
        $str =~ s{\\u([0-9A-Fa-f]{4})}{# unicode         (U+XXXX)
            chr hex $1
        }xmge;
        $str =~ s{\\U([0-9A-Fa-f]{8})}{# unicode         (U+XXXXXXXX)
            chr hex $1
        }xmge;

        ${$POINTER} = $str;
        return 1;
    }

    return;
}

sub _parse_identifier {
    my $self = shift;

    if (/\G([a-z_\$][0-9a-z_\$]*)/imgc) {
        my $identifier = $1;
        ${$POINTER} = $identifier;
        return 1;
    }

    return;
}

sub _error {
    my ($self, $msg) = @_;

    my $src   = $_;
    my $line  = 1;
    my $start = pos $src || 0;
    while ($src =~ /$/smgco and pos $src <= pos) {
        $start = pos $src;
        $line++;
    }
    my $end = pos $src;
    my $len = pos() - $start;
    $len-- if $len > 0;

    my $trace = join "\n",
        "${msg}: line:$line",
        substr($src, $start || 0, $end - $start),
        (' ' x $len) . '^';
    die $trace, "\n";
}

1;
__END__
