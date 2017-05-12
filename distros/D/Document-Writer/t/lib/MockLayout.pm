package # Hide from CPAN
    MockLayout;
use Moose;

with 'Graphics::Primitive::Driver::TextLayout';

has 'component' => (
    is => 'rw',
    isa => 'Graphics::Primitive::TextBox'
);
has 'height' => (
    is => 'rw',
    isa => 'Num',
    default => 0
);
has 'width' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);
has 'lines' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] }
);

sub layout {
    my ($self) = @_;

    return unless(defined($self->component->text));

    my @lines = split("\n", $self->component->text);
    $self->lines(\@lines);
    $self->height(scalar(@lines));
}

sub slice {
    my ($self, $offset, $size) = @_;

    my $count = $self->height;

    unless(defined($size)) {
        $size = $self->height;
    }

    my @lines;
    my $using = 0;
    my $found = 0;
    for(my $i = 0; $i < $count; $i++) {
        if($found >= $offset) {
            push(@lines, $self->lines->[$i]);
            $using++;
        }
        $found++;
        last if($using >= $size);
    }
    return Graphics::Primitive::TextBox->new(
        minimum_width => $self->width,
        minimum_height => $using,
        lines => \@lines,
        size => $using
    );
}

1;