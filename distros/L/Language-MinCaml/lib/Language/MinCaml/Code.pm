package Language::MinCaml::Code;
use strict;
use base qw(Class::Accessor::Fast);
use Carp;
use IO::File;

__PACKAGE__->mk_ro_accessors(qw(line column));

sub new {
    bless { buffer => q{},
            line => 0,
            column => 0,
            next_line => undef
        }, __PACKAGE__;
}

sub from_string {
    my($class, $string) = @_;
    my @lines = split(/\n/, $string);
    my $self = $class->new;

    $self->{next_line} = sub {
        if (@lines) {
            $self->{buffer} = shift @lines;
            $self->{line}++;
            $self->{column} = 1;
        }
        else {
            $self->{buffer} = q{};
            $self->{line} = 0;
            $self->{column} = 0;
        }
        return;
    };

    $self->{next_line}->();
    $self;
}

sub from_file {
    my($class, $file_path) = @_;
    my $handler = IO::File->new($file_path, 'r')
        or croak "Can't open '$file_path'.";
    my $self = $class->new;

    $self->{next_line} = sub {
        if ($handler->eof) {
            $handler->close;
            $self->{buffer} = q{};
            $self->{line} = 0;
            $self->{column} = 0;
        }
        else {
            $self->{buffer} = $handler->getline;
            chomp $self->{buffer};
            $self->{line}++;
            $self->{column} = 1;
        }
        return;
    };

    $self->{next_line}->();
    $self;
}

sub buffer {
    my $self = shift;
    $self->{buffer} ? substr($self->{buffer}, $self->{column} - 1) : q{};
}

sub forward {
    my($self, $number) = @_;
    $self->{column} += $number if $self->{buffer};
    $self->{next_line}->() if $self->{column} > length($self->{buffer});
    return;
}

1;
