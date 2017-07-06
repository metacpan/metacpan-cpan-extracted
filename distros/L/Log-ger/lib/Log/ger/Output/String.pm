package Log::ger::Output::String;

our $DATE = '2017-07-02'; # DATE
our $VERSION = '0.012'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    $conf{string} or die "Please specify string";

    my $formatter = $conf{formatter};
    my $append_newline = $conf{append_newline};
    $append_newline = 1 unless defined $append_newline;

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;
                my $level = $args{level};
                my $logger = sub {
                    my $msg = $_[1];
                    if ($formatter) {
                        $msg = $formatter->($msg);
                    }
                    ${ $conf{string} } .= $msg;
                    ${ $conf{string} } .= "\n"
                        unless !$append_newline || $msg =~ /\R\z/;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Set output to a string

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::String - Set output to a string

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use var '$str';
 use Log::ger::Output 'String' => (
     string => \$str,
     # append_newline => 0, # default is true, to mimic Log::ger::Output::Screen
 );
 use Log::ger;

 log_warn "warn ...";
 log_error "debug ...";

C<$str> will contain "warn ...\n".

=head1 DESCRIPTION

For testing only.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 string => scalarref

Required.

=head2 formatter => coderef

Optional.

=head2 append_newline => bool (default: 1)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
