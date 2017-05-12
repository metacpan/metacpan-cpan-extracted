package Faker::Role::Process;

use Faker::Role;
use Faker::Function qw(confess);

with 'Faker::Role::Format';

our $VERSION = '0.12'; # VERSION

has factory => (
    is       => 'ro',
    isa      => FAKER,
    required => 1,
);

method process (
    STRING :$random,
    STRING :$all_markers    = '',
    STRING :$lex_markers    = '',
    STRING :$line_markers   = '',
    STRING :$number_markers = ''
) {
    my $string = $self->process_random($random);
       $string = $self->process_markers($string)       if $all_markers;
       $string = $self->format_lex_markers($string)    if $lex_markers;
       $string = $self->format_line_markers($string)   if $line_markers;
       $string = $self->format_number_markers($string) if $number_markers;

    return $string;
}

method parse_format (STRING $string = '') {
    $string =~ s/\{\{\s?([#\.\w]+)\s?\}\}/$self->process_format($1)/eg;

    return $string;
}

method process_format (STRING $token, @args) {
    my $factory = $self->factory;
    my ($method, $provider) = reverse split /[#\.]/, $token;
    my $object  = $provider ? $factory->provider($provider) : $self;

    return $object->$method(@args) if $object->can($method);
    return $object->process_random($method);
}

method process_markers (STRING $string = '') {
    my @markers = qw(lex_markers line_markers number_markers);

    for my $marker (@markers) {
        my $filter = "format_${marker}";
        $string = $self->$filter($string);
    }

    return $string;
}

method process_random (STRING $name) {
    my $data = $self->data;
    my @samples = ($name, "format_for_${name}", "data_for_${name}");

    for my $sample (@samples) {
        if (my $array = $data->{$sample}) {
            my $format = $array->[rand @$array];
            return $self->parse_format($format);
        }
    }

    my $sections = join ' or ', @samples;
    confess "Unable to find data or formats for ($name) using $sections";
}

1;
