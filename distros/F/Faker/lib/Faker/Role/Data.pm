package Faker::Role::Data;

use Faker::Role;
use Faker::Function qw(confess merge);

our $VERSION = '0.12'; # VERSION

has data => (
    is      => 'ro',
    isa     => HASH,
    builder => 'token_data',
    lazy    => 1,
);

method token_data () {
    my $class   = ref $self;
    my @parents = do { no strict 'refs'; @{"${class}::ISA"} };
    my @data    = {};

    for my $target ($class, @parents) {
        push @data => $self->token_data_from_file($target);
        push @data => $self->token_data_from_section($target);
    }

    return merge reverse @data;
}

method token_data_from_file (STRING $class) {
    my $file = $class;
       $file =~ s/::/\//g;

    my @data = ();
    my $path = $INC{"$file.pm"};

    for my $ext (qw(dat fmt)) {
        open(my $handle, "<:encoding(UTF-8)", "$path.$ext") or next;
        push @data, (<$handle>);
    }

    return $self->token_data_parser(join "\n", @data);
}

method token_data_from_section (STRING $class) {
    my $handle = do { no strict 'refs'; \*{"${class}::DATA"} };
    return {} if ! fileno $handle;

    seek $handle, 0, 0;
    my $data = join '', <$handle>;

    $data =~ s/^.*\n__DATA__\r?\n/\n/s;
    $data =~ s/\n__END__\r?\n.*$/\n/s;

    return $self->token_data_parser($data);
}

method token_data_parser (STRING $data) {
    my $mappings = {};
    my @chunks   = split /^@@\s*(.+?)\s*\r?\n/m, $data;

    shift (@chunks);
    while (@chunks) {
        my ($name, $data)  = splice @chunks, 0, 2;
        $mappings->{$name} = [split /\n+/, $data] if $name && $data;
    }

    return $mappings;
}

1;
