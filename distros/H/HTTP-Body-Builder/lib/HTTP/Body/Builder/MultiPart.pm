package HTTP::Body::Builder::MultiPart;
use strict;
use warnings;
use utf8;
use 5.008_005;

use File::Basename ();

my $CRLF = "\015\012";

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    my $content = delete $args{content};
    my $files = delete $args{files};
    my $self = bless {
        boundary => 'xYzZY',
        buffer_size => 2048,
        %args
    }, $class;
    if ($content) {
        for my $key (keys %{$content}) {
            for my $value (ref $content->{$key} ? @{$content->{$key}} : $content->{$key}) {
                $self->add_content($key => $value);
            }
        }
    }
    if ($files) {
        for my $name (keys %{$files}) {
            $self->add_file($name => $files->{$name});
        }
    }
    return $self;
}

sub add_content {
    my ($self, $name, $value) = @_;
    push @{$self->{content}}, [$name, $value];
}

sub add_file {
    my ($self, $name, $filename) = @_;
    push @{$self->{file}}, [$name, $filename];
}

sub content_type {
    my $self = shift;
    return 'multipart/form-data';
}

sub _gen {
    my ($self, $code) = @_;

    for my $row (@{$self->{content}}) {
        $code->(join('', "--$self->{boundary}$CRLF",
            qq{Content-Disposition: form-data; name="$row->[0]"$CRLF},
            "$CRLF",
            $row->[1] . $CRLF
        ));
    }
    for my $row (@{$self->{file}}) {
        my $filename = File::Basename::basename($row->[1]);
        $code->(join('', "--$self->{boundary}$CRLF",
            qq{Content-Disposition: form-data; name="$row->[0]"; filename="$filename"$CRLF},
            "Content-Type: text/plain$CRLF",
            "$CRLF",
        ));
        open my $fh, '<:raw', $row->[1]
            or do {
            $self->{errstr} = "Cannot open '$row->[1]' for reading: $!";
            return;
        };
        my $buf;
        while (1) {
            my $r = read $fh, $buf, $self->{buffer_size};
            if (not defined $r) {
                $self->{errstr} = "Cannot open '$row->[1]' for reading: $!";
                return;
            } elsif ($r == 0) { # eof
                last;
            } else {
                $code->($buf);
            }
        }
        $code->($CRLF);
    }
    $code->("--$self->{boundary}--$CRLF");
    return 1;
}

sub as_string {
    my ($self) = @_;
    my $buf = '';
    $self->_gen(sub { $buf .= $_[0] })
        or return;
    $buf;
}

sub errstr { shift->{errstr} }

sub write_file {
    my ($self, $filename) = @_;

    open my $fh, '>:raw', $filename
        or do {
        $self->{errstr} = "Cannot open '$filename' for writing: $!";
        return;
    };
    $self->_gen(sub { print {$fh} $_[0] })
        or return;
    close $fh;
}

1;
__END__

=head1 NAME

HTTP::Body::Builder::MultiPart - multipart/form-data

=head1 SYNOPSIS

    use HTTP::Body::Builder::MultiPart;

    my $builder = HTTP::Body::Builder::MultiPart->new();
    $builder->add_content('x' => 'y');
    $builder->as_string;
    # => x=y

=head1 METHODS

=over 4

=item my $builder = HTTP::Body::Builder::MultiPart->new()

Create a new HTTP::Body::Builder::MultiPart instance.

The constructor accepts named arguments as a hash. The allowed parameters are
C<content> and C<files>. Each of these parameters should in turn be a hashref.

For the C<content> parameter, each key/value pair in this hashref will be
added to the builder by calling the C<add_content> method.

For the C<files> parameter, the keys are parameter names and the values are
filenames.

If the value of one of the content hashref's keys is an arrayref, then each
member of the arrayref will be added separately.

    HTTP::Body::Builder::MultiPart->new(
        content => {'a' => 42, 'b' => [1, 2]},
        files   => {'x' => 'path/to/file'},
    );

is equivalent to the following:

    my $builder = HTTP::Body::Builder::MultiPart->new;
    $builder->add_content('a' => 42);
    $builder->add_content('b' => 1);
    $builder->add_content('b' => 2);
    $builder->add_files('x' => 'path/to/file');

=item $builder->add_content($key => $value);

Add new parameter in raw string.

=item $builder->add_file($key => $real_file_name);

Add C<$real_file_name> as C<$key>.

=item $builder->as_string();

Generate body as string.

=item $builder->write_file($filename);

Write the content to C<$filename>.

=back
