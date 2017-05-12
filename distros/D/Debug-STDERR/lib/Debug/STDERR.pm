package Debug::STDERR;
use strict;
use warnings;
use constant DEBUG_FLAG => $ENV{DEBUG};
use Carp;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use POSIX qw(strftime);
use base qw(Exporter);
our @EXPORT = qw(debug);

our $VERSION = '0.00003';

if (DEBUG_FLAG) {

    # debug method
    *debug = sub {
        my $message = shift;
        my $hashref = shift;

        print STDERR "-" x 120, "\n";

        # timestamp
        my ( $sec, $microsec ) = gettimeofday;
        my $date = strftime( '%Y-%m-%d %H:%M:%S', localtime($sec) );
        print STDERR "$date $microsec\t";

        # caller info
        my ( $package, $filename, $line, $subroutine ) = caller();
        print STDERR "$subroutine\n" if $subroutine;
        print STDERR "  FROM    : $package of $filename line $line\n";

        # output message
        print STDERR "  MESSAGE : ", $message, "\n";
        if ( ref($hashref) eq "HASH" ) {
            print STDERR "  DUMPER  :\n";
            print STDERR "    ", Dumper($hashref);
        }
    };

    # save and redirect STDERR out to log file
    if ( my $logfile = $ENV{STDERR2LOG} ) {
        no warnings;
        open( SAVEERR, "<&STDERR" )  || confess "Cannot open SAVEERR";
        open( STDERR,  ">$logfile" ) || confess "Cannot open $logfile";
        $|++;
    }
}
else {

    # do nothing
    *debug = sub { };
}

1;
__END__

=head1 NAME

Debug::STDERR - provide debug() method and redirect STDERR. 

=head1 SYNOPSIS

  use strict;
  use warnings;

  # set environment variables, or set and export it for your shell

  BEGIN {
    $ENV{DEBUG} = 1;
    $ENV{STDERR2LOG} = "log.out";
  }

  use Debug::STDERR;

  debug( "foo" => { bar => "baz" });


=head1 DESCRIPTION

Debug::STDERR provides debug() method and redirect STDERR out to a file.

If you want to use it, you should set tow environment variables for your shell.

   $ export DEBUG=1
   $ export STDERR2LOG=log.out

or edit $ENV on BEGIN block. ( you must put it on before the line 'use Debug::STDERR;' ) 

If you set only 'DEBUG' variable, the debug messages out to STDERR.
Furthermore if you set 'STDERR2LOG' variable, the data for STDERR will be redirect to log file. 

=head1 OUTPUT SAMPLE

    # sample code   

    use strict;
    use warnings;
    use LWP::UserAgent;
    BEGIN {
        $ENV{DEBUG} = 1;
    }
    use Debug::STDERR;
    my $ua = LWP::UserAgent->new;
    debug( my_debug => { ua => $ua } );

   # output sample
    ------------------------------------------------------------------------------------------------------------------------
    2009-05-21 15:12:07 511529        FROM    : main of test.pl line 9 
      MESSAGE : my_debug
      DUMPER  :
        $VAR1 = {
              'ua' => bless( {
                               'max_redirect' => 7,
                               'protocols_forbidden' => undef,
                               'show_progress' => undef,
                               'handlers' => {
                                               'response_header' => bless( [
                                                                             {
                                                                               'owner' => 'LWP::UserAgent::parse_head',
                                                                               'callback' => sub { "DUMMY" },
                                                                               'm_media_type' => 'html',
                                                                               'line' => '/usr/local/lib/perl5/site_perl/5.10.0/LWP/UserAgent.pm:608'
                                                                             }
                                                                           ], 'HTTP::Config' )
                                             },
                               'no_proxy' => [],
                               'protocols_allowed' => undef,
                               'use_eval' => 1,
                               'requests_redirectable' => [
                                                            'GET',
                                                            'HEAD'
                                                          ],
                               'timeout' => 180,
                               'def_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/5.826'
                                                       }, 'HTTP::Headers' ),
                               'proxy' => {},
                               'max_size' => undef
                             }, 'LWP::UserAgent' )
            };

=head1 METHOD

=head2 debug($label => \%hash)

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
