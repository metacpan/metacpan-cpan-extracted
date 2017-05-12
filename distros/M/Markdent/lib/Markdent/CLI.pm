package Markdent::CLI;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use File::Slurp qw( read_file );

# We need to make this a prereq so we have --help
use Getopt::Long::Descriptive;
use Markdent::Simple::Document;
use Markdent::Simple::Fragment;
use Markdent::Types qw( ArrayRef Bool ExistingFile Str );
use MooseX::Getopt::OptionTypeMap;

use Moose;

with 'MooseX::Getopt::Dashes';

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    ExistingFile() => '=s',
);

has file => (
    is        => 'ro',
    isa       => ExistingFile,
    predicate => 'has_file',
    documentation =>
        'A Markdown file to parse and turn into HTML. Conflicts with --text.',
);

has text => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_text',
    documentation =>
        'Markdown text to parse and turn into HTML. Conflicts with --file.',
);

has title => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_title',
    documentation => 'The title for the created document. Optional.',
);

has charset => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_charset',
    documentation => 'The charset for the created document. Optional.',
);

has language => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_language',
    documentation => 'The language for the created document. Optional.',
);

has dialects => (
    is            => 'ro',
    isa           => ArrayRef [Str],
    default       => sub { [] },
    documentation => 'One oe more dialects to use when parsing.',
);

sub BUILD {
    my $self = shift;

    die 'Cannot pass both --file and --text options'
        if $self->has_file() && $self->has_text();

    die 'You must pass a --file or --text parameter'
        unless $self->has_file() || $self->has_text();

    return;
}

sub run {
    my $self = shift;

    my $markdown
        = $self->has_file()
        ? read_file( $self->file() )
        : $self->text();

    my ( $class, %p )
        = $self->_has_title()
        ? (
        'Markdent::Simple::Document',
        title => $self->title(),
        ( $self->_has_charset()  ? ( charset  => $self->charset() )  : () ),
        ( $self->_has_language() ? ( language => $self->language() ) : () ),
        )
        : ('Markdent::Simple::Fragment');

    my $html = $class->new()->markdown_to_html(
        markdown => $markdown,
        dialects => $self->dialects(),
        %p,
    );

    ## no critic (InputOutput::RequireCheckedSyscalls)
    print $html;
    ## use critic;

    exit 0;
}

__PACKAGE__->meta()->make_immutable();

1;
