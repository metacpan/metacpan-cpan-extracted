# minimalism
## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Level::FromVar;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-18'; # DATE
our $DIST = 'Log-ger-Level-FromVar'; # DIST
our $VERSION = '0.001'; # VERSION

use Log::ger::Util;

sub import {
    my ($class, %args) = @_;
    my $var_name = $args{var_name};
    $var_name = "Default_Log_Level" unless defined $var_name;
    $var_name = "main::$var_name" unless $var_name =~ /::/;
    if (defined ${$var_name}) {
        Log::ger::Util::set_level(${$var_name});
    }
}

1;
# ABSTRACT: Set log level from some variable

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Level::FromVar - Set log level from some variable

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger;
 BEGIN { our $Default_Log_Level = 'info' }
 use Log::ger::Level::FromVar;

 log_info "blah ...";

To configure variable name:

 use Log::ger;
 BEGIN { our $Default_Level = 'info' }
 use Log::ger::Level::FromVar var_name => 'Default_Level';

 log_info "blah ...";

=head1 DESCRIPTION

This module sets C<$Log::ger::Current_Level> based on the value of a scalar
variable. The default name is C<main::Default_Log_Level> but it can be
customized via import argument C<var_name>, as shown in the Synopsis.

=head1 SEE ALSO

L<Log::ger::App> observes the same variable.

L<Log::ger::Screen> observes the same variable.

L<Log::ger::Level::FromEnv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
