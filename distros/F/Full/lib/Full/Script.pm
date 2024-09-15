package Full::Script;
use Full::Pragmata qw(:v1);
use parent qw(Full::Pragmata);

our $VERSION = '1.002'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Full::Script - common preämble for Perl scripts

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use Full::Script;
 $log->infof('Starting');
 await $loop->delay_future(after => 1);

=head1 DESCRIPTION

Loads common modules and applies language syntax and other features
as described in L<Full::Pragmata>.

The intention is to use this as the first line in every script or cron job
so that we have consistent configuration and language features. It also
allows us to apply new standards across the entire codebase without having
to modify the code itself.

=cut

use Log::Any::Adapter;
use Time::Moment;
use Time::Moment::Role::Strptime;
use Time::Moment::Role::TimeZone;
use Time::Moment;
use Role::Tiny;

# Extend Time::Moment to include ->strptime and some basic timezone support.
Role::Tiny->apply_roles_to_package('Time::Moment', qw(
    Time::Moment::Role::Strptime
    Time::Moment::Role::TimeZone
));

sub import ($called_on, $version, %args) {
    my $pkg  = $args{target} // caller(0);

    # Ensure we have a sensible encoding layer - scripts that expect
    # to work with binary data would need to remove this layer (and if
    # we do that often, we'll add an option for it).
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
    binmode STDIN,  ':encoding(UTF-8)';
    STDOUT->autoflush(1);

    Log::Any::Adapter->import('Stderr', log_level => $ENV{LOG_LEVEL} // 'info');

    # Apply pragmata
    return $called_on->next::method(
        $version,
        %args,
        target => $pkg,
    );
}

1;

__END__

=head1 AUTHOR

Original code can be found at https://github.com/deriv-com/perl-Myriad/tree/master/lib/Myriad/Class.pm,
by Deriv Group Services Ltd. C<< DERIV@cpan.org >>. This version has been split out as a way to provide
similar functionality.

=head1 LICENSE

Released under the same terms as Perl itself.

