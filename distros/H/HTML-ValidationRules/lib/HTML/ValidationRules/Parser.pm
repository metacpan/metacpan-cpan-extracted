package HTML::ValidationRules::Parser;
use strict;
use warnings;
use autodie;
use HTML::Parser;

my %ELEMENTS = (
    input => [qw(
        max
        maxlength
        min
        pattern
        required
    ), {
        name   => 'type',
        values => [qw(
            url
            email
            number
            range
        )],
    }],

    textarea => [qw(
        maxlength
        required
    )],

    select => [qw(
        required
    )],
);

my $ELEMENTS_PATTERN = qr/(@{[join '|', (map { quotemeta } keys %ELEMENTS)]})/o;
my %ATTRS_MAP = map {
    my $attr = ref $_ ? $_->{name} : $_;
       $attr => +{ map { $_ => 1 } @{$ELEMENTS{$_}} };
} keys %ELEMENTS;
my %TYPE_ATTR_MAP = map {
    my $attr = $_;
    map { $_ => 1 } @{$attr->{values}};
} grep { ref $_ && $_->{name} eq 'type' } @{$ELEMENTS{input}};

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub parser {
    my ($self) = @_;
    $self->{parser} ||= HTML::Parser->new(
        api_version => 3,
        start_h     => [\&start, 'self, tagname, attr, attrseq'],
        %{$self->{options} || {}},
    );
}

sub load_rules {
    my ($self, %args) = @_;
    my $file = delete $args{file};
    my $html = delete $args{html};

    undef $self->parser->{rules};

    if ($file) {
        $self->parser->parse_file($file);
    }
    else {
        $self->parser->parse($html);
        $self->parser->eof;
    }

    $self->parser->{rules};
}

sub start {
    my ($parser, $tag, $attr, $attrseq) = @_;
    return if $tag !~ $ELEMENTS_PATTERN;

    my $name = $attr->{name};
    return if !defined $name;

    my @rules;
    my $attrs = $ATTRS_MAP{lc $tag};

    if (defined $attr->{type} && $TYPE_ATTR_MAP{lc $attr->{type} || ''}) {
        my $type = $attr->{type};
        unshift @rules, key($type);
        $attrseq = [ grep { lc $_ ne 'type' } @$attrseq ];
    }

    for my $key (@{$attrseq || []}) {
        next if !$attrs->{$key};

        my $value = $attr->{$key};
        if (defined $value && $key ne $value) {
            push @rules, [ key($key) => $value ];
        }
        elsif ($key eq $value) {
            push @rules, key($key);
        }
    }

    $parser->{rules} ||= [];
    push @{$parser->{rules}}, $name => \@rules;
}

sub key {
    my $key = shift;
    return 'NOT_BLANK' if $key eq 'required';
    sprintf 'HTML_%s', uc $key;
}

!!1;
