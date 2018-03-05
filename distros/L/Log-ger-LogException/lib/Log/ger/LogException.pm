package Log::ger::LogException;

our $DATE = '2018-03-05'; # DATE
our $VERSION = '0.001'; # VERSION

use Log::ger;

my $prev_die_handler  = $SIG{__DIE__};
my $prev_warn_handler = $SIG{__WARN__};

$SIG{__DIE__} = sub {
    my ($msg) = @_;
    chomp $msg;
    log_fatal "die(): $msg";
    if ($prev_die_handler) { goto &$prev_die_handler } else { die @_ }
};

$SIG{__WARN__} = sub {
    my ($msg) = @_;
    chomp $msg;
    log_warn "warn(): $msg";
    if ($prev_warn_handler) { goto &$prev_warn_handler } else { warn @_ }
};

1;
# ABSTRACT: Log warn()/die()

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::LogException - Log warn()/die()

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::LogException;

 warn "blah ..."; # "blah ..." will be logged as well as printed to stderr
 die  "argh ..."; # "argh ..." will be logged as well as printed to stderr, then we die

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
