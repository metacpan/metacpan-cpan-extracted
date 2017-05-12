package Games::Lacuna::Task::Table;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
use Text::Table;

has 'headline' => (
    is              => 'rw',
    isa             => 'Str',
    predicate       => 'has_headline',
);

has 'columns' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    required        => 1,
);

has 'data' => (
    is              => 'rw',
    isa             => 'ArrayRef[HashRef]',
    traits          => ['Array'],
    default         => sub { [] },
    handles => {
        rows            => 'elements',
        add_row         => 'push',
    },
);

sub render_text {
    my ($self) = @_;
    
    my @header =
        map { ($_,\"|") }
        @{$self->columns};
    pop @header;
    
    my $table = Text::Table->new(
        @header
    );
    
    foreach my $row ($self->rows) {
        my @row;
        foreach my $column (@{$self->columns}) {
            my $column_key = lc($column);
            $column_key =~ s/\s+/_/g;
            push(@row,$row->{$column_key} // '');
        }
        $table->add(@row);
    }
    
    my $content = '';
    if ($self->has_headline) {
        $content .= '*'.uc($self->headline)."*\n";
    }
    $content .= $table->title;
    $content .= $table->rule('-','+');
    $content .= $table->body;
    
    return $content;
}

sub render_html {
    my ($self) = @_;
    
    my $rendered = '<div>';
    $rendered .= '<h2>'.$self->headline.'</h2>'
        if $self->has_headline;
    
    $rendered .= '<table witdh="100%"><thead><tr>';
    foreach my $column (@{$self->columns}) {
        $rendered .= '<th>'.$column.'</th>';
    }
    $rendered .= '</tr></thead><tbody>';
    foreach my $row ($self->rows) {
        $rendered .= '<tr>';
        foreach my $column (@{$self->columns}) {
            my $column_key = lc($column);
            $column_key =~ s/\s+/_/g;
            $rendered .= '<td>'.($row->{$column_key} // '').'</td>';
        }
        $rendered .= '</tr>';
    }
    $rendered .= '</tbody></table></div>';
    return $rendered;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Task::Table - Simple table for reports

=head1 SYNOPSIS

    my $table = Games::Lacuna::Task::Table->new(
        headline    => 'Some table',
        columns     => ['Column 1','Column 2'],
    );
    
    foreach (@data) {
        $table->add_row({
            column_1    => $_->[0],
            column_2    => $_->[1],
        });
    }
    
    say $table->render_text;

=head1 ACCESSORS

=head3 headline

Headline. [Optional]

=head3 columns

Array of column names. [Required]

=head3 data

Array of HashRefs. Usually not accessed directly.

=head1 METHODS

=head3 render_html

Render table as HTML.

=head3 render_text

Render table as plain text.

=head3 has_headline

Checks if headline is set

=head3 add_row

Add a new row.