package Foorum::Formatter::Pod;

use strict;
use warnings;

our $VERSION = '1.001000';

# most are copied from L<Angerwhale::Format::Pod>, Thank you, Jonathan Rockway

use IO::String;
use base qw(Pod::Xhtml);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        TopLinks     => 0,
        MakeIndex    => 0,
        FragmentOnly => 1,
        TopHeading   => 2,
    );
    return $self;
}

sub format {
    my $self = shift;
    my $text = shift;

    $text = "=pod\n\n$text" unless $text =~ /\n=[a-z]+\s/;

    my $input  = IO::String->new($text);
    my $result = IO::String->new;

    $self->parse_from_filehandle( $input, $result );

    my $output = ${ $result->string_ref };
    $output =~ s{\n</pre>}{</pre>}g;    # fixup some weird formatting
    return $output;
}

1;
