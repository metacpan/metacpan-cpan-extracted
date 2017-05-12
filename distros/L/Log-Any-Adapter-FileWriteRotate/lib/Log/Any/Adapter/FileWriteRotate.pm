package Log::Any::Adapter::FileWriteRotate;

our $DATE = '2016-10-02'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use parent qw(Log::Any::Adapter::Base);

my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};

sub init {
    require File::Write::Rotate;

    my ($self) = @_;
    $self->{default_level} //= 'warning';
    $self->{min_level}     //= $self->{default_level};

    $self->{_fwr} = File::Write::Rotate->new(
        dir         => $self->{dir},
        prefix      => $self->{prefix},
        (suffix      => $self->{suffix})      x !!defined($self->{suffix}),
        (size        => $self->{size})        x !!defined($self->{size}),
        (histories   => $self->{histories})   x !!defined($self->{histories}),
        (buffer_size => $self->{buffer_size}) x !!defined($self->{buffer_size}),
    );
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $msg) = @_;

            return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};

            $self->{_fwr}->write($msg);
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {
            my $self = shift;
            $logging_levels{$level} >= $logging_levels{$self->{min_level}};
        }
    );
}

1;
# ABSTRACT: Send logs to File::Write::Rotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::FileWriteRotate - Send logs to File::Write::Rotate

=head1 VERSION

This document describes version 0.001 of Log::Any::Adapter::FileWriteRotate (from Perl distribution Log-Any-Adapter-FileWriteRotate), released on 2016-10-02.

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('FileWriteRotate',
     dir          => '/var/log',    # required
     prefix       => 'myapp',       # required
     #suffix      => '.log',        # default is ''
     size         => 25*1024*1024,  # default is 10MB, unless period is set
     histories    => 12,            # default is 10
     #buffer_size => 100,           # default is none
 );

=head1 DESCRIPTION

This Log::Any adapter prints log messages to file through
L<File::Write::Rotate>.

=for Pod::Coverage ^(init)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-Adapter-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-Adapter-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-Adapter-FileWriteRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::Any>

L<File::Write::Rotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
