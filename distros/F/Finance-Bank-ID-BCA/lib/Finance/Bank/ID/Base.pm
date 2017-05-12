package Finance::Bank::ID::Base;

our $DATE = '2015-09-08'; # DATE
our $VERSION = '0.43'; # VERSION

use 5.010;
use Moo;
use Log::Any::IfLOG '$log';

use Data::Dumper;
use Data::Rmap qw(:all);
use DateTime;
use Finance::BankUtils::ID::Mechanize;
use YAML::Syck qw(LoadFile DumpFile);

has mech        => (is => 'rw');
has username    => (is => 'rw');
has password    => (is => 'rw');
has logged_in   => (is => 'rw');
has accounts    => (is => 'rw');
has logger      => (is => 'rw',
                    default => sub { Log::Any::IfLOG->get_logger() } );
has logger_dump => (is => 'rw',
                    default => sub { Log::Any::IfLOG->get_logger() } );

has site => (is => 'rw');

has _req_counter => (is => 'rw', default => sub{0});

has verify_https => (is => 'rw', default => sub{0});
has https_ca_dir => (is => 'rw', default => sub{'/etc/ssl/certs'});
has https_host   => (is => 'rw');
has mode         => (is => 'rw', default => sub{''});
has save_dir     => (is => 'rw');

sub _fmtdate {
    my ($self, $dt) = @_;
    $dt->ymd;
}

sub _fmtdt {
    my ($self, $dt) = @_;
    $dt->datetime;
}

sub _dmp {
    my ($self, $var) = @_;
    Data::Dumper->new([$var])->Indent(0)->Terse(1)->Dump;
}

# strip non-digit characters
sub _stripD {
    my ($self, $s) = @_;
    $s =~ s/\D+//g;
    $s;
}

sub BUILD {
    my ($self, $args) = @_;

    # alias
    $self->username($args->{login}) if $args->{login} && !$self->username;
    $self->username($args->{user})  if $args->{user}  && !$self->username;
    $self->password($args->{pin})   if $args->{pin}   && !$self->password;
}

sub _set_default_mech {
    my ($self) = @_;
    $self->mech(
        Finance::BankUtils::ID::Mechanize->new(
            verify_https => $self->verify_https,
            https_ca_dir => $self->https_ca_dir,
            https_host   => $self->https_host,
        )
    );
}

sub _req {
    my ($self, $meth, $args, $opts) = @_;

    if (ref($opts) ne 'HASH') {
        die "Please update your module, 3rd arg is now a hashref since ".__PACKAGE__." 0.27";
    }

    $opts->{id} or die "BUG: Request does not have id";
    $opts->{id} =~ /\A[\w-]+\z/ or die "BUG: Invalid syntax in id '$opts->{id}'";

    $self->_set_default_mech unless $self->mech;
    my $mech = $self->mech;
    my $c = $self->_req_counter + 1;
    $self->_req_counter($c);
    $self->logger->debug("mech request #$c: $meth ".$self->_dmp($args)."");
    my $errmsg = "";

    eval {
        if ($self->mode eq 'simulation' &&
                $self->save_dir && (-f $self->save_dir . "/$opts->{id}.yaml")) {
            $Finance::BankUtils::ID::Mechanize::saved_resp =
                LoadFile($self->save_dir . "/$opts->{id}.yaml");
        }
        $mech->$meth(@$args);
        if ($self->save_dir && $self->mode ne 'simulation') {
            DumpFile($self->save_dir . "/$opts->{id}.yaml", $mech->response);
        }
    };
    my $evalerr = $@;

    eval {
        $self->logger_dump->debug(
            "<!-- result of mech request #$c ($meth ".$self->_dmp($args)."):\n".
            $mech->response->status_line."\n".
            $mech->response->headers->as_string."\n".
            "-->\n".
            $mech->content
            );
    };

    if ($evalerr) {
        # mech dies on error, we catch it so we can log it
        $errmsg = "die: $evalerr";
    } elsif (!$mech->success) {
        # actually mech usually dies if unsuccessful (see above), but
        # this is just in case
        $errmsg = "network error: " . $mech->response->status_line;
    } elsif ($opts->{after_request}) {
        $errmsg = $opts->{after_request}->($mech);
        $errmsg = "after_request check error: $errmsg" if $errmsg;
    }
    if ($errmsg) {
        $errmsg = "mech request #$c failed: $errmsg";
        $self->logger->fatal($errmsg);
        die $errmsg;
    }
}

sub login {
    die "Should be implemented by child";
}

sub logout {
    die "Should be implemented by child";
}

sub list_accounts {
    die "Should be implemented by child";
}

sub check_balance {
    die "Should be implemented by child";
}

sub get_balance { check_balance(@_) }

sub get_statement {
    die "Should be implemented by child";
}

sub check_statement { get_statement(@_) }

sub account_statement { get_statement(@_) }

