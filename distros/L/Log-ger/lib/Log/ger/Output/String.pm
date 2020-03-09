package Log::ger::Output::String;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.033'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %plugin_conf = @_;

    $plugin_conf{string} or die "Please specify string";

    my $formatter = $plugin_conf{formatter};
    my $append_newline = $plugin_conf{append_newline};
    $append_newline = 1 unless defined $append_newline;

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"
                my $level = $hook_args{level};
                my $outputter = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    if ($formatter) {
                        $msg = $formatter->($msg);
                    }
                    ${ $plugin_conf{string} } .= $msg;
                    ${ $plugin_conf{string} } .= "\n"
                        unless !$append_newline || $msg =~ /\R\z/;
                };
                [$outputter];
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

version 0.033

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

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
