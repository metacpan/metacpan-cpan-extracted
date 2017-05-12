package HTTP::Proxy::Builder;

use strict;
use warnings;
our $VERSION = 0.01;

use File::Spec;
use HTTP::Proxy;

use Carp;
use Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( $proxy &proxy_load &proxy_abort );

my $abort = 0;

our $proxy;

$SIG{__DIE__} = sub {
    die @_ if $^S;
    $abort++;
};

sub import {
    my ($class) = @_;

    # there's only one thing in the import list that interests us
    $_[$_] eq 'no_start' && splice( @_, $_, 1 ) && $abort++ for 0 .. @_ - 1;

    # we let Exporter handle the rest
    $class->export_to_level( 1, @_ );

    # setup the proxy
    if ( !$proxy ) {
        my @args;

        # get our parameters from @ARGV
        if ( grep { $_ eq '--' } @ARGV ) {
            push @args, shift @ARGV while @ARGV && $ARGV[0] ne '--';
            shift @ARGV;    # get rid of the delimiter
        }
        else {
            @args = @ARGV;
            @ARGV = ();
        }

        # create the  proxy
        $proxy = HTTP::Proxy->new(@args);
    }
}

sub proxy_load {
    my @proxies = @_;

    for my $file (@proxies) {

        $file = File::Spec->rel2abs($file);

        # do file -- potentially dangerous
        my $return = do $file;
        carp "Couldn't parse $file: $@" if $@;
        carp "Couldn't do $file: $!"    if !defined $return;
    }
}

sub proxy_abort { $abort++ }

END { $proxy->start() if $proxy && !$abort; }

1;

__END__

=head1 NAME

HTTP::Proxy::Builder - Assemble several proxies into a single one.

=head1 SYNOPSIS

C<HTTP::Proxy::Builder> can be used in a single proxy script:

    use HTTP::Proxy::Builder;

    # The exported $proxy variable is a valid HTTP::Proxy object,
    # initialized when HTTP::Proxy::Builder is first used
    $proxy->push_filter( ... );

    # no call to $proxy->start() is needed

or to build larger proxies from individual ones:

    use HTTP::Proxy::Builder;

    proxy_load( 'myproxy.pl' );
    proxy_load( 'myotherproxy.pl' );


=head1 DESCRIPTION

Until now, HTTP::Proxy programs started as a simple one-purpose program,
and quickly grew out of that when one started to "enhance" more and more
web sites. Sometimes not all the features are needed, and commenting out
large sections of a big proxy script is not what one would call flexible.

With HTTP::Proxy::Builder it is now possible to keep proxyies with
different functionalities or aimed a different websites in separate
programs, and to combine them at will using a wrapper program that
aggregates them.

C<HTTP::Proxy::Builder> lets one build a fully working proxy, that
is also integrable into a larger script that loads all the individual
proxies and set them up as a single configurable multi-purpose proxy.

The B<build_proxy> command included in this distribution provides such
a flexible combining proxy.


=head1 EXPORTED VARIABLE

C<HTTP::Proxy::Builder> exports the C<$proxy> variable.

By default, it is configured like this:

    $proxy = HTTP::Proxy->new( @args );

Where C<@args> is the content of C<@ARGV> up to the first C<--> option
(which is removed, to allow further processing by the main program).


=head1 EXPORTED FUNCTIONS

C<HTTP::Proxy::Builder> exports the following functions:

=over 4

=item proxy_load( $file, ... )

Runs the script contained in the given file names.
The proxy script itself must C<use HTTP::Proxy::Builder> to work as expected.

B<This function will run one or several external files given by name:
this is potentially dangerous! Use at your own risk.>

=item proxy_abort( $reason )

Abort the proxy start. To be used when a proxy script must not be run.

Note that calling C<die()> in your script will automatically C<abort()>
(not in the context of an C<eval>, though).

=back


=head1 SEE ALSO

C<HTTP::Proxy>, code in the F<eg/> directory.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-http-proxy-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Proxy-Builder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Proxy::Builder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Proxy-Builder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Proxy-Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Proxy-Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-Proxy-Builder>

=back


=head1 COPYRIGHT

Copyright 2008 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

