package Log::ger::Output::Screen;

our $DATE = '2017-06-30'; # DATE
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

my %colors = (
    1 => "\e[31m"  , # fatal, red
    2 => "\e[35m"  , # error, magenta
    3 => "\e[1;34m", # warning, light blue
    4 => "\e[32m"  , # info, green
    5 => "",         # debug, no color
    6 => "\e[33m"  , # trace, orange
);

sub hook_before_log {
    my ($ctx, $msg) = @_;
}

sub hook_after_log {
    my ($ctx, $msg) = @_;
    print { $ctx->{_fh} } "\n" unless $msg =~ /\R\z/;
}

sub get_hooks {
    my %conf = @_;

    my $stderr = $conf{stderr};
    $stderr = 1 unless defined $stderr;
    my $handle = $stderr ? \*STDERR : \*STDOUT;
    my $use_color = $conf{use_color};
    $use_color = $ENV{COLOR} unless defined $use_color;
    $use_color = (-t STDOUT) unless defined $use_color;
    my $formatter = $conf{formatter};

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;
                my $logger = sub {
                    my $level = $args{level};
                    my $msg = $_[1];
                    if ($formatter) {
                        $msg = $formatter->($msg);
                    }
                    hook_before_log({ _fh=>$handle }, $msg);
                    if ($use_color) {
                        print $handle $colors{$level}, $msg, "\e[0m";
                    } else {
                        print $handle $msg;
                    }
                    hook_after_log({ _fh=>$handle }, $msg);
                };
                [$logger];
            }],
        create_logml_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;
                my $logger = sub {
                    my $level = Log::ger::Util::numeric_level($_[1]);
                    return if $level > $Log::ger::Current_Level;
                    my $msg = $_[2];
                    if ($formatter) {
                        $msg = $formatter->($msg);
                    }
                    hook_before_log({ _fh=>$handle }, $msg);
                    if ($use_color) {
                        print $handle $colors{$level}, $msg, "\e[0m";
                    } else {
                        print $handle $msg;
                    }
                    hook_after_log({ _fh=>$handle }, $msg);
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Output log to screen

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Screen - Output log to screen

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Log::ger::Output Screen => (
     # stderr => 1,    # set to 0 to print to stdout instead of stderr
     # use_color => 0, # set to 1/0 to force usage of color, default is from COLOR or (-t STDOUT)
     # formatter => sub { ... },
 );
 use Log::ger;

 log_warn "blah...";

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 stderr => bool (default: 1)

Whether to print to STDERR (the default) or st=head2 use_color => bool

=head2 use_color => bool

The default is to look at the COLOR environment variable, or 1 when in
interactive mode and 0 when not in interactive mode.

=head2 formatter => code

When defined, will pass the formatted message (but being applied with colors) to
this custom formatter.

=head1 TODO

Allow customizing colors.

=head1 ENVIRONMENT

=head2 COLOR => bool

=head1 SEE ALSO

Modelled after L<Log::Any::Adapter::Screen>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
