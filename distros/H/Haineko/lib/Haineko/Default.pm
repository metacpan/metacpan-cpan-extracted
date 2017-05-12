package Haineko::Default;
use strict;
use warnings;

sub conf {
    return {
        'smtpd' => { 
            'hostname' => '',               # used at EHLO
            'max_message_size' => 4194304,  # 4KB
            'max_rcpts_per_message' => 4,   # 4 recipients
            'max_workers' => 4,             # 4 worker processes
            'milter' => {
                'libs' => [],
            },
            'syslog' => {
                'disabled' => 1,
                'facility' => 'local2',
            },
        },
    };
}

sub table {
    my $class = shift;
    my $argvs = shift || return undef;
    my $table = {
        'mailer' => {
            'mail' => 'sendermt',
            'auth' => 'authinfo',
            'rcpt' => 'mailertable',
        },
        'access' => {
            'conn' => 'relayhosts',
            'rcpt' => 'recipients',
        },
    };

    return $table->{ $argvs } if exists $table->{ $argvs };
    return undef;
}

1;
__END__
=encoding utf8

=head1 NAME

Haineko::Default - Default configuration instead of etc/haineko.cf

=head1 DESCRIPTION

When etc/haineko.cf does not exist or failed to load at Haineko::HTTPD, This
class provides default configuration to run haineko server.

=head1 SYNOPSIS

    use Haineko::Default;
    my $v = undef;
    $v = Haineko::Default->conf;            # => isa 'HASH' # Default configuration
    $v = Haineko::Default->table('mailer'); # => isa 'HASH' # Mailer tables

=head1 CLASS METHODS

=head2 B<conf>

conf() returns a HASH reference which include default configuration for running
Haineko server.

    my $e = Haineko::Default->conf;
    warn Dumper $e;
    $VAR1 = {
        'smtpd' => { 
            'auth' => 0,
            'hostname' => '',
            'max_message_size' => 4194304,
            'max_rcpts_per_message' => 4,
            'max_workers' => 4,
            'milter' => {
                'libs' => [],
            },
            'syslog' => {
                'disabled' => 1,
                'facility' => 'local2',
            },
        },
    };

=head2 B<table( [I<Name>] )>

table() return a HASH reference which define external table file names. The argument
is 'mailer' or 'access'.

    my $e = Haineko::Default->table('mailer');
    warn Dumper $e;
    $VAR1 = {
        'mail' => 'sendermt',
        'auth' => 'authinfo',
        'rcpt' => 'mailertable',
    };


=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