sub parse_statement {
    my ($self, $page, %opts) = @_;
    my $status = 500;
    my $error = "";
    my $stmt = {};

    while (1) {
        my $err;
        if ($err = $self->_ps_detect($page, $stmt)) {
            $status = 400; $error = "Can't detect: $err"; last;
        }
        if ($err = $self->_ps_get_metadata($page, $stmt)) {
            $status = 400; $error = "Can't get metadata: $err"; last;
        }
        if ($err = $self->_ps_get_transactions($page, $stmt)) {
            $status = 400; $error = "Can't get transactions: $err"; last;
        }

        if (defined($stmt->{_total_debit_in_stmt})) {
            my $na = $stmt->{_total_debit_in_stmt};
            my $nb = 0;
            my $ntx = 0;
            for (@{ $stmt->{transactions} },
                 @{ $stmt->{skipped_transactions} }) {
                if ($_->{amount} < 0) {
                    $nb += -$_->{amount}; $ntx++;
                }
            }
            if (abs($na-$nb) >= 0.01) {
                $log->warn(
                    "Check failed: total debit do not match ".
                        "($na in summary line vs $nb when totalled from ".
                        "$ntx transactions(s))");
            }
        }
        if (defined($stmt->{_total_credit_in_stmt})) {
            my $na = $stmt->{_total_credit_in_stmt};
            my $nb = 0;
            my $ntx = 0;
            for (@{ $stmt->{transactions} },
                 @{ $stmt->{skipped_transactions} }) {
                if ($_->{amount} > 0) {
                    $nb += $_->{amount}; $ntx++;
                }
            }
            if (abs($na-$nb) >= 0.01) {
                $log->warn(
                    "Check failed: total credit do not match ".
                        "($na in summary line vs $nb when totalled from ".
                        "$ntx transactions(s))");
            }
        }
        if (defined($stmt->{_num_debit_tx_in_stmt})) {
            my $na = $stmt->{_num_debit_tx_in_stmt};
            my $nb = 0;
            for (@{ $stmt->{transactions} },
                 @{ $stmt->{skipped_transactions} }) {
                $nb += $_->{amount} < 0 ? 1 : 0;
            }
            if ($na != $nb) {
                $status = 400;
                $error = "Check failed: number of debit transactions ".
                    "do not match ($na in summary line vs $nb when totalled)";
                last;
            }
        }
        if (defined($stmt->{_num_credit_tx_in_stmt})) {
            my $na = $stmt->{_num_credit_tx_in_stmt};
            my $nb = 0;
            for (@{ $stmt->{transactions} },
                 @{ $stmt->{skipped_transactions} }) {
                $nb += $_->{amount} > 0 ? 1 : 0;
            }
            if ($na != $nb) {
                $status = 400;
                $error = "Check failed: number of credit transactions ".
                    "do not match ($na in summary line vs $nb when totalled)";
                last;
            }
        }

        $status = 200;
        last;
    }

    $self->logger->debug("parse_statement(): Temporary result: ".$self->_dmp($stmt));
    $self->logger->debug("parse_statement(): Status: $status ($error)");

    $stmt = undef unless $status == 200;
    $self->logger->debug("parse_statement(): Result: ".$self->_dmp($stmt));

    unless ($opts{return_datetime_obj} // 1) {
        # $_[0]{seen} = {} is a trick to allow multiple places which mention the
        # same object to be converted (defeat circular checking)
        rmap_ref {
            $_[0]{seen} = {};
            $_ = $self->_fmtdt($_) if UNIVERSAL::isa($_, "DateTime");
        } $stmt;
    }

    [$status, $error, $stmt];
}

1;
# ABSTRACT: Base class for Finance::Bank::ID::BCA etc

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Bank::ID::Base - Base class for Finance::Bank::ID::BCA etc

=head1 VERSION

This document describes version 0.43 of Finance::Bank::ID::Base (from Perl distribution Finance-Bank-ID-BCA), released on 2015-09-08.

=head1 SYNOPSIS

    # Don't use this module directly, use one of its subclasses instead.

=head1 DESCRIPTION

This module provides a base implementation for L<Finance::Bank::ID::BCA> and
L<Finance::Bank::ID::Mandiri>.

=head1 ATTRIBUTES

=head2 accounts

=head2 https_ca_dir

=head2 https_host

=head2 logged_in

=head2 logger

=head2 logger_dump

=head2 mech

=head2 password

=head2 site

=head2 username

=head2 verify_https

=head2 save_dir => STR

If set, each HTP response will be saved as YAML files in this dir. Existing
files will be overwritten.

=head2 mode => STR

Can be set to C<simulation> for simulation mode. In this mode, instead of
actually sending requests to network, each request will use responses saved
previously in C<save_dir>.

=head1 METHODS

=for Pod::Coverage ^(BUILD)$

=head2 new(%args) => OBJ

Create a new instance.

=head2 $obj->login()

Login to netbanking site.

=head2 $obj->logout()

Logout from netbanking site.

=head2 $obj->list_accounts()

List accounts.

=head2 $obj->check_balance([$acct])

=head2 $obj->get_balance()

Synonym for check_balance.

=head2 $obj->get_statement(%args)

Get account statement.

=head2 $obj->check_statement()

Alias for get_statement

=head2 $obj->account_statement()

Alias for get_statement

=head2 $obj->parse_statement($html_or_text, %opts)

Parse HTML/text into statement data.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Bank-ID-BCA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Bank-ID-BCA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-ID-BCA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
